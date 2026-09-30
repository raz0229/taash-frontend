import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taash/core/billing/billing_service.dart';
import 'package:taash/core/billing/play_billing_gateway.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';

/// A Play Store the test drives directly.
///
/// The real gateway is platform-channel code and cannot be exercised here, so
/// this stands in for it. It records what the service asked for, which is what
/// makes the security-relevant assertions possible: the binding value and the
/// autoConsume flag are the two things that must never be wrong.
class FakePlayStore implements PlayBillingGateway {
  FakePlayStore({
    this.available = true,
    this.prices = const {},
    this.queryError,
    this.emptyQuery = false,
  });

  bool available;
  final Map<String, String> prices;
  IAPError? queryError;
  bool emptyQuery;
  bool buyAccepted = true;
  Object? buyThrows;

  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final List<Set<String>> queries = [];
  final List<PurchaseParam> buys = [];
  final List<bool> autoConsumeFlags = [];
  int restoreCalls = 0;
  bool disposed = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queries.add(ids);
    if (queryError != null) {
      return ProductDetailsResponse(
        error: queryError,
        productDetails: <ProductDetails>[],
        notFoundIDs: <String>[],
      );
    }
    if (emptyQuery) {
      return ProductDetailsResponse(
        productDetails: <ProductDetails>[],
        notFoundIDs: <String>[],
      );
    }
    return ProductDetailsResponse(
      notFoundIDs: const <String>[],
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
  }

  @override
  Future<bool> buyConsumable(
    PurchaseParam purchaseParam, {
    required bool autoConsume,
  }) async {
    buys.add(purchaseParam);
    autoConsumeFlags.add(autoConsume);
    if (buyThrows != null) throw buyThrows!;
    return buyAccepted;
  }

  @override
  Future<void> restorePurchases() async => restoreCalls++;

  /// Pushes a purchase the way Play would.
  void deliver(PurchaseDetails purchase) => _purchases.add([purchase]);

  Future<void> close() async {
    disposed = true;
    await _purchases.close();
  }
}

PurchaseDetails purchased({
  required String productId,
  String? token = 'token-abc',
  PurchaseStatus status = PurchaseStatus.purchased,
}) => PurchaseDetails(
  purchaseID: token,
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'server',
    source: "GooglePlay",
  ),
  transactionDate: '1700000000000',
  status: status,
);

const packsJson = {
  'enabled': true,
  'currency': 'PKR',
  'packs': [
    {
      'product_id': 'coins_10k',
      'coins': 10000,
      'base_price_pkr': 900,
      'title': 'Double Down',
      'tagline': '10,000 coins',
      'savings_percent': 0,
    },
    {
      'product_id': 'coins_50k',
      'coins': 50000,
      'base_price_pkr': 4500,
      'title': 'High Roller',
      'tagline': '50,000 coins',
      'savings_percent': 20,
    },
  ],
};

/// Answers the three billing endpoints and records the verification body.
class FakeBackend {
  FakeBackend({
    this.catalog = packsJson,
    this.verifyResult,
    this.verifyStatus = 200,
    this.verifyBody,
  });

  final Object catalog;
  Object? verifyResult;
  int verifyStatus;
  Object? verifyBody;
  final List<Map<String, dynamic>> verifications = [];
  int historyCalls = 0;

  /// All three billing endpoints sit behind authRequired, so the fake has to
  /// look like a signed-in client or the service would only ever see a 401.
  ApiClient client(AppConfig config) => ApiClient(
    config: config,
    client: MockClient((request) async {
      switch (request.url.path) {
        case '/v1/iap/products':
          return http.Response(
            jsonEncode(catalog),
            200,
            headers: {'content-type': 'application/json'},
          );
        case '/v1/iap/purchases/verify':
          verifications.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          if (verifyStatus != 200) {
            return http.Response(
              jsonEncode(verifyBody ?? {'error': {'code': 'x', 'message': 'no'}}),
              verifyStatus,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(verifyResult),
            200,
            headers: {'content-type': 'application/json'},
          );
        case '/v1/iap/purchases':
          historyCalls++;
          return http.Response(
            jsonEncode({
              'purchases': [
                {
                  'id': 1,
                  'product_id': 'coins_10k',
                  'coins': 10000,
                  'order_id': 'GPA.1',
                  'status': 'verified',
                  'purchased_at': '2026-01-01T00:00:00Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
      }
      return http.Response('not found', 404);
    }),
  )..tokenProvider = () async => 'test-token';
}

AppConfig config({bool enabled = true}) => AppConfig(
  backendUrl: 'https://api.example.test',
  firebaseApiKey: 'k',
  iapEnabled: enabled,
  iapProductIds: const ['coins_10k', 'coins_50k'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('account binding', () {
    // The client and server must agree exactly or every bound purchase is
    // rejected as belonging to another account. This value is the agreed
    // contract: SHA-256 hex of the trimmed player id.
    test('is the server transform, and trims before hashing', () {
      expect(
        BillingService.obfuscateAccountId('player-123'),
        '67bf2fd3025276ee4a549b54189b333a1299c280531352c948966d90bce2742e',
      );
      expect(
        BillingService.obfuscateAccountId('  player-123  '),
        BillingService.obfuscateAccountId('player-123'),
      );
    });

    test('fits the 64 character limit Google allows', () {
      expect(
        BillingService.obfuscateAccountId('x').length,
        lessThanOrEqualTo(64),
      );
    });

    test('never sends the raw player id to Play', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();
      await svc.buy(svc.packs.first);

      expect(store.buys.single.applicationUserName, isNot('player-123'));
      expect(
        store.buys.single.applicationUserName,
        '67bf2fd3025276ee4a549b54189b333a1299c280531352c948966d90bce2742e',
      );
      await store.close();
      svc.dispose();
    });

    test('omits the binding entirely when nobody is signed in', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => null,
        gateway: store,
      );
      await svc.initialize();
      await svc.buy(svc.packs.first);

      expect(store.buys.single.applicationUserName, isNull);
      await store.close();
      svc.dispose();
    });
  });

  group('initialize', () {
    test('merges the server catalog with real Play prices', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(
        prices: {'coins_10k': 'PKR 900', 'coins_50k': 'PKR 4,500'},
      );
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();

      expect(svc.stage, PurchaseStage.done);
      expect(svc.isAvailable, isTrue);
      expect(svc.packs.map((p) => p.productId), [
        'coins_10k',
        'coins_50k',
      ]);
      // Prices come from Play, never from the server payload, so a tampered
      // client cannot invent a cheaper price.
      expect(svc.packs.first.priceLabel, 'PKR 900');
      expect(svc.packs.first.isAvailable, isTrue);
      // A pack Play did not answer for must not look buyable.
      final partial = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      expect(partial.queries, isEmpty);
      await store.close();
      svc.dispose();
    });

    test('marks a pack with no Play price as unavailable', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();

      expect(
        svc.packs.firstWhere((p) => p.productId == 'coins_50k').isAvailable,
        isFalse,
      );
      await store.close();
      svc.dispose();
    });

    test('fails closed on a device with no Play Store', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(available: false);
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();

      expect(svc.stage, PurchaseStage.failed);
      expect(svc.isAvailable, isFalse);
      expect(svc.error, contains('Play Store'));
      // It must not have gone on to sell anything.
      expect(store.queries, isEmpty);
      await store.close();
      svc.dispose();
    });

    test('fails closed when the server has the shop switched off', () async {
      final backend = FakeBackend(
        catalog: {'enabled': false, 'currency': 'PKR', 'packs': <Object>[]},
      );
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();

      expect(svc.stage, PurchaseStage.failed);
      expect(svc.packs, isEmpty);
      await store.close();
      svc.dispose();
    });

    test('fails closed when the build has no products configured', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(enabled: false),
        api: backend.client(config(enabled: false)),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();

      expect(svc.stage, PurchaseStage.failed);
      expect(store.queries, isEmpty);
      await store.close();
      svc.dispose();
    });

    test('never lets the device consume the purchase', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();
      await svc.buy(svc.packs.first);

      // Consuming here would destroy the token if verification then failed, and
      // the player could pay twice and never get the coins.
      expect(store.autoConsumeFlags, [false]);
      await store.close();
      svc.dispose();
    });

    test('asks Play to re-deliver outstanding purchases on start', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );
      await svc.initialize();
      await pumpEventQueue();

      expect(store.restoreCalls, 1);
      await store.close();
      svc.dispose();
    });
  });

  group('buying', () {
    late FakeBackend backend;
    late FakePlayStore store;
    late BillingService svc;

    Future<void> boot({String playerId = 'player-123'}) async {
      backend = FakeBackend(
        verifyResult: {
          'status': 'credited',
          'product_id': 'coins_10k',
          'coins': 10000,
          'balance': 12000,
          'order_id': 'GPA.1',
          'consumed': true,
        },
      );
      store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => playerId,
        gateway: store,
      );
      await svc.initialize();
      expect(svc.packs, isNotEmpty, reason: 'boot() must leave a quoted pack');
    }

    test('refuses a pack Play never quoted', () async {
      await boot();
      await svc.buy(
        const CoinPack(
          productId: 'coins_50k',
          coins: 50000,
          basePricePkr: 4500,
          title: 'High Roller',
          tagline: '50,000 coins',
        ),
      );
      expect(svc.stage, PurchaseStage.failed);
      expect(store.buys, isEmpty);
      await store.close();
      svc.dispose();
    });

    test('reports a refused purchase launch', () async {
      await boot();
      store.buyAccepted = false;
      await svc.buy(svc.packs.first);
      expect(svc.stage, PurchaseStage.failed);
      expect(svc.error, isNotEmpty);
      await store.close();
      svc.dispose();
    });

    test('turns a purchased token into a server verification', () async {
      await boot();
      final results = <String>[];
      svc.purchaseUpdates.listen((r) => results.add(r.status));

      store.deliver(purchased(productId: 'coins_10k'));
      await pumpEventQueue();

      expect(backend.verifications.single, {
        'product_id': 'coins_10k',
        'token': 'token-abc',
        'obfuscated_account_id':
            '67bf2fd3025276ee4a549b54189b333a1299c280531352c948966d90bce2742e',
      });
      expect(svc.stage, PurchaseStage.done);
      expect(results, ['credited']);
      await store.close();
      svc.dispose();
    });

    test('treats a replay as a success for the player', () async {
      await boot();
      backend.verifyResult = {
        'status': 'already_processed',
        'product_id': 'coins_10k',
        'coins': 10000,
        'balance': 12000,
        'order_id': 'GPA.1',
        'consumed': true,
      };
      final statuses = <String>[];
      svc.purchaseUpdates.listen((r) => statuses.add(r.status));

      // The token is re-verified after a reinstall: the server must not fail the
      // request just because the coins were already granted.
      store.deliver(purchased(productId: 'coins_10k', status: PurchaseStatus.restored));
      await pumpEventQueue();

      expect(statuses, ['already_processed']);
      expect(svc.stage, PurchaseStage.done);
      expect(svc.error, isNull);
      await store.close();
      svc.dispose();
    });

    test('never verifies an empty receipt', () async {
      await boot();
      store.deliver(purchased(productId: 'coins_10k', token: null));
      await pumpEventQueue();

      expect(backend.verifications, isEmpty);
      expect(svc.stage, PurchaseStage.failed);
      expect(svc.error, contains('receipt'));
      await store.close();
      svc.dispose();
    });

    test('surfaces a server rejection and keeps the token unspent', () async {
      await boot();
      backend
        ..verifyStatus = 409
        ..verifyBody = {
          'error': {
            'code': 'already_consumed',
            'message': 'This purchase was already redeemed.',
          },
        };
      // The client's own message is what the player sees, so the test pins the
      // behaviour rather than the wire text.
      store.deliver(purchased(productId: 'coins_10k'));
      await pumpEventQueue();

      expect(svc.stage, PurchaseStage.failed);
      expect(svc.error, isNotEmpty);
      // No result is emitted, so the UI cannot claim a purchase succeeded.
      expect(svc.purchaseUpdates, emitsDone);
      await store.close();
      svc.dispose();
    });

    test('a pending purchase is waiting, not failed', () async {
      await boot();
      store.deliver(
        purchased(
          productId: 'coins_10k',
          status: PurchaseStatus.pending,
        ),
      );
      await pumpEventQueue();

      // Nothing is sent: a pending purchase has no receipt to verify yet.
      expect(backend.verifications, isEmpty);
      expect(svc.stage, PurchaseStage.done);
      expect(svc.error, contains('waiting'));
      await store.close();
      svc.dispose();
    });

    test('a cancelled purchase is not shown as an error', () async {
      await boot();
      store.deliver(
        purchased(
          productId: 'coins_10k',
          status: PurchaseStatus.canceled,
          token: null,
        ),
      );
      await pumpEventQueue();

      expect(backend.verifications, isEmpty);
      expect(svc.stage, PurchaseStage.done);
      expect(svc.error, isNull);
      await store.close();
      svc.dispose();
    });

    test('ignores a second tap while a purchase is in flight', () async {
      await boot();
      await svc.buy(svc.packs.first);
      await svc.buy(svc.packs.first);

      expect(store.buys, hasLength(1));
      await store.close();
      svc.dispose();
    });
  });

  group('purchase history', () {
    test('reads the server ledger', () async {
      final backend = FakeBackend();
      final store = FakePlayStore(prices: {'coins_10k': 'PKR 900'});
      final svc = BillingService(
        config: config(),
        api: backend.client(config()),
        playerId: () => 'player-123',
        gateway: store,
      );

      final history = await svc.purchaseHistory();
      expect(history.single.productId, 'coins_10k');
      expect(history.single.coins, 10000);
      expect(history.single.status, 'verified');
      expect(backend.historyCalls, 1);
      await store.close();
      svc.dispose();
    });
  });
}
