import 'package:taash/l10n/copy.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../errors/app_failure.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../storage/session_store.dart';
import 'google_auth.dart';

enum AuthStatus {
  booting,
  signedOut,
  authenticating,
  authenticated,
  offline,
  maintenance,
  error,
}

/// Returned by [AuthController.signInWithGoogle] when the Google account is
/// new to TaashOnline and the server still needs a display name and country
/// before the player record can be created.
class GoogleProfilePrompt {
  const GoogleProfilePrompt({
    required this.email,
    required this.displayName,
  });
  final String email;
  final String displayName;
}

class AuthController extends ChangeNotifier {
  AuthController({required this.api, SessionStore? store, GoogleAuth? googleAuth})
    : _store = store ?? SecureSessionStore(),
      _google = googleAuth ?? GoogleAuth() {
    api.tokenProvider = freshToken;
    api.onUnauthorized = forceRefresh;
  }
  final ApiClient api;
  final SessionStore _store;
  final GoogleAuth _google;
  AuthStatus status = AuthStatus.booting;
  PlayerProfile? profile;
  AppFailure? error;
  AuthSession? _session;
  Future<String?>? _refreshing;
  Future<void> _storageTail = Future.value();
  int _generation = 0;
  bool _disposed = false;
  bool get isSignedIn => _session != null && profile != null;
  bool get busy =>
      status == AuthStatus.booting || status == AuthStatus.authenticating;
  String? get playerId => _session?.userId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist(int generation, AuthSession? session) {
    _storageTail = _storageTail.catchError((Object _) {}).then((_) async {
      if (generation != _generation) return;
      if (session == null) {
        await _store.clear();
      } else {
        await _store.write(session);
      }
    });
    return _storageTail;
  }

  Future<void> restore() async {
    final generation = _generation;
    status = AuthStatus.booting;
    error = null;
    _notify();
    try {
      if (api.config.mock) {
        _session = AuthSession(
          idToken: 'mock',
          refreshToken: 'mock',
          expiresAt: DateTime.now().add(const Duration(days: 99)),
          userId: 'mock',
          email: 'dummy@example.com',
          password: 'dummypassword',
        );
        profile = PlayerProfile(
          id: 'mock',
          displayName: 'Mock Player',
          coins: 1000,
          xp: 500,
          country: 'US',
          selectedPfp: 1,
          createdAt: DateTime.now(),
        );
        status = AuthStatus.authenticated;
        _notify();
        return;
      }
      final session = await _store.read();
      if (generation != _generation) return;
      _session = session;
      if (session == null) {
        status = AuthStatus.signedOut;
        return;
      }
      await freshToken();
      await refreshProfile();
      if (generation == _generation) status = AuthStatus.authenticated;
    } on AppFailure catch (failure) {
      if (generation != _generation) return;
      error = failure;
      status = failure.isMaintenance
          ? AuthStatus.maintenance
          : failure.isOffline
          ? AuthStatus.offline
          : AuthStatus.signedOut;
    } catch (_) {
      error = const AppFailure(
        'storage',
        Copy.weCouldNotRestoreYourSavedSession,
      );
      status = AuthStatus.signedOut;
    } finally {
      _notify();
    }
  }

  Future<void> signIn(String email, String password) =>
      _authenticate(() => api.signIn(email, password), email: email, password: password);
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String country,
  }) => _authenticate(
    () => api.register(
      email: email,
      password: password,
      displayName: displayName,
      country: country,
    ),
    email: email,
    password: password,
  );

  /// Signs in with Google. The Google ID token is exchanged for a Firebase
  /// session on the server, which creates or finds the player record in the
  /// same way register does.
  ///
  /// Returns a [GoogleProfilePrompt] when the Google account is brand new and
  /// the server needs a display name and country before it can create the
  /// player; the UI collects them and calls this again with the completed
  /// profile. Returns null once the user is authenticated, or when the user
  /// cancels the Google account chooser.
  Future<GoogleProfilePrompt?> signInWithGoogle({
    String? displayName,
    String? country,
  }) async {
    if (api.config.mock) {
      throw const AppFailure(
        'authentication',
        Copy.weCouldNotCompleteSignInPlease,
      );
    }
    if (busy) throw const AppFailure('busy', Copy.signInIsAlreadyInProgress);
    final account = await _google.signIn();
    if (account == null) return null;
    final session = await api.signInWithGoogle(
      idToken: account.idToken,
      displayName: displayName,
      country: country,
    );
    if (session == null) {
      return GoogleProfilePrompt(
        email: account.email,
        displayName: account.displayName ?? '',
      );
    }
    await _authenticate(() async => session, email: account.email);
    return null;
  }

  Future<void> _authenticate(
    Future<AuthSession> Function() action, {
    String? email,
    String? password,
  }) async {
    if (busy) throw const AppFailure('busy', Copy.signInIsAlreadyInProgress);
    final generation = ++_generation;
    _refreshing = null;
    status = AuthStatus.authenticating;
    error = null;
    _notify();
    try {
      final session = api.config.mock
          ? AuthSession(
              idToken: 'mock',
              refreshToken: 'mock',
              expiresAt: DateTime.now().add(const Duration(days: 99)),
              userId: 'mock',
              email: 'dummy@example.com',
              password: 'dummypassword',
            )
          : (await action()).copyWith(email: email, password: password);
      if (generation != _generation) return;
      _session = session;
      if (api.config.mock) {
        profile = PlayerProfile(
          id: 'mock',
          displayName: 'Mock Player',
          coins: 1000,
          xp: 500,
          country: 'US',
          selectedPfp: 1,
          createdAt: DateTime.now(),
        );
        status = AuthStatus.authenticated;
        _notify();
        return;
      }
      await _persist(generation, session);
      await refreshProfile();
      if (generation == _generation) status = AuthStatus.authenticated;
    } on AppFailure catch (failure) {
      if (generation == _generation) {
        error = failure;
        status = failure.isMaintenance
            ? AuthStatus.maintenance
            : failure.isOffline
            ? AuthStatus.offline
            : AuthStatus.error;
      }
      rethrow;
    } catch (_) {
      const failure = AppFailure(
        'authentication',
        Copy.weCouldNotCompleteSignInPlease,
      );
      if (generation == _generation) {
        error = failure;
        status = AuthStatus.error;
      }
      throw failure;
    } finally {
      _notify();
    }
  }

  Future<String?> freshToken() async {
    final session = _session;
    if (session == null) {
      throw const AppFailure('unauthorized', Copy.pleaseSignInToContinue);
    }
    if (!session.needsRefresh) return session.idToken;
    return _refresh();
  }

  Future<void> forceRefresh() async {
    await _refresh();
  }

  Future<String?> _refresh() {
    if (_refreshing != null) return _refreshing!;
    final session = _session;
    if (session == null) {
      return Future.error(
        const AppFailure('unauthorized', Copy.pleaseSignInToContinue),
      );
    }
    final generation = _generation;
    final future = () async {
      try {
        var next = await api.refreshSession(session);
        if (generation != _generation || _disposed) {
          throw const AppFailure(
            'session_expired',
            Copy.theSessionChangedPleaseTryAgain,
          );
        }
        next = next.copyWith(email: session.email, password: session.password);
        _session = next;
        await _persist(generation, next);
        return next.idToken;
      } on AppFailure catch (failure) {
        if (generation == _generation && failure.isUnauthorized) {
          if (session.email != null && session.password != null) {
            try {
              var next = await api.signIn(session.email!, session.password!);
              if (generation != _generation || _disposed) {
                throw const AppFailure(
                  'session_expired',
                  Copy.theSessionChangedPleaseTryAgain,
                );
              }
              next = next.copyWith(email: session.email, password: session.password);
              _session = next;
              await _persist(generation, next);
              await refreshProfile();
              return next.idToken;
            } catch (_) {
              // Ignore silent sign-in error and fall through to logout
            }
          } else if (session.email != null) {
            // Google sessions have no password. Renew silently through the
            // remembered Google account before giving up.
            try {
              final googleAccount = await _google.silent();
              if (googleAccount != null) {
                final renewed = await api.signInWithGoogle(
                  idToken: googleAccount.idToken,
                );
                if (renewed != null &&
                    generation == _generation &&
                    !_disposed) {
                  final next = renewed.copyWith(
                    email: session.email,
                    password: null,
                  );
                  _session = next;
                  await _persist(generation, next);
                  await refreshProfile();
                  return next.idToken;
                }
              }
            } catch (_) {
              // Fall through to a clean logout when silent Google renewal fails.
            }
          }
          _session = null;
          profile = null;
          status = AuthStatus.signedOut;
          error = failure;
          await _persist(generation, null);
          _notify();
        }
        rethrow;
      } finally {
        if (generation == _generation) _refreshing = null;
      }
    }();
    _refreshing = future;
    return future;
  }

  Future<void> refreshProfile() async {
    final generation = _generation;
    final id = _session?.userId;
    if (id == null) return;
    if (api.config.mock) return;
    final next = await api.getPlayer(id);
    if (next.id != id) {
      throw const AppFailure(
        'identity_mismatch',
        Copy.theServerCouldNotMatchYourAccount,
      );
    }
    if (generation != _generation || _disposed) return;
    profile = next;
    error = null;
    _notify();
  }

  Future<void> forgotPassword(String email) => api.forgotPassword(email);

  Future<void> resendVerificationEmail(String email, String password) =>
      api.sendVerificationEmail(email, password);

  Future<void> signOut() async {
    final token = _session?.idToken;
    final generation = ++_generation;
    _session = null;
    _refreshing = null;
    profile = null;
    status = AuthStatus.signedOut;
    error = null;
    _notify();
    await _persist(generation, null);
    if (token != null) unawaited(api.logout(token).catchError((Object _) {}));
    // The next Google sign-in should show the account chooser again.
    unawaited(_google.signOut());
  }

  Future<void> deleteAccount() async {
    final id = _session?.userId;
    if (id == null) {
      throw const AppFailure('unauthorized', Copy.pleaseSignInToContinue);
    }
    await api.deleteAccount(id);
    await signOut();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    api.tokenProvider = null;
    api.onUnauthorized = null;
    super.dispose();
  }
}
