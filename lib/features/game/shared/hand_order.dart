import 'package:taash/l10n/copy.dart';

/// Local presentation only. The server remains the owner of every card.
class HandOrder {
  final List<String> _cards = [];
  final Set<String> _selected = {};

  List<String> get cards => List.unmodifiable(_cards);
  Set<String> get selected => Set.unmodifiable(_selected);

  /// Retain manual order, remove departed cards, append newly received cards.
  void reconcile(Iterable<String> authoritativeHand) {
    final incoming = authoritativeHand.toSet();
    _cards.removeWhere((card) => !incoming.contains(card));
    _selected.removeWhere((card) => !incoming.contains(card));
    final retained = _cards.toSet();
    for (final card in authoritativeHand) {
      if (retained.add(card)) _cards.add(card);
    }
  }

  bool toggle(String card, {int limit = 1}) {
    if (!_cards.contains(card)) return false;
    if (_selected.remove(card)) return true;
    if (limit == 1) _selected.clear();
    if (_selected.length >= limit) return false;
    _selected.add(card);
    return true;
  }

  void clearSelection() => _selected.clear();

  void move(String card, int destination) {
    final index = _cards.indexOf(card);
    if (index < 0 || _cards.length < 2) return;
    final target = destination.clamp(0, _cards.length - 1);
    _cards.removeAt(index);
    _cards.insert(target, card);
  }

  void sort({bool byRank = false}) => _cards.sort((a, b) {
    final left = CardIdentity.parse(a);
    final right = CardIdentity.parse(b);
    if (byRank) {
      final rank = left.rankIndex.compareTo(right.rankIndex);
      return rank != 0 ? rank : left.suitIndex.compareTo(right.suitIndex);
    }
    final suit = left.suitIndex.compareTo(right.suitIndex);
    return suit != 0 ? suit : left.rankIndex.compareTo(right.rankIndex);
  });
}

class CardIdentity {
  const CardIdentity(this.id, this.suit, this.rank);
  final String id;
  final String suit;
  final String rank;
  static const ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'g',
    'b',
    'k',
    'y',
  ];
  static const suits = ['c', 'e', 'h', 'p'];

  static CardIdentity parse(String id) {
    final parts = id.split('-');
    if (parts.length != 2 ||
        !suits.contains(parts[0]) ||
        !ranks.contains(parts[1])) {
      return CardIdentity(id, '', '');
    }
    return CardIdentity(id, parts[0], parts[1]);
  }

  bool get valid => suit.isNotEmpty && rank.isNotEmpty;
  bool get red => suit == 'e' || suit == 'p';
  int get rankIndex => ranks.indexOf(rank);
  int get suitIndex => suits.indexOf(suit);
  String get suitName => suitNameFor(suit);
  String get rankName => rankNameFor(rank);
  String get label => valid ? '$rankName of $suitName' : Copy.unrecognizedCard;
  String get glyph => switch (rank) {
    'y' => 'Y',
    'k' => 'K',
    'b' => 'B',
    'g' => 'G',
    _ => rank,
  };

  static String suitNameFor(String suit) => switch (suit) {
    'c' => Copy.chirri,
    'e' => Copy.eit,
    'h' => Copy.hukam,
    'p' => Copy.pawn,
    _ => Copy.noSuit,
  };
  static String rankNameFor(String rank) => switch (rank) {
    'y' => Copy.yakka2,
    'k' => Copy.kinga,
    'b' => Copy.begi,
    'g' => Copy.gola,
    _ => rank,
  };
}

/// Input guidance derived only from the player's own hand and public state.
/// Never computes a winner, hidden pile, capture recipient, score or wallet.
abstract final class HandGuidance {
  static bool bhabhiCardAllowed(
    String card,
    List<String> hand, {
    required bool firstTrick,
    required List<String> trick,
    bool resolving = false,
  }) {
    if (resolving || !hand.contains(card)) return false;
    if (firstTrick && trick.isEmpty) return card == 'h-y';
    if (trick.isEmpty) return true;
    final lead = CardIdentity.parse(trick.first).suit;
    final hasLead = hand.any((own) => CardIdentity.parse(own).suit == lead);
    return !hasLead || CardIdentity.parse(card).suit == lead;
  }

  static bool bluffSelectionAllowed(int count, {required bool emptyPile}) =>
      count >= (emptyPile ? 2 : 1) && count <= 4;

  static bool daketiMayDraw(int handCount, int stockCount) =>
      handCount < 5 && stockCount > 0;
  static bool tcMayDraw(int handCount) => handCount == 10;
  static bool tcMayDiscard(
    int handCount,
    String card,
    String? knownTakenDiscard,
  ) => handCount == 11 && card != knownTakenDiscard;
  static bool tcMayClaim(int handCount) => handCount == 10 || handCount == 11;
  static bool tcMayRecycle(int handCount, int stockCount, int discardCount) =>
      handCount == 10 && stockCount == 0 && discardCount > 0;
}
