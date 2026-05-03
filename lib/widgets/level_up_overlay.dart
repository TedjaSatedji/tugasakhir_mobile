import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Fullscreen level-up celebration overlay.
/// Triggered by listening to [CharacterProvider.levelUpNotifier].
/// Usage: LevelUpOverlay.show(context, newLevel);
class LevelUpOverlay {
  static void show(BuildContext context, int newLevel) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _LevelUpWidget(
        newLevel: newLevel,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ─── Particle ─────────────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy, life, maxLife;
  double size;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
  }) : maxLife = life;
}

// ─── Overlay Widget ───────────────────────────────────────────────────────────

class _LevelUpWidget extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDone;

  const _LevelUpWidget({required this.newLevel, required this.onDone});

  @override
  State<_LevelUpWidget> createState() => _LevelUpWidgetState();
}

class _LevelUpWidgetState extends State<_LevelUpWidget>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _particleCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _bgFade;

  final List<_Particle> _particles = [];
  final _rng = Random();

  static const _autoDismiss = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)),
    );

    _spawnParticles();
    _ctrl.forward();
    _particleCtrl.forward();

    // Auto-dismiss
    Future.delayed(_autoDismiss, _dismiss);
  }

  void _spawnParticles() {
    const colors = [
      AppColors.xpColor,
      AppColors.primaryNeon,
      AppColors.secondaryNeon,
      AppColors.levelUpColor,
    ];
    for (int i = 0; i < 40; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 80 + _rng.nextDouble() * 220;
      _particles.add(_Particle(
        x: 0.5,
        y: 0.45,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.8 + _rng.nextDouble() * 1.0,
        size: 4 + _rng.nextDouble() * 6,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
  }

  void _dismiss() {
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, _particleCtrl]),
        builder: (_, __) {
          // Update particles
          final dt = 0.016; // ~60fps approximation
          for (final p in _particles) {
            p.x += p.vx * dt / size.width;
            p.y += p.vy * dt / size.height;
            p.vy += 120 * dt; // gravity
            p.life -= dt;
          }

          return Stack(
            children: [
              // Darkened background
              Opacity(
                opacity: _bgFade.value,
                child: Container(color: Colors.black),
              ),
              // Radial gold shimmer
              Center(
                child: Opacity(
                  opacity: _fadeAnim.value * 0.4,
                  child: Container(
                    width: size.width * 0.9,
                    height: size.width * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.xpColor.withOpacity(0.6),
                          AppColors.xpColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Particles
              CustomPaint(
                size: size,
                painter: _ParticlePainter(_particles),
              ),
              // Content
              Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 12),
                        const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: AppColors.xpColor,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${widget.newLevel}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: AppColors.primaryNeon,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '+30 🪙',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: AppColors.xpColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tap untuk lanjut',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
