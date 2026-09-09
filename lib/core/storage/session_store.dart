import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

class AuthSession {
  const AuthSession({
    required this.idToken,
    required this.refreshToken,
    required this.userId,
    required this.expiresAt,
    this.email,
    this.password,
  });
  factory AuthSession.fromFirebase(Map<String, dynamic> json) {
    final token = jsonString(json['idToken'] ?? json['id_token']);
    final refresh = jsonString(json['refreshToken'] ?? json['refresh_token']);
    final id = jsonString(json['localId'] ?? json['user_id']);
    final lifetime = jsonInt(json['expiresIn'] ?? json['expires_in']);
    if (token.isEmpty || refresh.isEmpty || id.isEmpty || lifetime <= 0) {
      throw const FormatException('Incomplete authentication response');
    }
    return AuthSession(
      idToken: token,
      refreshToken: refresh,
      userId: id,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: lifetime)),
    );
  }
  factory AuthSession.fromStorage(Map<String, dynamic> json) {
    if (jsonString(json['id_token']).isEmpty ||
        jsonString(json['refresh_token']).isEmpty ||
        jsonString(json['user_id']).isEmpty ||
        DateTime.tryParse(jsonString(json['expires_at'])) == null) {
      throw const FormatException('Incomplete stored session');
    }
    return AuthSession(
      idToken: jsonString(json['id_token']),
      refreshToken: jsonString(json['refresh_token']),
      userId: jsonString(json['user_id']),
      expiresAt: jsonDate(json['expires_at']),
      email: json['email'] != null ? jsonString(json['email']) : null,
      password: json['password'] != null ? jsonString(json['password']) : null,
    );
  }
  final String idToken, refreshToken, userId;
  final DateTime expiresAt;
  final String? email, password;

  bool get needsRefresh => !expiresAt.isAfter(
    DateTime.now().toUtc().add(const Duration(minutes: 2)),
  );
  
  Map<String, dynamic> toStorage() => {
    'id_token': idToken,
    'refresh_token': refreshToken,
    'user_id': userId,
    'expires_at': expiresAt.toIso8601String(),
    if (email != null) 'email': email,
    if (password != null) 'password': password,
  };

  AuthSession copyWith({
    String? idToken,
    String? refreshToken,
    String? userId,
    DateTime? expiresAt,
    String? email,
    String? password,
  }) {
    return AuthSession(
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      expiresAt: expiresAt ?? this.expiresAt,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
  // Do not override toString with credential fields.
}

abstract interface class SessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'taash.auth.session.v1';
  @override
  Future<AuthSession?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    try {
      return AuthSession.fromStorage(jsonObject(jsonDecode(value)));
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toStorage()));
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
