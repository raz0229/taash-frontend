import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shakes its child sideways in a short burst, then rests, then repeats while
/// the child is shown. Used to draw the player's eye to a card they can pick
/// up (stock/discard in Daketi and TC) instead of a glowing halo. Honors the
/// OS reduced-motion setting by holding still.
class CardShake extends StatefulWidget {
  const CardShake({super.key, required this.child});
  final Widget child;

  @override
  State<CardShake> createState() => _CardShakeState();
}

class _CardShakeState extends State<CardShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shake.stop();
      _shake.value = 0;
    } else if (!_shake.isAnimating) {
      _shake.repeat();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      child: widget.child,
      builder: (context, child) {
        // First 40% of the cycle wiggles the card left and right with a
        // decaying amplitude; the remaining 60% keeps it still.
        final t = _shake.value;
        var offset = 0.0;
        if (t < 0.4) {
          final local = t / 0.4;
          offset = 7 * math.sin(local * 6 * math.pi) * (1 - local);
        }
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
    );
  }
}