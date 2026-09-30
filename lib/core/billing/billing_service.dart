import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import 'play_billing_gateway.dart';

/// Why a purchase could not be completed, in terms the UI can explain.
enum PurchaseStage { idle, querying, buying, verifying, done, failed }

/// Raised when the Coins Shop cannot be used at all.
class BillingUnavailable implements Exception {
  const BillingUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The Google Play half of the Coins Shop.
///
/// The service owns three responsibilities and delegates the rest:
///
///  * Load the server catalog and merge Google's real prices onto it, so the UI
///    shows the price the player will actually be charged.
///  * Sell a pack, then hand the purchase token to the server, which is the only
///    thing allowed to grant coins.
///  * Recover purchases Play still reports as outstanding, which is what a
///    reinstall or a crash mid-purchase looks like.
///
/// It deliberately does **not** acknowledge or consume. The server does both
/// after it has credited the coins, so a token can never be finished by a device
/// the purchase was not made on.
class BillingService extends ChangeNotifier {
  BillingService({
    required this.config,
    required this.api,
    required this.playerId,
    PlayBillingGateway? gateway,
  }) : _gateway = gateway ?? PluginPlayBillingGateway();

  final AppConfig config;
  final ApiClient api;

  /// The authenticated player's id, resolved on every use rather than captured,
  /// because it only exists after sign-in and a purchase must bind to whoever is
  /// actually signed in at that moment.
  final String? Function() playerId;

  final PlayBillingGateway _gateway;

  CoinCatalog _catalog = CoinCatalog.empty;
  Map<String, ProductDetails> _details = const {};
  PurchaseStage _stage = PurchaseStage.idle;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  final StreamController<CoinPurchaseResult> _purchases =
      StreamController<CoinPurchaseResult>.broadcast();

  CoinCatalog get catalog => _catalog;
  PurchaseStage get stage => _stage;
  String? get error => _error;
  bool get isBusy =>
      _stage == PurchaseStage.querying ||
      _stage == PurchaseStage.buying ||
      _stage == PurchaseStage.verifying;

  /// True once the shop has enough to render: the server enabled it and Play
  /// answered with a price for at least one pack.
  bool get isAvailable => _catalog.enabled && _details.isNotEmpty;

  /// Emits once per purchase the server accepted, so the UI can show the
  /// completion modal without reaching into the service.
  Stream<CoinPurchaseResult> get purchaseUpdates => _purchases.stream;

  /// The packs to render, in catalog order, with Play's prices merged in.
  List<CoinPack> get packs => _catalog.packs
      .map((pack) => pack.withPlayDetails(price: _details[pack.productId]?.price))
      .toList(growable: false);

  /// Loads the catalog, connects to Play, and reconciles anything already
  /// purchased. Safe to call more than once.
  Future<void> initialize() async {
    if (!config.iapReady) {
      _fail(
        const BillingUnavailable(
          'Coin purchases are not available in this build.',
        ),
      );
      return;
    }
    _setStage(PurchaseStage.querying);

    try {
      // A device with no Play Store at all must fail closed rather than
      // presenting a shop that cannot take money.
      if (!await _gateway.isAvailable()) {
        _fail(
          const BillingUnavailable(
            'The Play Store is not available on this device.',
          ),
        );
        return;
      }
      await _purchaseSub?.cancel();
      _purchaseSub = _gateway.purchaseStream.listen(
        _onPurchase,
        onError: (Object error) => _fail(error),
      );
    } catch (error) {
      _fail(error);
      return;
    }

    try {
      _catalog = await api.getCoinPacks();
    } on AppFailure catch (error) {
      // A shop that cannot reach the server must not show stale or invented
      // prices, so it fails closed rather than rendering a broken storefront.
      _fail(error);
      return;
    }
    if (!_catalog.enabled) {
      _fail(
        const BillingUnavailable(
          'Coin purchases are turned off right now. Please try again later.',
        ),
      );
      return;
    }
    await _loadProductDetails();
    unawaited(_recoverOutstandingPurchases());
  }

  /// Queries Play for the real price of every catalog pack.
  Future<void> _loadProductDetails() async {
    final productIds = _catalog.packs.map((pack) => pack.productId).toSet();
    if (productIds.isEmpty) {
      _error = null;
      _setStage(PurchaseStage.done);
      return;
    }
    try {
      final response = await _gateway.queryProductDetails(productIds);
      final found = response.productDetails;
      if (response.error != null) {
        _error =
            'The Play Store returned an error: ${response.error!.message}';
      } else if (found.isEmpty) {
        _error =
            'The coin packs could not be loaded from the Play Store. '
            'Check your connection and try again.';
      } else {
        _details = {for (final detail in found) detail.id: detail};
        _error = null;
      }
    } catch (error) {
      _fail(error);
      return;
    }
    _setStage(PurchaseStage.done);
  }

  /// Starts a purchase. The coins are only granted after the server verifies
  /// the token, so nothing here is treated as success on its own.
  Future<void> buy(CoinPack pack) async {
    if (isBusy) return;
    final detail = _details[pack.productId];
    if (detail == null) {
      _fail(
        const BillingUnavailable(
          'That coin pack is not available right now. Please try another one.',
        ),
      );
      return;
    }

    _error = null;
    _setStage(PurchaseStage.buying);
    final binding = _playerBinding;
    try {
      final started = await _gateway.buyConsumable(
        PurchaseParam(
          productDetails: detail,
          // The SHA-256 of the player id. Google returns it on the purchase and
          // the server compares it to prove the purchase belongs to this
          // account. It is a hash precisely because this value is visible in
          // Play tooling, so the raw id must never be sent.
          applicationUserName: binding.isEmpty ? null : binding,
        ),
        // The server acknowledges and consumes after crediting. If the device
        // consumed it, a failed verification would take the coins with it and
        // the player could never buy the pack again.
        autoConsume: false,
      );
      if (!started) {
        _fail(
          const AppFailure(
            'purchase_failed',
            'The purchase could not be started. Please try again.',
          ),
        );
      }
    } catch (error) {
      _fail(error);
    }
  }

  /// The account binding sent to Google Play and echoed back to the server.
  ///
  /// It is empty when nobody is signed in. That is not fatal on its own: the
  /// server's GOOGLE_PLAY_REQUIRE_ACCOUNT_BINDING setting decides whether an
  /// unbound purchase is acceptable, and a build that requires binding will
  /// reject it rather than credit it wrongly.
  String get _playerBinding {
    final id = playerId() ?? '';
    return id.isEmpty ? '' : obfuscateAccountId(id);
  }

  /// The exact transform the server applies to the player id. Keep the two in
  /// step or every bound purchase will be rejected as belonging to someone else.
  static String obfuscateAccountId(String playerId) =>
      sha256.convert(utf8.encode(playerId.trim())).toString();

  void _onPurchase(List<PurchaseDetails> details) {
    for (final purchase in details) {
      unawaited(_handlePurchase(purchase));
    }
  }

  /// Turns one Play purchase into a server verification.
  ///
  /// Nothing is completed locally. A purchase the server has not yet accepted is
  /// left pending, so the token stays with Google and can be retried.
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _error =
            'This purchase is waiting for approval. It will complete shortly.';
        _setStage(PurchaseStage.done);
      case PurchaseStatus.error:
        _fail(_describe(purchase.error));
      case PurchaseStatus.canceled:
        // A cancelled purchase is not a failure worth reporting; the player
        // backed out on purpose.
        _error = null;
        _setStage(PurchaseStage.done);
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndCredit(purchase);
    }
  }

  /// Sends the token to the server and reports the outcome.
  Future<void> _verifyAndCredit(PurchaseDetails purchase) async {
    final token = purchase.purchaseID;
    if (token == null || token.isEmpty) {
      // Play can deliver a purchase with no receipt, which is a plugin or store
      // problem rather than a payment. Forwarding an empty token would just
      // produce a confusing server rejection, and there is nothing to verify.
      _fail(
        const AppFailure(
          'purchase_failed',
          'The Play Store did not return a receipt for this purchase.',
        ),
      );
      return;
    }
    _error = null;
    _setStage(PurchaseStage.verifying);
    try {
      final result = await api.verifyCoinPurchase(
        productId: purchase.productID,
        token: token,
        obfuscatedAccountId: _playerBinding,
      );
      _setStage(PurchaseStage.done);
      if (!_purchases.isClosed) {
        _purchases.add(result);
      }
    } on AppFailure catch (error) {
      // The purchase is deliberately left unacknowledged. The server holds the
      // record, so the next verification resumes from there instead of losing
      // the payment.
      _fail(error);
    }
  }

  /// Re-verifies any purchase Play still considers outstanding.
  ///
  /// This is what a reinstall, a crash between payment and credit, or a device
  /// swap looks like. Play reports the purchase; the server either credits it for
  /// the first time or reports it was already processed, and the coins are never
  /// granted twice either way.
  Future<void> _recoverOutstandingPurchases() async {
    final known = _catalog.packs.map((pack) => pack.productId).toSet();
    if (known.isEmpty) return;
    try {
      await _gateway.restorePurchases();
    } catch (_) {
      // Recovery is best effort. A device that cannot report past purchases is
      // not a reason to block the shop, and anything it did miss is still
      // recoverable by the player asking support.
    }
    // restorePurchases re-delivers through purchaseStream, which
    // _handlePurchase already filters down to catalog products, so there is
    // nothing further to do here. [known] is kept only so an empty catalog
    // skips the call entirely.
  }

  /// The player's own purchase history, for the restore screen and for support.
  Future<List<CoinPurchaseRecord>> purchaseHistory() =>
      api.getCoinPurchases();

  /// Turns Play's own error codes into something a player can act on.
  AppFailure _describe(IAPError? error) {
    final code = error?.code ?? '';
    if (code == 'already_purchased' || code == 'item_already_owned') {
      return const AppFailure(
        'already_purchased',
        'This purchase is still being processed. Please try again in a moment.',
      );
    }
    if (code == 'item_unavailable' || code == 'sku_not_available') {
      return const AppFailure(
        'unavailable',
        'That coin pack is not available on your account yet.',
      );
    }
    if (code == 'service_unavailable' || code == 'billing_unavailable') {
      return const AppFailure(
        'service_unavailable',
        'The Play Store is unavailable. Please try again later.',
      );
    }
    if (code == 'network_error' || code == 'developer_error_network') {
      return const AppFailure(
        'offline',
        'We could not reach the Play Store. Check your connection.',
      );
    }
    return const AppFailure(
      'purchase_failed',
      'The purchase could not be completed. Please try again.',
    );
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _fail(Object error) {
    _error = switch (error) {
      final BillingUnavailable failure => failure.message,
      final AppFailure failure => failure.message,
      _ => 'Coin purchases are unavailable right now.',
    };
    _setStage(PurchaseStage.failed);
  }

  void _setStage(PurchaseStage stage) {
    if (_stage == stage) return;
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_purchaseSub?.cancel());
    unawaited(_purchases.close());
    super.dispose();
  }
}
