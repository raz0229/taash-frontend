import 'package:flutter/services.dart';
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

/// Thin wrapper around `google_sign_in` that resolves a Google account into a
/// [GoogleAccount]. It requests an ID token for [webClientId], the web client
/// ID from the Firebase console. This repository — unlike google-services.json
/// based projects — passes it explicitly because credentials come from the
/// runtime configuration.
class GoogleAuth {
  GoogleAuth({String? webClientId})
    : _googleSignIn = GoogleSignIn(
        clientId: webClientId,
        serverClientId: webClientId,
        scopes: const ['email'],
      );

  final GoogleSignIn _googleSignIn;

  /// Shows the account chooser, or resolves the already authenticated account
  /// with no UI when one is remembered. Returns null when the user cancelled.
  Future<GoogleAccount?> signIn() async {
    final GoogleSignInAccount? account;
    try {
      account =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      // google_sign_in reports sign-in failures as PlatformExceptions (for
      // example DEVELOPER_ERROR when the app's SHA-1 fingerprint is missing
      // from the Firebase project). Surface the platform reason instead of
      // letting it fall through to the app's generic error banner.
      throw GoogleAuthFailure(
        'Google sign-in failed on this device (${e.code}: ${e.message ?? e.details ?? 'unknown reason'}).'
        '\nCheck that this app\'s SHA-1 and the Firebase web client ID are '
        'registered in the Firebase console.',
      );
    }
    return _toAccount(account);
  }

  /// Resolves the previously authenticated account with no UI, used for
  /// silent session renewal. Returns null when no Google account is signed in.
  Future<GoogleAccount?> silent() async {
    final account = await _googleSignIn.signInSilently();
    return _toAccount(account);
  }

  /// Forgets the Google sign-in so the next [signIn] shows the chooser again.
  /// Never throws; sign-out is best effort to avoid aborting app sign-out.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      /* best effort; the app session is cleared regardless */
    }
  }

  Future<GoogleAccount?> _toAccount(GoogleSignInAccount? account) async {
    if (account == null) return null;
    final GoogleSignInAuthentication authentication;
    try {
      authentication = await account.authentication;
    } on PlatformException catch (e) {
      throw GoogleAuthFailure(
        'Google could not return a verified token (${e.code}: ${e.message ?? e.details ?? 'unknown reason'}).'
        '\nMake sure Google Play services is available and the Firebase web '
        'client ID is correct.',
      );
    }
    final idToken = authentication.idToken;
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