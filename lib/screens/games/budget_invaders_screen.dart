import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shop_item_model.dart';
import '../../providers/shop_provider.dart';
import '../../providers/character_provider.dart';
import '../../widgets/coin_reward_overlay.dart';
import 'leaderboard_screen.dart';
import '../../core/extensions/theme_extensions.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class _Bullet {
  double x;
  double y;
  bool isEnemy;
  _Bullet({required this.x, required this.y, this.isEnemy = false});
}

class _Invader {
  double x;
  double y;
  int type; // 0-3
  bool alive;
  _Invader({required this.x, required this.y, required this.type, this.alive = true});
}

class _Particle {
  double x, y, vx, vy, life, maxLife;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  }) : maxLife = life;
}

// ─── Main Screen ────────────────────────────────────────────────────────────

class BudgetInvadersScreen extends StatefulWidget {
  /// When true the game starts immediately (pushed as a full-screen route).
  /// When false (default) the lobby/start screen is shown inside the tab.
  final bool autoStart;
  const BudgetInvadersScreen({super.key, this.autoStart = false});

  @override
  State<BudgetInvadersScreen> createState() => BudgetInvadersScreenState();
}

class BudgetInvadersScreenState extends State<BudgetInvadersScreen>
    with TickerProviderStateMixin {
  // Game area
  double _W = 0, _H = 0;

  // Player
  double _playerX = 0;
  final double _playerW = 44;
  final double _playerH = 36;
  double _playerY = 0;

  // Bullets
  final List<_Bullet> _bullets = [];
  double _shootCooldown = 0;

  // Invaders
  final List<_Invader> _invaders = [];

  // ── Smooth invader movement (speed scales as enemies die) ───────────────
  bool _invaderGoingRight = true;
  int _invaderTotal = 0;           // total enemies at wave start
  double _invaderBaseSpeedX = 60.0; // px/sec at full grid
  double _invaderMaxSpeedX  = 400.0; // px/sec when last enemy alive
  // Instant drop distance on wall hit (≈ one grid row)
  double _invaderDropY = 20.0;

  double _enemyShootTimer = 0;

  // Particles
  final List<_Particle> _particles = [];

  // Game state
  int _score = 0;
  int _highScore = 0;
  int _lives = 3;
  int _wave = 1;
  bool _gameOver = false;
  bool _gameStarted = false;
  bool _paused = false;

  // Timing
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // Gyro controls (EMP)
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSubscription;
  double _latestUserAccel = 0.0;
  double _empCooldown = 0.0;
  static const double _empMaxCooldown = 10.0;
  static const double _empRotationThreshold = 2.4;
  static const double _empMaxLinearAccel = 5.0;

  // Drag controls
  double? _dragStartX;
  double _dragAccumulator = 0.0;
  static const double _dragSensitivity = 1.2; // multiplier: drag px → player px

  // Shield blocks
  final List<Rect> _shields = [];

  final _rng = Random();
  final List<String> _invaderEmojis = ['💸', '🛍️', '🍕', '🎮'];
  final List<Color> _invaderColors = [
    AppColors.error,
    AppColors.warning,
    AppColors.secondaryNeon,
    AppColors.levelUpColor,
  ];

  // ── Upgrades loaded from ShopProvider ───────────────────────────────────
  GameUpgrades _upgrades = const GameUpgrades();

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _ticker = createTicker(_onTick);

    // Load game upgrades from ShopProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _upgrades = context.read<ShopProvider>().upgrades;
      }
    });

    // Listen to gyroscope for EMP attack
    _userAccelSubscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((UserAccelerometerEvent event) {
      _latestUserAccel = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
    });
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (_gameStarted && !_paused && !_gameOver) {
        // A flick on the Y or Z axis triggers EMP
        final hasStrongRotation =
            event.y.abs() > _empRotationThreshold || event.z.abs() > _empRotationThreshold;
        final hasLowLinearAccel = _latestUserAccel < _empMaxLinearAccel;
        if (hasStrongRotation && hasLowLinearAccel && _empCooldown <= 0) {
          _triggerEmp();
        }
      }
    });
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _userAccelSubscription?.cancel();
    _ticker.dispose();
    _exitFullscreen();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final provider = context.read<CharacterProvider>();
    int syncedScore = provider.character?.stats['budget_invaders_high_score'] ?? 0;

    // Migrate any existing old local score
    final prefs = await SharedPreferences.getInstance();
    int localScore = prefs.getInt('budget_invaders_high_score') ?? 0;

    if (localScore > syncedScore) {
      syncedScore = localScore;
      await provider.updateStat('budget_invaders_high_score', syncedScore);
    }

    if (mounted) {
      setState(() {
        _highScore = syncedScore;
      });
    }
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final provider = context.read<CharacterProvider>();
      await provider.updateStat('budget_invaders_high_score', _score);
      // We can also keep a local copy for redundancy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('budget_invaders_high_score', _score);

      if (mounted) {
        setState(() => _highScore = _score);
      }

      // Sync leaderboard rank — may grant/revoke exclusive rank frames
      provider.syncLeaderboardRank();
    }
  }

  void _initGame() {
    _upgrades = context.read<ShopProvider>().upgrades; // refresh on each new game
    _playerX = _W / 2;
    _playerY = _H - 80;
    _bullets.clear();
    _particles.clear();
    _shields.clear();
    _score = 0;
    _lives = 3 + _upgrades.extraLivesBonus;
    _wave = 1;
    _gameOver = false;
    _shootCooldown = 0;
    _empCooldown = 0.0;
    _dragAccumulator = 0.0;
    _dragStartX = null;
    _spawnWave();
    _spawnShields();
    _gameStarted = true;
    _lastTime = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
    _enterFullscreen();
  }

  void _spawnWave() {
    _invaders.clear();
    _invaderGoingRight = true;


    // Grow the grid slightly with each wave (capped)
    final cols = (6 + (_wave - 1)).clamp(6, 11);
    final rows = (3 + (_wave - 1)).clamp(3, 5);

    // Step size and drop scale with screen so it feels the same on any device
    _invaderBaseSpeedX = _W * 0.08 + (_wave - 1) * _W * 0.01; // grows slightly each wave
    _invaderMaxSpeedX  = _W * 0.65;
    _invaderDropY      = _H * 0.025;

    final spacingX = _W * 0.64 / (cols - 1);
    final spacingY = 46.0;
    final startX  = _W * 0.18;
    const startY  = 70.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _invaders.add(_Invader(
          x: startX + c * spacingX,
          y: startY + r * spacingY,
          type: r % 4,
        ));
      }
    }
    _invaderTotal = _invaders.length;
  }

  void _spawnShields() {
    _shields.clear();
    final positions = [_W * 0.2, _W * 0.5, _W * 0.8];
    const shW = 50.0, shH = 20.0;
    for (final px in positions) {
      for (int r = 0; r < 2; r++) {
        for (int c = 0; c < 3; c++) {
          _shields.add(Rect.fromLTWH(
            px - shW * 1.5 / 2 + c * (shW / 2),
            _playerY - 70 + r * (shH / 2 + 4),
            shW / 2 - 2,
            shH / 2 - 2,
          ));
        }
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    if (_paused || _gameOver || !_gameStarted) return;

    final dt = (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;

    setState(() {
      _update(dt.clamp(0.0, 0.05));
    });
  }


  void _update(double dt) {
    // ── Player movement via drag accumulator ─────────────────────────────
    if (_dragAccumulator != 0.0) {
      _playerX = (_playerX + _dragAccumulator).clamp(_playerW / 2, _W - _playerW / 2);
      _dragAccumulator = 0.0;
    }

    // ── Auto-shoot ───────────────────────────────────────────────────────
    _shootCooldown -= dt;
    if (_shootCooldown <= 0) _shoot();

    if (_empCooldown > 0) {
      _empCooldown -= dt;
    }

    // ── Move bullets ─────────────────────────────────────────────────────
    final bulletSpeed = _upgrades.bulletSpeed;
    for (final b in _bullets) {
      b.y += (b.isEnemy ? 1 : -1) * bulletSpeed * dt;
    }

    // ── Player bullet vs invader ─────────────────────────────────────────
    for (final b in _bullets.where((b) => !b.isEnemy).toList()) {
      for (final inv in _invaders.where((i) => i.alive)) {
        if ((b.x - inv.x).abs() < 22 && (b.y - inv.y).abs() < 20) {
          inv.alive = false;
          b.y = -999;
          _score += (inv.type + 1) * 10 * _wave;
          _spawnExplosion(inv.x, inv.y, _invaderColors[inv.type]);
          HapticFeedback.lightImpact();
        }
      }
    }

    // ── Enemy bullet vs player ───────────────────────────────────────────
    for (final b in _bullets.where((b) => b.isEnemy).toList()) {
      if ((b.x - _playerX).abs() < _playerW / 2 &&
          (b.y - _playerY).abs() < _playerH / 2) {
        b.y = 9999;
        _lives--;
        _spawnExplosion(_playerX, _playerY, AppColors.primaryNeon);
        HapticFeedback.heavyImpact();
        if (_lives <= 0) {
          _gameOver = true;
          _ticker.stop();
          _exitFullscreen();
          _saveHighScore();
        }
      }
      // vs shields — use rect overlap so thin bullets don't pass through
      final bulletRect = Rect.fromCenter(
        center: Offset(b.x, b.y),
        width: 4,
        height: 10,
      );
      final hitShield = _shields.indexWhere((s) => s.overlaps(bulletRect));
      if (hitShield != -1) {
        _shields.removeAt(hitShield);
        b.y = 9999; // kill the bullet
      }
    }

    // ── Remove off-screen bullets ────────────────────────────────────────
    _bullets.removeWhere((b) => b.y < -10 || b.y > _H + 10);

    // ── Space Invaders step-based movement ──────────────────────────────────
    {
      final alive = _invaders.where((i) => i.alive).toList();

      if (alive.isEmpty) {
        // Wave clear — award capped coins then advance
        final coinReward = (_wave * 5).clamp(0, 30);
        if (mounted) {
          context.read<CharacterProvider>().addCoins(coinReward);
          CoinRewardOverlay.show(context, coinReward);
        }
        _wave++;
        _spawnWave();
        _spawnShields();
      } else {
        // Smooth velocity-based movement; speed scales linearly with kill fraction
        final killFraction = 1.0 - (alive.length / _invaderTotal.clamp(1, 999));
        final speedX = _invaderBaseSpeedX +
            killFraction * (_invaderMaxSpeedX - _invaderBaseSpeedX);

        final dx = (_invaderGoingRight ? 1 : -1) * speedX * dt;
        for (final inv in alive) {
          inv.x += dx;
        }

        // Wall detection: instant drop + direction flip
        final rightmost = alive.map((i) => i.x).reduce(max);
        final leftmost  = alive.map((i) => i.x).reduce(min);

        final hitRight = _invaderGoingRight && rightmost >= _W - 20;
        final hitLeft  = !_invaderGoingRight && leftmost  <= 20;

        if (hitRight || hitLeft) {
          _invaderGoingRight = !_invaderGoingRight;
          for (final inv in alive) {
            inv.y += _invaderDropY;
          }
          if (alive.any((i) => i.y >= _playerY - 20)) {
            _gameOver = true;
            _ticker.stop();
            _exitFullscreen();
            _saveHighScore();
          }
        }
      }
    }

    // ── Enemy shooting (original: bottom-most alive in a random column) ────
    _enemyShootTimer += dt;
    // Shoot interval shrinks with wave; floor at 0.4 s
    final shootInterval = max(0.4, 2.0 - (_wave - 1) * 0.15);
    if (_enemyShootTimer >= shootInterval) {
      _enemyShootTimer = 0;
      final alive = _invaders.where((i) => i.alive).toList();
      if (alive.isNotEmpty) {
        // Group by column (enemies share x within ±4 px because they move together)
        final Map<int, List<_Invader>> byCol = {};
        for (final inv in alive) {
          final col = (inv.x / 40.0).round(); // group enemies by ~40px column buckets
          byCol.putIfAbsent(col, () => []).add(inv);
        }
        // Pick a random column and shoot from its bottom-most invader
        final cols = byCol.values.toList();
        final colInvaders = cols[_rng.nextInt(cols.length)];
        colInvaders.sort((a, b) => b.y.compareTo(a.y)); // highest y = bottom
        final shooter = colInvaders.first;
        _bullets.add(_Bullet(x: shooter.x, y: shooter.y + 16, isEnemy: true));
      }
    }

    // ── Particles ────────────────────────────────────────────────────────
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void _shoot() {
    if (_shootCooldown > 0) return;
    _bullets.add(_Bullet(x: _playerX, y: _playerY - _playerH / 2));
    _shootCooldown = 0.3; // upgrades don't touch shoot cooldown in current scope
    HapticFeedback.selectionClick();
  }

  void _triggerEmp() {
    _empCooldown = _empMaxCooldown;
    HapticFeedback.heavyImpact();
    
    // Destroy all enemy bullets
    for (var b in _bullets.where((b) => b.isEnemy)) {
      _spawnExplosion(b.x, b.y, AppColors.primaryNeon);
    }
    _bullets.removeWhere((b) => b.isEnemy);

    // Visual explosion
    for (int i = 0; i < 30; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 100 + _rng.nextDouble() * 300;
      _particles.add(_Particle(
        x: _playerX,
        y: _playerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.8 + _rng.nextDouble() * 0.8,
        color: AppColors.secondaryNeon,
      ));
    }
  }

  void _spawnExplosion(double x, double y, Color color) {
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 50 + _rng.nextDouble() * 120;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.4 + _rng.nextDouble() * 0.4,
        color: color,
      ));
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  // Returns true if a game is actively running (needs confirmation to leave)
  bool get isGameActive => _gameStarted && !_gameOver;

  Future<bool> onWillPop() async {
    return await _onWillPop();
  }

  Future<bool> _onWillPop() async {
    if (!isGameActive) return true;

    // Pause the game while the dialog is shown
    final wasPaused = _paused;
    setState(() => _paused = true);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: AppColors.primaryNeon.withOpacity(0.5), width: 2),
        ),
        title: const Text(
          '🚀 Keluar Game?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNeon,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Permainan sedang berlangsung.\nProgress kamu akan hilang jika keluar.',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: context.textDim,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Lanjut Main',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.secondaryNeon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // If user cancelled, restore previous pause state
    if (confirmed != true && mounted) {
      setState(() => _paused = wasPaused);
    }

    return confirmed == true;
  }

  void resetGame() {
    _exitFullscreen();
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _paused = false;
      if (_ticker.isActive) _ticker.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // In autoStart (game route): only intercept while game is active.
      // In lobby (tab): intercept game-over so back resets to start screen.
      canPop: widget.autoStart ? !isGameActive : (!isGameActive && !_gameOver),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!widget.autoStart && _gameOver) {
          // Lobby mode + game over → reset to start screen
          resetGame();
          return;
        }
        if (isGameActive) {
          final shouldQuit = await _onWillPop();
          if (shouldQuit && mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        leading: widget.autoStart
            // ── Full-screen game route: always show back button
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (isGameActive) {
                    final shouldQuit = await _onWillPop();
                    if (shouldQuit && mounted) Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              )
            // ── Lobby tab: back button only while game is active
            : isGameActive
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      final shouldQuit = await _onWillPop();
                      if (shouldQuit && mounted) resetGame();
                    },
                  )
                : null,
        title: Row(
          children: [
            const Text('💰 Budget Invaders',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (!_gameStarted || _gameOver)
              IconButton(
                icon: const Icon(Icons.leaderboard, color: AppColors.xpColor),
                tooltip: 'Leaderboard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen()),
                  );
                },
              ),
            if (_gameStarted && !_gameOver) ...[
              IconButton(
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause,
                    color: AppColors.primaryNeon),
                onPressed: () => setState(() => _paused = !_paused),
              ),
            ],
          ],
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        _W = constraints.maxWidth;
        _H = constraints.maxHeight;
        if (_playerY == 0) {
          _playerY = _H - 80;
          // Auto-start game on first layout (only in autoStart mode)
          if (widget.autoStart && !_gameStarted && !_gameOver) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_gameStarted) _initGame();
            });
          }
        }

        // Wrap in GestureDetector for drag-to-move on the game canvas
        return GestureDetector(
          // Tap to shoot (when no drag detected)
          onTap: _gameStarted && !_gameOver && !_paused
              ? () => _shoot()
              : null,

          // ── Drag controls ──────────────────────────────────────────────
          onHorizontalDragStart: (_gameStarted && !_gameOver && !_paused)
              ? (details) {
                  _dragStartX = details.localPosition.dx;
                }
              : null,

          onHorizontalDragUpdate: (_gameStarted && !_gameOver && !_paused)
              ? (details) {
                  if (_dragStartX != null) {
                    final delta = details.localPosition.dx - _dragStartX!;
                    _dragStartX = details.localPosition.dx;
                    // Accumulate; game loop will flush on next tick
                    _dragAccumulator += delta * _dragSensitivity;
                  }
                }
              : null,

          onHorizontalDragEnd: (_gameStarted && !_gameOver && !_paused)
              ? (details) {
                  _dragStartX = null;
                  _dragAccumulator = 0.0;
                }
              : null,

          child: Stack(
            children: [
              // Starfield background
              CustomPaint(painter: _StarfieldPainter(), size: Size(_W, _H)),

              // Game canvas
              if (_gameStarted)
                CustomPaint(
                  painter: _GamePainter(
                    playerX: _playerX,
                    playerY: _playerY,
                    playerW: _playerW,
                    playerH: _playerH,
                    bullets: _bullets,
                    invaders: _invaders,
                    particles: _particles,
                    shields: _shields,
                    invaderEmojis: _invaderEmojis,
                    invaderColors: _invaderColors,
                  ),
                  size: Size(_W, _H),
                ),

              // HUD
              if (_gameStarted)
                Positioned(
                  top: 4,
                  left: 12,
                  right: 12,
                  child: _HUD(
                      score: _score,
                      lives: _lives,
                      maxLives: 3 + _upgrades.extraLivesBonus,
                      wave: _wave,
                      highScore: _highScore,
                      empCooldown: _empCooldown,
                      empMaxCooldown: _empMaxCooldown),
                ),

              // Start screen
              if (!_gameStarted) _buildStartScreen(),

              // Pause overlay
              if (_paused && _gameStarted && !_gameOver)
                _buildOverlay(
                    '⏸ PAUSED', 'Tap tombol play untuk lanjut', null, null),

              // Game over
              if (_gameOver)
                _buildOverlay('💥 GAME OVER',
                    'Tabunganmu diserang!\nSkor: $_score', 'Main Lagi', _initGame),
            ],
          ),
        );
      }),
    ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      color: context.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💰', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text('BUDGET INVADERS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppColors.primaryNeon,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 8),
            Text('High Score: $_highScore',
                style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.xpColor,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 24),
            _buildLegend(),
            const SizedBox(height: 20),
            Text(
              '👆 Drag layar untuk gerak\n'
              '⚡ Goyangkan HP (flick) untuk EMP (Hapus peluru musuh!)\n'
              '🚀 Jangan sampai nyawamu habis!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: context.textDim,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            Text('Lindungi tabunganmu dari serangan pengeluaran!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: context.textDim,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNeon,
                foregroundColor: AppColors.darkBg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Push a full-screen game route (hides navbar)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BudgetInvadersScreen(autoStart: true),
                  ),
                );
              },
              child: const Text('MULAI GAME',

                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      ('💸', 'Pembelanjaan', '10 pts'),
      ('🛍️', 'Belanja', '20 pts'),
      ('🍕', 'Makanan', '30 pts'),
      ('🎮', 'Hiburan', '40 pts'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNeon.withOpacity(0.3)),
      ),
      child: Column(
        children: items
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 80,
                          child: Text(e.$2,
                              style: TextStyle(
                                  color: context.text,
                                  fontFamily: 'Poppins',
                                  fontSize: 13))),
                      const SizedBox(width: 8),
                      Text(e.$3,
                          style: const TextStyle(
                              color: AppColors.xpColor,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildOverlay(
      String title, String subtitle, String? btnLabel, VoidCallback? onBtn) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.primaryNeon.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: AppColors.primaryNeon,
                  )),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
              if (btnLabel != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    foregroundColor: AppColors.darkBg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onBtn,
                  child: Text(btnLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HUD Widget ─────────────────────────────────────────────────────────────

class _HUD extends StatelessWidget {
  final int score, lives, maxLives, wave, highScore;
  final double empCooldown;
  final double empMaxCooldown;
  const _HUD(
      {required this.score,
      required this.lives,
      required this.maxLives,
      required this.wave,
      required this.highScore,
      required this.empCooldown,
      required this.empMaxCooldown});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('⭐ $score',
            style: const TextStyle(
                color: AppColors.xpColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(width: 12),
        Text('Best: $highScore',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontSize: 12)),
        const Spacer(),
        // EMP Indicator
        if (empCooldown <= 0)
          const Text('⚡ EMP READY', style: TextStyle(color: AppColors.secondaryNeon, fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold))
        else
          SizedBox(
            width: 40,
            height: 4,
            child: LinearProgressIndicator(
              value: 1 - (empCooldown / empMaxCooldown),
              backgroundColor: Colors.white24,
              color: AppColors.secondaryNeon,
            )
          ),
        const SizedBox(width: 12),
        Text('Wave $wave',
            style: const TextStyle(
                color: AppColors.secondaryNeon,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(width: 12),
        Row(
            children: List.generate(
                maxLives,
                (i) => Text(
                      i < lives ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 16),
                    ))),
      ],
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  final _stars = <Offset>[];
  _StarfieldPainter() {
    final rng = Random(42);
    for (int i = 0; i < 80; i++) {
      _stars.add(Offset(rng.nextDouble(), rng.nextDouble()));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);
    for (final s in _stars) {
      canvas.drawCircle(
          Offset(s.dx * size.width, s.dy * size.height), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GamePainter extends CustomPainter {
  final double playerX, playerY, playerW, playerH;
  final List<_Bullet> bullets;
  final List<_Invader> invaders;
  final List<_Particle> particles;
  final List<Rect> shields;
  final List<String> invaderEmojis;
  final List<Color> invaderColors;

  const _GamePainter({
    required this.playerX,
    required this.playerY,
    required this.playerW,
    required this.playerH,
    required this.bullets,
    required this.invaders,
    required this.particles,
    required this.shields,
    required this.invaderEmojis,
    required this.invaderColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Draw shields
    final shieldPaint = Paint()..color = AppColors.primaryNeon.withOpacity(0.5);
    for (final s in shields) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(s, const Radius.circular(4)), shieldPaint);
    }

    // Draw invaders
    for (final inv in invaders.where((i) => i.alive)) {
      tp.text = TextSpan(
          text: invaderEmojis[inv.type],
          style: const TextStyle(fontSize: 22));
      tp.layout();
      tp.paint(canvas, Offset(inv.x - tp.width / 2, inv.y - tp.height / 2));
    }

    // Draw player ship (triangle with notch)
    final playerPaint = Paint()
      ..color = AppColors.primaryNeon
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = AppColors.primaryNeon.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(playerX, playerY - playerH / 2);
    path.lineTo(playerX - playerW / 2, playerY + playerH / 2);
    path.lineTo(playerX - playerW / 6, playerY + playerH / 4);
    path.lineTo(playerX, playerY + playerH / 2 - 8);
    path.lineTo(playerX + playerW / 6, playerY + playerH / 4);
    path.lineTo(playerX + playerW / 2, playerY + playerH / 2);
    path.close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, playerPaint);

    // Draw bullets
    for (final b in bullets) {
      final bPaint = Paint()
        ..color = b.isEnemy ? AppColors.error : AppColors.primaryNeon
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRect(
          Rect.fromCenter(
            center: Offset(b.x, b.y),
            width: b.isEnemy ? 4 : 3,
            height: b.isEnemy ? 10 : 14,
          ),
          bPaint);
    }

    // Draw particles
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final pPaint = Paint()..color = p.color.withOpacity(alpha);
      canvas.drawCircle(Offset(p.x, p.y), 3 * alpha, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}