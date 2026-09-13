import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/errors/app_failure.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/storage/session_store.dart';

class MemorySessionStore implements SessionStore {
  AuthSession? value;
  @override
  Future<AuthSession?> read() async => value;
  @override
  Future<void> write(AuthSession session) async {
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

Map<String, dynamic> playerJson() => {
  'id': 'uid-a',
  'display_name': 'Sana',
  'coins': 2000,
  'xp': 0,
  'selected_pfp': 0,
  'unlocked_pfps': [0, 1],
  'country': 'PK',
  'created_at': '2026-09-05T00:00:00Z',
};
Map<String, dynamic> loginJson() => {
  'localId': 'uid-a',
  'idToken': 'initial-test-token',
  'refreshToken': 'refresh-test-token',
  'expiresIn': '3600',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig(
    backendUrl: 'https://api.example.test',
    firebaseApiKey: 'public-test-key',
  );

  test('REST normalizes non-JSON rate-limit responses', () async {
    final api = ApiClient(
      config: config,
      client: MockClient((_) async => http.Response('Too many requests', 429)),
    );
    await expectLater(
      api.request('GET', '/healthz', authenticated: false),
      throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'rate_limited')),
    );
    api.close();
  });

  test('read 401 refreshes once; mutation 401 is never replayed', () async {
    var calls = 0, refreshes = 0;
    final api = ApiClient(
      config: config,
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('{"error":{"code":"unauthorized"}}', 401)
            : http.Response(jsonEncode(playerJson()), 200);
      }),
    );
    api.tokenProvider = () async => 'test-token';
    api.onUnauthorized = () async {
      refreshes++;
    };
    await api.getPlayer('uid-a');
    expect(calls, 2);
    expect(refreshes, 1);
    calls = 0;
    refreshes = 0;
    await expectLater(api.buyPfp('uid-a', 2), throwsA(isA<AppFailure>()));
    expect(calls, 1);
    expect(refreshes, 0);
    api.close();
  });

  test(
    'concurrent expiry refresh is single flight and persists rotated token',
    () async {
      final store = MemorySessionStore();
      final refreshGate = Completer<http.Response>();
      var refreshCalls = 0;
      final api = ApiClient(
        config: config,
        client: MockClient((request) async {
          if (request.url.host == 'securetoken.googleapis.com') {
            refreshCalls++;
            expect(
              request.headers['content-type'],
              contains('application/x-www-form-urlencoded'),
            );
            expect(request.body, contains('grant_type=refresh_token'));
            return refreshGate.future;
          }
          return http.Response(jsonEncode(playerJson()), 200);
        }),
      );
      store.value = AuthSession(
        idToken: 'expired-test-token',
        refreshToken: 'old-test-refresh',
        userId: 'uid-a',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final auth = AuthController(api: api, store: store);
      final restoring = auth.restore();
      await Future<void>.delayed(Duration.zero);
      final a = auth.freshToken();
      final b = auth.freshToken();
      refreshGate.complete(
        http.Response(
          jsonEncode({
            'user_id': 'uid-a',
            'id_token': 'next-test-token',
            'refresh_token': 'rotated-test-refresh',
            'expires_in': '3600',
          }),
          200,
        ),
      );
      await restoring;
      expect(await a, 'next-test-token');
      expect(await b, 'next-test-token');
      expect(refreshCalls, 1);
      expect(store.value!.refreshToken, 'rotated-test-refresh');
      expect(auth.status, AuthStatus.authenticated);
      auth.dispose();
      api.close();
    },
  );

  test('logout while refresh is pending cannot restore credentials', () async {
    final store = MemorySessionStore();
    store.value = AuthSession(
      idToken: 'expired',
      refreshToken: 'refresh',
      userId: 'uid-a',
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final gate = Completer<http.Response>();
    final api = ApiClient(
      config: config,
      client: MockClient(
        (request) async => request.url.host == 'securetoken.googleapis.com'
            ? gate.future
            : http.Response('{}', 200),
      ),
    );
    final auth = AuthController(api: api, store: store);
    final restoring = auth.restore();
    await Future<void>.delayed(Duration.zero);
    await auth.signOut();
    gate.complete(
      http.Response(
        jsonEncode({
          'user_id': 'uid-a',
          'id_token': 'new',
          'refresh_token': 'new-refresh',
          'expires_in': '3600',
        }),
        200,
      ),
    );
    await restoring;
    expect(store.value, null);
    expect(auth.profile, null);
    expect(auth.status, AuthStatus.signedOut);
    auth.dispose();
    api.close();
  });

  test('offline refresh preserves session for later recovery', () async {
    final store = MemorySessionStore();
    store.value = AuthSession(
      idToken: 'expired',
      refreshToken: 'refresh',
      userId: 'uid-a',
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    final api = ApiClient(
      config: config,
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    final auth = AuthController(api: api, store: store);
    await auth.restore();
    expect(auth.status, AuthStatus.offline);
    expect(store.value, isNotNull);
    auth.dispose();
    api.close();
  });

  test(
    'account data is fetched from UID without enumerating players',
    () async {
      final paths = <String>[];
      final api = ApiClient(
        config: config,
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('signIn') ? loginJson() : playerJson(),
            ),
            200,
          );
        }),
      );
      final auth = AuthController(api: api, store: MemorySessionStore());
      await auth.restore();
      await auth.signIn('sana@example.test', 'not-a-real-password');
      expect(paths, ['/v1/auth/signIn', '/v1/players/uid-a']);
      expect(auth.profile!.displayName, 'Sana');
      auth.dispose();
      api.close();
    },
  );

  test('register surfaces email_verification_required instead of a session',
      () async {
    final api = ApiClient(
      config: config,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'email_verification_required',
              'message': 'we sent a verification email to your address',
            },
          }),
          409,
        ),
      ),
    );
    final auth = AuthController(api: api, store: MemorySessionStore());
    await auth.restore();
    await expectLater(
      auth.register(
        email: 'sana@example.test',
        password: 'secret123',
        displayName: 'Sana',
        country: 'PK',
      ),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          'email_verification_required',
        ),
      ),
    );
    expect(auth.isSignedIn, isFalse);
    auth.dispose();
    api.close();
  });

  test('signIn maps email_not_verified without normalizing it', () async {
    final api = ApiClient(
      config: config,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'email_not_verified',
              'message': 'verify your email before signing in',
            },
          }),
          403,
        ),
      ),
    );
    final auth = AuthController(api: api, store: MemorySessionStore());
    await auth.restore();
    await expectLater(
      auth.signIn('sana@example.test', 'secret123'),
      throwsA(
        isA<AppFailure>().having((e) => e.code, 'code', 'email_not_verified'),
      ),
    );
    expect(auth.isSignedIn, isFalse);
    auth.dispose();
    api.close();
  });

  test('sendVerificationEmail posts credentials to the resend endpoint',
      () async {
    http.Request? captured;
    final api = ApiClient(
      config: config,
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'status': 'email_sent'}), 200);
      }),
    );
    await api.sendVerificationEmail('sana@example.test', 'secret123');
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/v1/auth/sendVerificationEmail');
    expect(captured!.body, contains('sana@example.test'));
    expect(captured!.body, contains('secret123'));
    api.close();
  });
}
