import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:taash/core/ads/ad_service.dart';
import 'package:taash/core/widgets/banner_ad.dart';

/// Counts requests without touching the platform channel, so the test can
/// observe ordering rather than an actual ad.
class _CountingAds extends AdService {
  _CountingAds({required Future<void> initialization})
      : super(
          adUnitId: 'ca-app-pub-9996609411214010/7964124574',
          bannerAdUnitId: 'ca-app-pub-9996609411214010/8265039725',
          initialization: initialization,
        );

  int bannerRequests = 0;

  @override
  BannerAd? loadBannerAd({
    required AdSize size,
    void Function(Ad ad)? onFailed,
  }) {
    bannerRequests++;
    return null;
  }
}

void main() {
  testWidgets('the banner waits for MobileAds init before requesting an ad',
      (tester) async {
    // An init future that has not resolved: the state a player is in when they
    // reach a room soon after launch.
    final gate = Completer<void>();
    final ads = _CountingAds(initialization: gate.future);
    addTearDown(ads.dispose);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TaashBannerAd(adService: ads))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(ads.bannerRequests, 0,
        reason: 'must not request a banner before the SDK has initialised');

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(ads.bannerRequests, 1,
        reason: 'requests the banner once init has resolved');
  });

  testWidgets('a disposed banner does not request after the gate opens',
      (tester) async {
    final gate = Completer<void>();
    final ads = _CountingAds(initialization: gate.future);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TaashBannerAd(adService: ads))),
    );
    await tester.pump();

    // Leave the room before the SDK is ready.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pump();
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(ads.bannerRequests, 0,
        reason: 'an ad asked for after leaving must never be requested');
    ads.dispose();
  });
}