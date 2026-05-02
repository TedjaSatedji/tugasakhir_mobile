import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

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
  const BudgetInvadersScreen({super.key});

  @override
  State<BudgetInvadersScreen> createState() => _BudgetInvadersScreenState();
}

class _BudgetInvadersScreenState extends State<BudgetInvadersScreen>
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

  // Smooth invader movement state
  bool _invaderGoingRight = true;
  double _invaderSpeedX = 60.0; // px/sec horizontal speed
  double _invaderDropAmount = 0.0; // pending drop distance
  double _invaderDropProgress = 0.0; // how much of the drop is done
  static const double _invaderDropStep = 22.0; // px to drop each direction change
  static const double _invaderDropSpeed = 80.0; // px/sec drop speed

  double _enemyShootTimer = 0;

  // Particles
  final List<_Particle> _particles = [];

  // Game state
  int _score = 0;
  int _highScore = 0;
  int _lives = 3;
  int _wave = 1;
  bool _gameOver = false;
  bool _gameWon = false;
  bool _gameStarted = false;
  bool _paused = false;

  // Timing
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

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

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('budget_invaders_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('budget_invaders_high_score', _score);
      setState(() => _highScore = _score);
    }
  }

  void _initGame() {
    _playerX = _W / 2;
    _playerY = _H - 80;
    _bullets.clear();
    _particles.clear();
    _shields.clear();
    _score = 0;
    _lives = 3;
    _wave = 1;
    _gameOver = false;
    _gameWon = false;
    _shootCooldown = 0;
    _dragAccumulator = 0.0;
    _dragStartX = null;
    _spawnWave();
    _spawnShields();
    _gameStarted = true;
    _lastTime = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _spawnWave() {
    _invaders.clear();
    _invaderGoingRight = true;
    _invaderDropAmount = 0.0;
    _invaderDropProgress = 0.0;

    // Base speed scales up with wave; caps at ~150 px/sec
    _invaderSpeedX = min(150.0, 30.0 + (_wave - 1) * 15.0);

    const cols = 6, rows = 4;
    final startX = _W * 0.18;
    const startY = 80.0;
    final spacingX = (_W - startX * 2) / (cols - 1);
    const spacingY = 50.0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _invaders.add(_Invader(
          x: startX + c * spacingX,
          y: startY + r * spacingY,
          type: r % 4,
        ));
      }
    }
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
    if (_paused || _gameOver || _gameWon || !_gameStarted) return;

    final dt = (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;

    setState(() {
      _update(dt.clamp(0.0, 0.05));
    });
  }

  // ─── Returns a speed multiplier based on alive count (fewer = faster) ───
  double _invaderSpeedMultiplier() {
    final total = _invaders.length;
    final alive = _invaders.where((i) => i.alive).length;
    if (total == 0) return 1.0;
    // Scale from 1.0 at full grid to 2.0 at last invader
    final frac = alive / total;
    return 1.0 + (1.0 - frac) * 1.0;
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

    // ── Move bullets ─────────────────────────────────────────────────────
    const bulletSpeed = 420.0;
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
      // vs shields
      _shields.removeWhere((s) => s.contains(Offset(b.x, b.y)));
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
          _saveHighScore();
        }
      }
      // vs shields
      _shields.removeWhere((s) => s.contains(Offset(b.x, b.y)));
    }

    // ── Remove off-screen bullets ────────────────────────────────────────
    _bullets.removeWhere((b) => b.y < -10 || b.y > _H + 10);

    // ── Invader smooth movement ──────────────────────────────────────────
    {
      final alive = _invaders.where((i) => i.alive).toList();

      if (alive.isEmpty) {
        // Wave clear
        _wave++;
        if (_wave > 5) {
          _gameWon = true;
          _ticker.stop();
          _saveHighScore();
        } else {
          _spawnWave();
          _spawnShields();
        }
      } else {
        final speedMul = _invaderSpeedMultiplier();
        final effectiveSpeedX = _invaderSpeedX * speedMul;

        if (_invaderDropAmount > 0) {
          // Currently dropping — move everything down
          final dropThisFrame = _invaderDropSpeed * dt * speedMul;
          final actual = min(dropThisFrame, _invaderDropAmount);
          for (final inv in alive) {
            inv.y += actual;
          }
          _invaderDropAmount -= actual;

          // Check if invaders reached player line after drop
          if (alive.any((i) => i.y >= _playerY - 20)) {
            _gameOver = true;
            _ticker.stop();
            _saveHighScore();
          }
        } else {
          // Horizontal movement
          final dx = (_invaderGoingRight ? 1 : -1) * effectiveSpeedX * dt;
          for (final inv in alive) {
            inv.x += dx;
          }

          // Check bounds
          final rightmost = alive.map((i) => i.x).reduce(max);
          final leftmost = alive.map((i) => i.x).reduce(min);

          if (_invaderGoingRight && rightmost >= _W - 28) {
            _invaderGoingRight = false;
            _invaderDropAmount = _invaderDropStep;
          } else if (!_invaderGoingRight && leftmost <= 28) {
            _invaderGoingRight = true;
            _invaderDropAmount = _invaderDropStep;
          }
        }
      }
    }

    // ── Enemy shooting ───────────────────────────────────────────────────
    _enemyShootTimer += dt;
    final shootInterval = max(0.6, 2.5 - (_wave - 1) * 0.3);
    if (_enemyShootTimer >= shootInterval) {
      _enemyShootTimer = 0;
      final alive = _invaders.where((i) => i.alive).toList();
      if (alive.isNotEmpty) {
        final shooter = alive[_rng.nextInt(alive.length)];
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
    _shootCooldown = 0.3;
    HapticFeedback.selectionClick();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: Row(
          children: [
            const Text('💰 Budget Invaders',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_gameStarted && !_gameOver && !_gameWon) ...[
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
        if (_playerY == 0) _playerY = _H - 80;

        // Wrap in GestureDetector for drag-to-move on the game canvas
        return GestureDetector(
          // Tap to shoot (when no drag detected)
          onTap: _gameStarted && !_gameOver && !_gameWon && !_paused
              ? () => _shoot()
              : null,

          // ── Drag controls ──────────────────────────────────────────────
          onHorizontalDragStart: (_gameStarted && !_gameOver && !_gameWon && !_paused)
              ? (details) {
                  _dragStartX = details.localPosition.dx;
                }
              : null,

          onHorizontalDragUpdate: (_gameStarted && !_gameOver && !_gameWon && !_paused)
              ? (details) {
                  if (_dragStartX != null) {
                    final delta = details.localPosition.dx - _dragStartX!;
                    _dragStartX = details.localPosition.dx;
                    // Accumulate; game loop will flush on next tick
                    _dragAccumulator += delta * _dragSensitivity;
                  }
                }
              : null,

          onHorizontalDragEnd: (_gameStarted && !_gameOver && !_gameWon && !_paused)
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
                      wave: _wave,
                      highScore: _highScore),
                ),

              // Start screen
              if (!_gameStarted) _buildStartScreen(),

              // Pause overlay
              if (_paused && _gameStarted && !_gameOver && !_gameWon)
                _buildOverlay(
                    '⏸ PAUSED', 'Tap tombol play untuk lanjut', null, null),

              // Game over
              if (_gameOver)
                _buildOverlay('💥 GAME OVER',
                    'Tabunganmu diserang!\nSkor: $_score', 'Main Lagi', _initGame),

              // Game won
              if (_gameWon)
                _buildOverlay('🏆 MENANG!',
                    'Semua invader dikalahkan!\nSkor: $_score', 'Main Lagi', _initGame),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      color: AppColors.darkBg,
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
            const Text(
              '👆 Drag layar atau pakai tombol ◀ ▶ untuk gerak\n'
              '🚀 Tap layar atau tombol 🚀 untuk tembak',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            const Text('Lindungi tabunganmu dari serangan pengeluaran!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
              onPressed: _initGame,
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
        color: AppColors.darkCard,
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
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
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
  final int score, lives, wave, highScore;
  const _HUD(
      {required this.score,
      required this.lives,
      required this.wave,
      required this.highScore});

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
        Text('Wave $wave',
            style: const TextStyle(
                color: AppColors.secondaryNeon,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(width: 12),
        Row(
            children: List.generate(
                3,
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