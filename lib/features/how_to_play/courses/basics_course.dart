import 'package:flutter/material.dart';

import '../learn_drills.dart';
import '../learn_model.dart';

/// Shared foundation for every game: card names, rank order, rooms and coins.
final basicsLessons = [
  Lesson(
    id: 'basics.deck',
    title: 'Know your deck',
    summary: 'Suit and face names used at every Taash table.',
    icon: Icons.style_outlined,
    build: (rng) => [
      ExplainStep(
        title: 'One deck, four suits',
        body:
            'Every game uses a standard 52-card deck: four suits of 13 cards. At the table the suits go by their local names.',
        scene: const [
          SceneZone('The four suits', [
            SceneCard('h-y', caption: 'Hukam ♠'),
            SceneCard('e-y', caption: 'Eit ♦'),
            SceneCard('p-y', caption: 'Pawn ♥'),
            SceneCard('c-y', caption: 'Chirri ♣'),
          ]),
        ],
        tip:
            'Hukam is spades, Eit is diamonds, Pawn is hearts and Chirri is clubs.',
      ),
      const ExplainStep(
        title: 'The face cards',
        body:
            'The picture cards and the ace have names too. You will hear them in every lesson.',
        scene: [
          SceneZone('Faces', [
            SceneCard('p-y', caption: 'Yakka (A)'),
            SceneCard('p-k', caption: 'Kinga (K)'),
            SceneCard('p-b', caption: 'Begi (Q)'),
            SceneCard('p-g', caption: 'Gola (J)'),
          ]),
        ],
      ),
      const ExplainStep(
        title: 'Low to high',
        body:
            'Ranks always run the same way: 2 is the lowest and Yakka is the highest. Suits are never ranked against each other.',
        bullets: ['2 3 4 5 6 7 8 9 10', 'then Gola → Begi → Kinga → Yakka'],
        scene: [
          SceneZone('Lowest → highest', [
            SceneCard('c-2', caption: 'lowest'),
            SceneCard('c-9'),
            SceneCard('c-g'),
            SceneCard('c-b'),
            SceneCard('c-k'),
            SceneCard('c-y', caption: 'highest'),
          ]),
        ],
      ),
      const QuizStep(
        question: 'Which suit is Pawn?',
        options: ['Hearts ♥', 'Spades ♠', 'Clubs ♣', 'Diamonds ♦'],
        correct: 0,
        explanation:
            'Pawn is hearts. Hukam is spades, Chirri is clubs and Eit is diamonds.',
      ),
      nameCardDrill(rng),
      highestRankDrill(rng),
      const QuizStep(
        question: 'Which is higher: a Begi or a Gola?',
        options: ['Begi', 'Gola', 'They are equal'],
        correct: 0,
        explanation:
            'Begi (queen) beats Gola (jack). The order is Gola → Begi → Kinga → Yakka.',
      ),
    ],
  ),
  Lesson(
    id: 'basics.rooms',
    title: 'Rooms, coins & places',
    summary: 'How a table fills, what you pay and what you win.',
    icon: Icons.casino_outlined,
    build: (rng) => const [
      ExplainStep(
        title: 'Taking a seat',
        body:
            'Every game happens in a room. Each player pays the room\'s entry fee when they sit down, and all fees go into one pot. The game starts automatically once every seat is filled.',
        bullets: [
          'Bhabhi, Bluff and Daketi: 2 to 7 players',
          'Tissar Chausar: 2 to 4 players',
          'Public rooms may fill empty seats with bots',
          'Leave before the game starts and your fee is refunded',
        ],
      ),
      ExplainStep(
        title: 'Places and prizes',
        body:
            'When a game ends, players are ranked into places. In Bhabhi, Bluff and Daketi everyone except the last place wins a share of the pot, and better places win more: 1st earns twice as much as 2nd and three times as much as 3rd.',
        tip: 'Tissar Chausar is different: one winner takes the whole pot.',
      ),
      ExplainStep(
        title: 'The server is the referee',
        body:
            'Every move is checked by the server. Illegal moves are rejected and your hand stays as it was, so you can never be cheated by another player\'s app. Your own cards are hidden from everyone else.',
      ),
      QuizStep(
        question:
            'Six players finish a game of Daketi. How many of them win coins?',
        options: ['Five — all but last place', 'Only the winner', 'All six'],
        correct: 0,
        explanation:
            'In Bhabhi, Bluff and Daketi every place except the last shares the pot, with bigger shares for better places.',
      ),
      QuizStep(
        question: 'Four players finish Tissar Chausar. Who wins coins?',
        options: [
          'Only the player who claimed victory',
          'The top three',
          'Everyone',
        ],
        correct: 0,
        explanation: 'In Tissar Chausar the winner takes the whole pot.',
      ),
    ],
  ),
];
