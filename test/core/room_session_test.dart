import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/errors/app_failure.dart';
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
  TestRoomSocket socket, {
  Duration timeout = const Duration(milliseconds: 150),
  RoomSocketConnector? connector,
}) => RoomSession(
  config: const AppConfig(backendUrl: 'https://api.example.test'),
  tokenProvider: () async => 'test-token',
  playerId: 'player-a',
  connector: connector ?? (_, _, _) async => socket,
  commandTimeout: timeout,
  reconnectBase: const Duration(milliseconds: 5),
  reconnectJitter: Duration.zero,
  observeLifecycle: false,
);
Future<void> enter(
  RoomSession session,
  TestRoomSocket socket, {
  String status = 'active',
}) async {
  final joining = session.join(
    RoomSummary.fromJson(roomFixture(status: 'waiting')),
  );
  await flush();
  socket.receive('room.snapshot', snapshotFixture(version: 2, status: status));
  await joining;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'admission requires snapshot and succeeds even if ACK is lost',
    () async {
      final socket = TestRoomSocket();
      final session = sessionFor(socket);
      await enter(session, socket);
      expect(session.connected, true);
      expect(session.snapshot!.you.id, 'player-a');
      expect(socket.sent.single['type'], 'room.join');
      expect(session.busy, false);
      session.dispose();
      await flush();
    },
  );

  test(
    'snapshot before ACK updates authoritative state without duplicate command',
    () async {
      final socket = TestRoomSocket();
      final session = sessionFor(socket);
      await enter(session, socket);
      final command = session.command('tc.draw_stock');
      final requestId = socket.sent.last['request_id'] as String;
      socket.receive(
        'room.snapshot',
        snapshotFixture(version: 3, hand: ['h-y', 'c-2']),
      );
      await flush();
      expect(session.snapshot!.you.hand.length, 2);
      expect(session.busy, true);
      socket.receive('ack', {'command': 'tc.draw_stock'}, requestId: requestId);
      await command;
      expect(session.busy, false);
      expect(socket.sent.where((m) => m['type'] == 'tc.draw_stock').length, 1);
      session.dispose();
      await flush();
    },
  );

  test(
    'lost mutation ACK requests state, never replays the mutation',
    () async {
      final socket = TestRoomSocket();
      final session = sessionFor(
        socket,
        timeout: const Duration(milliseconds: 40),
      );
      await enter(session, socket);
      final result = session.command('tc.draw_stock');
      final expected = expectLater(
        result,
        throwsA(
          isA<AppFailure>().having((e) => e.uncertain, 'uncertain', true),
        ),
      );
      socket.receive(
        'room.snapshot',
        snapshotFixture(version: 3, hand: ['h-y', 'c-2']),
      );
      await expected;
      await flush();
      expect(socket.sent.last['type'], 'room.snapshot');
      socket.receive(
        'room.snapshot',
        snapshotFixture(version: 3, hand: ['h-y', 'c-2']),
        requestId: socket.sent.last['request_id'] as String,
      );
      await flush();
      expect(session.busy, false);
      expect(socket.sent.where((m) => m['type'] == 'tc.draw_stock').length, 1);
      session.dispose();
      await flush();
    },
  );

  test(
    'duplicate chat is bounded and malformed/stale updates are ignored',
    () async {
      final socket = TestRoomSocket();
      final session = sessionFor(socket);
      await enter(session, socket);
      for (var i = 0; i < 160; i++) {
        socket.receive('chat.message', {
          'id': '$i',
          'player_id': 'player-b',
          'display_name': 'B',
          'text': 'Hello',
          'sent_at': '2026-09-05T10:00:00Z',
        });
      }
      socket.receive('chat.message', {
        'id': '159',
        'player_id': 'player-b',
        'display_name': 'B',
        'text': 'Hello',
        'sent_at': '2026-09-05T10:00:00Z',
      });
      socket.receive('room.snapshot', snapshotFixture(version: 1));
      socket.input.add('not-json');
      await flush();
      expect(session.chat.length, 150);
      expect(session.highestVersion, 2);
      expect(session.error!.code, 'malformed_response');
      session.dispose();
      await flush();
    },
  );

  test(
    'waiting disconnect does not pay for an automatic second join',
    () async {
      final socket = TestRoomSocket();
      var connections = 0;
      final session = sessionFor(
        socket,
        connector: (_, _, _) async {
          connections++;
          return socket;
        },
      );
      await enter(session, socket, status: 'waiting');
      await socket.close();
      await flush();
      expect(session.state, RoomConnectionState.roomUnavailable);
      expect(connections, 1);
      await expectLater(session.retryConnection(), throwsA(isA<AppFailure>()));
      session.dispose();
      await flush();
    },
  );

  test(
    'active reconnect rejoins without replay and stops on unavailable room',
    () async {
      final first = TestRoomSocket(), second = TestRoomSocket();
      var connections = 0;
      final session = sessionFor(
        first,
        connector: (_, _, _) async => ++connections == 1 ? first : second,
      );
      await enter(session, first);
      await first.close();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(second.sent.single['type'], 'room.join');
      second.receive('error', {
        'code': 'room_conflict',
        'message': 'room is not joinable',
      }, requestId: second.sent.single['request_id'] as String);
      await flush();
      expect(session.state, RoomConnectionState.roomUnavailable);
      expect(connections, 2);
      session.dispose();
      await flush();
    },
  );

  test('maintenance closes without reconnect storm', () async {
    final socket = TestRoomSocket();
    final session = sessionFor(socket);
    await enter(session, socket);
    socket.receive('error', {
      'code': 'server_under_maintenance',
      'message': 'maintenance',
    });
    await flush();
    expect(session.state, RoomConnectionState.maintenance);
    expect(session.error!.isMaintenance, true);
    session.dispose();
    await flush();
  });

  test(
    'failed join rejects its Future rather than pretending success',
    () async {
      final socket = TestRoomSocket();
      final session = sessionFor(socket);
      final joining = session.join(
        RoomSummary.fromJson(roomFixture(status: 'waiting')),
      );
      final expected = expectLater(joining, throwsA(isA<AppFailure>()));
      await flush();
      socket.receive('error', {
        'code': 'room_conflict',
        'message': 'room is full',
      }, requestId: socket.sent.single['request_id'] as String);
      await expected;
      session.dispose();
      await flush();
    },
  );
}
