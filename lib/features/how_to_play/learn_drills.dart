import 'dart:math';

import 'package:flutter/material.dart';

import 'learn_model.dart';
import 'learn_rules.dart';

const _names = ['Sana', 'Bilal', 'Zara', 'Omar', 'Hina', 'Ali', 'Ayesha'];

List<String> _pickNames(Random rng, int n) =>
    (List.of(_names)..shuffle(rng)).take(n).toList();

T _any<T>(Random rng, List<T> items) => items[rng.nextInt(items.length)];

String _n(String card) => Rules.name(card);

// =================================================================== Basics

final basicsDrills = [
  Drill(
    id: 'basics.name',
    title: 'Name that card',
    subtitle: 'Learn the table names for suits and faces.',
    icon: Icons.style_outlined,
    make: nameCardDrill,
  ),
  Drill(
    id: 'basics.higher',
    title: 'Highest rank',
    subtitle: 'Spot the strongest card at a glance.',
    icon: Icons.trending_up,
    make: highestRankDrill,
  ),
];

LessonStep nameCardDrill(Random rng) {
  final cards = Rules.draw(rng, 4, where: (c) => true);
  final target = cards.first;
  // Make distractors close to the answer: same rank or same suit.
  final options = <String>{_n(target)};
  final near =
      Rules.deck()
          .where(
            (c) =>
                c != target &&
                (Rules.rankId(c) == Rules.rankId(target) ||
                    Rules.suit(c) == Rules.suit(target)),
          )
          .toList()
        ..shuffle(rng);
  for (final c in near) {
    if (options.length == 4) break;
    options.add(_n(c));
  }
  final list = options.toList();
  return QuizStep(
    title: 'Name that card',
    question: 'What is this card called at the table?',
    scene: [
      SceneZone.of('Card', [target]),
    ],
    options: list,
    correct: 0,
    explanation:
        'It is the ${_n(target)}. Suits: Hukam ♠, Eit ♦, Pawn ♥, Chirri ♣. Faces: Yakka (A), Kinga (K), Begi (Q), Gola (J).',
  );
}

LessonStep highestRankDrill(Random rng) {
  late List<String> cards;
  do {
    cards = Rules.draw(rng, 3 + rng.nextInt(2));
  } while (cards.map(Rules.rank).toSet().length != cards.length);
  final best = cards.reduce((a, b) => Rules.rank(a) > Rules.rank(b) ? a : b);
  return TapStep.exact(
    title: 'Highest rank',
    prompt: 'Tap the card with the highest rank. Suits do not matter here.',
    hand: cards,
    handLabel: 'Cards',
    answer: {best},
    explanation:
        '${_n(best)} is highest. Order, low to high: 2 3 4 5 6 7 8 9 10 Gola Begi Kinga Yakka.',
    feedback: (_) =>
        'Not quite. Remember: 2 is lowest, Yakka is highest, and Gola < Begi < Kinga.',
  );
}

// =================================================================== Bhabhi

final bhabhiDrills = [
  Drill(
    id: 'bhabhi.legal',
    title: 'Follow the lead',
    subtitle: 'Which of your cards are allowed?',
    icon: Icons.rule,
    make: bhabhiLegalDrill,
  ),
  Drill(
    id: 'bhabhi.trick',
    title: 'Read the trick',
    subtitle: 'Thullu, clean trick or opening trick?',
    icon: Icons.visibility_outlined,
    make: bhabhiTrickDrill,
  ),
  Drill(
    id: 'bhabhi.dump',
    title: 'Smart Thullu',
    subtitle: 'Can\'t follow? Pick the best card to dump.',
    icon: Icons.bolt,
    make: bhabhiDumpDrill,
  ),
  Drill(
    id: 'bhabhi.last',
    title: 'The final trick',
    subtitle: 'Lowest card wins the better place.',
    icon: Icons.flag_outlined,
    make: bhabhiLastTrickDrill,
  ),
];

LessonStep bhabhiLegalDrill(Random rng) {
  final hand = Rules.sorted(Rules.draw(rng, 6 + rng.nextInt(2)));
  final held = hand.map(Rules.suit).toSet();
  final missing = Rules.suits.where((s) => !held.contains(s)).toList();
  final isVoid = missing.isNotEmpty && rng.nextInt(10) < 3;
  final leadSuit = isVoid ? _any(rng, missing) : _any(rng, held.toList());
  final lead = Rules.draw(
    rng,
    1,
    exclude: hand,
    where: (c) => Rules.suit(c) == leadSuit,
  ).first;
  final leader = _pickNames(rng, 1).first;
  final legal = Rules.bhabhiLegal(hand, leadSuit).toSet();
  final suitName = Rules.suitName(leadSuit);
  return TapStep(
    title: 'Follow the lead',
    prompt:
        '$leader led the ${_n(lead)}. Tap every card you are allowed to play, then check.',
    scene: [
      SceneZone('Trick', [SceneCard(lead, caption: leader)]),
    ],
    hand: hand,
    minPick: 1,
    maxPick: hand.length,
    accepts: (p) => p.length == legal.length && p.containsAll(legal),
    solution: legal,
    explanation: isVoid
        ? 'You have no $suitName at all, so every card is allowed. After the opening trick, playing off-suit like this causes a Thullu.'
        : 'You hold ${legal.length} $suitName card${legal.length == 1 ? '' : 's'}, so only ${legal.length == 1 ? 'that one is' : 'those are'} allowed. Other suits stay locked until you run out of $suitName.',
    feedback: (p) {
      if (isVoid) {
        return 'You hold no $suitName, so nothing is locked. Every card is playable.';
      }
      if (p.any((c) => !legal.contains(c))) {
        return 'You still hold $suitName, so every other suit is locked.';
      }
      return 'Almost. You missed a playable $suitName card.';
    },
  );
}

LessonStep bhabhiTrickDrill(Random rng) {
  final names = _pickNames(rng, 3 + rng.nextInt(2));
  final leadSuit = _any(rng, Rules.suits);
  final roll = rng.nextInt(10);
  final mode = roll < 5 ? 'thullu' : (roll < 8 ? 'clean' : 'opening');

  // How many players actually play this trick.
  final plays = mode == 'thullu'
      ? 2 + rng.nextInt(names.length - 1)
      : names.length;
  final offIndex = switch (mode) {
    'thullu' => plays - 1,
    'opening' => 1 + rng.nextInt(names.length - 1),
    _ => -1,
  };
  final followCount = plays - (offIndex >= 0 ? 1 : 0);
  final follow = Rules.draw(
    rng,
    followCount,
    where: (c) => Rules.suit(c) == leadSuit,
  );
  final off = Rules.draw(rng, 1, where: (c) => Rules.suit(c) != leadSuit).first;
  final trick = <String>[];
  var f = 0;
  for (var i = 0; i < plays; i++) {
    trick.add(i == offIndex ? off : follow[f++]);
  }
  final high = Rules.bhabhiHighest(trick);
  final highName = names[high];
  final suitName = Rules.suitName(leadSuit);

  final options = <String>[];
  final pickup = <int, int>{}; // option index -> player index
  final followers = [
    for (var i = 0; i < plays; i++)
      if (i != offIndex) i,
  ]..shuffle(rng);
  final shown = {high, ...followers.take(2)};
  for (final i in shown) {
    pickup[options.length] = i;
    options.add('${names[i]} picks up the cards');
  }
  options.add('Nobody — the cards leave the game');
  final correct = mode == 'thullu'
      ? pickup.entries.firstWhere((e) => e.value == high).key
      : options.length - 1;

  final giver = offIndex >= 0 ? names[offIndex] : '';
  final skipped = names.length - plays;
  final explanation = switch (mode) {
    'thullu' =>
      '$giver could not follow $suitName — Thullu! The trick stops at once${skipped > 0 ? ' and the remaining player${skipped == 1 ? '' : 's'} never play${skipped == 1 ? 's' : ''}' : ''}. $highName holds the highest $suitName (${_n(trick[high])}), so $highName picks up all $plays cards and leads next. An off-suit card can never be the highest.',
    'clean' =>
      'Everyone followed $suitName, so nobody picks anything up — the cards simply leave the game. $highName played the highest $suitName and leads the next trick.',
    _ =>
      'This is the opening trick, so there is no Thullu even though $giver could not follow. All cards leave the game, and $highName (highest $suitName) leads next.',
  };
  return QuizStep(
    title: 'Read the trick',
    question: 'What happens to this trick?',
    scene: [
      SceneZone(
        mode == 'opening' ? 'Opening trick' : 'Trick (led by ${names.first})',
        [
          for (var i = 0; i < plays; i++)
            SceneCard(trick[i], caption: names[i]),
        ],
        note: skipped > 0
            ? '${names.sublist(plays).join(' and ')} ha${skipped == 1 ? 's' : 've'} not played yet.'
            : null,
      ),
    ],
    options: options,
    correct: correct,
    hint:
        'First check: did anyone play a different suit? Then: is it the opening trick?',
    explanation: explanation,
  );
}

LessonStep bhabhiDumpDrill(Random rng) {
  final names = _pickNames(rng, 2);
  final leadSuit = _any(rng, Rules.suits);
  late List<String> hand;
  do {
    hand = Rules.sorted(
      Rules.draw(rng, 5, where: (c) => Rules.suit(c) != leadSuit),
    );
  } while (hand
          .where((c) => Rules.rank(c) == hand.map(Rules.rank).reduce(max))
          .length >
      2);
  final top = hand.map(Rules.rank).reduce(max);
  final best = hand.where((c) => Rules.rank(c) == top).toSet();
  final trick = Rules.draw(
    rng,
    2,
    exclude: hand,
    where: (c) => Rules.suit(c) == leadSuit,
  );
  final suitName = Rules.suitName(leadSuit);
  return TapStep(
    title: 'Smart Thullu',
    prompt:
        'You have no $suitName — you will give a Thullu! You may throw any card. Which one is smartest to get rid of?',
    scene: [
      SceneZone('Trick', [
        SceneCard(trick[0], caption: names[0]),
        SceneCard(trick[1], caption: names[1]),
      ]),
    ],
    hand: hand,
    accepts: (p) => best.containsAll(p),
    solution: {best.first},
    explanation:
        'Throw your highest card (${_n(best.first)}). High cards tend to win tricks, and whoever holds the highest card when someone breaks suit picks up the whole pile. A Thullu is your free chance to dump one — and it earns you +10 points.',
    feedback: (_) =>
        'That works, but you are keeping a higher, more dangerous card. Dump the biggest one.',
  );
}

LessonStep bhabhiLastTrickDrill(Random rng) {
  final names = _pickNames(rng, 2);
  final leadSuit = _any(rng, Rules.suits);
  final suitName = Rules.suitName(leadSuit);
  final played = Rules.draw(
    rng,
    2,
    where: (c) => Rules.suit(c) == leadSuit && Rules.rank(c) >= 3,
  );
  final own = Rules.draw(
    rng,
    2 + rng.nextInt(2),
    exclude: played,
    where: (c) => Rules.suit(c) == leadSuit,
  );
  final other = Rules.draw(rng, 1, where: (c) => Rules.suit(c) != leadSuit);
  final hand = Rules.sorted([...own, ...other]);
  final lowest = own.reduce((a, b) => Rules.rank(a) < Rules.rank(b) ? a : b);
  final theirLow = played.map(Rules.rank).reduce(min);
  final wins = Rules.rank(lowest) < theirLow;
  return TapStep.exact(
    title: 'The final trick',
    prompt:
        '${names.join(' and ')} each play their last card. After this trick only you will hold cards, so it is the final trick. Pick your card.',
    scene: [
      SceneZone('Final trick', [
        SceneCard(played[0], caption: names[0]),
        SceneCard(played[1], caption: names[1]),
      ]),
    ],
    hand: hand,
    answer: {lowest},
    explanation: wins
        ? 'On the final trick the LOWEST $suitName wins. Your ${_n(lowest)} undercuts everyone, so you take the best remaining place.'
        : 'On the final trick the LOWEST $suitName wins. Your ${_n(lowest)} is your lowest — it cannot undercut both cards this time, but it is your only chance. Never raise on the final trick.',
    feedback: (p) => p.any((c) => Rules.suit(c) != leadSuit)
        ? 'You still hold $suitName, so you must follow suit.'
        : 'The final trick flips the rule: the lowest card wins. Pick your lowest $suitName.',
  );
}

// ==================================================================== Bluff

final bluffDrills = [
  Drill(
    id: 'bluff.possible',
    title: 'Possible or impossible?',
    subtitle: 'Count copies to catch a liar.',
    icon: Icons.calculate_outlined,
    make: bluffPossibleDrill,
  ),
  Drill(
    id: 'bluff.outcome',
    title: 'After the challenge',
    subtitle: 'Who takes the pile? Who leads?',
    icon: Icons.gavel,
    make: bluffOutcomeDrill,
  ),
  Drill(
    id: 'bluff.honest',
    title: 'Honest play',
    subtitle: 'Find your real cards for the round.',
    icon: Icons.verified_outlined,
    make: bluffHonestDrill,
  ),
  Drill(
    id: 'bluff.open',
    title: 'Open a round',
    subtitle: 'Start a new pile the safe way.',
    icon: Icons.play_circle_outline,
    make: bluffOpenDrill,
  ),
];

LessonStep bluffPossibleDrill(Random rng) {
  final rank = _any(rng, Rules.ranks);
  final held = rng.nextInt(10) < 8 ? 1 + rng.nextInt(3) : 0;
  final impossible = held > 0 && rng.nextBool();
  final claimed = impossible
      ? 5 - held + rng.nextInt(held)
      : 1 + rng.nextInt(4 - held);
  final mine = Rules.draw(rng, held, where: (c) => Rules.rankId(c) == rank);
  final rest = Rules.draw(
    rng,
    6 - held + rng.nextInt(2),
    where: (c) => Rules.rankId(c) != rank,
  );
  final hand = Rules.sorted([...mine, ...rest]);
  final name = _pickNames(rng, 1).first;
  final plural = Rules.rankPlural(rank);
  final left = 4 - held;
  return QuizStep(
    title: 'Possible or impossible?',
    question:
        'The round is $plural. $name plays $claimed card${claimed == 1 ? '' : 's'}, claiming ${Rules.count(claimed, rank)}. Could that be true?',
    scene: [
      SceneZone('$name\'s play', [
        for (var i = 0; i < claimed; i++) const SceneCard.back(),
      ]),
      SceneZone.of('Your hand', hand),
    ],
    options: const ['It could be true', 'Impossible — challenge!'],
    correct: impossible ? 1 : 0,
    shuffle: false,
    hint: 'Each rank has exactly four copies. How many are in your hand?',
    explanation: impossible
        ? 'Only four $plural exist and you hold ${Rules.count(held, rank)}, so at most $left can be anywhere else. $name cannot have $claimed — challenge, and $name takes the whole pile.'
        : 'Four $plural exist and you hold ${Rules.count(held, rank)}, so up to $left could be out there. $name\'s claim is possible; challenging is a gamble.',
  );
}

LessonStep bluffOutcomeDrill(Random rng) {
  final name = _pickNames(rng, 1).first;
  final rank = _any(rng, Rules.ranks);
  final count = 1 + rng.nextInt(3);
  final honest = rng.nextBool();
  final real = Rules.draw(rng, count, where: (c) => Rules.rankId(c) == rank);
  if (!honest) {
    final fakes = 1 + rng.nextInt(count);
    final wrong = Rules.draw(rng, fakes, where: (c) => Rules.rankId(c) != rank);
    real.replaceRange(0, fakes, wrong);
    real.shuffle(rng);
  }
  final pile = count + 2 + rng.nextInt(9);
  final options = [
    '$name takes all $pile cards; you start the next round',
    'You take all $pile cards; $name starts the next round',
  ];
  return QuizStep(
    title: 'After the challenge',
    question:
        'You challenged $name\'s claim of ${Rules.count(count, rank)}. The cards flip over. What happens?',
    scene: [
      SceneZone('Pile', [SceneCard.back(caption: '$pile cards in total')]),
      SceneZone.of(
        '$name\'s play, revealed',
        real,
        glow: {...real.where((c) => Rules.rankId(c) != rank)},
      ),
    ],
    options: options,
    correct: honest ? 1 : 0,
    hint: 'Look for any card that is not a ${Rules.rankName(rank)}.',
    explanation: honest
        ? 'Every card really is a ${Rules.rankName(rank)}. A wrong challenge backfires: you pick up the whole pile, $name starts the next round, and $name gains 10 points while you lose 5.'
        : 'Caught! Not every card is a ${Rules.rankName(rank)}. $name picks up the whole pile, you start a fresh round, and you gain 10 points while $name loses 5.',
  );
}

LessonStep bluffHonestDrill(Random rng) {
  final rank = _any(rng, Rules.ranks);
  final held = 1 + rng.nextInt(3);
  final mine = Rules.draw(rng, held, where: (c) => Rules.rankId(c) == rank);
  final rest = Rules.draw(
    rng,
    5 + rng.nextInt(3),
    where: (c) => Rules.rankId(c) != rank,
  );
  final hand = Rules.sorted([...mine, ...rest]);
  final plural = Rules.rankPlural(rank);
  final names = _pickNames(rng, 2);
  return TapStep.exact(
    title: 'Honest play',
    prompt:
        'The round\'s rank is $plural. Select every ${Rules.rankName(rank)} you hold for a play nobody can catch.',
    scene: [
      SceneZone('Pile · round of $plural', [
        SceneCard.back(caption: names[0]),
        SceneCard.back(caption: names[1]),
      ]),
    ],
    hand: hand,
    answer: mine.toSet(),
    explanation:
        'You hold ${Rules.count(held, rank)}. Playing ${held == 1 ? 'it' : 'them all'} is 100% safe — a challenge would only make the challenger pick up the pile — and it empties your hand faster.',
    feedback: (p) => p.any((c) => Rules.rankId(c) != rank)
        ? 'At least one of those is not a ${Rules.rankName(rank)} — that would be a bluff.'
        : 'You hold more $plural. Play them all at once.',
  );
}

LessonStep bluffOpenDrill(Random rng) {
  final rank = _any(rng, Rules.ranks);
  final pairSize = 2 + rng.nextInt(2);
  final pair = Rules.draw(rng, pairSize, where: (c) => Rules.rankId(c) == rank);
  late List<String> rest;
  do {
    rest = Rules.draw(rng, 5, where: (c) => Rules.rankId(c) != rank);
  } while (rest.map(Rules.rankId).toSet().length != rest.length);
  final hand = Rules.sorted([...pair, ...rest]);
  return TapStep(
    title: 'Open a round',
    prompt:
        'The pile is empty — you start a new round. Select an honest opening: 2 to 4 cards of the same rank.',
    hand: hand,
    minPick: 2,
    maxPick: 4,
    accepts: (p) => p.length >= 2 && p.map(Rules.rankId).toSet().length == 1,
    solution: pair.toSet(),
    explanation:
        'Your ${Rules.rankPlural(rank)} are a truthful opening. You would then declare ${Rules.rankName(rank)}, and everyone must keep claiming ${Rules.rankPlural(rank)} until the round ends.',
    feedback: (p) => p.length < 2
        ? 'A new round needs at least 2 cards.'
        : 'Those ranks are different — that opening would be a bluff.',
  );
}

// =================================================================== Daketi

final daketiDrills = [
  Drill(
    id: 'daketi.best',
    title: 'Best capture',
    subtitle: 'Which card earns the most points?',
    icon: Icons.emoji_events_outlined,
    make: daketiBestDrill,
  ),
  Drill(
    id: 'daketi.turn',
    title: 'Keep the turn?',
    subtitle: 'Capture + stock left = go again.',
    icon: Icons.replay,
    make: daketiTurnDrill,
  ),
  Drill(
    id: 'daketi.count',
    title: 'Count the score',
    subtitle: 'Yakka 20, faces 10, numbers 5.',
    icon: Icons.scoreboard_outlined,
    make: daketiCountDrill,
  ),
];

/// A random Daketi board where at least one hand card captures.
({
  List<String> table,
  Map<String, List<String>> opps,
  List<String> own,
  List<String> hand,
})
_daketiBoard(Random rng) {
  final names = _pickNames(rng, 2);
  while (true) {
    final used = <String>{};
    List<String> take(int n, {bool Function(String)? where}) {
      final cards = Rules.draw(rng, n, exclude: used, where: where);
      used.addAll(cards);
      return cards;
    }

    final table = take(3 + rng.nextInt(2));
    final opps = <String, List<String>>{};
    for (final name in names) {
      final pile = take(1 + rng.nextInt(3));
      // Sometimes stack a matching rank on top, worth a bigger steal.
      if (rng.nextInt(4) == 0) {
        final top = Rules.rankId(pile.last);
        pile.addAll(take(1, where: (c) => Rules.rankId(c) == top));
      }
      opps[name] = pile;
    }
    final own = rng.nextBool() ? take(1 + rng.nextInt(2)) : <String>[];
    final hand = take(4 + rng.nextInt(2));
    final outcomes = hand.map((c) => Rules.daketiPlay(c, table, opps, own));
    if (outcomes.any((o) => o.fromTable.isNotEmpty || o.stolen.isNotEmpty)) {
      return (table: table, opps: opps, own: own, hand: hand);
    }
  }
}

List<SceneZone> _collectionZones(
  Map<String, List<String>> opps,
  List<String> own,
) {
  SceneZone zone(String label, List<String> pile) {
    if (pile.isEmpty) return SceneZone(label, const [], note: 'No cards yet');
    // Show the matching run on top; everything below stays hidden.
    var start = pile.length - 1;
    while (start > 0 &&
        Rules.rankId(pile[start - 1]) == Rules.rankId(pile.last)) {
      start--;
    }
    return SceneZone(label, [
      if (start > 0) SceneCard.back(caption: '$start below'),
      for (var i = start; i < pile.length; i++)
        SceneCard(pile[i], caption: i == pile.length - 1 ? 'top' : null),
    ]);
  }

  return [
    for (final e in opps.entries) zone('${e.key}\'s collection', e.value),
    zone('Your collection', own),
  ];
}

LessonStep daketiBestDrill(Random rng) {
  final b = _daketiBoard(rng);
  final outcomes = {
    for (final c in b.hand) c: Rules.daketiPlay(c, b.table, b.opps, b.own),
  };
  final bestPoints = outcomes.values.map((o) => o.points).reduce(max);
  final best = outcomes.entries
      .where((e) => e.value.points == bestPoints)
      .map((e) => e.key)
      .toSet();
  return TapStep(
    title: 'Best capture',
    prompt: 'Which card puts the most points into your collection?',
    scene: [SceneZone.of('Table', b.table), ..._collectionZones(b.opps, b.own)],
    hand: Rules.sorted(b.hand),
    accepts: (p) => best.containsAll(p),
    solution: {best.first},
    explanation: outcomes[best.first]!.describe(),
    feedback: (p) =>
        '${outcomes[p.first]!.describe()} Another card scores more — check every table card and every collection top.',
  );
}

LessonStep daketiTurnDrill(Random rng) {
  final b = _daketiBoard(rng);
  final capture = rng.nextBool();
  final candidates = b.hand
      .where(
        (c) => Rules.daketiPlay(c, b.table, b.opps, b.own).capture == capture,
      )
      .toList();
  final card = candidates.isEmpty ? b.hand.first : _any(rng, candidates);
  final outcome = Rules.daketiPlay(card, b.table, b.opps, b.own);
  final stock = rng.nextBool() ? 0 : 3 + rng.nextInt(25);
  final keeps = outcome.capture && stock > 0;
  return QuizStep(
    title: 'Keep the turn?',
    question: 'You play the ${_n(card)}. Do you keep your turn?',
    scene: [
      SceneZone(
        'Stock',
        stock > 0 ? [SceneCard.back(caption: '$stock left')] : const [],
        note: stock == 0 ? 'The stock is empty' : null,
      ),
      SceneZone.of('Table', b.table),
      ..._collectionZones(b.opps, b.own),
      SceneZone.of('You play', [card], glow: {card}),
    ],
    options: const ['Yes — draw and play again', 'No — the turn passes'],
    correct: keeps ? 0 : 1,
    shuffle: false,
    hint: 'Two questions: did it capture anything, and is there stock left?',
    explanation: switch ((outcome.capture, stock > 0)) {
      (true, true) =>
        '${outcome.describe()} A capture while stock remains means you go again: draw, then play another card.',
      (true, false) =>
        '${outcome.describe()} But the stock is empty, so play passes after every card — even a capture.',
      _ => '${outcome.describe()} No capture, so the turn passes.',
    },
  );
}

LessonStep daketiCountDrill(Random rng) {
  final cards = Rules.sorted(Rules.draw(rng, 4 + rng.nextInt(4)));
  final total = Rules.daketiPoints(cards);
  final options = <int>{total};
  for (final delta in [5, -5, 10, -10, 15, 20]..shuffle(rng)) {
    if (options.length == 4) break;
    if (total + delta > 0) options.add(total + delta);
  }
  final list = options.toList();
  final yakkas = cards.where((c) => Rules.rankId(c) == 'y').length;
  final faces = cards.where((c) => 'kbg'.contains(Rules.rankId(c))).length;
  final numbers = cards.length - yakkas - faces;
  return QuizStep(
    title: 'Count the score',
    question: 'How many points is this collection worth?',
    scene: [SceneZone.of('Collection', cards)],
    options: [for (final v in list) '$v points'],
    correct: 0,
    explanation:
        '${[if (yakkas > 0) '$yakkas Yakka${yakkas == 1 ? '' : 's'} × 20', if (faces > 0) '$faces face card${faces == 1 ? '' : 's'} × 10', if (numbers > 0) '$numbers number card${numbers == 1 ? '' : 's'} × 5'].join(' + ')} = $total points.',
  );
}

// ======================================================================= TC

final tcDrills = [
  Drill(
    id: 'tc.yarak',
    title: 'Find the Yarak',
    subtitle: 'The rank after the indicator is wild.',
    icon: Icons.auto_awesome,
    make: tcYarakDrill,
  ),
  Drill(
    id: 'tc.valid',
    title: 'Valid group?',
    subtitle: 'Sets, runs and wild cards.',
    icon: Icons.fact_check_outlined,
    make: tcValidDrill,
  ),
  Drill(
    id: 'tc.build',
    title: 'Build a group',
    subtitle: 'Find a set or run hiding in a hand.',
    icon: Icons.construction,
    make: tcBuildDrill,
  ),
  Drill(
    id: 'tc.claim',
    title: 'Ready to claim?',
    subtitle: 'Is this hand a full 4 + 3 + 3?',
    icon: Icons.workspace_premium_outlined,
    make: tcClaimDrill,
  ),
];

String _yarakLabel(int yarak) => Rules.rankName(Rules.ranks[yarak]);

LessonStep tcYarakDrill(Random rng) {
  final indicator = Rules.draw(rng, 1).first;
  final ir = Rules.rank(indicator);
  final yarak = Rules.yarak(ir);
  final options = <String>{_yarakLabel(yarak)};
  for (final r in [ir, (ir + 2) % 13, (ir + 12) % 13, (ir + 3) % 13]) {
    if (options.length == 4) break;
    options.add(_yarakLabel(r));
  }
  return QuizStep(
    title: 'Find the Yarak',
    question:
        'The indicator is the ${_n(indicator)}. Which rank is Yarak (wild)?',
    scene: [
      SceneZone.of('Indicator', [indicator]),
    ],
    options: options.toList(),
    correct: 0,
    explanation: ir == 12
        ? 'Yarak is the rank right after the indicator, and Yakka wraps around to 2. All four 2s are wild.'
        : 'Yarak is the rank right after the indicator: ${_yarakLabel(ir)} → ${_yarakLabel(yarak)}. All four ${_yarakLabel(yarak)}s are wild in any group.',
  );
}

List<String> _tcRun(Random rng, int n, {Set<String> exclude = const {}}) {
  while (true) {
    final s = _any(rng, Rules.suits);
    final low = rng.nextInt(8) == 0;
    final ranks = low
        ? [12, 0, 1, 2].take(n).toList()
        : [for (var i = 0, st = rng.nextInt(14 - n); i < n; i++) st + i];
    final cards = [for (final r in ranks) Rules.card(s, r)];
    if (!cards.any(exclude.contains)) return cards;
  }
}

List<String> _tcSet(Random rng, int n, {Set<String> exclude = const {}}) {
  while (true) {
    final r = _any(rng, Rules.ranks);
    final cards = (List.of(
      Rules.suits,
    )..shuffle(rng)).take(n).map((s) => '$s-$r').toList();
    if (!cards.any(exclude.contains)) return cards;
  }
}

LessonStep tcValidDrill(Random rng) {
  while (true) {
    final indicator = Rules.draw(rng, 1).first;
    final yarak = Rules.yarak(Rules.rank(indicator));
    bool isYarak(String c) => Rules.rank(c) == yarak;
    final n = 3 + rng.nextInt(2);
    final kind = rng.nextInt(7);
    var group = <String>[];
    var valid = true;
    var why = '';
    switch (kind) {
      case 0 || 1:
        group = _tcSet(rng, n, exclude: {indicator});
        why = 'Same rank, any suits — that is a set.';
      case 2 || 3:
        group = _tcRun(rng, n, exclude: {indicator});
        why = 'Same suit, ranks in a row — that is a run.';
      case 4:
        group = _tcRun(rng, n, exclude: {indicator});
        final i = rng.nextInt(n);
        final s = Rules.suit(group[i]);
        final other = _any(rng, Rules.suits.where((x) => x != s).toList());
        group[i] = '$other-${Rules.rankId(group[i])}';
        valid = false;
        why = 'The ranks are in a row, but a run must be all one suit.';
      case 5:
        final s = _any(rng, Rules.suits);
        final st = rng.nextInt(13 - n - 1);
        final ranks = [for (var i = 0; i < n + 1; i++) st + i]
          ..removeAt(1 + rng.nextInt(n - 1));
        group = [for (final r in ranks) Rules.card(s, r)];
        valid = false;
        why = 'There is a gap in the sequence, and no Yarak to fill it.';
      default:
        if (n == 3) {
          final s = _any(rng, Rules.suits);
          group = [Rules.card(s, 11), Rules.card(s, 12), Rules.card(s, 0)];
          why =
              'Runs do not wrap around: Kinga-Yakka-2 is not a run. Yakka is either high (Begi-Kinga-Yakka) or low (Yakka-2-3).';
        } else {
          group = _tcSet(rng, 3, exclude: {indicator});
          final r = Rules.rankId(group.first);
          group.add(
            Rules.draw(rng, 1, where: (c) => Rules.rankId(c) != r).first,
          );
          why =
              'A set needs every card to share one rank. One card is different.';
        }
        valid = false;
    }
    // Sometimes swap in a Yarak as a wild card in a valid group.
    if (valid && rng.nextInt(3) == 0) {
      final wild = Rules.draw(
        rng,
        1,
        exclude: [...group, indicator],
        where: isYarak,
      );
      if (wild.isNotEmpty && !group.any(isYarak)) {
        group[rng.nextInt(n)] = wild.first;
        why =
            '$why The ${_n(wild.first)} is a Yarak, so it stands in for the missing card.';
      }
    }
    if (group.toSet().length != group.length || group.contains(indicator)) {
      continue;
    }
    // Guard against an accidental Yarak quietly changing the answer.
    if (Rules.tcValidGroup(group, yarak) != valid) continue;
    return QuizStep(
      title: 'Valid group?',
      question: 'Yarak is ${_yarakLabel(yarak)}. Is this a valid group?',
      scene: [
        SceneZone.of('Indicator', [indicator]),
        SceneZone.of('Group', group..shuffle(rng)),
      ],
      options: const ['Valid group', 'Not valid'],
      correct: valid ? 0 : 1,
      shuffle: false,
      hint:
          'Set: one rank. Run: one suit, consecutive ranks. Yarak fills any gap.',
      explanation: why,
    );
  }
}

LessonStep tcBuildDrill(Random rng) {
  final indicator = Rules.draw(rng, 1).first;
  final yarak = Rules.yarak(Rules.rank(indicator));
  final n = 3 + rng.nextInt(2);
  final group = rng.nextBool()
      ? _tcSet(rng, n, exclude: {indicator})
      : _tcRun(rng, n, exclude: {indicator});
  final filler = Rules.draw(rng, 7 - n, exclude: [...group, indicator]);
  final hand = Rules.sorted([...group, ...filler]);
  return TapStep(
    title: 'Build a group',
    prompt:
        'Yarak is ${_yarakLabel(yarak)}. Select 3 or 4 cards that form a valid set or run.',
    scene: [
      SceneZone.of('Indicator', [indicator]),
    ],
    hand: hand,
    minPick: 3,
    maxPick: 4,
    accepts: (p) => Rules.tcValidGroup(p.toList(), yarak),
    solution: group.toSet(),
    explanation:
        'Valid! Sets share one rank; runs share one suit with ranks in a row. A Yarak can stand in for any card.',
    feedback: (_) =>
        'Not a valid group. Sets need one rank; runs need one suit with no gaps (unless a Yarak fills it).',
  );
}

LessonStep tcClaimDrill(Random rng) {
  while (true) {
    final indicator = Rules.draw(rng, 1).first;
    final yarak = Rules.yarak(Rules.rank(indicator));
    final used = <String>{indicator};
    List<String> group(int n) {
      final g = rng.nextBool()
          ? _tcSet(rng, n, exclude: used)
          : _tcRun(rng, n, exclude: used);
      used.addAll(g);
      return g;
    }

    final hand = [...group(4), ...group(3), ...group(3)];
    if (hand.toSet().length != 10) continue;
    final winner = rng.nextBool();
    if (!winner) {
      final i = rng.nextInt(10);
      hand[i] = Rules.draw(
        rng,
        1,
        exclude: used,
        where: (c) => Rules.rank(c) != yarak,
      ).first;
    }
    final groups = Rules.tcWinningGroups(hand, yarak);
    final wins = groups != null;
    final split = groups == null
        ? ''
        : groups.map((g) => g.map(CardShort.of).join(' ')).join('  |  ');
    return QuizStep(
      title: 'Ready to claim?',
      question:
          'Yarak is ${_yarakLabel(yarak)}. Can this 10-card hand claim victory?',
      scene: [
        SceneZone.of('Indicator', [indicator]),
        SceneZone.of('Your hand', Rules.sorted(hand)),
      ],
      options: const ['Yes — claim victory', 'Not yet'],
      correct: wins ? 0 : 1,
      shuffle: false,
      hint:
          'Try to find a group of 4 first, then two groups of 3 from what is left.',
      explanation: wins
          ? 'Yes: $split. Every card is used exactly once.'
          : 'No exact 4 + 3 + 3 split uses all ten cards. Keep drawing — a wrong claim is simply rejected by the server, but it wastes a moment.',
    );
  }
}

/// Compact card text such as "B♦" for inline explanations.
abstract final class CardShort {
  static String of(String card) {
    final r = switch (Rules.rankId(card)) {
      'y' => 'Y',
      'k' => 'K',
      'b' => 'B',
      'g' => 'G',
      final other => other,
    };
    final s = switch (Rules.suit(card)) {
      'h' => '♠',
      'e' => '♦',
      'p' => '♥',
      _ => '♣',
    };
    return '$r$s';
  }
}
