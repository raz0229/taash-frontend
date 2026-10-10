import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/game/shared/playing_card.dart';
import 'package:taash/features/how_to_play/courses/basics_course.dart';
import 'package:taash/features/how_to_play/learn_drills.dart';
import 'package:taash/features/how_to_play/learn_model.dart';
import 'package:taash/features/how_to_play/learn_rules.dart';
import 'package:taash/features/how_to_play/learn_screen.dart';
import 'package:taash/features/how_to_play/learn_widgets.dart';
import 'package:taash/features/how_to_play/lesson_player.dart';

final _cardId = RegExp(r'^[cehp]-(?:[2-9]|10|g|b|k|y)$');

/// Structural checks every generated or scripted step must pass.
void expectSound(LessonStep step, String where) {
  final faceUp = <String>[];
  List<SceneZone> scene = const [];
  switch (step) {
    case ExplainStep s:
      scene = s.scene;
    case QuizStep s:
      scene = s.scene;
      expect(
        s.options.toSet().length,
        s.options.length,
        reason: '$where: duplicate options',
      );
      expect(
        s.correct,
        inInclusiveRange(0, s.options.length - 1),
        reason: where,
      );
    case TapStep s:
      scene = s.scene;
      faceUp.addAll(s.hand);
      expect(
        s.hand.toSet().length,
        s.hand.length,
        reason: '$where: duplicate hand card',
      );
      expect(
        s.hand.toSet().containsAll(s.solution),
        isTrue,
        reason: '$where: solution not in hand',
      );
      expect(
        s.solution.length,
        inInclusiveRange(s.minPick, s.maxPick),
        reason: where,
      );
      expect(
        s.accepts(s.solution),
        isTrue,
        reason: '$where: solution rejected',
      );
  }
  for (final zone in scene) {
    for (final c in zone.cards) {
      if (c.card != null) faceUp.add(c.card!);
    }
  }
  for (final c in faceUp) {
    expect(_cardId.hasMatch(c), isTrue, reason: '$where: bad card id $c');
  }
}

final _checkButton = find.byWidgetPredicate(
  (w) => w is Text && (w.data?.startsWith('Check') ?? false),
);

void main() {
  group('Rules mirror the server', () {
    test('Bhabhi follow suit, pickup and final trick', () {
      expect(Rules.bhabhiLegal(['e-3', 'h-4', 'e-k'], 'e'), ['e-3', 'e-k']);
      expect(Rules.bhabhiLegal(['h-4', 'c-2'], 'e'), ['h-4', 'c-2']);
      // Off-suit Yakka never takes the trick.
      expect(Rules.bhabhiHighest(['c-4', 'c-10', 'e-y']), 1);
      expect(Rules.bhabhiLowest(['h-8', 'h-b', 'h-4']), 2);
    });

    test('Daketi steals the whole matching run and scores values', () {
      final o = Rules.daketiPlay(
        'c-9',
        ['h-4'],
        {
          'You': ['p-k', 'c-k', 'h-9', 'e-9', 'p-9'],
        },
        const [],
      );
      expect(o.stolen['You'], ['p-9', 'e-9', 'h-9']);
      expect(o.points, 20);
      expect(Rules.daketiPoints(['h-y', 'c-k', 'e-b', 'p-g', 'h-2']), 55);
      final own = Rules.daketiPlay('h-g', const [], const {}, ['c-g']);
      expect(own.capture, isTrue);
      expect(own.points, 10);
    });

    test('TC groups, Yakka ends and Yarak wrap', () {
      expect(Rules.yarak(12), 0); // Indicator Yakka -> 2s wild.
      expect(Rules.tcValidRun(['h-y', 'h-2', 'h-3'], 8), isTrue);
      expect(Rules.tcValidRun(['h-y', 'h-2', 'h-3', 'h-4'], 8), isTrue);
      expect(Rules.tcValidRun(['h-b', 'h-k', 'h-y'], 8), isTrue);
      expect(Rules.tcValidRun(['h-k', 'h-y', 'h-2'], 8), isFalse);
      expect(Rules.tcValidRun(['e-4', 'c-g', 'e-6'], 9), isTrue);
      expect(Rules.tcValidSet(['h-k', 'c-k', 'c-7'], 5), isTrue);
      final natural = [
        'h-2',
        'h-3',
        'h-4',
        'h-5',
        'c-7',
        'e-7',
        'p-7',
        'c-k',
        'e-k',
        'p-k',
      ];
      expect(Rules.tcWinningGroups(natural, 8), isNotNull);
      // Eleven cards: one spare is allowed.
      expect(Rules.tcWinningGroups([...natural, 'c-2'], 8), isNotNull);
      final broken = [...natural]..[9] = 'p-2';
      expect(Rules.tcWinningGroups(broken, 8), isNull);
    });

    test('Bluff claims are bounded by four copies', () {
      expect(Rules.bluffClaimPossible(2, 2), isTrue);
      expect(Rules.bluffClaimPossible(3, 2), isFalse);
    });
  });

  test('Every drill generates sound scenarios', () {
    final rng = Random(7);
    final drills = [
      ...basicsDrills,
      for (final course in courses.values) ...course.drills,
    ];
    for (final drill in drills) {
      for (var i = 0; i < 300; i++) {
        expectSound(drill.make(rng), '${drill.id} #$i');
      }
    }
  });

  test('Drills vary between rounds', () {
    final rng = Random(3);
    for (final drill in bhabhiDrills) {
      final prompts = {
        for (var i = 0; i < 20; i++)
          switch (drill.make(rng)) {
            final TapStep s => '${s.prompt}${s.hand}',
            final QuizStep s =>
              '${s.question}${s.scene.map((z) => z.cards.map((c) => c.card))}',
            final ExplainStep s => s.body,
          },
      };
      expect(prompts.length, greaterThan(10), reason: drill.id);
    }
  });

  test('Every lesson is sound', () {
    final lessons = [
      ...basicsLessons,
      for (final course in courses.values) ...course.lessons,
    ];
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
    for (final lesson in lessons) {
      for (var seed = 0; seed < 20; seed++) {
        final steps = lesson.build(Random(seed));
        expect(steps, isNotEmpty);
        for (var i = 0; i < steps.length; i++) {
          expectSound(steps[i], '${lesson.id} step ${i + 1}');
        }
      }
    }
  });

  group('Learn UI', () {
    Future<void> setPhone(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1236, 2745);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    /// Plays a lesson through to the finish screen, answering every step.
    Future<void> playThrough(
      WidgetTester tester,
      List<Lesson> lessons,
      int index,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: T.theme,
          home: LessonPlayerScreen(
            lessons: lessons,
            index: index,
            color: Colors.purple,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var guard = 0; guard < 40; guard++) {
        if (find.text('Lesson complete!').evaluate().isNotEmpty) return;
        final step = tester.widget<StepView>(find.byType(StepView)).step;
        switch (step) {
          case QuizStep s:
            await tapVisible(
              tester,
              find.widgetWithText(OutlinedButton, s.options[s.correct]),
            );
          case TapStep s:
            for (final card in s.solution) {
              await tapVisible(
                tester,
                find.byWidgetPredicate(
                  (w) => w is PlayingCard && w.card == card && w.onTap != null,
                ),
              );
            }
            await tapVisible(tester, _checkButton);
          case ExplainStep _:
            break;
        }
        expect(tester.takeException(), isNull);
        final next = find.text(
          find.text('Finish lesson').evaluate().isNotEmpty
              ? 'Finish lesson'
              : 'Continue',
        );
        await tapVisible(tester, next);
      }
      fail('${lessons[index].id} did not finish');
    }

    testWidgets('Course hub switches games and opens a lesson', (tester) async {
      await setPhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: T.theme,
          home: const Scaffold(body: LearnScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Know your deck'), findsOneWidget);
      await tapVisible(tester, find.text('TC'));
      expect(find.text('Find 4 + 3 + 3'), findsOneWidget);
      await tapVisible(tester, find.text('Find 4 + 3 + 3'));
      expect(find.text('Three groups, ten cards'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Every lesson can be played to the end', (tester) async {
      await setPhone(tester);
      final all = [basicsLessons, for (final c in courses.values) c.lessons];
      for (final lessons in all) {
        for (var i = 0; i < lessons.length; i++) {
          await playThrough(tester, lessons, i);
          expect(find.text('Lesson complete!'), findsOneWidget);
        }
      }
    });

    testWidgets('Wrong answers explain and offer help', (tester) async {
      await setPhone(tester);
      final step = TapStep.exact(
        prompt: 'Pick the Kinga',
        hand: const ['h-k', 'c-2'],
        answer: const {'h-k'},
        explanation: 'Kinga it is.',
        feedback: (_) => 'Not the 2!',
      );
      var resolvedFirstTry = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: T.theme,
          home: Scaffold(
            body: ListView(
              children: [
                StepView(
                  step: step,
                  color: Colors.purple,
                  onResolved: (first) => resolvedFirstTry = first,
                ),
              ],
            ),
          ),
        ),
      );
      Finder card(String id) => find.byWidgetPredicate(
        (w) => w is PlayingCard && w.card == id && w.onTap != null,
      );
      for (var i = 0; i < 2; i++) {
        await tapVisible(tester, card('c-2'));
        await tapVisible(tester, _checkButton);
        expect(find.text('Not the 2!'), findsOneWidget);
        await tapVisible(tester, card('c-2'));
      }
      await tapVisible(tester, find.text('Show me'));
      expect(find.textContaining('Kinga it is.'), findsOneWidget);
      expect(resolvedFirstTry, isFalse);
    });

    testWidgets('Practice deals a new scenario each round', (tester) async {
      await setPhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: T.theme,
          home: PracticeScreen(
            id: 'test',
            title: 'Practice',
            drills: [tcDrills.first],
            color: Colors.blue,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var round = 0; round < 3; round++) {
        final step =
            tester.widget<StepView>(find.byType(StepView)).step as QuizStep;
        await tapVisible(
          tester,
          find.widgetWithText(OutlinedButton, step.options[step.correct]),
        );
        expect(find.text('${round + 1}/${round + 1}'), findsOneWidget);
        await tapVisible(tester, find.text('Next challenge'));
      }
      expect(tester.takeException(), isNull);
    });
  });
}
