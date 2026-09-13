import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/features/game/game_surfaces.dart';
import 'package:taash/features/game/shared/card_shake.dart';
import 'core/core_models_test.dart' show roomFixture;

const _tenCards = [
  'h-2', 'h-3', 'h-4', 'h-5', 'h-6', 'h-7', 'h-8',
  'h-9', 'h-10', 'h-g',
];

Map<String, dynamic> _snapshot({
  required String game,
  required String current,
  required List<String> hand,
  Map<String, dynamic>? gameState,
}) => {
  'room': roomFixture(game: game),
  'you': {'id': 'player-a', 'hand': hand},
  'current_player_id': current,
  'players': [
    {
      'id': 'player-a',
      'display_name': 'A',
      'seat': 0,
      'hand_count': hand.length,
      'selectedPfp': 0,
    },
    {
      'id': 'player-b',
      'display_name': 'B',
      'seat': 1,
      'hand_count': 3,
      'selectedPfp': 1,
    },
  ],
  'winners': null,
  'game_state': gameState,
  'winner_hand': [],
};

final _tcState = <String, dynamic>{
  'stock_count': 31,
  'discard_count': 0,
  'discard_top': null,
  'indicator': 'c-k',
  'yarak_rank': 'y',
};
final _daketiState = <String, dynamic>{'stock_count': 31, 'play_area': <String>[]};

Widget _surface(RoomSnapshot s) => MaterialApp(
  home: Scaffold(
    body: GameSurface(
      snapshot: s,
      onCardDrop: (_) {},
      canDrop: false,
      onInspectCollection: (_) {},
      onDrawStock: () {},
      onTakeDiscard: () {},
    ),
  ),
);

void main() {
  testWidgets('TC stock shakes on your turn when you can draw (hand of 10)',
      (tester) async {
    final s = RoomSnapshot.fromJson(
      _snapshot(
        game: 'tc',
        current: 'player-a',
        hand: _tenCards,
        gameState: _tcState,
      ),
    );
    await tester.pumpWidget(_surface(s));
    await tester.pump();
    expect(find.byType(CardShake), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC stock does not shake when it is not your turn', (tester) async {
    final s = RoomSnapshot.fromJson(
      _snapshot(
        game: 'tc',
        current: 'player-b',
        hand: _tenCards,
        gameState: _tcState,
      ),
    );
    await tester.pumpWidget(_surface(s));
    await tester.pump();
    expect(find.byType(CardShake), findsNothing);
  });

  testWidgets('Daketi stock shakes on your turn while you can draw from stock',
      (tester) async {
    final s = RoomSnapshot.fromJson(
      _snapshot(
        game: 'daketi',
        current: 'player-a',
        hand: const ['h-y'],
        gameState: _daketiState,
      ),
    );
    await tester.pumpWidget(_surface(s));
    await tester.pump();
    expect(find.byType(CardShake), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daketi stock does not shake out of turn or when the hand is full',
      (tester) async {
    final s = RoomSnapshot.fromJson(
      _snapshot(
        game: 'daketi',
        current: 'player-b',
        hand: const ['h-y'],
        gameState: _daketiState,
      ),
    );
    await tester.pumpWidget(_surface(s));
    await tester.pump();
    expect(find.byType(CardShake), findsNothing);
  });
}