import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';

/// Initializes Firebase and activates App Check for this run.
///
/// Firebase is initialized with explicit [FirebaseOptions] built from the
/// runtime config (no google-services.json is used, so credentials live in the
/// ignored config/local.json alongside FIREBASE_API_KEY). App Check uses the
/// debug provider with the configured debug token during development, and
/// Play Integrity in production builds.
///
/// Returns true when App Check is active on this run; false when it is
/// disabled, in mock mode, or when Firebase could not be configured (in which
/// case the backend's ENABLE_APP_CHECK gate determines what happens).
Future<bool> bootstrapFirebase(AppConfig config) async {
  if (!config.enableAppCheck || config.mock) {
    return false;
  }
  final options = _firebaseOptions(config);
  if (options == null) {
    return false;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: config.appCheckDebugToken.isEmpty
          ? const AndroidPlayIntegrityProvider()
          : AndroidDebugProvider(debugToken: config.appCheckDebugToken),
    );
    FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    return true;
  } on FirebaseException {
    // The environment could not initialize Firebase (e.g. tests without a
    // native Firebase plugin). Callers treat this as App Check being off.
    return false;
  }
}

/// Resolves the current App Check token for the X-Firebase-AppCheck header,
/// or null when Firebase is not initialized/activated so the header is simply
/// omitted.
Future<String?> appCheckTokenProvider() async {
  try {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return await FirebaseAppCheck.instance.getToken();
  } on FirebaseException {
    return null;
  } catch (_) {
    return null;
  }
}

FirebaseOptions? _firebaseOptions(AppConfig config) {
  if (config.firebaseApiKey.isEmpty ||
      config.firebaseAppId.isEmpty ||
      config.firebaseProjectId.isEmpty) {
    return null;
  }
  return FirebaseOptions(
    apiKey: config.firebaseApiKey,
    appId: config.firebaseAppId,
    messagingSenderId: config.firebaseMessagingSenderId,
    projectId: config.firebaseProjectId,
    storageBucket: config.firebaseStorageBucket.isEmpty
        ? null
        : config.firebaseStorageBucket,
  );
}