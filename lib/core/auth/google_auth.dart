import 'package:google_sign_in/google_sign_in.dart';

/// The Google identity the user chose, carrying a fresh Google OAuth ID
/// token. Firebase session creation happens on the TaashOnline server, which
/// exchanges this token via the Identity Toolkit `accounts:signInWithIdp`.
class GoogleAccount {
  const GoogleAccount({
    required this.idToken,
    required this.email,
    this.displayName,
  });
  final String idToken;
  final String email;
  final String? displayName;
}

/// A Google sign-in the app could not complete on this device. The user or
/// device can keep using email sign-in; Google is purely an alternative door.
class GoogleAuthFailure implements Exception {
  const GoogleAuthFailure(this.message);
  final String message;
  @override
  String toString() => 'GoogleAuthFailure($message)';
}

/// The current google_sign_in release (7.x) is built on top of Google's
/// Credential Manager / Google Identity Services replace the deprecated Google
/// Sign-In SDK that 6.x used. GoogleSignIn is now a singleton that must be
/// initialized once before any other call.
class GoogleAuth {
  GoogleAuth({String? webClientId}) : _webClientId = webClientId;

  final String? _webClientId;
  static bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _webClientId,
      serverClientId: _webClientId,
    );
    _initialized = true;
  }

  /// Shows the account chooser. Returns null when the user cancelled.
  Future<GoogleAccount?> signIn() async {
    await _ensureInitialized();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      // Surface the platform reason (for example DEVELOPER_ERROR when the
      // app's SHA-1 fingerprint is missing from the Firebase project) instead
      // of letting it fall through to the app's generic error banner.
      throw GoogleAuthFailure(
        'Google sign-in failed on this device (${e.code.name}: ${e.description ?? e.details ?? 'unknown reason'}).'
        '\nCheck that this app\'s SHA-1 and the Firebase web client ID are '
        'registered in the Firebase console.',
      );
    }
    return _toAccount(account);
  }

  /// Resolves the previously authenticated account with no UI, used for
  /// silent session renewal. Returns null when no Google account is signed in
  /// or the attempt could not complete silently.
  Future<GoogleAccount?> silent() async {
    await _ensureInitialized();
    final Future<GoogleSignInAccount?>? attempt =
        GoogleSignIn.instance.attemptLightweightAuthentication();
    if (attempt == null) return null;
    final GoogleSignInAccount? account;
    try {
      account = await attempt;
    } on GoogleSignInException {
      return null;
    }
    return _toAccount(account);
  }

  /// Forgets the Google sign-in so the next [signIn] shows the chooser again.
  /// Never throws; sign-out is best effort to avoid aborting app sign-out.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      /* best effort; the app session is cleared regardless */
    }
  }

  GoogleAccount? _toAccount(GoogleSignInAccount? account) {
    if (account == null) return null;
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleAuthFailure(
        'Google did not return an ID token. Check the Firebase web client ID.',
      );
    }
    return GoogleAccount(
      idToken: idToken,
      email: account.email,
      displayName: account.displayName,
    );
  }
}