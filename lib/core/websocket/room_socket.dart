import 'dart:io';
import '../errors/app_failure.dart';

abstract interface class RoomSocket {
  Stream<Object?> get messages;
  void send(String message);
  Future<void> close();
}

typedef RoomSocketConnector =
    Future<RoomSocket> Function(Uri uri, String token);

Future<RoomSocket> connectRoomSocket(Uri uri, String token) async {
  try {
    return NativeRoomSocket(
      await WebSocket.connect(
        uri.toString(),
        headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
      ),
    );
  } on WebSocketException catch (failure) {
    // Dart exposes upgrade status only in this exception's text. Do not surface
    // that text: it may include a URL or transport internals.
    if (failure.message.contains('401') || failure.message.contains('403')) {
      throw const AppFailure(
        'session_expired',
        'Please sign in again to join the room.',
      );
    }
    if (failure.message.contains('503')) {
      throw const AppFailure(
        'server_under_maintenance',
        'The server is temporarily unavailable. Try again shortly.',
      );
    }
    if (failure.message.contains('429')) {
      throw const AppFailure(
        'rate_limited',
        'Wait a moment before reconnecting.',
      );
    }
    rethrow;
  }
}

class NativeRoomSocket implements RoomSocket {
  NativeRoomSocket(this._socket) {
    _socket.pingInterval = const Duration(seconds: 25);
  }
  final WebSocket _socket;
  @override
  Stream<Object?> get messages => _socket;
  @override
  void send(String message) => _socket.add(message);
  @override
  Future<void> close() async {
    await _socket.close(WebSocketStatus.normalClosure);
  }
}
