import 'package:flutter_test/flutter_test.dart';
import 'package:taash/features/game/shared/hand_order.dart';

void main() {
  test(
    'manual order survives snapshots and departing selection is removed',
    () {
      final hand = HandOrder()..reconcile(['h-y', 'c-2', 'p-g']);
      hand.move('p-g', 0);
      hand.toggle('c-2');
      hand.reconcile(['h-y', 'p-g', 'e-b']);
      expect(hand.cards, ['p-g', 'h-y', 'e-b']);
      expect(hand.selected, isEmpty);
      hand.reconcile(['h-y', 'p-g', 'e-b']);
      expect(hand.cards, ['p-g', 'h-y', 'e-b']);
    },
  );

  test('Bluff selection caps at four and never selects an unowned card', () {
    final hand = HandOrder()..reconcile(['c-2', 'c-3', 'c-4', 'c-5', 'c-6']);
    for (final card in hand.cards.take(4)) {
      hand.toggle(card, limit: 4);
    }
    expect(hand.toggle('c-6', limit: 4), false);
    expect(hand.toggle('p-2', limit: 4), false);
    expect(hand.selected.length, 4);
  });

  test('sorting uses canonical local ranks and suit identity', () {
    final hand = HandOrder()..reconcile(['h-y', 'p-2', 'c-k', 'c-g', 'h-b']);
    hand.sort();
    expect(hand.cards, ['c-g', 'c-k', 'h-b', 'h-y', 'p-2']);
    expect(CardIdentity.parse('h-y').label, 'Yakka of Hukam');
    expect(CardIdentity.parse('x-j').valid, false);
  });

  test(
    'Bhabhi opening, follow suit, Thullu eligibility and resolving guidance',
    () {
      const hand = ['h-y', 'h-2', 'c-k'];
      expect(
        HandGuidance.bhabhiCardAllowed(
          'h-2',
          hand,
          firstTrick: true,
          trick: [],
        ),
        false,
      );
      expect(
        HandGuidance.bhabhiCardAllowed(
          'h-y',
          hand,
          firstTrick: true,
          trick: [],
        ),
        true,
      );
      expect(
        HandGuidance.bhabhiCardAllowed(
          'c-k',
          hand,
          firstTrick: false,
          trick: ['h-3'],
        ),
        false,
      );
      expect(
        HandGuidance.bhabhiCardAllowed(
          'c-k',
          ['c-k'],
          firstTrick: false,
          trick: ['h-3'],
        ),
        true,
      );
      expect(
        HandGuidance.bhabhiCardAllowed(
          'h-y',
          hand,
          firstTrick: false,
          trick: [],
          resolving: true,
        ),
        false,
      );
    },
  );

  test('Bluff opening differs from following plays', () {
    expect(HandGuidance.bluffSelectionAllowed(1, emptyPile: true), false);
    expect(HandGuidance.bluffSelectionAllowed(2, emptyPile: true), true);
    expect(HandGuidance.bluffSelectionAllowed(1, emptyPile: false), true);
    expect(HandGuidance.bluffSelectionAllowed(5, emptyPile: false), false);
  });

  test('Daketi can draw up to five without enforcing a mandatory draw', () {
    expect(HandGuidance.daketiMayDraw(4, 1), true);
    expect(HandGuidance.daketiMayDraw(5, 1), false);
    expect(HandGuidance.daketiMayDraw(3, 0), false);
  });

  test('TC handles 11-card claims, known pickup restriction and recycle', () {
    expect(HandGuidance.tcMayDraw(10), true);
    expect(HandGuidance.tcMayDraw(11), false);
    expect(HandGuidance.tcMayDiscard(11, 'h-y', 'h-y'), false);
    expect(HandGuidance.tcMayDiscard(11, 'h-y', null), true);
    expect(HandGuidance.tcMayClaim(11), true);
    expect(HandGuidance.tcMayClaim(9), false);
    expect(HandGuidance.tcMayRecycle(10, 0, 1), true);
    expect(HandGuidance.tcMayRecycle(11, 0, 1), false);
  });
}
