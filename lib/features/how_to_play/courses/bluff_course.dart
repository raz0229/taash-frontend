import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../learn_drills.dart';
import '../learn_model.dart';

final bluffCourse = Course(
  game: GameType.bluff,
  players: '2–7 players',
  goal:
      'Empty your hand first — honestly or not. The last player holding cards loses.',
  drills: bluffDrills,
  cheatSheet: const [
    ('Deal', 'All 52 cards are dealt. The Hukam Yakka holder starts.'),
    ('Open', 'Empty pile: play 2–4 cards face down and declare any rank.'),
    ('Continue', 'Play 1–4 cards claiming the same rank, pass, or challenge.'),
    (
      'Challenge',
      'Only the last play is revealed. Liar caught: they take the pile. Honest: the challenger takes it.',
    ),
    (
      'All pass',
      'Everyone else passes: the pile leaves the game and the last player to play opens next.',
    ),
    (
      'Going out',
      'Your finish is provisional until the next player plays or passes.',
    ),
    ('Points', 'Right call +10, wrong side of a challenge −5.'),
    ('Prizes', 'Everyone except last place shares the pot.'),
  ],
  lessons: [
    Lesson(
      id: 'bluff.goal',
      title: 'Lie your way out',
      summary: 'The goal, the deal and what others can see.',
      icon: Icons.theater_comedy_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Shed your cards — somehow',
          body:
              'Bluff is a race to empty your hand. All 52 cards are dealt out. Cards are played face down onto a shared pile, so you can tell the truth about them... or not.',
          bullets: [
            '2 to 7 players',
            'The Hukam Yakka holder starts',
            'First to empty their hand wins; the last one holding cards loses',
            'Everyone except last place shares the pot',
          ],
        ),
        ExplainStep(
          title: 'What everyone sees',
          body:
              'When you play, the table only sees HOW MANY cards you put down and WHICH RANK the round is about. The cards themselves stay hidden unless someone challenges.',
          scene: [
            SceneZone('Pile · round of 8s', [
              SceneCard.back(caption: 'Sana: two 8s'),
              SceneCard.back(caption: 'Bilal: one 8'),
              SceneCard.back(caption: 'You: two 8s'),
            ]),
          ],
        ),
        QuizStep(
          question: 'What can other players see when you play?',
          options: [
            'How many cards, and the rank being claimed',
            'The actual cards',
            'Nothing at all',
          ],
          correct: 0,
          explanation:
              'Card count and claimed rank are public. The faces stay hidden unless your play is challenged.',
        ),
      ],
    ),
    Lesson(
      id: 'bluff.open',
      title: 'Opening a round',
      summary: 'Two to four cards and a declared rank.',
      icon: Icons.play_circle_outline,
      build: (rng) => [
        const ExplainStep(
          title: 'Declare a rank',
          body:
              'When the pile is empty, the player to move opens a new round: put 2 to 4 cards face down and declare a rank — anything from 2 to Yakka. That rank holds for the whole round.',
          scene: [
            SceneZone('New pile', [
              SceneCard.back(),
              SceneCard.back(),
              SceneCard.back(caption: '"Three 8s"'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'Truth is optional',
          body:
              'You may declare a rank you do not even hold. Opening with your pair of 8s and declaring 8 is honest; slipping in a stray card is a bluff. Nobody knows which — yet.',
        ),
        bluffOpenDrill(rng),
        const QuizStep(
          question:
              'The pile is empty, it is your turn, and you hold just one card. What do you do?',
          options: [
            'Pass — a new round needs at least 2 cards',
            'Play it and declare any rank',
            'Challenge the last player',
          ],
          correct: 0,
          explanation:
              'Openings need 2+ cards. Pass and let someone else open; then you can finish by adding your last card to their round.',
        ),
      ],
    ),
    Lesson(
      id: 'bluff.turn',
      title: 'Play, pass or challenge',
      summary: 'Your three options mid-round.',
      icon: Icons.alt_route,
      build: (rng) => [
        const ExplainStep(
          title: 'Three choices',
          body: 'Once a round has started, on your turn you choose one move:',
          bullets: [
            'Play 1–4 cards face down, claiming they are the declared rank',
            'Pass — play nothing this turn',
            'Challenge the most recent play',
          ],
          scene: [
            SceneZone('Pile · round of Kingas', [
              SceneCard.back(caption: 'Omar: 2'),
              SceneCard.back(caption: 'Hina: 1'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'The rank is locked',
          body:
              'Every play in a round claims the same rank as the opening. You cannot switch ranks mid-round. If you hold none of that rank, you can bluff with other cards, pass, or challenge.',
        ),
        const QuizStep(
          question:
              'The round is Kingas and you hold no Kingas. What may you do?',
          options: [
            'Play 1–4 cards anyway, pass, or challenge',
            'Only pass',
            'Declare a new rank',
          ],
          correct: 0,
          explanation:
              'All three moves are open to you. Playing other cards as "Kingas" is a bluff — legal, but risky.',
        ),
        bluffHonestDrill(rng),
        bluffHonestDrill(rng),
      ],
    ),
    Lesson(
      id: 'bluff.challenge',
      title: 'Calling a bluff',
      summary: 'Who picks up when the cards flip.',
      icon: Icons.gavel,
      build: (rng) => [
        const ExplainStep(
          title: 'Only the last play',
          body:
              'On your turn you may challenge the most recent play — even if other players passed since. Only that last play is flipped over; the rest of the pile stays hidden.',
        ),
        const ExplainStep(
          title: 'Caught lying',
          body:
              'If even one revealed card is not the declared rank, the liar picks up the ENTIRE pile. The challenger starts the next round. Challenger +10 points, liar −5.',
          scene: [
            SceneZone('Hina\'s "two Begis", revealed', [
              SceneCard('c-b'),
              SceneCard('h-4', glow: true, caption: 'not a Begi!'),
            ]),
          ],
        ),
        const ExplainStep(
          title: 'Wrong call',
          body:
              'If every revealed card matches, the challenger was wrong and picks up the entire pile. The honest player starts the next round. Honest player +10, challenger −5.',
          scene: [
            SceneZone('Hina\'s "two Begis", revealed', [
              SceneCard('c-b'),
              SceneCard('e-b'),
            ]),
          ],
        ),
        const QuizStep(
          question: 'Can you challenge your own play?',
          options: ['No — only someone else\'s play', 'Yes, any time'],
          correct: 0,
          shuffle: false,
          explanation: 'You can only challenge a play made by another player.',
        ),
        bluffOutcomeDrill(rng),
        bluffOutcomeDrill(rng),
      ],
    ),
    Lesson(
      id: 'bluff.pass',
      title: 'When everyone passes',
      summary: 'The pile vanishes and a new round begins.',
      icon: Icons.do_not_disturb_on_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Nobody wants it',
          body:
              'If every other player passes in a row after a play, the whole pile is discarded — out of the game for good. The player who made the last play opens the next round.',
          scene: [
            SceneZone('Round of 5s', [
              SceneCard.back(caption: 'Ali played 2'),
            ], note: 'Sana passes · Bilal passes · You pass'),
          ],
        ),
        QuizStep(
          question:
              'Ali played 2 cards. Then Sana, Bilal and you all passed. What happens?',
          options: [
            'The pile leaves the game; Ali opens a new round',
            'Ali picks up the pile',
            'The next player must challenge',
          ],
          correct: 0,
          explanation:
              'All passes: the pile is discarded and the last player who played, Ali, opens the next round.',
        ),
        ExplainStep(
          title: 'The perfect crime',
          body:
              'A bluff that everybody passes on disappears forever — nobody ever sees it. That is the dream outcome for a liar.',
        ),
      ],
    ),
    Lesson(
      id: 'bluff.endgame',
      title: 'Going out',
      summary: 'Your last cards can still be challenged.',
      icon: Icons.sports_score,
      build: (rng) => const [
        ExplainStep(
          title: 'A provisional finish',
          body:
              'When you play your last cards you are provisionally out. The next player can still challenge that final play. If they play or pass instead, your finish is confirmed and you take your place.',
        ),
        ExplainStep(
          title: 'Caught on the way out',
          body:
              'If that challenge catches a bluff, you pick up the whole pile and you are back in the game. Honest last cards cannot be punished.',
        ),
        QuizStep(
          question:
              'You play your last two cards, claiming two 9s. Are you out?',
          options: [
            'Not yet — the next player may still challenge',
            'Yes, immediately',
          ],
          correct: 0,
          shuffle: false,
          explanation:
              'You are confirmed only once the next player plays or passes instead of challenging.',
        ),
        QuizStep(
          question:
              'You hold one card. Someone opens a round of 5s with two cards. Can you play your last card?',
          options: [
            'Yes — plays mid-round need only 1 card',
            'No — every play needs 2 cards',
          ],
          correct: 0,
          shuffle: false,
          explanation:
              'Only openings need 2+ cards. Joining a running round takes 1 to 4.',
        ),
        ExplainStep(
          title: 'Stuck with one card each',
          body:
              'If the pile is empty and every remaining player holds exactly one card, nobody can open a round. The game ends right there and those players take the last places.',
        ),
      ],
    ),
    Lesson(
      id: 'bluff.reading',
      title: 'Count the copies',
      summary: 'Catch impossible claims with simple maths.',
      icon: Icons.calculate_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Only four of each',
          body:
              'Every rank has exactly four cards. If you hold two Begis, nobody else can play more than two. A claim bigger than what is left is a guaranteed lie.',
          scene: [
            SceneZone('Your hand', [
              SceneCard('c-b', glow: true),
              SceneCard('p-b', glow: true),
              SceneCard('h-6'),
              SceneCard('e-10'),
            ]),
            SceneZone('Omar claims three Begis', [
              SceneCard.back(),
              SceneCard.back(),
              SceneCard.back(),
            ], note: 'Only two Begis are left. Impossible!'),
          ],
        ),
        bluffPossibleDrill(rng),
        bluffPossibleDrill(rng),
        bluffPossibleDrill(rng),
        const ExplainStep(
          title: 'Other warning signs',
          body: 'Even a possible claim can smell fishy:',
          bullets: [
            'Claims of 3 or 4 cards are hard to make honestly',
            'A player playing out their last cards has every reason to lie',
            'Cards you saw revealed or discarded are not in anyone\'s hand',
          ],
        ),
      ],
    ),
    Lesson(
      id: 'bluff.strategy',
      title: 'Strategy',
      summary: 'When to lie, when to call.',
      icon: Icons.psychology_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Bluff smart',
          body: 'Good Bluff players pick their moments:',
          bullets: [
            'Tell the truth when you can — an honest play cannot be punished',
            'Bluff when the pile is small: getting caught costs less',
            'Hide one fake card among real ones',
            'Open with a rank you hold, so later honest plays are easy',
            'Challenge big claims when you hold copies of that rank',
          ],
        ),
        QuizStep(
          question:
              'The pile has 18 cards. Hina claims one Kinga and you hold one Kinga. Challenge?',
          options: [
            'Probably not — the claim is easy and a wrong call costs 18 cards',
            'Always challenge when the pile is big',
          ],
          correct: 0,
          shuffle: false,
          explanation:
              'Three Kingas are still out there, so one is very believable. A wrong challenge would hand you all 18 cards.',
        ),
        QuizStep(
          question: 'When is a bluff cheapest if it gets caught?',
          options: ['When the pile is small', 'When the pile is huge'],
          correct: 0,
          shuffle: false,
          explanation:
              'A caught liar takes the whole pile, so small piles mean small damage.',
        ),
      ],
    ),
    Lesson(
      id: 'bluff.guided',
      title: 'Guided hand',
      summary: 'Open, catch a liar and bluff your way out.',
      icon: Icons.play_circle_outline,
      guided: true,
      build: (rng) => [
        const ExplainStep(
          title: 'Your seat at the table',
          body:
              'Three players: you, then Ali, then Hina. You hold the Hukam Yakka, so you open the first round. Notice your three 7s.',
          scene: [
            SceneZone('Your hand', [
              SceneCard('h-y', glow: true),
              SceneCard('c-7'),
              SceneCard('e-7'),
              SceneCard('p-7'),
              SceneCard('p-b'),
              SceneCard('h-3'),
              SceneCard('c-10'),
            ]),
          ],
        ),
        TapStep.exact(
          title: 'Round 1 · open honestly',
          prompt:
              'Open with your Chirri 7 and Eit 7. Keep the Pawn 7 as your secret.',
          hand: const ['h-y', 'c-7', 'e-7', 'p-7', 'p-b', 'h-3', 'c-10'],
          answer: const {'c-7', 'e-7'},
          explanation:
              'Two cards face down, declared as 7s. Now you know where three of the four 7s are.',
          feedback: (_) =>
              'For this walkthrough, select the Chirri 7 and the Eit 7.',
        ),
        const ExplainStep(
          title: 'The claims pile up',
          body:
              'Ali plays one card, claiming one 7. Hina plays two cards, claiming two 7s.',
          scene: [
            SceneZone('Pile · round of 7s', [
              SceneCard.back(caption: 'You: 2'),
              SceneCard.back(caption: 'Ali: 1'),
              SceneCard.back(caption: 'Hina: 2'),
            ]),
          ],
        ),
        const QuizStep(
          title: 'Your turn',
          question:
              'You put two 7s in the pile and still hold the third. How many 7s could Hina really have?',
          options: ['At most one — challenge!', 'Two — it is possible'],
          correct: 0,
          shuffle: false,
          explanation:
              'Four 7s exist: two in the pile from you, one in your hand. Only one is unaccounted for, so Hina cannot have two. Challenge!',
        ),
        const ExplainStep(
          title: 'Caught!',
          body:
              'Hina\'s play is flipped: a 7 and a Chirri Kinga. Hina picks up all five pile cards and you open the next round (+10 for you). Ali\'s card was never revealed — only the last play is checked — so Ali\'s fake 7 slipped away into Hina\'s hand.',
          scene: [
            SceneZone('Hina\'s play, revealed', [
              SceneCard('h-7'),
              SceneCard('c-k', glow: true, caption: 'not a 7!'),
            ]),
          ],
        ),
        TapStep(
          title: 'Round 2 · a small bluff',
          prompt:
              'Open a new round with a small bluff: select your Pawn Begi plus any one other card. You will declare Begi.',
          hand: const ['h-y', 'p-7', 'p-b', 'h-3', 'c-10'],
          minPick: 2,
          maxPick: 2,
          accepts: (p) => p.length == 2 && p.contains('p-b'),
          solution: const {'p-b', 'h-3'},
          explanation:
              'Two cards down, declared as Begis: one real, one fake. The pile is tiny, so getting caught would cost little.',
          feedback: (_) => 'Include the Pawn Begi, plus one other card.',
        ),
        const ExplainStep(
          title: 'Everyone passes',
          body:
              'Ali passes. Hina passes. Nobody challenged, so the pile is discarded for good — fake card included — and you open the next round. The perfect crime.',
        ),
        TapStep.exact(
          title: 'Round 3 · join honestly',
          prompt:
              'Fast-forward: Ali opens a round of Yakkas with two cards and Hina passes. Play your honest Yakka.',
          scene: const [
            SceneZone('Pile · round of Yakkas', [
              SceneCard.back(caption: 'Ali: 2'),
            ]),
          ],
          hand: const ['h-y', 'p-7'],
          answer: const {'h-y'},
          explanation:
              'An honest card can never be punished. You are down to your last card.',
          feedback: (_) =>
              'Play the real Yakka — it is the one card nobody can catch.',
        ),
        const QuizStep(
          title: 'Your last card',
          question:
              'Next round Hina opens 9s. You play your last card, the Pawn 7, as a 9. Are you out?',
          options: [
            'Not yet — Ali can still challenge',
            'Yes, the moment my hand is empty',
          ],
          correct: 0,
          shuffle: false,
          explanation:
              'Your finish is provisional. If Ali challenges, your 7 is revealed, you take the pile and you are back in. If Ali plays or passes — you are out!',
        ),
        const ExplainStep(
          title: 'Well played!',
          body: 'You just used every key idea in Bluff:',
          bullets: [
            'Opened honestly with 2 cards and a declared rank',
            'Counted copies to catch an impossible claim',
            'Bluffed on a small pile and watched it vanish',
            'Joined a round honestly with a single card',
            'Learned that going out can still be challenged',
          ],
        ),
      ],
    ),
  ],
);
