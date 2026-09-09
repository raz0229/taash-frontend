import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/how_to_play/learn_screen.dart';
import 'package:taash/features/game/shared/playing_card.dart';

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
}
