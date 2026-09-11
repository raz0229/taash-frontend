import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../models/models.dart';
import '../storage/session_store.dart';

class ApiClient {
  ApiClient({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();
  final AppConfig config;
  final http.Client _client;
  final Duration timeout;
  Future<String?> Function()? tokenProvider;
  Future<void> Function()? onUnauthorized;
  Future<String?> Function()? appCheckTokenProvider;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
    bool retryRead = false,
    String? explicitToken,
  }) async {
    if (!config.isConfigured) {
      throw const AppFailure(
        'configuration',
        'Add your TaashOnline server configuration to connect.',
      );
    }
    final mayRetry = method == 'GET' || retryRead;
    for (var attempt = 0; attempt < 2; attempt++) {
      final token =
          explicitToken ?? (authenticated ? await tokenProvider?.call() : null);
      if (authenticated && (token == null || token.isEmpty)) {
        throw const AppFailure('unauthorized', 'Please sign in to continue.');
      }
      final req = http.Request(method, config.endpoint(path, query));
      req.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      final appCheckToken = await appCheckTokenProvider?.call();
      if (appCheckToken != null && appCheckToken.isNotEmpty) {
        req.headers['X-Firebase-AppCheck'] = appCheckToken;
      }
      if (body != null) {
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode(body);
      }
      final response = await _send(req, mutation: !mayRetry);
      if (response.statusCode == 401 &&
          mayRetry &&
          attempt == 0 &&
          onUnauthorized != null &&
          explicitToken == null) {
        await onUnauthorized!();
        continue;
      }
      return _decode(response);
    }
    throw const AppFailure('unauthorized', 'Please sign in again to continue.');
  }

  Future<http.Response> _send(
    http.BaseRequest request, {
    bool mutation = false,
  }) async {
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw AppFailure(
        'timeout',
        mutation
            ? 'The response took too long. Check the latest state before trying again.'
            : 'The connection took too long. Please try again.',
        uncertain: mutation,
      );
    } on SocketException {
      throw AppFailure(
        'offline',
        'You appear to be offline. Your place will be checked when you reconnect.',
        uncertain: mutation,
      );
    } on http.ClientException {
      throw AppFailure(
        'offline',
        'We could not reach TaashOnline. Check your connection.',
        uncertain: mutation,
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic>? json;
    try {
      json = jsonObject(jsonDecode(response.body));
    } on FormatException {
      /* handled below */
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = json?['error'];
      final detail = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      final code = jsonString(detail['code'], switch (response.statusCode) {
        401 => 'unauthorized',
        429 => 'rate_limited',
        _ => 'server_error',
      });
      throw AppFailure.fromServer(
        code,
        serverMessage: jsonString(detail['message']),
        statusCode: response.statusCode,
        details: detail,
      );
    }
    if (json == null) {
      throw const AppFailure(
        'malformed_response',
        'The server sent an unreadable response. Please try again.',
      );
    }
    return json;
  }

  Future<AuthSession> signIn(String email, String password) async {
    try {
      final json = await request(
        'POST',
        '/v1/auth/signIn',
        authenticated: false,
        body: {'email': email.trim(), 'password': password},
      );
      return AuthSession.fromFirebase(json);
    } on AppFailure catch (e) {
      if (e.isUnauthorized) throw AppFailure.fromServer('invalid_credentials');
      rethrow;
    } on FormatException {
      throw const AppFailure(
        'malformed_response',
        'The server returned an incomplete sign-in session.',
      );
    }
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
    required String country,
  }) async {
    final json = await request(
      'POST',
      '/v1/auth/register',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
        'display_name': displayName.trim(),
        'country': country.toUpperCase(),
      },
    );
    try {
      return AuthSession.fromFirebase(json);
    } on FormatException {
      throw const AppFailure(
        'malformed_response',
        'The server returned an incomplete account session. Try signing in.',
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    await request(
      'POST',
      '/v1/auth/forgotPassword',
      authenticated: false,
      body: {'email': email.trim()},
    );
  }

  /// Exchanges a Google OAuth ID token for an authenticated session exactly
  /// like [signIn]/[register]. Returns null when the Google account is new to
  /// TaashOnline and the server still needs a display name and country before
  /// the player can be created (HTTP 409 profile_required).
  Future<AuthSession?> signInWithGoogle({
    required String idToken,
    String? displayName,
    String? country,
  }) async {
    try {
      final json = await request(
        'POST',
        '/v1/auth/google',
        authenticated: false,
        body: {
          'id_token': idToken,
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
          if (country != null && country.trim().isNotEmpty)
            'country': country.trim().toUpperCase(),
        },
      );
      return AuthSession.fromFirebase(json);
    } on AppFailure catch (e) {
      if (e.code == 'profile_required') return null;
      rethrow;
    } on FormatException {
      throw const AppFailure(
        'malformed_response',
        'Google sign-in returned an incomplete session. Please try again.',
      );
    }
  }

  Future<AuthSession> refreshSession(AuthSession session) async {
    if (config.firebaseApiKey.isEmpty) {
      throw const AppFailure(
        'refresh_configuration',
        'Session renewal needs the Firebase project configuration. Please sign in again.',
      );
    }
    final request = http.Request(
      'POST',
      Uri.https('securetoken.googleapis.com', '/v1/token', {
        'key': config.firebaseApiKey,
      }),
    );
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.bodyFields = {
      'grant_type': 'refresh_token',
      'refresh_token': session.refreshToken,
    };
    final response = await _send(request);
    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      throw const AppFailure(
        'session_expired',
        'Your session has ended. Please sign in again.',
      );
    }
    try {
      final updated = AuthSession.fromFirebase(_decode(response));
      if (updated.userId != session.userId) {
        throw const AppFailure(
          'session_expired',
          'Your account session changed. Please sign in again.',
        );
      }
      return updated;
    } on FormatException {
      throw const AppFailure(
        'malformed_response',
        'Session renewal returned an incomplete response.',
      );
    }
  }

  Future<PlayerProfile> getPlayer(String id) async {
    if (config.mock) {
      return PlayerProfile(
        id: id,
        displayName: 'Mock Player',
        coins: 1000,
        xp: 500,
        country: 'US',
        selectedPfp: 1,
        createdAt: DateTime.now(),
      );
    }
    return PlayerProfile.fromJson(await request('GET', '/v1/players/$id'));
  }

  Future<List<PlayerStats>> getStats(String id) async {
    if (config.mock) {
      return GameType.values
          .map(
            (g) => PlayerStats(
              game: g,
              points: 5000,
              gamesWon: 20,
              gamesPlayed: 40,
              winStreakCount: 3,
            ),
          )
          .toList();
    }
    final json = await request(
      'GET',
      '/v1/players/${Uri.encodeComponent(id)}/stats',
      retryRead: true,
    );
    return (json['stats'] as List)
        .map((m) => PlayerStats.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerProfile> updateProfile(
    String id, {
    required String displayName,
    required String country,
  }) async => PlayerProfile.fromJson(
    await request(
      'PATCH',
      '/v1/players/${Uri.encodeComponent(id)}',
      body: {
        'display_name': displayName.trim(),
        'country': country.toUpperCase(),
      },
    ),
  );

  Future<int> claimThreeHourlyReward(String playerId) async {
    try {
      final response = await request(
        'POST',
        '/v1/players/${Uri.encodeComponent(playerId)}/claimThreeHourlyReward',
      );
      return (response['coins'] as num).toInt();
    } on AppFailure catch (e) {
      if (e.statusCode == 409) {
        final minutes = (e.details?['time_remaining_in_minutes'] as num?)
            ?.toInt();
        throw AppFailure(
          'reward_not_ready',
          minutes == null
              ? 'Check back later.'
              : 'Check back in $minutes minutes',
        );
      } else if (e.statusCode == 429) {
        throw const AppFailure('rate_limited', 'Too many requests');
      }
      rethrow;
    }
  }

  Future<RoomSummary> createRoom({
    required GameType game,
    required int maxPlayers,
    String name = '',
    bool private = false,
  }) async => RoomSummary.fromJson(
    await request(
      'POST',
      '/v1/rooms',
      body: {
        'name': name.trim(),
        'game_type': game.name,
        'max_players': maxPlayers,
        'privateRoom': private,
      },
    ),
  );
  Future<RoomSummary> findMatch(GameType game) async => RoomSummary.fromJson(
    await request('POST', '/v1/match', body: {'game_type': game.name}),
  );
  Future<RoomSummary> getRoom(String code) async => RoomSummary.fromJson(
    await request(
      'GET',
      '/v1/rooms/${Uri.encodeComponent(code.trim().toUpperCase())}',
    ),
  );
  Future<List<RoomSummary>> listRooms(GameType game) async {
    final json = await request(
      'GET',
      '/v1/rooms',
      query: {'game_type': game.name, 'room_status': 'waiting', 'limit': '100'},
    );
    return List.unmodifiable(
      jsonList(
        json['rooms'],
        (v) => RoomSummary.fromJson(jsonObject(v)),
      ).where((room) => !room.private),
    );
  }

  Future<List<LeaderboardEntry>> leaderboard(GameType game) async {
    if (config.mock) {
      return List.generate(
        10,
        (i) => LeaderboardEntry(
          playerId: 'mock$i',
          displayName: 'Mock Player $i',
          country: 'US',
          selectedPfp: (i % 10) + 1,
          points: 10000 - (i * 500),
        ),
      );
    }
    final json = await request(
      'POST',
      '/leaderboard',
      retryRead: true,
      body: {'game_type': game.name},
    );
    return (json['players'] as List)
        .map((m) => LeaderboardEntry.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> buyPfp(String playerId, int pfpId) async {
    await request(
      'POST',
      '/v1/pfps/buy',
      body: {'player_id': playerId, 'pfp_id': pfpId},
    );
  }

  Future<void> selectPfp(String playerId, int pfpId) async {
    await request(
      'POST',
      '/v1/pfps/select',
      body: {'player_id': playerId, 'pfp_id': pfpId},
    );
  }

  Future<void> logout(String token) async {
    await request('POST', '/v1/auth/logout', explicitToken: token);
  }

  Future<void> deleteAccount(String playerId) async {
    await request(
      'DELETE',
      '/v1/auth/deleteUser',
      body: {'player_id': playerId},
    );
  }

  Future<String> startRewardSession() async {
    final json = await request('POST', '/v1/rewards/ad/start');
    return json['reward_session_id'] as String;
  }

  /// Dev/test-only reward grant for local testing without an AdMob account.
  /// The SSV callback relies on a configured AdMob account + callback URL,
  /// so if [config.devRewardGrant] is enabled the client asks the backend to
  /// grant coins directly. This trusts the client and MUST stay disabled in
  /// production.
  bool get needsDevRewardGrant => config.devRewardGrant;

  Future<void> devGrantReward(String sessionId) async {
    await request(
      'POST',
      '/v1/rewards/ad/devgrant',
      body: {'reward_session_id': sessionId},
    );
  }

  void close() => _client.close();
}
