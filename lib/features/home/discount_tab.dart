import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/copy.dart';

/// Bright red, used for the spikes and the disc alike so the badge reads as one
/// solid shape rather than a ring around a second colour.
const _redBadge = Color(0xFFE53935);

/// Glow thrown from under the badge. A dark red keeps the halo from washing out
/// into orange the way a hot gradient did.
const _redGlow = Color(0xFF7F1D1D);

/// White, for the copy on the red badge. Contrast against [_redBadge] is 4.6:1,
/// which clears AA for the bold weight these lines are set in.
const _badgeInk = Color(0xFFFFFFFF);

/// Points around the badge's rim. Twelve keeps them long enough to read as
/// spikes without turning the badge into a cog.
const _spikes = 12;

/// Where the valleys between spikes sit, as a fraction of the badge's radius.
/// Tight valleys mean long spikes.
const _innerRatio = .8;

/// Bright edge badge on the Home screen that points at the Coins Shop.
///
/// It is a spiky coin-badge rather than a long tab: only a slice of the disc
/// hangs off the left edge, so it reads as one round object peeking out of the
/// screen while taking almost none of the lobby's width. The slow pulse is what
/// keeps it noticeable without being a banner over the game tiles.
class DiscountTab extends StatefulWidget {
  const DiscountTab({super.key, required this.onTap});

  /// Opens the Coins Shop.
  final VoidCallback onTap;

  @override
  State<DiscountTab> createState() => _DiscountTabState();
}

class _DiscountTabState extends State<DiscountTab>
    with SingleTickerProviderStateMixin {
  /// Diameter of the whole badge, spikes included. Sized to hold two lines of
  /// copy inside the valleys, which is what rules it out from being small.
  static const _diameter = 100.0;

  /// How far the badge is pulled past the left edge, which the parent stack
  /// clips off. Only a sliver hangs off: the disc has to be wide enough for
  /// "DISCOUNTS" to render at a legible size inside its own valleys, and every
  /// pixel clipped off the left is a pixel of text the screen edge eats.
  static const _hidden = -10.0;

  /// How far the badge leans back out on each half of the cycle.
  static const _peek = 8.0;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Someone who has turned animations off gets the fully visible resting
    // position instead of the pulse, not a permanently half-hidden badge.
    final lean = MediaQuery.disableAnimationsOf(context) ? 1.0 : _pulse.value;
    return Semantics(
      button: true,
      label: Copy.getDiscounts,
      excludeSemantics: true,
      child: Transform.translate(
        offset: Offset(_hidden + _peek * lean, 0),
        child: SizedBox.square(
          dimension: _diameter,
          child: CustomPaint(
            painter: _SpikyBadgePainter(lean: lean),
            child: Material(
              color: Colors.transparent,
              // The badge is round, so the touch and its ripple are too. The
              // full square stays tappable, which gives a forgiving target even
              // where the spikes pull the ink in.
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                // The copy itself, not an icon: two short lines in white, set
                // inside the valleys so neither line crosses a spike. The wider
                // inset on the left compensates for the part of the disc the
                // screen edge clips, which would otherwise cut the first
                // letter off.
                child: Padding(
                  // Left inset is wider than the right so the two lines sit in
                  // the visible part of the disc rather than centred on a
                  // circle the screen edge has already cut into.
                  padding: const EdgeInsets.fromLTRB(18, 20, 14, 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          Copy.getDiscountsTop,
                          style: TextStyle(
                            color: _badgeInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          Copy.getDiscountsBottom,
                          style: TextStyle(
                            color: _badgeInk,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the sale seal: one solid red body with [_spikes] points around the rim
/// and a matching red disc inside it, so the two lines of copy sit on red with
/// nothing behind them but red.
class _SpikyBadgePainter extends CustomPainter {
  const _SpikyBadgePainter({required this.lean});

  /// 0 while tucked away, 1 at the peak of the pulse. Only the glow follows it,
  /// so the badge never visibly resizes while it leans.
  final double lean;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final seal = _sealPath(center, outer);
    final hot = Paint()..color = _redBadge;
    // The glow is thrown from a plain circle the size of the valleys, not from
    // the seal itself: blurring the seal would flood every valley between the
    // spikes and leave a lumpy blob instead of a seal. Painted underneath, the
    // halo still lifts the badge off the lobby, and the crisp seal on top keeps
    // its points.
    canvas.drawCircle(
      center,
      outer * _innerRatio,
      Paint()
        ..color = _redGlow.withValues(alpha: .75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * lean),
    );
    canvas.drawPath(seal, hot);
  }

  /// Closed stamp path: [_spikes] points at [outer] with the valleys between
  /// them pulled in to [_innerRatio] of the radius.
  ///
  /// Each side of a spike runs from the tip down to the valley through a control
  /// point that sits just above the valley radius, so the edge dives inward the
  /// moment it leaves the tip. That is what makes the points read as points
  /// rather than rounding off into a scalloped circle.
  static Path _sealPath(Offset center, double outer) {
    final inner = outer * _innerRatio;
    final shoulder = inner + (outer - inner) * .35;
    final step = math.pi * 2 / _spikes;
    Offset at(double turns, double radius) =>
        center + Offset(math.cos(turns), math.sin(turns)) * radius;

    final path = Path();
    for (var i = 0; i < _spikes; i++) {
      final tip = at(i * step - math.pi / 2, outer);
      final valley = at((i + .5) * step - math.pi / 2, inner);
      final nextTip = at((i + 1) * step - math.pi / 2, outer);
      final inControl = at((i + .12) * step - math.pi / 2, shoulder);
      final outControl = at((i + .88) * step - math.pi / 2, shoulder);
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      path
        ..quadraticBezierTo(inControl.dx, inControl.dy, valley.dx, valley.dy)
        ..quadraticBezierTo(
          outControl.dx,
          outControl.dy,
          nextTip.dx,
          nextTip.dy,
        );
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_SpikyBadgePainter oldDelegate) =>
      oldDelegate.lean != lean;
}
