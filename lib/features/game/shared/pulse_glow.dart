import 'package:flutter/material.dart';

/// Pulsating halo under a card that the player is invited to tap, e.g. the
/// stock pile in Daketi and TC while a draw is available. Holds at maximum
/// brightness when the OS asks for reduced motion.
class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    required this.color,
    required this.child,
    this.blurRadius = 10,
    this.spreadRadius = 2,
  });
  final Color color;
  final Widget child;
  final double blurRadius;
  final double spreadRadius;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .35 + _pulse.value * .4),
              blurRadius: widget.blurRadius + _pulse.value * 6,
              spreadRadius: widget.spreadRadius + _pulse.value * 2,
            ),
          ],
          borderRadius: BorderRadius.circular(7),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}