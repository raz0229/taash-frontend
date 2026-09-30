import 'package:flutter/material.dart';

import '../../l10n/copy.dart';

/// Bright edge tab on the Home screen that points at the Coins Shop.
///
/// It peeks out of the left edge at mid-height: only its leading cap sits
/// off-screen, so the whole label reads at a glance while covering as little of
/// the lobby as possible. The slow nudge is what keeps it noticeable without
/// being a banner over the game tiles.
class DiscountTab extends StatefulWidget {
  const DiscountTab({super.key, required this.onTap});

  /// Opens the Coins Shop.
  final VoidCallback onTap;

  @override
  State<DiscountTab> createState() => _DiscountTabState();
}

class _DiscountTabState extends State<DiscountTab>
    with SingleTickerProviderStateMixin {
  /// Hot red-orange into sale gold: the loudest pair in the app's palette,
  /// reserved for the one thing that spends money.
  static const _gradient = LinearGradient(
    colors: [Color(0xffff5A2B), Color(0xffffC531)],
  );
  static const _ink = Color(0xff2B1206);

  /// The label is pulled this far past the left edge, which tucks its rounded
  /// cap off-screen while leaving the icon and every letter visible.
  static const _hidden = -12.0;

  /// How far the tab leans back out on each half of the cycle.
  static const _peek = 8.0;

  late final AnimationController _nudge;

  @override
  void initState() {
    super.initState();
    _nudge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Someone who has turned animations off gets the fully visible resting
    // position instead of the nudge, not a permanently half-hidden label.
    final lean = MediaQuery.disableAnimationsOf(context) ? 1.0 : _nudge.value;
    return Semantics(
      button: true,
      label: Copy.getDiscounts,
      excludeSemantics: true,
      child: Transform.translate(
        offset: Offset(_hidden + _peek * lean, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: _gradient,
                // Only the trailing end is rounded: the leading edge runs into
                // the screen edge so the tab reads as emerging from it.
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: .5),
                    blurRadius: 10 + 6 * lean,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 16, 0),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        size: 18,
                        color: _ink,
                      ),
                      SizedBox(width: 6),
                      Text(
                        Copy.getDiscounts,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                          color: _ink,
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
    );
  }
}
