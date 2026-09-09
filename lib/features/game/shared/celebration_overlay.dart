import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/taash_theme.dart';

/// A lightweight confetti/celebration overlay used for:
/// - Bhabhi Thullu moments (A6)
/// - Bluff caught events (A5)
/// - Game results celebration (B6)
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.active,
    this.text,
    this.textColor = T.ochre,
    this.particleCount = 40,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
  });
  final bool active;
  final String? text;
  final Color textColor;
  final int particleCount;
  final Duration duration;
  final VoidCallback? onComplete;
  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _visible = false);
          widget.onComplete?.call();
        }
      });
    _particles = _generateParticles();
    if (widget.active) _trigger();
  }

  @override
  void didUpdateWidget(CelebrationOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _trigger();
  }

  void _trigger() {
    _particles = _generateParticles();
    _visible = true;
    _controller
      ..reset()
      ..forward();
  }

  List<_Particle> _generateParticles() {
    final rng = math.Random();
    return List.generate(widget.particleCount, (_) {
      return _Particle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * .3,
        speed: .4 + rng.nextDouble() * .6,
        drift: (rng.nextDouble() - .5) * .3,
        size: 4 + rng.nextDouble() * 6,
        color: [
          T.ochre,
          T.coral,
          T.mint,
          const Color(0xffFF7777),
          const Color(0xff69DFFF),
          const Color(0xffDCA9FF),
          Colors.white,
        ][rng.nextInt(7)],
        rotation: rng.nextDouble() * 6.283,
        rotationSpeed: (rng.nextDouble() - .5) * 8,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final reduce = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: reduce
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      painter: _ConfettiPainter(
                        particles: _particles,
                        progress: _controller.value,
                      ),
                    ),
            ),
            if (widget.text != null)
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _controller.value < .8
                      ? 1
                      : (1 - _controller.value) / .2,
                  child: Transform.scale(
                    scale: reduce
                        ? 1
                        : Curves.elasticOut.transform(
                            (_controller.value / .3).clamp(0, 1),
                          ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: T.paper.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.textColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.textColor.withValues(alpha: .3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.text!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
  final double x, delay, speed, drift, size, rotation, rotationSpeed;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = t * p.speed * size.height;
      final x = p.x * size.width + p.drift * t * size.width;
      final opacity = t > .7 ? (1 - t) / .3 : 1.0;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * .6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
