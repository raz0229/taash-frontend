import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/errors/app_failure.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/websocket/snapshot_reducer.dart';

Map<String, dynamic> roomFixture({
  int version = 1,
  String status = 'active',
  String game = 'tc',
}) => {
  'id': 'ABC234',
  'name': 'Friday table',
  'game_type': game,
  'max_players': 2,
  'player_count': 2,
  'status': status,
  'version': version,
  'created_at': '2026-09-05T10:00:00Z',
};

Map<String, dynamic> snapshotFixture({
  int version = 1,
  String status = 'active',
  String game = 'tc',
  String self = 'player-a',
  List<String> hand = const ['h-y'],
  List<String> reveal = const [],
}) => {
  'room': roomFixture(version: version, status: status, game: game),
  'you': {'id': self, 'hand': hand},
  'current_player_id': 'player-a',
  'players': [
    {
      'id': 'player-a',
      'display_name': 'A',
      'seat': 0,
      'hand_count': 1,
      'selectedPfp': 0,
    },
    {
      'id': 'player-b',
      'display_name': 'B',
      'seat': 1,
      'hand_count': 1,
      'selectedPfp': 1,
    },
  ],
  'winners': status == 'finished'
      ? [
          {'player_id': 'player-b', 'place': 1},
          {'player_id': 'player-a', 'place': 2},
        ]
      : null,
  'game_state': game == 'tc'
      ? {
          'stock_count': 31,
          'discard_count': 0,
          'indicator': 'c-k',
          'yarak_rank': 'y',
        }
      : game == 'bluff'
      ? {
          'pile_count': 4,
          'last_play_count': 2,
          'declared_rank': '7',
          'pile': ['h-7'],
          'last_play': ['h-7'],
        }
      : null,
  if (reveal.isNotEmpty) 'winner_hand': reveal,
};

void main() {
  test('configuration requires TLS unless explicit development opt-in', () {
    expect(const AppConfig(backendUrl: '').isConfigured, false);
    expect(
      const AppConfig(backendUrl: 'http://example.test').isConfigured,
      false,
    );
    expect(
      const AppConfig(
        backendUrl: 'http://127.0.0.1:8080',
        allowInsecure: true,
      ).isConfigured,
      true,
    );
    final config = const AppConfig(backendUrl: 'https://example.test/api/');
    expect(
      config.endpoint('/v1/rooms').toString(),
      'https://example.test/api/v1/rooms',
    );
    expect(config.websocketUrl.toString(), 'wss://example.test/api/v1/ws');
    expect(
      const AppConfig(backendUrl: 'https://secret@example.test').isConfigured,
      false,
    );
  });

  test('player limits and fees follow current backend', () {
    expect(GameType.tc.maxPlayers, 4);
    expect(GameType.values.every((g) => g.minPlayers == 2), true);
    expect(GameType.bhabhi.entryFee, 500);
    expect(GameType.bluff.entryFee, 400);
    expect(GameType.daketi.entryFee, 250);
    expect(GameType.tc.entryFee, 1000);
    expect(
      () => RoomSummary.fromJson({...roomFixture(), 'max_players': 1}),
      throwsFormatException,
    );
  });

  test('null lists normalize to immutable empty lists', () {
    final snapshot = RoomSnapshot.fromJson(snapshotFixture());
    expect(snapshot.winners, isEmpty);
    expect(() => snapshot.you.hand.add('c-2'), throwsUnsupportedError);
    expect(() => snapshot.players.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.winners.add(const Winner(playerId: 'x', place: 1)),
      throwsUnsupportedError,
    );
  });

  test('Bluff public model ignores injected hidden pile fields', () {
    final snapshot = RoomSnapshot.fromJson(snapshotFixture(game: 'bluff'));
    final bluff = snapshot.gameState! as BluffState;
    expect(bluff.pileCount, 4);
    expect(bluff.lastPlayCount, 2);
    expect(bluff.declaredRank, '7');
    // Public BluffState deliberately has no pile/lastPlay card accessors.
    expect(snapshot.players.every((p) => p.collection.isEmpty), true);
  });

  test('bluff challenge event parses from ack envelope, result or bare data',
      () {
    final fromEnvelope = BluffChallengeEvent.tryParse({
      'command': 'bluff.challenge',
      'result': {
        'type': 'bluff.challenge_result',
        'data': {
          'bluff_caught': true,
          'challenger': 'player-a',
          'challenged': 'player-b',
          'pile_goes_to': 'player-b',
          'declared_rank': '2',
          'last_play_cards': ['h-2', 'c-4'],
        },
      },
    });
    expect(fromEnvelope, isNotNull);
    expect(fromEnvelope!.bluffCaught, true);
    expect(fromEnvelope.challenger, 'player-a');
    expect(fromEnvelope.challenged, 'player-b');
    expect(fromEnvelope.pileGoesTo, 'player-b');
    expect(fromEnvelope.declaredRank, '2');
    expect(fromEnvelope.lastPlayCards, ['h-2', 'c-4']);

    final fromResult = BluffChallengeEvent.tryParse({
      'type': 'bluff.challenge_result',
      'data': {
        'bluff_caught': false,
        'challenger': 'player-a',
        'challenged': 'player-b',
        'pile_goes_to': 'player-a',
        'declared_rank': 'y',
        'last_play_cards': ['h-y'],
      },
    });
    expect(fromResult!.bluffCaught, false);
    expect(fromResult.pileGoesTo, 'player-a');

    final fromData = BluffChallengeEvent.tryParse({
      'bluff_caught': true,
      'challenger': 'player-a',
      'challenged': 'player-b',
      'pile_goes_to': 'player-b',
      'declared_rank': 'g',
      'last_play_cards': ['h-g'],
    });
    expect(fromData!.declaredRank, 'g');

    expect(BluffChallengeEvent.tryParse({'type': 'room.snapshot'}), isNull);
    expect(BluffChallengeEvent.tryParse('not-a-map'), isNull);
    expect(
      BluffChallengeEvent.tryParse({
        'command': 'bluff.challenge',
        'result': {
          'type': 'bluff.challenge_result',
          'data': {'bluff_caught': true},
        },
      }),
      isNull,
    );
  });

  test('stale, foreign room and foreign self snapshots are rejected', () {
    final reducer = SnapshotReducer(playerId: 'player-a');
    expect(
      reducer.apply(
        RoomSnapshot.fromJson(snapshotFixture(version: 5)),
        roomId: 'ABC234',
      ),
      true,
    );
    expect(
      reducer.apply(
        RoomSnapshot.fromJson(snapshotFixture(version: 4)),
        roomId: 'ABC234',
      ),
      false,
    );
    expect(
      reducer.apply(
        RoomSnapshot.fromJson(snapshotFixture(version: 6, self: 'player-b')),
        roomId: 'ABC234',
      ),
      false,
    );
    expect(
      reducer.apply(
        RoomSnapshot.fromJson(snapshotFixture(version: 6)),
        roomId: 'XYZ234',
      ),
      false,
    );
    expect(reducer.highestVersion, 5);
  });

  test('equal-version TC reveal preserves losing self hand', () {
    final reducer = SnapshotReducer(playerId: 'player-a');
    reducer.apply(
      RoomSnapshot.fromJson(snapshotFixture(version: 5, status: 'finished')),
      roomId: 'ABC234',
    );
    final reveal = RoomSnapshot.fromJson(
      snapshotFixture(
        version: 5,
        status: 'finished',
        self: 'player-b',
        hand: ['c-2'],
        reveal: ['c-2'],
      ),
    );
    expect(reducer.apply(reveal, roomId: 'ABC234'), true);
    expect(reducer.current!.you.id, 'player-a');
    expect(reducer.current!.you.hand, ['h-y']);
    expect(reducer.current!.winnerHand, ['c-2']);
    expect(reducer.apply(reveal, roomId: 'ABC234'), false);
  });

  test('TC reveal arriving before ordinary finish cannot replace own hand', () {
    final reducer = SnapshotReducer(playerId: 'player-a');
    reducer.apply(
      RoomSnapshot.fromJson(snapshotFixture(version: 4)),
      roomId: 'ABC234',
    );
    reducer.apply(
      RoomSnapshot.fromJson(
        snapshotFixture(
          version: 5,
          status: 'finished',
          self: 'player-b',
          hand: ['c-2'],
          reveal: ['c-2'],
        ),
      ),
      roomId: 'ABC234',
    );
    reducer.apply(
      RoomSnapshot.fromJson(snapshotFixture(version: 5, status: 'finished')),
      roomId: 'ABC234',
    );
    expect(reducer.current!.you.hand, ['h-y']);
    expect(reducer.current!.winnerHand, ['c-2']);
  });

  test('empty stats avoid division by zero and errors hide internals', () {
    const stats = PlayerStats(game: GameType.tc);
    expect(stats.winRate, 0);
    expect(stats.gamesLost, 0);
    final failure = AppFailure.fromServer(
      'invalid_request',
      serverMessage: 'invalid move: insufficient coins to join',
    );
    expect(failure.message, contains('more coins'));
    expect(failure.toString(), isNot(contains('insufficient coins')));

    final rewardFailure = AppFailure.fromServer(
      'reward_not_ready',
      serverMessage: 'reward already claimed',
      details: {'time_remaining_in_minutes': 179},
    );
    expect(rewardFailure.details?['time_remaining_in_minutes'], 179);

    final emailExists = AppFailure.fromServer('email_exists');
    expect(emailExists.message, contains('already exists'));
    expect(emailExists.message, contains('Try signing in'));
  });
}
