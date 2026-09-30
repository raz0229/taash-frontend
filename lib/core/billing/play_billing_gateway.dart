import 'package:in_app_purchase/in_app_purchase.dart';

/// The slice of Google Play the Coins Shop depends on.
///
/// The plugin's [InAppPurchase] talks to platform channels, so it cannot be
/// driven from a test. Everything [BillingService] needs is declared here
/// instead, which keeps the purchase flow — the most security-sensitive code in
/// the app — covered by unit tests instead of only by manual store testing.
///
/// This is deliberately a thin port rather than an abstraction layer: every
/// method maps one-to-one onto the plugin, and no behaviour is added here.
abstract class PlayBillingGateway {
  /// Whether a Play Store capable of billing is reachable.
  Future<bool> isAvailable();

  /// Purchases Play pushes to the app, including restored ones.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// The real price Play will charge for each product id.
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);

  /// Starts a purchase. Returns false when Play refused to launch the flow.
  ///
  /// [autoConsume] stays false for the shop: the server acknowledges and
  /// consumes after crediting, so a failed verification cannot leave a consumed
  /// token with no coins.
  Future<bool> buyConsumable(
    PurchaseParam purchaseParam, {
    required bool autoConsume,
  });

  /// Asks Play to re-deliver anything still outstanding.
  Future<void> restorePurchases();
}

/// The production gateway, a one-to-one adapter over the plugin.
class PluginPlayBillingGateway implements PlayBillingGateway {
  PluginPlayBillingGateway([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);

  @override
  Future<bool> buyConsumable(
    PurchaseParam purchaseParam, {
    required bool autoConsume,
  }) => _iap.buyConsumable(
    purchaseParam: purchaseParam,
    autoConsume: autoConsume,
  );

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();
}
