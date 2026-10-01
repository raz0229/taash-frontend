import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_service.dart';

/// Google banner sized to sit inside the room's waiting state.
///
/// Nothing is rendered until an ad has actually loaded, and nothing at all
/// unless this build has a banner unit. That is deliberate: an empty unit, or
/// one that never fills, must leave the waiting state exactly as it was instead
/// of holding a hole open for an ad that will not arrive.
class TaashBannerAd extends StatefulWidget {
  const TaashBannerAd({
    super.key,
    required this.adService,
    this.frame,
    this.inset = 24,
  });

  /// Null in builds and tests that ship without ads.
  final AdService? adService;

  /// Panel drawn behind the ad, so the room can frame it in its own tint.
  /// Skipped entirely while there is no ad to put in it.
  final Decoration? frame;

  /// Horizontal inset, matching the room's own screen inset.
  final double inset;

  @override
  State<TaashBannerAd> createState() => _TaashBannerAdState();
}

class _TaashBannerAdState extends State<TaashBannerAd> {
  /// The one size Taash asks for: the standard 320x50 banner, which fits inside
  /// the room's inset column on every phone the app runs on. The box is never
  /// allowed to grow past the width it was given, so a narrower layout shrinks
  /// the slot instead of overflowing the screen.
  static final _size = AdSize.banner;

  /// A failed banner leaves a hole rather than an ad. Ask again after this,
  /// while the room is still parked in its waiting state.
  static const _retryDelay = Duration(seconds: 20);

  BannerAd? _ad;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ads = widget.adService;
    if (ads == null) {
      _ad = null;
      return;
    }
    // A banner is the one ad this app does not preload, because the widget
    // showing it owns the platform view. That makes this the only request that
    // is not already gated on MobileAds.initialize(), and a player can reach a
    // room before that future resolves, so loading straight away lands in a
    // half-started SDK and fails. Wait for init, then ask.
    ads.whenInitialized().then((_) {
      if (!mounted) return;
      setState(() => _ad = ads.loadBannerAd(size: _size, onFailed: _retryLater));
    }).catchError((e) {
      debugPrint('[TaashBannerAd] MobileAds init failed: $e');
    });
  }

  /// Drops the failed ad and schedules another attempt. The ad itself is
  /// already disposed by the time this runs.
  void _retryLater(Ad ad) {
    _retry?.cancel();
    if (!mounted) return;
    if (identical(_ad, ad)) setState(() => _ad = null);
    _retry = Timer(_retryDelay, () {
      if (mounted) setState(_load);
    });
  }

  @override
  void dispose() {
    _retry?.cancel();
    final ad = _ad;
    if (ad != null) widget.adService?.disposeBannerAd(ad);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final frame = widget.frame;
    if (ad == null) return const SizedBox.shrink();
    final banner = LayoutBuilder(
      builder: (context, constraints) => Center(
        child: SizedBox(
          width: math.min(_size.width.toDouble(), constraints.maxWidth),
          height: _size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.inset, 0, widget.inset, 12),
      child: frame == null
          ? banner
          : DecoratedBox(decoration: frame, child: banner),
    );
  }
}
