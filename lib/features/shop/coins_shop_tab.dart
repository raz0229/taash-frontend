import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/billing/billing_service.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/copy.dart';

/// Coins Shop: the five purchasable coin bundles.
///
/// Every pack is described by the server catalog and priced by Google Play, so
/// this widget never decides what a pack costs or is worth. It only renders what
/// it is told, and hands the purchase to [BillingService], which defers to the
/// server before any coins appear.
class CoinsShopTab extends StatefulWidget {
  const CoinsShopTab({
    super.key,
    required this.auth,
    required this.billing,
  });

  final AuthController auth;
  final BillingService billing;

  @override
  State<CoinsShopTab> createState() => _CoinsShopTabState();
}

class _CoinsShopTabState extends State<CoinsShopTab> {
  StreamSubscription<CoinPurchaseResult>? _updates;

  @override
  void initState() {
    super.initState();
    widget.billing.addListener(_onBillingChanged);
    _updates = widget.billing.purchaseUpdates.listen(_onPurchaseVerified);
    // Kick off loading only once. The tab lives inside an IndexedStack, so it is
    // built on first visit to the Shop and kept alive afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  @override
  void dispose() {
    widget.billing.removeListener(_onBillingChanged);
    unawaited(_updates?.cancel());
    super.dispose();
  }

  Future<void> _initialize() async {
    if (widget.billing.stage == PurchaseStage.idle) {
      await widget.billing.initialize();
    }
    // The balance shown in the header is the server's, so it must be re-read
    // after any shop visit or a purchase.
    await widget.auth.refreshProfile();
  }

  void _onBillingChanged() {
    if (mounted) setState(() {});
  }

  /// The server accepted a purchase, so the coins are real. This is the only
  /// path that opens the completion modal: nothing here trusts Play's own
  /// "purchased" event.
  Future<void> _onPurchaseVerified(CoinPurchaseResult result) async {
    if (!mounted || !result.isSuccess) return;
    await widget.auth.refreshProfile();
    if (!mounted) return;
    await PurchaseCompletedSheet.show(
      context,
      result: result,
      title: widget.billing.packs
              .where((pack) => pack.productId == result.productId)
              .firstOrNull
              ?.title ??
          '',
    );
    if (mounted) setState(() {});
  }

  Future<void> _buy(CoinPack pack) async {
    await widget.billing.buy(pack);
    if (!mounted) return;
    // A failed purchase may still have been credited server-side if the response
    // was lost, so re-read the balance either way rather than leaving a stale
    // number on screen.
    await widget.auth.refreshProfile();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final billing = widget.billing;
    if (billing.stage == PurchaseStage.querying && !billing.isAvailable) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final error = billing.error;
    if (error != null && !billing.isAvailable) {
      return TaashEmpty(
        title: Copy.coinShopUnavailableTitle,
        message: error,
        icon: Icons.shopping_bag_outlined,
        onRetry: () {
          billing.clearError();
          unawaited(_initialize());
        },
      );
    }
    final packs = billing.packs;
    if (packs.isEmpty) {
      return TaashEmpty(
        title: Copy.coinShopUnavailableTitle,
        message: Copy.coinsShopUnavailableBody,
        icon: Icons.shopping_bag_outlined,
        onRetry: () {
          billing.clearError();
          unawaited(_initialize());
        },
      );
    }
    return Column(
      children: [
        const _ShopHeader(),
        if (error != null) _ShopNotice(message: error),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            itemCount: packs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CoinPackCard(
              pack: packs[index],
              // Only one pack can be in flight, so any tap while a purchase is
              // running is ignored rather than queued into a second one.
              busy: billing.isBusy,
              highlighted: index == _highlightedIndex(packs),
              onBuy: () => _buy(packs[index]),
            ),
          ),
        ),
        const _SecurePaymentFooter(),
      ],
    );
  }

  /// The biggest pack is the one worth suggesting, so it is the one that gets
  /// the emphasized treatment. It is picked from what the server actually
  /// returned rather than hard-coded.
  int _highlightedIndex(List<CoinPack> packs) {
    var best = 0;
    for (var i = 1; i < packs.length; i++) {
      if (packs[i].coins > packs[best].coins) best = i;
    }
    return best;
  }
}

/// One line of context above the packs.
///
/// The tab bar already names the section, so repeating "Coins Shop" under it
/// only pushed the bundles down; the sentence that explains what buying coins
/// gets you is the part worth the space.
class _ShopHeader extends StatelessWidget {
  const _ShopHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
    child: Text(
      Copy.coinsShopSubtitle,
      style: const TextStyle(color: T.muted, fontSize: 13, height: 1.35),
    ),
  );
}

class _ShopNotice extends StatelessWidget {
  const _ShopNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: T.danger.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: T.danger.withValues(alpha: .4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: T.danger),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: T.white, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({
    required this.pack,
    required this.busy,
    required this.highlighted,
    required this.onBuy,
  });

  final CoinPack pack;
  final bool busy;
  final bool highlighted;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? T.ochre : T.coral;
    // The badge comes from the backend so the marketing copy can change without
    // shipping a build, but a pack without one must still look deliberate.
    final badge = pack.badge;
    final coins = _formatCoins(pack.coins);
    final savings = pack.savingsPercent;
    final name = pack.title.isEmpty ? coins : pack.title;
    return Semantics(
      container: true,
      label:
          '$name, $coins, ${pack.displayPrice}'
          '${badge.isEmpty ? '' : ', $badge'}',
      excludeSemantics: true,
      // The saving tag hangs off the corner over the top of the content, so the
      // tile is a Stack: the tag rides above everything without costing the
      // bundle a row of its own.
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: highlighted ? T.ochre : T.outline,
                width: highlighted ? 1.6 : 1,
              ),
              gradient: highlighted
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        T.ochre.withValues(alpha: .16),
                        T.surface,
                      ],
                    )
                  : null,
            ),
            // A hung tag needs clear air above the content, so the packs that
            // advertise a saving reserve the header band it hangs in.
            padding: EdgeInsets.fromLTRB(
              16,
              savings > 0 ? _SaveTag.bandHeight : 14,
              16,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The marketing tag leads the tile, so the bundle name and its
                // artwork get the full width of the tile underneath it.
                if (badge.isNotEmpty) _PackBadge(label: badge, accent: accent),
                if (badge.isNotEmpty) const SizedBox(height: 10),
                // The artwork is inset on every side and the name block is
                // squeezed beside it, so a long name and its tagline wrap
                // around the art rather than running under it.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: T.white,
                            ),
                          ),
                          if (pack.tagline.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              pack.tagline,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.3,
                                color: T.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 0, 4),
                      child: _PackArtwork(
                        productId: pack.productId,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          coins,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: T.ochre,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'coins',
                          style: TextStyle(
                            fontSize: 13,
                            color: T.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // The price is Play's, so a pack whose price has not loaded
                    // yet shows the catalog figure rather than an empty button.
                    Text(
                      pack.displayPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: T.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Full width and the only saturated block on the tile, so the
                // buy target is unmissable and easy to hit with one thumb.
                SizedBox(
                  width: double.infinity,
                  child: TaashButton(
                    label: Copy.buy,
                    icon: Icons.shopping_bag_outlined,
                    fill: accent,
                    onFill: const Color(0xff2A193A),
                    // A pack whose price Play has not confirmed is not buyable:
                    // selling it would mean charging an unknown amount.
                    onPressed: busy || !pack.isAvailable ? null : onBuy,
                  ),
                ),
              ],
            ),
          ),
          if (savings > 0)
            Positioned(
              top: _SaveTag.inset,
              right: _SaveTag.inset,
              child: _SaveTag(percent: savings),
            ),
        ],
      ),
    );
  }

  /// 100000 reads badly as "100,000" in a narrow row, so group the digits and
  /// keep the coin count the loudest thing on the card.
  static String _formatCoins(int coins) {
    final digits = coins.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// The "Popular" / "Great Value" / "Hot Deal" chip that leads a tile.
class _PackBadge extends StatelessWidget {
  const _PackBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: accent.withValues(alpha: .7)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .6,
        color: accent,
      ),
    ),
  );
}

/// The transparent bundle art, shipped one file per purchasable pack.
///
/// The file name is the pack's product id, so the artwork follows whatever the
/// catalog sells. A pack whose art is missing still renders — it falls back to
/// the tile's own coin mark rather than a broken image.
class _PackArtwork extends StatelessWidget {
  const _PackArtwork({required this.productId, required this.accent});

  final String productId;
  final Color accent;

  /// Art box. The bundles are drawn wide, so the artwork keeps its aspect ratio
  /// inside this square instead of being stretched to fill it.
  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    // A product id is an opaque server string; never let one become a path that
    // reaches outside assets/purchases.
    final asset = RegExp(r'^[A-Za-z0-9_]+$').hasMatch(productId)
        ? 'assets/purchases/$productId.png'
        : null;
    return SizedBox(
      width: size,
      height: size,
      child: asset == null
          ? _fallback()
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(64, 400),
              errorBuilder: (_, _, _) => _fallback(),
            ),
    );
  }

  Widget _fallback() => DecoratedBox(
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .12),
      shape: BoxShape.circle,
      border: Border.all(color: accent.withValues(alpha: .35)),
    ),
    child: Icon(Icons.toll_rounded, size: 30, color: accent),
  );
}

/// The "Save X%" label, hung off the tile's top-right corner.
///
/// A price tag is a tilted label with a punched eyelet, so it is drawn that way
/// rather than set as plain text. It hangs *inwards*: [inset] is wide enough
/// that the rotation's bounding box — taller and wider than the tag itself —
/// still lands inside the tile instead of spilling over its border.
class _SaveTag extends StatelessWidget {
  const _SaveTag({required this.percent});

  final int percent;

  /// Distance from the corner the tag hangs off.
  static const double inset = 10;

  /// Vertical room the tilted tag needs, plus the air that keeps it clear of
  /// the tile's content.
  static const double bandHeight = 46;

  static const double _height = 24;
  static const Color _ink = Color(0xff3A2606);

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.11,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xffFFB020), Color(0xffffE39A)],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CustomPaint(
          painter: const _SaveTagPainter(),
          child: Padding(
            // The right inset clears the eyelet the painter punches out.
            padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
            child: SizedBox(
              height: _height,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sell_outlined, size: 12, color: _ink),
                  const SizedBox(width: 4),
                  Text(
                    Copy.savePercent(percent),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                      height: 1,
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
  );
}

/// Punches the eyelet and its tie line, so the saving reads as a tag hung from
/// the corner rather than a chip pasted over the tile.
class _SaveTagPainter extends CustomPainter {
  const _SaveTagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final eyelet = Offset(size.width - 9, size.height / 2);
    // Ties the eyelet back to the corner the tag hangs from.
    final tie = Paint()
      ..color = const Color(0xff3A2606).withValues(alpha: .55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(eyelet.dx + 3, eyelet.dy - 3),
      Offset(size.width - 0.5, 1.5),
      tie,
    );
    canvas.drawCircle(eyelet, 3.2, Paint()..color = const Color(0xff6B4A12));
    canvas.drawCircle(eyelet, 1.5, Paint()..color = const Color(0xffffF0C6));
  }

  @override
  bool shouldRepaint(covariant _SaveTagPainter oldDelegate) => false;
}

class _SecurePaymentFooter extends StatelessWidget {
  const _SecurePaymentFooter();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: T.outline)),
    ),
    child: Row(
      children: [
        const Icon(Icons.shield_outlined, size: 16, color: T.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            Copy.securePaymentNote,
            style: const TextStyle(fontSize: 11.5, color: T.muted),
          ),
        ),
      ],
    ),
  );
}

/// Shown only after the server has credited the coins.
///
/// The copy deliberately distinguishes a fresh purchase from one that was
/// already processed, so a double-tap or a retried request never looks like the
/// player was just charged again.
class PurchaseCompletedSheet extends StatelessWidget {
  const PurchaseCompletedSheet({
    super.key,
    required this.result,
    required this.title,
  });

  final CoinPurchaseResult result;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required CoinPurchaseResult result,
    required String title,
  }) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: T.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => PurchaseCompletedSheet(result: result, title: title),
  );

  @override
  Widget build(BuildContext context) {
    final replay = result.isReplay;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (replay ? T.mint : T.ochre).withValues(alpha: .18),
                border: Border.all(
                  color: replay ? T.mint : T.ochre,
                  width: 1.6,
                ),
              ),
              child: Icon(
                replay ? Icons.check_circle_outline : Icons.verified_rounded,
                size: 42,
                color: replay ? T.mint : T.ochre,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              replay ? Copy.alreadyProcessedTitle : Copy.purchaseCompleteTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              replay
                  ? Copy.alreadyProcessedBody
                  : Copy.coinsAdded(result.coins),
              textAlign: TextAlign.center,
              style: const TextStyle(color: T.muted),
            ),
            if (title.isNotEmpty && !replay) ...[
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: T.ochre,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TaashButton(
                label: Copy.continueLabel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
