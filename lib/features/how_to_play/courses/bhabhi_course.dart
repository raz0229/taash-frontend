import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../learn_drills.dart';
import '../learn_model.dart';
import '../learn_rules.dart';

String? _mustFollow(Set<String> picked, String suit) =>
    picked.any((c) => Rules.suit(c) != suit)
    ? 'You still hold ${Rules.suitName(suit)}, so you must follow suit.'
    : null;

final bhabhiCourse = Course(
  game: GameType.bhabhi,
  players: '2–7 players',
  goal:
      'Empty your hand before everyone else. The last player holding cards is the Bhabhi.',
  drills: bhabhiDrills,
  cheatSheet: const [
    (
      'Deal',
      'All 52 cards are dealt out. The Hukam Yakka holder leads first, with any card.',
    ),
    ('Follow suit', 'If you hold the lead suit you must play it.'),
    (
      'Clean trick',
      'Everyone followed: the cards leave the game. Highest lead-suit card leads next.',
    ),
    (
      'Thullu',
      'Can\'t follow (after the opening trick)? The trick stops and the highest lead-suit card picks up every card on it.',
    ),
    (
      'Opening trick',
      'No Thullu on the very first trick, even if someone can\'t follow.',
    ),
    ('Final trick', 'The LOWEST lead-suit card wins the best remaining place.'),
    ('Points', 'Thullu giver +10, the player who picks up −5.'),
    (
      'Prizes',
      'Everyone except the Bhabhi shares the pot; earlier finishers win more.',
    ),
  ],
  lessons: [
    Lesson(
      id: 'bhabhi.goal',
      title: 'Don\'t be the Bhabhi',
      summary: 'The goal, the deal and who wins coins.',
      icon: Icons.flag_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Race to an empty hand',
          body:
              'Bhabhi is a shedding game. All 52 cards are dealt out evenly, so everyone starts with a big hand. Get rid of all your cards to escape. The last player still holding cards is the Bhabhi — and loses.',
          bullets: [
            '2 to 7 players',
            'Every card is dealt; there is no stock',
            'Players finish one by one and take places in order',
          ],
          scene: [
            SceneZone(
              'A starting hand',
              [
                SceneCard('h-y'),
                SceneCard('h-6'),
                SceneCard('e-k'),
                SceneCard('e-3'),
                SceneCard('p-9'),
                SceneCard('c-b'),
                SceneCard('c-4'),
              ],
              note: 'Real hands are bigger: 52 cards ÷ the number of players.',
            ),
          ],
        ),
        ExplainStep(
          title: 'Coins for everyone but one',
          body:
              'Everyone pays the entry fee into the pot. At the end, every player except the Bhabhi wins coins. The earlier you finish, the bigger your share.',
          tip:
              '1st place earns twice what 2nd earns, and three times what 3rd earns.',
        ),
        QuizStep(
          question: 'Who loses a game of Bhabhi?',
          options: [
            'The last player still holding cards',
            'The player who picked up the most cards',
            'The player who played the highest card',
          ],
          correct: 0,
          explanation:
              'Only the last player holding cards is the Bhabhi. Picking up cards hurts because it makes you slower to finish, but it does not lose the game by itself.',
        ),
        QuizStep(
          question: 'Five players are in a game. How many of them win coins?',
          options: [
            'Four — everyone except the Bhabhi',
            'Only the first to finish',
            'All five',
          ],
          correct: 0,
          explanation: 'Every place except the last shares the pot.',
        ),
      ],
    ),
    Lesson(
      id: 'bhabhi.tricks',
      title: 'Tricks & the first lead',
      summary: 'How a trick works and who starts.',
      icon: Icons.layers_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'Playing in tricks',
          body:
              'Bhabhi is played in tricks. One player leads a card, then each other player plays one card in turn. The suit of the first card is the lead suit.',
          scene: [
            SceneZone('A trick of Eit', [
              SceneCard('e-6', caption: 'Sana leads'),
              SceneCard('e-10', caption: 'Bilal'),
              SceneCard('e-2', caption: 'Zara'),
              SceneCard('e-b', caption: 'You'),
            ]),
          ],
        ),
        ExplainStep(
          title: 'Who leads first?',
          body:
              'Whoever was dealt the Hukam Yakka leads the very first trick. They may open with ANY card in their hand — it does not have to be the Yakka.',
          scene: [
            SceneZone('Your hand', [
              SceneCard('h-y', glow: true, caption: 'You start!'),
              SceneCard('c-4'),
              SceneCard('e-9'),
              SceneCard('p-k'),
            ]),
          ],
        ),
        QuizStep(
          question: 'You were dealt the Hukam Yakka. Which cards may you lead?',
          options: [
            'Any card in my hand',
            'Only the Hukam Yakka',
            'Only a Hukam card',
          ],
          correct: 0,
          explanation:
              'Holding the Hukam Yakka decides WHO starts, not WHAT is played. Open with any card.',
        ),
        ExplainStep(
          title: 'Who leads next?',
          body:
              'The highest card of the lead suit leads the next trick. Only the lead suit counts: a big card of another suit can never take control.',
          scene: [
            SceneZone('Trick', [
              SceneCard('e-6', caption: 'Sana'),
              SceneCard('e-10', caption: 'Bilal'),
              SceneCard('e-2', caption: 'Zara'),
              SceneCard('e-b', caption: 'You', glow: true),
            ], note: 'Your Begi is the highest Eit, so you lead next.'),
          ],
        ),
        QuizStep(
          question: 'Who leads the next trick?',
          scene: [
            SceneZone('Trick', [
              SceneCard('p-7', caption: 'Omar'),
              SceneCard('p-k', caption: 'Hina'),
              SceneCard('p-2', caption: 'Ali'),
              SceneCard('p-9', caption: 'You'),
            ]),
          ],
          options: ['Hina', 'Omar', 'Ali', 'You'],
          correct: 0,
          explanation: 'Hina\'s Kinga is the highest Pawn on the trick.',
        ),
      ],
    ),
    Lesson(
      id: 'bhabhi.follow',
      title: 'Follow the lead suit',
      summary: 'The one rule you must never break.',
      icon: Icons.rule,
      build: (rng) => [
        const ExplainStep(
          title: 'The golden rule',
          body:
              'If you hold any card of the lead suit, you must play one of them — you choose which. Only when you have none of that suit may you play something else.',
          scene: [
            SceneZone('Trick', [SceneCard('e-8', caption: 'Sana')]),
            SceneZone('Your hand', [
              SceneCard('h-3', dim: true),
              SceneCard('e-4', glow: true),
              SceneCard('e-g', glow: true),
              SceneCard('p-10', dim: true),
            ], note: 'Only your Eit cards may be played.'),
          ],
          tip:
              'In a live game, cards you cannot play look faded, and the server rejects illegal moves.',
        ),
        TapStep.exact(
          prompt:
              'Sana leads the Chirri 9. Tap every card you may play, then check.',
          scene: const [
            SceneZone('Trick', [SceneCard('c-9', caption: 'Sana')]),
          ],
          hand: const ['h-3', 'c-2', 'c-k', 'e-7', 'p-10'],
          answer: const {'c-2', 'c-k'},
          explanation:
              'You hold two Chirri cards, so you must play one of them. Hukam, Eit and Pawn are locked for this trick.',
          feedback: (p) =>
              _mustFollow(p, 'c') ?? 'Both of your Chirri cards are playable.',
        ),
        TapStep.exact(
          prompt: 'Bilal leads the Pawn 5. Tap every card you may play.',
          scene: const [
            SceneZone('Trick', [SceneCard('p-5', caption: 'Bilal')]),
          ],
          hand: const ['h-k', 'h-4', 'e-b', 'c-6'],
          answer: const {'h-k', 'h-4', 'e-b', 'c-6'},
          explanation:
              'You have no Pawn at all, so any card is allowed. Playing off-suit like this is called giving a Thullu — next lesson!',
          feedback: (_) =>
              'You hold no Pawn, so nothing is locked. Select every card.',
        ),
        bhabhiLegalDrill(rng),
        bhabhiLegalDrill(rng),
      ],
    ),
    Lesson(
      id: 'bhabhi.clean',
      title: 'Clean tricks',
      summary: 'When everyone follows, the cards vanish.',
      icon: Icons.cleaning_services_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Gone for good',
          body:
              'When every player follows the lead suit, the trick is clean. Its cards are thrown out of the game — nobody picks them up. That is good news: those cards are gone from everyone\'s hand for good.',
          scene: [
            SceneZone('Clean trick', [
              SceneCard('h-5', caption: 'Zara'),
              SceneCard('h-9', caption: 'Omar'),
              SceneCard('h-k', caption: 'You', glow: true),
              SceneCard('h-2', caption: 'Hina'),
            ], note: 'All four cards leave the game. You lead next.'),
          ],
        ),
        const QuizStep(
          question: 'A clean trick ends. Where do its cards go?',
          options: [
            'Out of the game',
            'Into the hand of the highest card',
            'Back into the deck',
          ],
          correct: 0,
          explanation:
              'Clean tricks are discarded. Cards are only picked up when someone gives a Thullu.',
        ),
        const ExplainStep(
          title: 'Shed under the leader',
          body:
              'When someone has already played a high card of the lead suit, you can slip a big card of your own underneath it. You get rid of a dangerous card while they stay in front.',
        ),
        TapStep.exact(
          prompt:
              'Zara led the Eit Kinga and Omar played the Eit 4. Which card is smartest to play?',
          scene: const [
            SceneZone('Trick', [
              SceneCard('e-k', caption: 'Zara'),
              SceneCard('e-4', caption: 'Omar'),
            ]),
          ],
          hand: const ['e-b', 'e-3', 'h-9', 'c-5'],
          answer: const {'e-b'},
          explanation:
              'Your Begi slips under Zara\'s Kinga, so Zara stays highest. You shed a big card for free and keep the little 3 as a shield for later.',
          feedback: (p) =>
              _mustFollow(p, 'e') ??
              'Safe, but wasteful: the Kinga covers you right now, so this is a free chance to drop your bigger Eit.',
        ),
        bhabhiTrickDrill(rng),
      ],
    ),
    Lesson(
      id: 'bhabhi.thullu',
      title: 'Thullu!',
      summary: 'Break suit and someone picks up the pile.',
      icon: Icons.bolt,
      build: (rng) => [
        const ExplainStep(
          title: 'What is a Thullu?',
          body:
              'After the opening trick, a player with no card of the lead suit plays any other card. That is a Thullu. The trick stops immediately — anyone who has not played yet does not play.',
          scene: [
            SceneZone('Trick', [
              SceneCard('p-6', caption: 'Sana'),
              SceneCard('p-b', caption: 'Bilal'),
              SceneCard('h-2', caption: 'You', glow: true),
            ], note: 'You have no Pawn → Thullu! Zara never plays.'),
          ],
        ),
        const ExplainStep(
          title: 'Who picks up?',
          body:
              'The player holding the highest lead-suit card at that moment picks up EVERY card on the trick — including the Thullu card — into their hand. Then they lead the next trick.',
          scene: [
            SceneZone('Trick', [
              SceneCard('p-6', caption: 'Sana'),
              SceneCard('p-b', caption: 'Bilal', glow: true),
              SceneCard('h-2', caption: 'You'),
            ], note: 'Bilal\'s Begi is the highest Pawn → Bilal takes all 3.'),
          ],
          tip:
              'In-game points: the Thullu giver earns +10, the player who picks up loses 5.',
        ),
        const QuizStep(
          question: 'Ali cannot follow and plays the Eit Yakka. Who picks up?',
          scene: [
            SceneZone('Trick', [
              SceneCard('c-4', caption: 'Omar'),
              SceneCard('c-10', caption: 'Hina'),
              SceneCard('e-y', caption: 'Ali'),
            ]),
          ],
          options: ['Hina', 'Ali', 'Omar'],
          correct: 0,
          hint: 'Only the lead suit counts. What suit was led?',
          explanation:
              'The Yakka is the biggest card on the table — but it is Eit, not Chirri. Only Chirri counts, so Hina\'s 10 picks up all three cards.',
        ),
        const QuizStep(
          question: 'After a Thullu, who leads the next trick?',
          options: [
            'The player who picked up',
            'The player who gave the Thullu',
            'The next player in seat order',
          ],
          correct: 0,
          explanation:
              'The player who picked up the pile leads next, with a bigger hand to play from.',
        ),
        bhabhiTrickDrill(rng),
        bhabhiTrickDrill(rng),
      ],
    ),
    Lesson(
      id: 'bhabhi.opening',
      title: 'The safe opening trick',
      summary: 'Why the first trick never hurts.',
      icon: Icons.shield_outlined,
      build: (rng) => const [
        ExplainStep(
          title: 'No Thullu on trick one',
          body:
              'The very first trick of the game is special. If someone cannot follow suit they still play any card — but there is no Thullu. Every player plays, all the cards leave the game, and the highest lead-suit card leads next.',
          scene: [
            SceneZone('Opening trick', [
              SceneCard('e-5', caption: 'You'),
              SceneCard('e-k', caption: 'Sana', glow: true),
              SceneCard('c-9', caption: 'Bilal'),
              SceneCard('e-2', caption: 'Zara'),
            ], note: 'Bilal had no Eit, but nobody picks up.'),
          ],
        ),
        QuizStep(
          question: 'What happens to this opening trick?',
          scene: [
            SceneZone('Opening trick', [
              SceneCard('e-5', caption: 'You'),
              SceneCard('e-k', caption: 'Sana'),
              SceneCard('c-9', caption: 'Bilal'),
              SceneCard('e-2', caption: 'Zara'),
            ]),
          ],
          options: [
            'All cards leave the game; Sana leads next',
            'Sana picks up all four cards',
            'Bilal picks up all four cards',
          ],
          correct: 0,
          explanation:
              'Opening trick: no Thullu. The cards are discarded and Sana\'s Kinga (highest Eit) leads next.',
        ),
        ExplainStep(
          title: 'It still reveals a secret',
          body:
              'Everybody saw Bilal fail to follow Eit, so now everybody knows Bilal holds no Eit at all. From now on, whenever Eit is led, Bilal can give a Thullu. Remember who is out of which suit!',
        ),
        QuizStep(
          question:
              'Why can leading a high card on the opening trick be smart?',
          options: [
            'It sheds a dangerous card with zero Thullu risk',
            'High cards score bonus points',
            'It forces everyone to play Hukam',
          ],
          correct: 0,
          explanation:
              'High cards are what get you stuck picking up later. Trick one is the one trick where they can never cost you.',
        ),
      ],
    ),
    Lesson(
      id: 'bhabhi.finish',
      title: 'Finishing & the final trick',
      summary: 'Getting out, and the trick where low wins.',
      icon: Icons.sports_score,
      build: (rng) => [
        const ExplainStep(
          title: 'Getting out',
          body:
              'When your hand is empty after a trick finishes, you are out and take the next finishing place. If several players empty their hands on the same trick, whoever played earlier in that trick gets the better place.',
        ),
        const ExplainStep(
          title: 'Not safe yet!',
          body:
              'Playing your last card does not make you safe until the trick is over. If your last card is the highest of the lead suit and someone gives a Thullu, you pick up the pile — and you are back in the game.',
          scene: [
            SceneZone('Trick', [
              SceneCard('p-k', caption: 'You (last card)', glow: true),
              SceneCard('p-3', caption: 'Sana'),
              SceneCard('h-7', caption: 'Bilal'),
            ], note: 'Bilal breaks suit: you pick up 3 cards.'),
          ],
        ),
        const ExplainStep(
          title: 'The final trick flips',
          body:
              'When a trick will leave at most one player holding cards, it is the final trick — and the rule flips. The LOWEST card of the lead suit wins and claims the best remaining place. Others who emptied their hands follow in play order, and anyone still holding cards comes last.',
          scene: [
            SceneZone('Final trick', [
              SceneCard('c-9', caption: 'Sana'),
              SceneCard('c-3', caption: 'You', glow: true),
              SceneCard('c-6', caption: 'Bilal'),
            ], note: 'Lowest Chirri wins: your 3 takes the best place.'),
          ],
          tip:
              'A Thullu still works on the final trick: if someone cannot follow, the highest card picks up as usual.',
        ),
        const QuizStep(
          question:
              'This is the final trick. Who wins the best remaining place?',
          scene: [
            SceneZone('Final trick', [
              SceneCard('h-8', caption: 'Omar'),
              SceneCard('h-b', caption: 'Hina'),
              SceneCard('h-4', caption: 'Ali'),
            ]),
          ],
          options: ['Ali', 'Hina', 'Omar'],
          correct: 0,
          explanation:
              'Final trick: lowest wins. Ali\'s 4 is the lowest Hukam.',
        ),
        bhabhiLastTrickDrill(rng),
        const QuizStep(
          question:
              'You play your last card and it is the highest Pawn. The next player cannot follow. What happens?',
          options: [
            'You pick up the trick and you are back in',
            'You are out — your hand was empty',
            'The trick is cancelled',
          ],
          correct: 0,
          explanation:
              'You are only out once the trick resolves with your hand empty. The Thullu hands you the pile first.',
        ),
      ],
    ),
    Lesson(
      id: 'bhabhi.strategy',
      title: 'Strategy: dodge & trap',
      summary: 'Shed high cards, read voids, set traps.',
      icon: Icons.psychology_outlined,
      build: (rng) => [
        const ExplainStep(
          title: 'Shed high, keep low',
          body:
              'High cards are dangerous: they make you the highest card when a Thullu lands. Low cards are shields: they let you duck under everyone else.',
          bullets: [
            'Dump big cards on the opening trick',
            'Slip big cards under someone else\'s higher card',
            'When you give a Thullu, throw your biggest card',
            'Last to play on a trick where everyone followed? It is guaranteed clean — drop anything',
          ],
        ),
        const ExplainStep(
          title: 'Voids are public',
          body:
              'Every time a player fails to follow a suit, the whole table sees it. That player is void in that suit and will give a Thullu whenever it is led — so think about where they sit before you lead.',
        ),
        TapStep(
          title: 'Danger next door',
          prompt:
              'Bilal plays right after you and has no Hukam. Pick a safe card to lead.',
          scene: const [
            SceneZone(
              'Known voids',
              [],
              note: 'Bilal (next after you): no Hukam',
            ),
          ],
          hand: const ['h-2', 'h-10', 'c-k', 'c-4', 'e-6'],
          accepts: (p) => p.length == 1 && {'c-4', 'e-6'}.contains(p.first),
          solution: const {'c-4'},
          explanation:
              'If you lead Hukam, Bilal gives a Thullu straight away and your card is the only Hukam on the trick — you would pick up. A low card of another suit keeps you safe.',
          feedback: (p) => Rules.suit(p.first) == 'h'
              ? 'Careful! Bilal has no Hukam and plays right after you. Your card would be the only Hukam, so you would pick up.'
              : 'Not Hukam — good. But leading a Kinga makes you the likely highest card if anyone breaks suit. Lead low.',
        ),
        const ExplainStep(
          title: 'Set a trap',
          body:
              'If the void player sits further away, flip it around: lead a LOW card of their empty suit. The players between you must follow, one of them will probably beat your card — and when the void player breaks suit, THEY pick up instead of you.',
        ),
        TapStep(
          title: 'Spring the trap',
          prompt:
              'Zara has no Eit and plays two seats after you; Sana plays in between. Spring the trap.',
          scene: const [
            SceneZone(
              'Known voids',
              [],
              note: 'Zara (two seats after you): no Eit',
            ),
          ],
          hand: const ['e-2', 'e-k', 'p-9', 'c-7'],
          accepts: (p) => p.length == 1 && p.first == 'e-2',
          solution: const {'e-2'},
          explanation:
              'Lead the Eit 2. Sana must follow with an Eit — almost certainly higher — then Zara breaks suit, and Sana picks up the pile.',
          feedback: (p) => p.first == 'e-k'
              ? 'Leading the Kinga makes YOU the likely highest when Zara strikes. Lead your lowest Eit instead.'
              : 'Use Zara\'s void: lead Eit, but low.',
        ),
        bhabhiDumpDrill(rng),
        const QuizStep(
          question:
              'When you give a Thullu, which card should you usually throw?',
          options: [
            'My highest, most dangerous card',
            'My lowest card',
            'It never matters',
          ],
          correct: 0,
          explanation:
              'Your Thullu card goes to someone else\'s hand, so make it the card you least want to keep: a big one.',
        ),
      ],
    ),
    Lesson(
      id: 'bhabhi.guided',
      title: 'Guided hand',
      summary: 'Play a short game move by move.',
      icon: Icons.play_circle_outline,
      guided: true,
      build: (rng) => [
        const ExplainStep(
          title: 'Your seat at the table',
          body:
              'Four players: you, then Sana, Bilal and Zara in turn order. We have shortened the hands so you can see a whole game flow. You hold the Hukam Yakka, so you lead the first trick.',
          scene: [
            SceneZone('Your hand', [
              SceneCard('h-y', glow: true),
              SceneCard('h-4'),
              SceneCard('e-k'),
              SceneCard('e-3'),
              SceneCard('p-9'),
              SceneCard('p-2'),
              SceneCard('c-6'),
            ]),
          ],
        ),
        TapStep.exact(
          title: 'Trick 1 · the opening',
          prompt:
              'No Thullu can happen on the opening trick. Lead your Eit Kinga — big cards are risky later, so this is a free chance to drop one.',
          hand: const ['h-y', 'h-4', 'e-k', 'e-3', 'p-9', 'p-2', 'c-6'],
          answer: const {'e-k'},
          explanation: 'You lead the Eit Kinga. Now watch the others.',
          feedback: (_) =>
              'For this walkthrough, lead the Eit Kinga: the opening trick is the safest moment to shed a big card.',
        ),
        const ExplainStep(
          title: 'Bilal cannot follow',
          body:
              'Bilal threw a Pawn, so Bilal holds no Eit. On the opening trick that is fine — no Thullu. All four cards leave the game, and your Kinga was the highest Eit, so you lead again.',
          scene: [
            SceneZone('Opening trick', [
              SceneCard('e-k', caption: 'You', glow: true),
              SceneCard('e-5', caption: 'Sana'),
              SceneCard('p-7', caption: 'Bilal'),
              SceneCard('e-9', caption: 'Zara'),
            ]),
          ],
          tip: 'Remember: Bilal has no Eit.',
        ),
        TapStep.exact(
          title: 'Trick 2 · set the trap',
          prompt:
              'Bilal (two seats after you) has no Eit, and Sana plays in between. Which card springs the trap?',
          hand: const ['h-y', 'h-4', 'e-3', 'p-9', 'p-2', 'c-6'],
          answer: const {'e-3'},
          explanation:
              'You lead the Eit 3. Sana must follow Eit, and almost any Eit beats your 3.',
          feedback: (_) =>
              'Lead your Eit 3: Sana must follow Eit, then Bilal will break suit — and Sana, not you, will hold the highest Eit.',
        ),
        const ExplainStep(
          title: 'Thullu!',
          body:
              'Bilal cannot follow and throws the Chirri Yakka. The trick stops — Zara does not play. Sana\'s 10 is the highest Eit, so Sana picks up all three cards and leads next. Bilal earns 10 points and Sana loses 5. Your trap worked.',
          scene: [
            SceneZone('Trick 2', [
              SceneCard('e-3', caption: 'You'),
              SceneCard('e-10', caption: 'Sana', glow: true),
              SceneCard('c-y', caption: 'Bilal'),
            ], note: 'Sana picks up 3 cards.'),
          ],
        ),
        TapStep.exact(
          title: 'Trick 3 · duck under',
          prompt:
              'Sana leads the Pawn Kinga; Bilal and Zara follow. You play last. Which Pawn?',
          scene: const [
            SceneZone('Trick 3', [
              SceneCard('p-k', caption: 'Sana'),
              SceneCard('p-3', caption: 'Bilal'),
              SceneCard('p-6', caption: 'Zara'),
            ]),
          ],
          hand: const ['h-y', 'h-4', 'p-9', 'p-2', 'c-6'],
          answer: const {'p-9'},
          explanation:
              'The Kinga covers you, so you drop the bigger Pawn and keep the 2 as a shield. Everyone followed: a clean trick, and Sana leads again.',
          feedback: (p) =>
              _mustFollow(p, 'p') ??
              'Safe, but the Kinga already covers you — this is a free chance to drop the bigger 9.',
        ),
        TapStep.exact(
          title: 'Trick 4 · last to play',
          prompt:
              'Sana leads Hukam and everyone follows. You are last to play, so this trick is guaranteed clean. Which card?',
          scene: const [
            SceneZone('Trick 4', [
              SceneCard('h-8', caption: 'Sana'),
              SceneCard('h-b', caption: 'Bilal'),
              SceneCard('h-5', caption: 'Zara'),
            ]),
          ],
          hand: const ['h-y', 'h-4', 'p-2', 'c-6'],
          answer: const {'h-y'},
          explanation:
              'Nobody can break suit after you, so there is zero risk. Out goes your Yakka — the most dangerous card you held. You lead next with just the Hukam 4, Pawn 2 and Chirri 6.',
          feedback: (p) =>
              _mustFollow(p, 'h') ??
              'Safe, but wasteful: everyone has followed and you are last, so the trick is guaranteed clean. Perfect moment to dump your Yakka.',
        ),
        const QuizStep(
          title: 'The final trick',
          question:
              'Fast-forward: Sana and Zara are out. Bilal leads the Chirri 8 and you play your last card, the Chirri 6. Who becomes the Bhabhi?',
          scene: [
            SceneZone('Final trick', [
              SceneCard('c-8', caption: 'Bilal'),
              SceneCard('c-6', caption: 'You'),
            ]),
          ],
          options: ['Bilal', 'You', 'Nobody'],
          correct: 0,
          explanation:
              'On the final trick the lowest card wins. Your 6 undercuts Bilal\'s 8, so you take 3rd place and Bilal finishes last — Bilal is the Bhabhi!',
        ),
        const ExplainStep(
          title: 'Well played!',
          body: 'You just used every key idea in Bhabhi:',
          bullets: [
            'Shed a big card on the safe opening trick',
            'Used a known void to trap another player',
            'Ducked under a higher card',
            'Dumped your Yakka on a guaranteed-clean trick',
            'Won the final trick with the lowest card',
          ],
        ),
      ],
    ),
  ],
);
