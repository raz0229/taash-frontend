class AppConfig {
  const AppConfig({
    required this.backendUrl,
    this.firebaseApiKey = '',
    this.allowInsecure = false,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    backendUrl: String.fromEnvironment('TAASH_API_URL'),
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    allowInsecure: bool.fromEnvironment('ALLOW_INSECURE_API'),
  );

  final String backendUrl;
  final String firebaseApiKey;
  final bool allowInsecure;

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
