import 'dart:math';

import '../game/shared/hand_order.dart';

/// Offline mirror of the server rules, used only to build and grade practice
/// scenarios in the Learn section. Live games are always decided by the server.
abstract final class Rules {
  static const ranks = CardIdentity.ranks;
  static const suits = CardIdentity.suits;

  static List<String> deck() => [
    for (final s in suits)
      for (final r in ranks) '$s-$r',
  ];

  static int rank(String card) => CardIdentity.parse(card).rankIndex;
  static String rankId(String card) => CardIdentity.parse(card).rank;
  static String suit(String card) => CardIdentity.parse(card).suit;

  /// Suit first, as players say it at the table: "Eit Begi", "Pawn 7".
  static String name(String card) {
    final id = CardIdentity.parse(card);
    return '${id.suitName} ${id.rankName}';
  }

  static String suitName(String suit) => CardIdentity.suitNameFor(suit);
  static String rankName(String rank) => CardIdentity.rankNameFor(rank);

  /// Plural rank name for claims: "Begis", "7s".
  static String rankPlural(String rank) => '${rankName(rank)}s';

  /// "one Begi", "three 7s", "no Yakkas".
  static String count(int n, String rank) {
    const words = ['no', 'one', 'two', 'three', 'four'];
    final number = n < words.length ? words[n] : '$n';
    return '$number ${n == 1 ? rankName(rank) : rankPlural(rank)}';
  }

  static String card(String suit, int rank) => '$suit-${ranks[rank]}';

  /// Draws [n] distinct random cards, avoiding [exclude].
  static List<String> draw(
    Random rng,
    int n, {
    Iterable<String> exclude = const [],
    bool Function(String)? where,
  }) {
    final banned = exclude.toSet();
    final pool =
        deck()
            .where((c) => !banned.contains(c) && (where?.call(c) ?? true))
            .toList()
          ..shuffle(rng);
    return pool.take(n).toList();
  }

  static List<String> sorted(Iterable<String> cards) {
    final out = cards.toList();
    out.sort((a, b) {
      final s = suits.indexOf(suit(a)).compareTo(suits.indexOf(suit(b)));
      return s != 0 ? s : rank(a).compareTo(rank(b));
    });
    return out;
  }

  // ---------------------------------------------------------------- Bhabhi

  /// Cards a player may play onto a trick led in [leadSuit].
  static List<String> bhabhiLegal(List<String> hand, String? leadSuit) {
    if (leadSuit == null) return List.of(hand);
    final follow = hand.where((c) => suit(c) == leadSuit).toList();
    return follow.isEmpty ? List.of(hand) : follow;
  }

  /// Index of the highest card in the lead suit (the pickup / next leader).
  static int bhabhiHighest(List<String> trick) {
    final lead = suit(trick.first);
    var best = 0;
    for (var i = 1; i < trick.length; i++) {
      if (suit(trick[i]) == lead && rank(trick[i]) > rank(trick[best])) {
        best = i;
      }
    }
    return best;
  }

  /// Index of the lowest card in the lead suit (wins the final trick).
  static int bhabhiLowest(List<String> trick) {
    final lead = suit(trick.first);
    var best = 0;
    for (var i = 1; i < trick.length; i++) {
      if (suit(trick[i]) == lead && rank(trick[i]) < rank(trick[best])) {
        best = i;
      }
    }
    return best;
  }

  // ----------------------------------------------------------------- Bluff

  /// Whether [claimed] copies of a rank can exist when you hold [held].
  static bool bluffClaimPossible(int claimed, int held) => claimed <= 4 - held;

  // ---------------------------------------------------------------- Daketi

  static int daketiValue(String card) => switch (rankId(card)) {
    'y' => 20,
    'k' || 'b' || 'g' => 10,
    _ => 5,
  };

  static int daketiPoints(Iterable<String> cards) =>
      cards.fold(0, (sum, c) => sum + daketiValue(c));

  /// Result of playing [card]. Opponent collections are bottom-to-top.
  static DaketiOutcome daketiPlay(
    String card,
    List<String> table,
    Map<String, List<String>> opponents,
    List<String> own,
  ) {
    final r = rankId(card);
    final fromTable = table.where((c) => rankId(c) == r).toList();
    final stolen = <String, List<String>>{};
    for (final entry in opponents.entries) {
      final pile = entry.value;
      final taken = <String>[];
      for (var i = pile.length - 1; i >= 0 && rankId(pile[i]) == r; i--) {
        taken.add(pile[i]);
      }
      if (taken.isNotEmpty) stolen[entry.key] = taken;
    }
    final ownStack = own.isNotEmpty && rankId(own.last) == r;
    return DaketiOutcome(card, fromTable, stolen, ownStack);
  }

  // -------------------------------------------------------------------- TC

  /// Yarak is the rank right after the indicator; Yakka wraps to 2.
  static int yarak(int indicatorRank) => (indicatorRank + 1) % 13;

  static bool tcValidSet(List<String> group, int yarak) {
    if (group.length != 3 && group.length != 4) return false;
    int? want;
    for (final c in group) {
      if (rank(c) == yarak) continue;
      want ??= rank(c);
      if (rank(c) != want) return false;
    }
    return true;
  }

  static bool tcValidRun(List<String> group, int yarak) {
    final n = group.length;
    if (n != 3 && n != 4) return false;
    String? s;
    final present = <int>{};
    for (final c in group) {
      if (rank(c) == yarak) continue;
      s ??= suit(c);
      if (suit(c) != s) return false;
      if (!present.add(rank(c))) return false;
    }
    final sequences = <List<int>>[
      for (var start = 0; start + n <= 13; start++)
        [for (var i = 0; i < n; i++) start + i],
      // Yakka can also sit below the 2: Y-2-3 and Y-2-3-4.
      n == 3 ? [12, 0, 1] : [12, 0, 1, 2],
    ];
    return sequences.any((seq) => present.every(seq.contains));
  }

  static bool tcValidGroup(List<String> group, int yarak) =>
      tcValidSet(group, yarak) || tcValidRun(group, yarak);

  /// One exact 4+3+3 split (11-card hands may leave one card spare).
  static List<List<String>>? tcWinningGroups(List<String> hand, int yarak) {
    final n = hand.length;
    if (n != 10 && n != 11) return null;
    final bySize = <int, List<int>>{3: [], 4: []};
    for (var mask = 1; mask < (1 << n); mask++) {
      final size = _bits(mask);
      if (size != 3 && size != 4) continue;
      if (tcValidGroup(_pick(hand, mask), yarak)) bySize[size]!.add(mask);
    }
    const sizes = [4, 3, 3];
    final chosen = <int>[];
    final failed = <int>{};
    bool dfs(int remaining, int step) {
      if (step == sizes.length) return _bits(remaining) == n - 10;
      final key = remaining * 4 + step;
      if (failed.contains(key)) return false;
      for (final mask in bySize[sizes[step]]!) {
        if (mask & remaining != mask) continue;
        chosen.add(mask);
        if (dfs(remaining ^ mask, step + 1)) return true;
        chosen.removeLast();
      }
      failed.add(key);
      return false;
    }

    if (!dfs((1 << n) - 1, 0)) return null;
    return [for (final m in chosen) _pick(hand, m)];
  }

  static int _bits(int v) {
    var count = 0;
    for (var x = v; x != 0; x &= x - 1) {
      count++;
    }
    return count;
  }

  static List<String> _pick(List<String> hand, int mask) => [
    for (var i = 0; i < hand.length; i++)
      if (mask & (1 << i) != 0) hand[i],
  ];
}

class DaketiOutcome {
  const DaketiOutcome(this.played, this.fromTable, this.stolen, this.ownStack);
  final String played;
  final List<String> fromTable;
  final Map<String, List<String>> stolen;
  final bool ownStack;

  bool get capture => fromTable.isNotEmpty || stolen.isNotEmpty || ownStack;

  /// Every card that lands in your collection, including the one you played.
  List<String> get gained => !capture
      ? const []
      : [played, ...fromTable, for (final s in stolen.values) ...s];

  int get points => Rules.daketiPoints(gained);

  String describe() {
    if (!capture) {
      return 'The ${Rules.name(played)} matches nothing, so it stays on the table.';
    }
    final parts = <String>[];
    if (fromTable.isNotEmpty) {
      parts.add('takes ${_list(fromTable)} from the table');
    }
    for (final e in stolen.entries) {
      parts.add('steals ${_list(e.value)} from ${e.key}');
    }
    if (parts.isEmpty) {
      return 'The ${Rules.name(played)} matches your own top card, so it joins your collection (+$points).';
    }
    return 'The ${Rules.name(played)} ${parts.join(' and ')}: +$points points.';
  }

  static String _list(List<String> cards) =>
      cards.map((c) => Rules.name(c)).join(', ');
}
