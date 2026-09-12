import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/how_to_play/learn_screen.dart';
import 'package:taash/features/game/shared/player_strip.dart';
import 'package:taash/features/game/shared/playing_card.dart';
import 'package:taash/features/game/shared/stock_draw_animation.dart';

RoomSnapshot _stripSnapshot() => RoomSnapshot(
  room: RoomSummary(
    id: 'r',
    name: 'Room',
    game: GameType.daketi,
    maxPlayers: 4,
    status: 'active',
    createdAt: DateTime(2026),
  ),
  you: PrivatePlayer(id: 'p1', hand: []),
  players: [
    PublicPlayer(id: 'p1', displayName: 'A', seat: 0, handCount: 5),
    PublicPlayer(id: 'p2', displayName: 'B', seat: 1, handCount: 5),
    PublicPlayer(id: 'p3', displayName: 'C', seat: 2, handCount: 5),
    PublicPlayer(id: 'p4', displayName: 'D', seat: 3, handCount: 5),
  ],
  winners: const [],
  currentPlayerId: 'p2',
);

void main() {
  testWidgets('Learning exercise switches games and explains the answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        home: const Scaffold(body: LearnScreen()),
      ),
    );
    await tester.tap(find.text('TC'));
    await tester.pumpAndSettle();
    expect(find.text('Find 4 + 3 + 3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('A same-suit run'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('A same-suit run'));
    await tester.pumpAndSettle();
    expect(find.textContaining('whole winning hand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Private cards have no identifying semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlayingCard(card: 'h-y', faceDown: true)),
      ),
    );
    expect(find.bySemanticsLabel('Face-down card'), findsOneWidget);
    expect(find.bySemanticsLabel('Hukam Yakka'), findsNothing);
    handle.dispose();
  });
  testWidgets('Seat centres track the strip scroll', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final stripKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerStrip(
            key: stripKey,
            snapshot: _stripSnapshot(),
            onPlayerTap: (_) {},
          ),
        ),
      ),
    );
    // revealTurn scrolls the strip so the current player (seat index 1) is in
    // view; a seat centre must resolve inside the strip, on screen, and to the
    // LEFT of center (proving the scroll offset is applied).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final seat = stripSeatGlobalCenter(stripKey, 1);
    expect(seat, isNotNull);
    expect(seat!.dx, inInclusiveRange(0, 800));
    expect(seat.dx, lessThan(400));
    expect(seat.dy, inInclusiveRange(0, 120));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Stock draw animation runs without assertions', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final stockKey = GlobalKey();
    final stripKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: KeyedSubtree(
                  key: stockKey,
                  child: Container(width: 60, height: 84, color: Colors.red),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: PlayerStrip(
                  key: stripKey,
                  snapshot: _stripSnapshot(),
                  onPlayerTap: (_) {},
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: StockDrawAnimation(
                    playerStripKey: stripKey,
                    stockKey: stockKey,
                    drawerSeat: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Resolve positions and run the whole hand-trip on bounded pumps (the
    // strip's own pulse animation would make pumpAndSettle spin forever).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.takeException(), isNull);
  });
}
