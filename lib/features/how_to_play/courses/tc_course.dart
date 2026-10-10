import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../learn_drills.dart';
import '../learn_model.dart';
import '../learn_rules.dart';

/// Indicator Chirri 6 makes 7 the Yarak in the scripted examples.
const _yarak7 = 5;

final tcCourse = Course(
  game: GameType.tc,
  players: '2–4 players',
  goal:
      'Arrange all ten cards into one group of 4 and two groups of 3, then claim victory.',
  drills: tcDrills,
  cheatSheet: const [
    ('Deal', '10 cards each; the rest is stock. A random player starts.'),
    (
      'Groups',
      'Set: 3–4 cards of one rank. Run: 3–4 cards of one suit in a row.',
    ),
    ('Yakka', 'High (B-K-Y) or low (Y-2-3, Y-2-3-4). Never K-Y-2.'),
    (
      'Yarak',
      'The rank after the indicator is wild. Indicator Yakka → 2s are wild.',
    ),
    ('Turn', 'Draw from stock or take the top discard → discard one.'),
    (
      'Restriction',
      'You cannot discard the card you just took from the discard pile.',
    ),
    (
      'Claim',
      'On your turn with 10 or 11 cards. With 11, one spare card is allowed.',
    ),
    (
      'Prizes',
      'The winner takes the whole pot. Each Yarak in hand at the end: +10 points.',
    ),
  ],
  lessons: [
    Lesson(
      id: 'tc.goal',
      title: 'Find 4 + 3 + 3',
      summary: 'The goal and the winning shape.',
      icon: Icons.flag_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Three groups, ten cards',
          body:
              'Tissar Chausar ("three-four") is a rummy game for 2 to 4 players. Everyone gets 10 cards. Your goal: arrange all ten into one group of FOUR and two groups of THREE.',
          scene: [
            SceneZone('Group of 4 · run', [
              SceneCard('e-5'),
              SceneCard('e-6'),
              SceneCard('e-7'),
              SceneCard('e-8'),
            ]),
            SceneZone('Group of 3 · set', [
              SceneCard('h-k'),
              SceneCard('c-k'),
              SceneCard('p-k'),
            ]),
            SceneZone('Group of 3 · run', [
              SceneCard('c-2'),
              SceneCard('c-3'),
              SceneCard('c-4'),
            ]),
          ],
        ),
        ExplainStep(
          title: 'Winner takes all',
          body:
              'The first player to make a valid claim wins the entire pot. There is no second place in Tissar Chausar.',
        ),
        QuizStep(
          question: 'Which shape wins?',
          options: ['4 + 3 + 3', '5 + 5', '3 + 3 + 3 + 1'],
          correct: 0,
          explanation:
              'Exactly one group of four and two groups of three, using all ten cards.',
        ),
      ],
    ),
    Lesson(
      id: 'tc.sets',
      title: 'Sets',
      summary: 'Same rank, any suits.',
      icon: Icons.copy_all_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Same rank',
          body: 'A set is 3 or 4 cards of the same rank. Suits do not matter.',
          scene: [
            SceneZone('Set of 3', [
              SceneCard('h-b'),
              SceneCard('e-b'),
              SceneCard('c-b'),
            ]),
            SceneZone('Set of 4', [
              SceneCard('h-5'),
              SceneCard('e-5'),
              SceneCard('p-5'),
              SceneCard('c-5'),
            ]),
          ],
        ),
        TapStep.exact(
          prompt: 'Select the set hiding in this hand.',
          hand: const ['c-8', 'h-8', 'e-2', 'p-8', 'h-k', 'c-g'],
          answer: const {'c-8', 'h-8', 'p-8'},
          explanation: 'Three 8s — a set of three.',
          feedback: (_) => 'A set needs every card to share one rank.',
        ),
        const QuizStep(
          question: 'Is Hukam Kinga, Eit Kinga, Pawn Begi a set?',
          options: ['Valid set', 'Not a set'],
          correct: 1,
          shuffle: false,
          explanation:
              'The Begi breaks it: every card in a set must share one rank.',
        ),
      ],
    ),
    Lesson(
      id: 'tc.runs',
      title: 'Runs',
      summary: 'One suit, ranks in a row.',
      icon: Icons.linear_scale,
      build: (rng) => [
        const ExplainStep(
          title: 'In a row',
          body: 'A run is 3 or 4 cards of the SAME suit with ranks in a row.',
          scene: [
            SceneZone('Run of 4', [
              SceneCard('p-9'),
              SceneCard('p-10'),
              SceneCard('p-g'),
              SceneCard('p-b'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'Yakka at both ends',
          body:
              'Yakka can sit at the top (Begi-Kinga-Yakka) or the bottom (Yakka-2-3, or Yakka-2-3-4). Runs never wrap around, so Kinga-Yakka-2 is not allowed.',
          scene: [
            SceneZone('High ✓', [
              SceneCard('h-b'),
              SceneCard('h-k'),
              SceneCard('h-y'),
            ]),
            SceneZone('Low ✓', [
              SceneCard('c-y'),
              SceneCard('c-2'),
              SceneCard('c-3'),
            ]),
            SceneZone('Wrap ✗', [
              SceneCard('e-k', dim: true),
              SceneCard('e-y', dim: true),
              SceneCard('e-2', dim: true),
            ]),
          ],
        ),
        const QuizStep(
          question: 'Is Pawn 9, Pawn 10, Eit Gola a run?',
          options: ['Valid run', 'Not a run'],
          correct: 1,
          shuffle: false,
          explanation:
              'The ranks are in a row, but a run must be all one suit.',
        ),
        tcValidDrill(rng),
        tcValidDrill(rng),
      ],
    ),
    Lesson(
      id: 'tc.yarak',
      title: 'Indicator & Yarak',
      summary: 'The wild card that changes every game.',
      icon: Icons.auto_awesome,
      build: (rng) => [
        const ExplainStep(
          title: 'The indicator',
          body:
              'After the deal, one card is shown face up beside the stock: the indicator. The rank right after it is the Yarak — and all four Yarak cards are wild.',
          scene: [
            SceneZone('Indicator', [SceneCard('c-6', caption: 'Chirri 6')]),
            SceneZone('Yarak = 7 (wild)', [
              SceneCard('h-7', glow: true),
              SceneCard('e-7', glow: true),
              SceneCard('p-7', glow: true),
              SceneCard('c-7', glow: true),
            ]),
          ],
          tip: 'Indicator Yakka? The rank wraps around: 2s are wild.',
        ),
        const ExplainStep(
          title: 'Wild anywhere',
          body:
              'A Yarak can stand in for any card in a set or a run. A group may even use more than one Yarak.',
          scene: [
            SceneZone('Run with a Yarak', [
              SceneCard('e-9'),
              SceneCard('e-10'),
              SceneCard('p-7', glow: true, caption: 'as Eit Gola'),
            ]),
            SceneZone('Set with a Yarak', [
              SceneCard('h-k'),
              SceneCard('c-k'),
              SceneCard('c-7', glow: true, caption: 'as a Kinga'),
            ]),
          ],
        ),
        tcYarakDrill(rng),
        tcYarakDrill(rng),
        const QuizStep(
          question:
              'The indicator is the Hukam 10. Is Eit 4, Chirri Gola, Eit 6 a valid group?',
          scene: [
            SceneZone('Indicator', [SceneCard('h-10')]),
            SceneZone('Group', [
              SceneCard('e-4'),
              SceneCard('c-g'),
              SceneCard('e-6'),
            ]),
          ],
          options: ['Valid group', 'Not valid'],
          correct: 0,
          shuffle: false,
          hint: 'Find the Yarak first: what comes right after 10?',
          explanation:
              'Gola comes after 10, so every Gola is wild. The Chirri Gola fills the gap: Eit 4-5-6.',
        ),
      ],
    ),
    Lesson(
      id: 'tc.turn',
      title: 'Draw & discard',
      summary: 'The rhythm of every turn.',
      icon: Icons.swap_vert,
      build: (rng) => [
        const ExplainStep(
          title: 'Two steps',
          body: 'Every turn has the same rhythm:',
          bullets: [
            '1. Take a card: tap the stock, or take the top card of the discard pile. You now hold 11.',
            '2. Discard one card face up. You are back to 10 and the turn passes.',
          ],
          scene: [
            SceneZone('Stock', [SceneCard.back(caption: 'hidden')]),
            SceneZone('Discard pile', [
              SceneCard('p-8', caption: 'top, face up'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'One restriction',
          body:
              'You cannot discard the same card you just took from the discard pile. A card drawn from the stock, though, may be thrown away immediately.',
        ),
        const QuizStep(
          question:
              'You took the Pawn 8 from the discard pile. Can you discard it right back?',
          options: ['No — choose another card', 'Yes'],
          correct: 0,
          shuffle: false,
          explanation:
              'A card taken from the discard pile must stay for at least a turn. Discard something else.',
        ),
        const QuizStep(
          question:
              'You drew the Hukam 2 from the stock and it is useless. May you discard it?',
          options: ['Yes', 'No'],
          correct: 0,
          shuffle: false,
          explanation: 'Stock cards can be discarded straight away.',
        ),
        const ExplainStep(
          title: 'When the stock runs out',
          body:
              'If the stock is empty at the start of your turn, tap Recycle: the discard pile is shuffled into a fresh stock. The Yarak stays the same.',
        ),
        TapStep(
          title: 'Pick a discard',
          prompt:
              'Yarak is 7. You hold 11 cards. Which card is worth throwing away?',
          scene: const [
            SceneZone('Indicator', [SceneCard('c-6')]),
          ],
          hand: const [
            'h-3',
            'h-4',
            'h-5',
            'e-9',
            'c-9',
            'p-9',
            'p-b',
            'p-k',
            'c-2',
            'e-6',
            'h-g',
          ],
          accepts: (p) =>
              p.length == 1 && {'c-2', 'e-6', 'h-g'}.contains(p.first),
          solution: const {'c-2'},
          explanation:
              'The Chirri 2, Eit 6 and Hukam Gola connect to nothing. Keep your Hukam 3-4-5 run, your three 9s, and the Pawn Begi-Kinga pair — it needs just one more card.',
          feedback: (_) =>
              'That card is part of a group or a near-group. Throw away a card that connects to nothing.',
        ),
      ],
    ),
    Lesson(
      id: 'tc.claim',
      title: 'Claiming victory',
      summary: 'When and how to call it.',
      icon: Icons.workspace_premium_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Make the call',
          body:
              'When your cards form 4 + 3 + 3, tap Claim victory on your turn. The server checks your hand. A wrong claim is simply rejected and the game goes on — your hand is unchanged.',
        ),
        const ExplainStep(
          title: 'Claim with 11 cards',
          body:
              'You do not have to discard first! Right after drawing you hold 11 cards. If ten of them make 4 + 3 + 3, claim straight away — the spare card is ignored.',
        ),
        const QuizStep(
          question:
              'You just drew the card that completes your hand. What now?',
          options: [
            'Claim victory right away',
            'Discard first, then claim next turn',
          ],
          correct: 0,
          shuffle: false,
          explanation:
              'Claim immediately. Waiting gives every other player another turn to beat you.',
        ),
        tcClaimDrill(rng),
        tcClaimDrill(rng),
        const ExplainStep(
          title: 'Yarak bonus',
          body:
              'When the game ends, every Yarak card still in a player\'s hand is worth 10 leaderboard points to them — winner or not.',
        ),
      ],
    ),
    Lesson(
      id: 'tc.strategy',
      title: 'Strategy',
      summary: 'Build flexibly and read your rivals.',
      icon: Icons.psychology_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Build smart',
          body: 'Good Tissar Chausar players think ahead:',
          bullets: [
            'Never discard a Yarak — it fits anywhere',
            'Keep near-groups: pairs, and two cards of a run with one gap',
            'Throw away cards that connect to nothing first',
            'Middle ranks (5–9) join more runs than Yakkas or 2s',
            'Aim for the group of four early: it is the hardest to finish',
          ],
        ),
        const ExplainStep(
          title: 'Read the discard pile',
          body:
              'When someone takes a card from the discard pile, they are building with that rank or suit. Avoid discarding cards that help them, and watch what they throw away too.',
        ),
        const QuizStep(
          question:
              'Omar just took the Eit 9 from the discard pile. You hold a Hukam 9 you do not need. Discard it?',
          options: [
            'Better not — Omar may be collecting 9s',
            'Yes, it does not matter',
          ],
          correct: 0,
          shuffle: false,
          explanation:
              'Omar wanted that 9. Feeding another one could complete their set. Throw something safer.',
        ),
        tcBuildDrill(rng),
        tcValidDrill(rng),
      ],
    ),
    Lesson(
      id: 'tc.guided',
      title: 'Guided hand',
      summary: 'From a messy hand to a winning claim.',
      icon: Icons.play_circle_outline,
      guided: true,
      build: (rng) => [
        const ExplainStep(
          title: 'Your hand',
          body:
              'Two players: you and Omar. Here are your ten cards and the indicator. Let\'s find your groups.',
          scene: [
            SceneZone('Indicator', [SceneCard('c-6')]),
            SceneZone('Your hand', [
              SceneCard('h-3'),
              SceneCard('h-4'),
              SceneCard('h-5'),
              SceneCard('h-7'),
              SceneCard('e-9'),
              SceneCard('c-9'),
              SceneCard('p-9'),
              SceneCard('e-b'),
              SceneCard('e-k'),
              SceneCard('c-2'),
            ]),
          ],
        ),
        const QuizStep(
          title: 'Step 1',
          question: 'The indicator is the Chirri 6. Which rank is Yarak?',
          scene: [
            SceneZone('Indicator', [SceneCard('c-6')]),
          ],
          options: ['7', '6', '8'],
          correct: 0,
          explanation: '7 comes right after 6. Your Hukam 7 is wild!',
        ),
        TapStep(
          title: 'Step 2',
          prompt: 'Select any complete group of three in your hand.',
          hand: const [
            'h-3',
            'h-4',
            'h-5',
            'h-7',
            'e-9',
            'c-9',
            'p-9',
            'e-b',
            'e-k',
            'c-2',
          ],
          minPick: 3,
          maxPick: 3,
          accepts: (p) => Rules.tcValidGroup(p.toList(), _yarak7),
          solution: const {'h-3', 'h-4', 'h-5'},
          explanation:
              'Nice. Your hand holds three groups of three: Hukam 3-4-5, three 9s, and Eit Begi-Kinga with the Hukam 7 as a wild card. Only the Chirri 2 is left over.',
          feedback: (_) =>
              'Not a group. Look for a Hukam run, a set of one rank, or use the wild Hukam 7.',
        ),
        const QuizStep(
          title: 'Step 3',
          question:
              'You need one card that turns a group of three into a group of four. Omar discards the Hukam 2. Take it, or draw from the stock?',
          scene: [
            SceneZone('Discard pile', [
              SceneCard('h-2', caption: 'Omar\'s discard', glow: true),
            ]),
          ],
          options: ['Take the Hukam 2', 'Draw from the stock'],
          correct: 0,
          shuffle: false,
          explanation: 'Hukam 2-3-4-5 is a run of four. Take it!',
        ),
        const QuizStep(
          title: 'Step 4',
          question: 'You now hold 11 cards. What is your best move?',
          scene: [
            SceneZone('Your hand', [
              SceneCard('h-2', glow: true),
              SceneCard('h-3'),
              SceneCard('h-4'),
              SceneCard('h-5'),
              SceneCard('e-9'),
              SceneCard('c-9'),
              SceneCard('p-9'),
              SceneCard('e-b'),
              SceneCard('e-k'),
              SceneCard('h-7'),
              SceneCard('c-2', dim: true),
            ]),
          ],
          options: [
            'Claim victory now',
            'Discard the Chirri 2 first',
            'Discard the Hukam 2',
          ],
          correct: 0,
          explanation:
              'Ten of your eleven cards make 4 + 3 + 3; the Chirri 2 is the spare. Claim right away! (You could not discard the Hukam 2 anyway — you just took it from the discard pile.)',
        ),
        const ExplainStep(
          title: 'Victory!',
          body:
              'The server checks your groups and you win the whole pot. Your Hukam 7, a Yarak, also earns you 10 leaderboard points.',
          scene: [
            SceneZone('Group of 4', [
              SceneCard('h-2'),
              SceneCard('h-3'),
              SceneCard('h-4'),
              SceneCard('h-5'),
            ]),
            SceneZone('Group of 3', [
              SceneCard('e-9'),
              SceneCard('c-9'),
              SceneCard('p-9'),
            ]),
            SceneZone('Group of 3', [
              SceneCard('e-b'),
              SceneCard('e-k'),
              SceneCard('h-7', glow: true, caption: 'wild'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'Well played!',
          body: 'You just used every key idea in Tissar Chausar:',
          bullets: [
            'Found the Yarak from the indicator',
            'Spotted sets, runs and a wild-card group',
            'Took the exact discard you needed',
            'Claimed with 11 cards instead of waiting',
          ],
        ),
      ],
    ),
  ],
);
