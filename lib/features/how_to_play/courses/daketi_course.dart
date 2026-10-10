import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../learn_drills.dart';
import '../learn_model.dart';
import '../learn_rules.dart';

final daketiCourse = Course(
  game: GameType.daketi,
  players: '2–7 players',
  goal: 'Capture and steal valuable cards. The biggest collection wins.',
  drills: daketiDrills,
  cheatSheet: const [
    (
      'Deal',
      '4 cards each, 4 face up on the table, the rest is stock. A random player starts.',
    ),
    ('Turn', 'Draw from the stock (up to 5 in hand), then play one card.'),
    (
      'Capture',
      'Match a table card\'s rank: take every table card of that rank.',
    ),
    (
      'Steal',
      'Match an opponent\'s top card: take it, plus any same-rank cards right under it.',
    ),
    ('Own stack', 'Match your own top card: your card joins your collection.'),
    (
      'Go again',
      'Any capture while stock remains keeps your turn. Empty stock: the turn always passes.',
    ),
    ('Values', 'Yakka 20 · Kinga, Begi, Gola 10 · 2–10 are 5.'),
    (
      'Prizes',
      'Highest points wins. Everyone except last place shares the pot.',
    ),
  ],
  lessons: [
    Lesson(
      id: 'daketi.goal',
      title: 'Goal & setup',
      summary: 'The deal, the table and what cards are worth.',
      icon: Icons.flag_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'A game of robbery',
          body:
              'Daketi means robbery. You build a collection of valuable cards by matching ranks — and by stealing from other players\' collections.',
          bullets: [
            '2 to 7 players',
            'Each player gets 4 cards',
            '4 cards go face up on the table',
            'The rest form the stock; a random player starts',
          ],
          scene: [
            SceneZone('Stock', [SceneCard.back(caption: 'draw pile')]),
            SceneZone('Table', [
              SceneCard('e-9'),
              SceneCard('c-k'),
              SceneCard('h-4'),
              SceneCard('p-9'),
            ]),
            SceneZone('Your hand', [
              SceneCard('h-9'),
              SceneCard('p-k'),
              SceneCard('c-2'),
              SceneCard('e-5'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'What cards are worth',
          body:
              'At the end, every card in your collection scores points. Suits never matter — only rank.',
          scene: [
            SceneZone('Values', [
              SceneCard('p-y', caption: '20'),
              SceneCard('h-k', caption: '10'),
              SceneCard('c-b', caption: '10'),
              SceneCard('e-g', caption: '10'),
              SceneCard('p-7', caption: '5'),
            ]),
          ],
          bullets: [
            'Yakka: 20 points',
            'Kinga, Begi, Gola: 10 points',
            '2 to 10: 5 points',
          ],
        ),
        const ExplainStep(
          title: 'Winning',
          body:
              'When every hand is empty, collections are scored. The highest total wins. Everyone except last place shares the pot, and your points also count toward your Daketi leaderboard score.',
          tip: 'Tied on points? The player in the earlier seat places higher.',
        ),
        daketiCountDrill(rng),
      ],
    ),
    Lesson(
      id: 'daketi.turn',
      title: 'Your turn',
      summary: 'Draw, then play one card.',
      icon: Icons.touch_app_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Draw, then play',
          body:
              'On your turn, tap the stock to draw a card — you can hold up to 5. Then play one card from your hand onto the table. What happens next depends on what it matches.',
        ),
        QuizStep(
          question:
              'You hold 4 cards and the stock has cards. What do you do first?',
          options: [
            'Draw from the stock',
            'Play immediately and skip drawing',
            'Wait for the next player',
          ],
          correct: 0,
          explanation:
              'Drawing first gives you five cards to choose from — more chances to match something valuable.',
        ),
        QuizStep(
          question: 'You already hold 5 cards. Can you draw?',
          options: ['No — 5 is the limit', 'Yes, as many as I like'],
          correct: 0,
          shuffle: false,
          explanation: 'Your hand can never go above five cards.',
        ),
      ],
    ),
    Lesson(
      id: 'daketi.table',
      title: 'Capture from the table',
      summary: 'Match a rank, take every copy.',
      icon: Icons.back_hand_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Match the rank',
          body:
              'Play a card with the same RANK as a table card and you capture it — suits do not matter. Every table card of that rank comes along, and your own card goes into your collection with them.',
          scene: [
            SceneZone('Table', [
              SceneCard('c-7', glow: true),
              SceneCard('e-7', glow: true),
              SceneCard('h-k'),
              SceneCard('p-3'),
            ]),
            SceneZone('You play', [
              SceneCard('p-7', glow: true),
            ], note: 'You collect all three 7s: 15 points.'),
          ],
        ),
        const ExplainStep(
          title: 'No match?',
          body:
              'If your card matches nothing, it simply stays on the table — where anybody can capture it later.',
        ),
        TapStep.exact(
          prompt: 'Which card captures the most points from the table?',
          scene: const [
            SceneZone('Table', [
              SceneCard('e-b'),
              SceneCard('c-9'),
              SceneCard('h-2'),
              SceneCard('p-b'),
            ]),
          ],
          hand: const ['h-7', 'c-b', 'e-4', 'p-2'],
          answer: const {'c-b'},
          explanation:
              'Your Chirri Begi takes both Begis: three face cards for 30 points. The Pawn 2 would only get 10.',
          feedback: (p) => p.first == 'p-2'
              ? 'That captures the Hukam 2 (10 points). Something else is worth more.'
              : 'That card matches nothing on the table. Look for a rank that appears there.',
        ),
        daketiBestDrill(rng),
      ],
    ),
    Lesson(
      id: 'daketi.steal',
      title: 'Daketi! Stealing',
      summary: 'Rob the top of other collections.',
      icon: Icons.local_police_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Collections are targets',
          body:
              'Every player\'s collection is a face-up stack, and only its top card matters. Play a card matching the RANK of an opponent\'s top card and you steal it — plus any cards of the same rank sitting right underneath.',
          scene: [
            SceneZone('Omar\'s collection', [
              SceneCard.back(caption: '6 below'),
              SceneCard('h-y', caption: 'top', glow: true),
            ]),
            SceneZone('You play', [
              SceneCard('p-y', glow: true),
            ], note: 'Steal the Yakka: 40 points!'),
          ],
        ),
        const ExplainStep(
          title: 'All at once',
          body:
              'One card can capture from the table AND steal from several players in the same move. Everything it matches goes into your collection.',
        ),
        TapStep.exact(
          prompt: 'Which card earns the most points?',
          scene: const [
            SceneZone('Table', [SceneCard('c-5'), SceneCard('e-9')]),
            SceneZone('Omar\'s collection', [
              SceneCard.back(caption: '4 below'),
              SceneCard('h-y', caption: 'top'),
            ]),
            SceneZone('Hina\'s collection', [
              SceneCard.back(caption: '2 below'),
              SceneCard('e-3', caption: 'top'),
            ]),
          ],
          hand: const ['p-y', 'c-3', 'h-9', 'e-6'],
          answer: const {'p-y'},
          explanation:
              'Your Pawn Yakka steals Omar\'s Hukam Yakka: two Yakkas, 40 points. The 9 or the 3 would only earn 10.',
          feedback: (p) =>
              '${Rules.daketiPlay(p.first, const ['c-5', 'e-9'], const {
                'Omar': ['h-y'],
                'Hina': ['e-3'],
              }, const []).describe()} Look at the collection tops — one is very valuable.',
        ),
        daketiBestDrill(rng),
        daketiBestDrill(rng),
      ],
    ),
    Lesson(
      id: 'daketi.again',
      title: 'Keep the turn',
      summary: 'Your own stack, and capturing again and again.',
      icon: Icons.replay,
      build: (rng) => [
        const ExplainStep(
          title: 'Your own stack',
          body:
              'Play a card matching your OWN top card and it joins your collection. That counts as a capture too.',
          scene: [
            SceneZone('Your collection', [
              SceneCard.back(caption: '3 below'),
              SceneCard('c-g', caption: 'top'),
            ]),
            SceneZone('You play', [
              SceneCard('h-g', glow: true),
            ], note: 'The Gola joins your stack.'),
          ],
        ),
        const ExplainStep(
          title: 'Go again',
          body:
              'Any capture — from the table, a steal, or your own stack — while the stock still has cards means you go again: draw and play another card. Once the stock is empty, the turn passes after every card, capture or not.',
        ),
        daketiTurnDrill(rng),
        daketiTurnDrill(rng),
        daketiTurnDrill(rng),
      ],
    ),
    Lesson(
      id: 'daketi.end',
      title: 'Endgame',
      summary: 'When the stock runs dry.',
      icon: Icons.hourglass_bottom,
      build: (rng) => [
        const ExplainStep(
          title: 'Playing out',
          body:
              'When the stock is empty, nobody draws any more. Players keep taking turns, playing one card at a time, until every hand is empty. Then the collections are scored.',
        ),
        const QuizStep(
          question:
              'The stock is empty and you capture two Kingas. What happens next?',
          options: ['The turn passes', 'You play again'],
          correct: 0,
          shuffle: false,
          explanation:
              'Without stock, every card ends your turn — even a capture.',
        ),
        daketiCountDrill(rng),
        daketiCountDrill(rng),
      ],
    ),
    Lesson(
      id: 'daketi.strategy',
      title: 'Strategy: guard your top',
      summary: 'Count ranks, protect your stack.',
      icon: Icons.psychology_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Your top is a target',
          body:
              'After a capture, your top card is the rank you just played. Anyone holding that rank can steal the whole matching run off your stack. Count how many copies of that rank are already accounted for.',
          scene: [
            SceneZone('Your collection', [
              SceneCard('p-k'),
              SceneCard('c-k'),
              SceneCard('h-9'),
              SceneCard('e-9'),
              SceneCard('p-9', caption: 'top'),
            ]),
          ],
        ),
        const QuizStep(
          question:
              'Your top is three 9s. Omar plays the last 9. What does Omar take?',
          options: [
            'All three 9s on your top',
            'Only the top 9',
            'Your whole collection',
          ],
          correct: 0,
          explanation:
              'A steal takes the whole run of matching cards on top — here, three 9s. Your Kingas underneath are safe.',
        ),
        const ExplainStep(
          title: 'Feed the table cheap cards',
          body:
              'When nothing captures, play your least valuable card. Whatever you leave on the table can be captured by the next player, so never leave them a Yakka.',
        ),
        TapStep(
          prompt:
              'Nothing in your hand captures. Which card do you leave on the table?',
          scene: const [
            SceneZone('Table', [SceneCard('p-8'), SceneCard('c-6')]),
            SceneZone('Omar\'s collection', [
              SceneCard('e-10', caption: 'top'),
            ]),
          ],
          hand: const ['h-y', 'c-k', 'e-4'],
          accepts: (p) => p.length == 1 && p.first == 'e-4',
          solution: const {'e-4'},
          explanation:
              'The 4 is worth just 5 points if someone captures it. The Yakka (20) and Kinga (10) stay in your hand for a real capture later.',
          feedback: (_) =>
              'Leaving a high card on the table hands points to the next player. Play your cheapest card.',
        ),
        const ExplainStep(
          title: 'More tips',
          body: 'Think before every card:',
          bullets: [
            'Value beats count: one Yakka pair (40) beats three number cards (15)',
            'Check every collection top, not just the table',
            'Keep pairs in your hand — they capture each other\'s rank later',
            'Remember which ranks are used up: their tops are safe',
          ],
        ),
        daketiBestDrill(rng),
      ],
    ),
    Lesson(
      id: 'daketi.guided',
      title: 'Guided hand',
      summary: 'Capture, chain turns and get robbed.',
      icon: Icons.play_circle_outline,
      guided: true,
      build: (rng) => [
        const ExplainStep(
          title: 'Your seat at the table',
          body: 'Two players: you and Omar. You start.',
          scene: [
            SceneZone('Table', [
              SceneCard('e-9'),
              SceneCard('c-k'),
              SceneCard('h-4'),
              SceneCard('p-9'),
            ]),
            SceneZone('Your hand', [
              SceneCard('h-9'),
              SceneCard('p-k'),
              SceneCard('c-2'),
              SceneCard('e-5'),
            ]),
          ],
        ),
        const QuizStep(
          title: 'Step 1',
          question: 'You hold 4 cards and the stock is full. First move?',
          options: ['Draw a card', 'Play a card right away'],
          correct: 0,
          shuffle: false,
          explanation:
              'You draw the Eit Yakka. Five cards: more chances to match.',
        ),
        TapStep.exact(
          title: 'Step 2 · capture',
          prompt: 'Which card captures the most points?',
          scene: const [
            SceneZone('Table', [
              SceneCard('e-9'),
              SceneCard('c-k'),
              SceneCard('h-4'),
              SceneCard('p-9'),
            ]),
          ],
          hand: const ['h-9', 'p-k', 'c-2', 'e-5', 'e-y'],
          answer: const {'p-k'},
          explanation:
              'Your Pawn Kinga captures the Chirri Kinga: 20 points. You captured and the stock is not empty, so you go again. You draw the Hukam 6.',
          feedback: (p) => p.first == 'h-9'
              ? 'That grabs two 9s for 15 points — good, but the Kinga pair is worth 20.'
              : 'That card matches nothing on the table.',
        ),
        TapStep.exact(
          title: 'Step 3 · keep going',
          prompt: 'Still your turn. Capture again!',
          scene: const [
            SceneZone('Table', [
              SceneCard('e-9'),
              SceneCard('h-4'),
              SceneCard('p-9'),
            ]),
            SceneZone('Your collection', [
              SceneCard('p-k'),
              SceneCard('c-k', caption: 'top'),
            ]),
          ],
          hand: const ['h-9', 'c-2', 'e-5', 'e-y', 'h-6'],
          answer: const {'h-9'},
          explanation:
              'Three 9s: +15. Another capture with stock left — you go again. You draw the Chirri 3.',
          feedback: (_) => 'Look for a rank that is on the table.',
        ),
        TapStep(
          title: 'Step 4 · no match',
          prompt:
              'Nothing on the table, Omar\'s empty collection or your own top matches any more. Which card do you leave on the table?',
          scene: const [
            SceneZone('Table', [SceneCard('h-4')]),
            SceneZone('Your collection', [
              SceneCard.back(caption: '2 Kingas'),
              SceneCard('h-9'),
              SceneCard('e-9'),
              SceneCard('p-9', caption: 'top'),
            ]),
          ],
          hand: const ['c-2', 'e-5', 'e-y', 'h-6', 'c-3'],
          accepts: (p) => p.length == 1 && p.first != 'e-y',
          solution: const {'c-2'},
          explanation:
              'A number card costs only 5 if Omar captures it. Never leave a Yakka on the table! No capture, so the turn passes to Omar.',
          feedback: (_) =>
              'Leaving your Yakka gives Omar a free 20 points. Pick a number card.',
        ),
        const QuizStep(
          title: 'Omar\'s turn',
          question:
              'Omar plays the Chirri 9 — the last 9 in the deck. What does Omar take?',
          scene: [
            SceneZone('Your collection', [
              SceneCard.back(caption: '2 Kingas'),
              SceneCard('h-9'),
              SceneCard('e-9'),
              SceneCard('p-9', caption: 'top'),
            ]),
          ],
          options: [
            'All three 9s from your top',
            'Just your top 9',
            'Nothing — collections are safe',
          ],
          correct: 0,
          explanation:
              'Daketi! A steal takes the whole run of matching cards on top. Omar collects four 9s (20 points). Your top is a Kinga again — and the other two Kingas are still out there, so guard it.',
        ),
        const ExplainStep(
          title: 'Well played!',
          body: 'You just used every key idea in Daketi:',
          bullets: [
            'Drew up to five before playing',
            'Chose value over card count',
            'Chained captures while the stock lasted',
            'Left only a cheap card on the table',
            'Saw how an exposed top gets stolen',
          ],
        ),
      ],
    ),
  ],
);
