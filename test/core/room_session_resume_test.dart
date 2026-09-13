import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/websocket/room_session.dart';
import 'package:taash/core/websocket/room_socket.dart';
import 'core_models_test.dart' show roomFixture, snapshotFixture;

class TestRoomSocket implements RoomSocket {
  final input = StreamController<Object?>();
  final sent = <Map<String, dynamic>>[];
  @override
  Stream<Object?> get messages => input.stream;
  @override
  void send(String message) =>
      sent.add(Map<String, dynamic>.from(jsonDecode(message) as Map));
  void receive(String type, Map<String, dynamic> payload, {String? requestId}) {
    input.add(
      jsonEncode({
        'v': 1,
        'type': type,
        'room_id': 'ABC234',
        'request_id': ?requestId,
        'payload': payload,
      }),
    );
  }

  @override
  Future<void> close() async {
    if (!input.isClosed) await input.close();
  }
}

Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 5));
RoomSession sessionFor(
  TestRoomSocket socket,
  RoomSocketConnector connector,
) => RoomSession(
  config: const AppConfig(backendUrl: 'https://api.example.test'),
  tokenProvider: () async => 'test-token',
  playerId: 'player-a',
  connector: connector,
  commandTimeout: const Duration(milliseconds: 400),
  resumeProbeTimeout: const Duration(milliseconds: 60),
  reconnectBase: const Duration(milliseconds: 5),
  reconnectJitter: Duration.zero,
  observeLifecycle: false,
);

Future<void> enter(RoomSession session, TestRoomSocket socket) async {
  final joining = session.join(
    RoomSummary.fromJson(roomFixture(status: 'active')),
  );
  await flush();
  socket.receive('room.snapshot', snapshotFixture(version: 2, status: 'active'));
  await joining;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resume probes the transport and stays connected when it answers',
      () async {
    final socket = TestRoomSocket();
    var connections = 0;
    final session = sessionFor(
      socket,
      (_, _, _) async {
        connections++;
        return socket;
      },
    );
    await enter(session, socket);
    final before = socket.sent.length;

    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    final probe = socket.sent
        .skip(before)
        .where((m) => m['type'] == 'room.snapshot')
        .toList();
    expect(probe, hasLength(1));
    socket.receive(
      'room.snapshot',
      snapshotFixture(version: 3, status: 'active'),
      requestId: probe.single['request_id'] as String,
    );
    await flush();

    expect(session.connected, true);
    expect(connections, 1);
    session.dispose();
    await flush();
  });

  test('resume recovers with a fresh connection when the background transport '
      'never answers', () async {
    final first = TestRoomSocket(), second = TestRoomSocket();
    var connections = 0;
    final session = sessionFor(
      first,
      (_, _, _) async => ++connections == 1 ? first : second,
    );
    await enter(session, first);

    // The resumed socket is stale: the probe write goes out but nothing comes
    // back before the probe timeout, so the session must drop it and rejoin.
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await flush();

    expect(connections, greaterThanOrEqualTo(2));
    expect(
      second.sent.any((m) => m['type'] == 'room.join'),
      true,
      reason: 'a dead background transport should rejoin on a fresh socket',
    );
    session.dispose();
    await flush();
  });
}