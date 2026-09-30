import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taash/core/ads/ad_service.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/billing/billing_service.dart';
import 'package:taash/core/billing/play_billing_gateway.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/storage/session_store.dart';
import 'package:taash/core/widgets/reward_sheet.dart';
import 'package:taash/features/shop/coins_shop_tab.dart';

/// A signed-in player without any Google or Firebase machinery behind it.
class MemorySessionStore implements SessionStore {
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> write(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

const catalogJson = {
  'enabled': true,
  'currency': 'PKR',
  'packs': [
    {
      'product_id': 'coins_10k',
      'coins': 10000,
      'base_price_pkr': 900,
      'title': 'Double Down',
      'tagline': '10,000 coins',
    },
    {
      'product_id': 'coins_50k',
      'coins': 50000,
      'base_price_pkr': 4500,
      'title': 'High Roller',
      'tagline': '50,000 coins',
      'savings_percent': 20,
      'badge': 'Best value',
    },
  ],
};

const playerJson = {
  'id': 'uid-a',
  'display_name': 'Sana',
  'coins': 2000,
  'xp': 0,
  'selected_pfp': 0,
  'unlocked_pfps': [0, 1],
  'country': 'PK',
  'created_at': '2026-09-05T00:00:00Z',
};

const AppConfig config = AppConfig(
  backendUrl: 'https://api.example.test',
  firebaseApiKey: 'k',
  iapEnabled: true,
  iapProductIds: ['coins_10k', 'coins_50k'],
);

/// Serves the catalog, the profile, and a verification the tests can steer.
ApiClient fakeApi({Object catalog = catalogJson}) => ApiClient(
  config: config,
  client: MockClient((request) async {
    final body = switch (request.url.path) {
      '/v1/iap/products' => catalog,
      '/v1/iap/purchases/verify' => {
        'status': 'credited',
        'product_id': 'coins_10k',
        'coins': 10000,
        'balance': 12000,
        'order_id': 'GPA.1',
        'consumed': true,
      },
      _ => playerJson,
    };
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
)..tokenProvider = () async => 'test-token';

AuthController signedInAuth() {
  final auth = AuthController(api: fakeApi(), store: MemorySessionStore())
    ..status = AuthStatus.authenticated
    ..profile = PlayerProfile.fromJson(playerJson);
  auth.api.tokenProvider = () async => 'test-token';
  return auth;
}

/// A Play Store the test drives. [available: false] models a device with no Play
/// at all, which is the state the shop has to refuse.
class FakePlayStore implements PlayBillingGateway {
  FakePlayStore({this.available = true, this.prices = const {}});

  final bool available;
  final Map<String, String> prices;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        notFoundIDs: const [],
        productDetails: [
          for (final entry in prices.entries)
            ProductDetails(
              id: entry.key,
              title: entry.key,
              description: entry.key,
              price: entry.value,
              rawPrice: 1,
              currencyCode: 'PKR',
            ),
        ],
      );

  @override
  Future<bool> buyConsumable(
    PurchaseParam purchaseParam, {
    required bool autoConsume,
  }) async => true;

  @override
  Future<void> restorePurchases() async {}
}

Future<AuthController> pumpShop(WidgetTester tester) async {
  final auth = signedInAuth();
  final billing = BillingService(
    config: config,
    api: auth.api,
    playerId: () => auth.playerId,
    // The plugin talks to platform channels, so the widget tests drive the
    // service through a gateway. A device with no Play Store is the state worth
    // pinning here: the shop must refuse rather than render a dead storefront.
    gateway: FakePlayStore(available: false),
  );
  addTearDown(() {
    billing.dispose();
    auth.dispose();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CoinsShopTab(auth: auth, billing: billing)),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('a device with no Play Store gets no shop, and an explanation', (
    tester,
  ) async {
    await pumpShop(tester);

    // Nothing is for sale, so no pack may be presented as buyable.
    expect(find.text('Double Down'), findsNothing);
    expect(find.text('High Roller'), findsNothing);
    expect(
      find.textContaining('not available'),
      findsWidgets,
      reason: 'the player must be told why, not just shown an empty shop',
    );
  });

  testWidgets('the reward sheet offers the shop when the lobby can navigate', (
    tester,
  ) async {
    final auth = signedInAuth();
    addTearDown(auth.dispose);
    // An empty ad unit means loadAd() returns before touching AdMob, so this is
    // a real service in its permanent "no fill" state.
    final ads = AdService(adUnitId: '');
    addTearDown(ads.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => RewardSheet(
                  adService: ads,
                  auth: auth,
                  onPurchaseCoins: () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Purchase Coins'), findsOneWidget);
    // The free option stays visible above it: buying is an alternative to the
    // ad, not a replacement for it.
    expect(find.text('Watch Ad +100 Coins'), findsOneWidget);
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('the reward sheet hides the purchase option when it goes nowhere', (
    tester,
  ) async {
    final auth = signedInAuth();
    addTearDown(auth.dispose);
    final ads = AdService(adUnitId: '');
    addTearDown(ads.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => RewardSheet(adService: ads, auth: auth),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // A build with no billing service must not show a button leading nowhere.
    expect(find.text('Purchase Coins'), findsNothing);
    expect(find.text('Watch Ad +100 Coins'), findsOneWidget);
  });

  testWidgets('pressing it runs the navigation callback', (tester) async {
    final auth = signedInAuth();
    addTearDown(auth.dispose);
    final ads = AdService(adUnitId: '');
    addTearDown(ads.dispose);
    var opened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => RewardSheet(
                  adService: ads,
                  auth: auth,
                  onPurchaseCoins: () => opened++,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purchase Coins'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
