/// Splits a comma or whitespace separated compile-time list, dropping blanks.
///
/// A malformed entry is dropped rather than throwing: a typo in a --dart-define
/// must not stop the app from starting, it just means that product is not
/// loaded, and the server still decides what a valid purchase is worth.
List<String> _csv(String value) => value
    .split(RegExp(r'[,\s]+'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

class AppConfig {
  const AppConfig({
    required this.backendUrl,
    this.inGameNewsJson = '',
    this.firebaseApiKey = '',
    this.allowInsecure = false,
    this.adMobAppId = '',
    this.adMobRewardedAdUnitId = '',
    this.adMobInterstitialAdUnitId = '',
    this.adMobBannerAdUnitId = '',
    this.devRewardGrant = false,
    this.firebaseAppId = '',
    this.firebaseMessagingSenderId = '',
    this.firebaseProjectId = '',
    this.firebaseStorageBucket = '',
    this.enableAppCheck = false,
    this.appCheckDebugToken = '',
    this.firebaseWebClientId = '',
    this.iapEnabled = false,
    this.iapProductIds = const <String>[],
    this.iapBasePlanId = '',
  });

  factory AppConfig.fromEnvironment() => AppConfig(
    backendUrl: const String.fromEnvironment('TAASH_API_URL'),
    inGameNewsJson: const String.fromEnvironment('IN_GAME_NEWS_JSON'),
    firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    allowInsecure: const bool.fromEnvironment('ALLOW_INSECURE_API'),
    adMobAppId: const String.fromEnvironment('ADMOB_APP_ID'),
    adMobRewardedAdUnitId: const String.fromEnvironment(
      'ADMOB_REWARDED_AD_UNIT_ID',
    ),
    adMobInterstitialAdUnitId: const String.fromEnvironment(
      'ADMOB_INTERSTITIAL_AD_UNIT_ID',
    ),
    adMobBannerAdUnitId: const String.fromEnvironment(
      'ADMOB_BANNER_AD_UNIT_ID',
    ),
    devRewardGrant: const bool.fromEnvironment('ADMOB_DEV_REWARD_GRANT'),
    firebaseAppId: const String.fromEnvironment('FIREBASE_APP_ID'),
    firebaseMessagingSenderId: const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    firebaseStorageBucket: const String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    ),
    enableAppCheck: const bool.fromEnvironment('ENABLE_APP_CHECK'),
    appCheckDebugToken: const String.fromEnvironment('APP_CHECK_DEBUG_TOKEN'),
    firebaseWebClientId: const String.fromEnvironment('FIREBASE_WEB_CLIENT_ID'),
    // iapEnabled and the product list are read with const defaults so the
    // factory itself can stay const-callable; _csv cannot run in a const
    // expression, so it is applied to a const list instead.
    iapEnabled: const bool.fromEnvironment(
      'IAP_ENABLED',
      defaultValue: false,
    ),
    // Comma separated so the value fits a single --dart-define, matching the
    // GOOGLE_PLAY_PRODUCT_IDS list on the backend.
    iapProductIds: _csv(
      const String.fromEnvironment('IAP_PRODUCT_IDS'),
    ),
    iapBasePlanId: const String.fromEnvironment('IAP_BASE_PLAN_ID'),
  );

  final String backendUrl;
  final String inGameNewsJson;
  final String firebaseApiKey;
  final bool allowInsecure;
  final String adMobAppId;
  final String adMobRewardedAdUnitId;
  final String adMobInterstitialAdUnitId;

  /// Unit shown as a banner in the room's waiting state. Empty means the build
  /// ships without one, and the room then shows no ad at all.
  final String adMobBannerAdUnitId;

  final bool devRewardGrant;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final bool enableAppCheck;
  final String appCheckDebugToken;
  final String firebaseWebClientId;

  /// Whether the Coins Shop may be shown. This is a client-side switch only:
  /// the server still refuses to credit anything when it has Google Play
  /// disabled, so shipping a build with this on can never mint coins on its own.
  final bool iapEnabled;

  /// Product ids to query Google Play for, in catalog order. The backend
  /// catalog remains authoritative for prices and coin amounts; this list only
  /// tells the client which Play products to load.
  final List<String> iapProductIds;

  /// The single base plan the packs are sold under. Empty means "let Google
  /// pick", which is what a plain one-off product does.
  final String iapBasePlanId;

  bool get mock =>
      const bool.fromEnvironment('MOCK_BACKEND', defaultValue: false);

  /// The Coins Shop needs both the feature switch and products to sell.
  bool get iapReady => iapEnabled && iapProductIds.isNotEmpty;

  bool get isConfigured {
    if (mock) return true;
    final uri = Uri.tryParse(backendUrl);
    return uri != null &&
        uri.hasAuthority &&
        uri.userInfo.isEmpty &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty &&
        (uri.scheme == 'https' || (allowInsecure && uri.scheme == 'http'));
  }

  Uri? get inGameNewsUri {
    final uri = Uri.tryParse(inGameNewsJson);
    return uri != null &&
            uri.hasAuthority &&
            uri.userInfo.isEmpty &&
            uri.fragment.isEmpty &&
            (uri.scheme == 'https' || (allowInsecure && uri.scheme == 'http'))
        ? uri
        : null;
  }

  Uri endpoint(String path, [Map<String, String>? query]) {
    if (!isConfigured) {
      throw StateError('A secure backend URL must be configured.');
    }
    final base = Uri.parse(backendUrl);
    return base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}$path',
      queryParameters: query,
    );
  }

  Uri get websocketUrl {
    final uri = endpoint('/v1/ws');
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }
}
