class AppConfig {
  const AppConfig({
    required this.backendUrl,
    this.firebaseApiKey = '',
    this.allowInsecure = false,
    this.adMobAppId = '',
    this.adMobRewardedAdUnitId = '',
    this.adMobInterstitialAdUnitId = '',
    this.devRewardGrant = false,
    this.firebaseAppId = '',
    this.firebaseMessagingSenderId = '',
    this.firebaseProjectId = '',
    this.firebaseStorageBucket = '',
    this.enableAppCheck = false,
    this.appCheckDebugToken = '',
    this.firebaseWebClientId = '',
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    backendUrl: String.fromEnvironment('TAASH_API_URL'),
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    allowInsecure: bool.fromEnvironment('ALLOW_INSECURE_API'),
    adMobAppId: String.fromEnvironment('ADMOB_APP_ID'),
    adMobRewardedAdUnitId: String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID'),
    adMobInterstitialAdUnitId: String.fromEnvironment(
      'ADMOB_INTERSTITIAL_AD_UNIT_ID',
    ),
    devRewardGrant: bool.fromEnvironment('ADMOB_DEV_REWARD_GRANT'),
    firebaseAppId: String.fromEnvironment('FIREBASE_APP_ID'),
    firebaseMessagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    firebaseProjectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    firebaseStorageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    enableAppCheck: bool.fromEnvironment('ENABLE_APP_CHECK'),
    appCheckDebugToken: String.fromEnvironment('APP_CHECK_DEBUG_TOKEN'),
    firebaseWebClientId: String.fromEnvironment('FIREBASE_WEB_CLIENT_ID'),
  );

  final String backendUrl;
  final String firebaseApiKey;
  final bool allowInsecure;
  final String adMobAppId;
  final String adMobRewardedAdUnitId;
  final String adMobInterstitialAdUnitId;
  final bool devRewardGrant;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final bool enableAppCheck;
  final String appCheckDebugToken;
  final String firebaseWebClientId;

  bool get mock =>
      const bool.fromEnvironment('MOCK_BACKEND', defaultValue: false);

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
