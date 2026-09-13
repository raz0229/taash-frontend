import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/models/models.dart';

RoomSnapshot _snapshot({
  required List<PublicPlayer> players,
  required PublicGameState gameState,
}) => RoomSnapshot(
  room: RoomSummary(
    id: 'r1',
    name: 'Test',
    game: GameType.bhabhi,
    maxPlayers: 4,
    version: 1,
    createdAt: DateTime.now(),
  ),
  you: PrivatePlayer(id: 'a', hand: const []),
  players: players,
  winners: const [],
  gameState: gameState,
);

PublicPlayer _p(String id, int handCount, int seat) => PublicPlayer(
  id: id,
  displayName: id,
  seat: seat,
  connected: true,
  handCount: handCount,
);

TcState _tc(String? discardTop, int discardCount) => TcState.fromJson({
  'stock_count': 8,
  'discard_count': discardCount,
  'discard_top': discardTop,
  'indicator': null,
  'yarak_rank': '',
});

DaketiState _daketi(List<String> playArea) => DaketiState.fromJson({
  'stock_count': 8,
  'play_area': playArea,
});

BhabhiState _bhabhi(List<String> trick, {String lastWinnerId = 'c'}) =>
    BhabhiState.fromJson({
      'trick': [
        for (final card in trick)
          {'player_id': lastWinnerId, 'card': card},
      ],
      'first_trick': false,
      'lead_suit': '',
      'last_pickup_player_id': '',
      'last_thullu': false,
    });

BluffState _bluff(int pileCount, {String lastPlayerId = 'a', int lastPlayCount = 1}) =>
    BluffState.fromJson({
      'pile_count': pileCount,
      'last_play_count': lastPlayCount,
      'last_player_id': lastPlayerId,
      'declared_rank': 'h',
      'passed_player_ids': <String>[],
      'pending_winner_id': '',
    });

void main() {
  test('TC play detected from the discard growth and actual card', () {
    final info = detectCardPlay(
      _snapshot(players: [_p('b', 4, 0)], gameState: _tc(null, 0)),
      _snapshot(players: [_p('b', 3, 0)], gameState: _tc('h-7', 1)),
    );
    expect(info.playerId, 'b');
    expect(info.cardCount, 1);
    expect(info.card, 'h-7');
  });

  test('Daketi play detected from the hand drop and play-area tail', () {
    final info = detectCardPlay(
      _snapshot(
        players: [_p('a', 5, 0), _p('b', 4, 1)],
        gameState: _daketi(['c-2']),
      ),
      _snapshot(
        players: [_p('a', 5, 0), _p('b', 3, 1)],
        gameState: _daketi(['c-2', 'p-9']),
      ),
    );
    expect(info.playerId, 'b');
    expect(info.cardCount, 1);
    expect(info.card, 'p-9');
  });

  test('Bhabhi play detected from the hand drop and trick tail', () {
    final info = detectCardPlay(
      _snapshot(
        players: [_p('c', 4, 0)],
        gameState: _bhabhi(['h-y', 'c-2', 'e-3', 'p-4']),
      ),
      _snapshot(
        players: [_p('c', 3, 0)],
        gameState: _bhabhi(['h-y', 'c-2', 'e-3', 'p-4', 'h-2']),
      ),
    );
    expect(info.playerId, 'c');
    expect(info.cardCount, 1);
    expect(info.card, 'h-2');
  });

  test('Bluff play stays face-down and reports the real play count', () {
    final info = detectCardPlay(
      _snapshot(players: [_p('c', 4, 0)], gameState: _bluff(3)),
      _snapshot(
        players: [_p('c', 2, 0)],
        gameState: _bluff(5, lastPlayerId: 'c', lastPlayCount: 2),
      ),
    );
    expect(info.playerId, 'c');
    expect(info.cardCount, 2);
    expect(info.card, '');
  });

  test('hidden Bluff metadata falls back to the last player', () {
    final info = detectCardPlay(
      _snapshot(players: [_p('a', 3, 0)], gameState: _bluff(4)),
      _snapshot(
        players: [_p('a', 3, 0)],
        gameState: _bluff(6, lastPlayerId: 'b', lastPlayCount: 3),
      ),
    );
    expect(info.playerId, 'b');
    expect(info.cardCount, 3);
  });

  test('no card played reports nothing', () {
    final info = detectCardPlay(
      _snapshot(players: [_p('a', 3, 0)], gameState: _daketi(['c-2'])),
      _snapshot(
        players: [_p('a', 3, 0)],
        gameState: _daketi(['c-2']),
      ),
    );
    expect(info.playerId, isEmpty);
    expect(info.cardCount, 0);
  });
}