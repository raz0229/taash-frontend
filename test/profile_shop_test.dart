import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/features/profile/presentation.dart';
import 'package:taash/features/profile/rank.dart';
import 'package:taash/features/shop/avatar_catalog.dart';

void main() {
  group('Rank presentation from brief', () {
    test(
      'below first rank is explicit and negative scores do not underflow',
      () {
        for (final points in [-100, 0, 49]) {
          final progress = rankFor(GameType.bhabhi, points);
          expect(progress.number, 0);
          expect(progress.next, 50);
          expect(progress.fraction, inInclusiveRange(0, 1));
        }
      },
    );
    test('exact thresholds start a new tier and progress uses interval', () {
      expect(rankFor(GameType.bhabhi, 50).number, 1);
      expect(rankFor(GameType.bhabhi, 99).number, 1);
      expect(rankFor(GameType.bhabhi, 100).number, 2);
      final veteran = rankFor(GameType.bluff, 4000);
      expect(veteran.name, 'Veteran');
      expect(veteran.number, 7);
      expect(veteran.fraction, .5);
      expect(veteran.remaining, 1000);
    });
    test('malformed rank 9 is never guessed', () {
      for (final points in [5000, 8000, 10999]) {
        expect(rankFor(GameType.bluff, points).ambiguous, isTrue);
      }
      for (final points in [15000, 22000, 29999]) {
        expect(rankFor(GameType.daketi, points).ambiguous, isTrue);
      }
      expect(rankFor(GameType.bluff, 11000).number, 10);
      expect(rankFor(GameType.daketi, 30000).number, 10);
      expect(rankFor(GameType.tc, 8000).number, 9);
    });
    test('known threshold boundaries and cap', () {
      const boundaries = [
        50,
        100,
        150,
        350,
        1000,
        2000,
        3000,
        5000,
        8000,
        11000,
        15000,
        20000,
        26000,
        35000,
        50000,
      ];
      for (var i = 0; i < boundaries.length; i++) {
        expect(rankFor(GameType.tc, boundaries[i]).number, i + 1);
        expect(rankFor(GameType.tc, boundaries[i] - 1).number, i);
      }
      expect(rankFor(GameType.tc, 900000).isMaximum, isTrue);
      expect(rankFor(GameType.tc, 900000).fraction, 1);
      expect(rankFor(GameType.tc, 900000).next, isNull);
      expect(rankFor(GameType.daketi, 99999).number, 15);
    });
  });
  test(
    'country representation validates membership rather than letter shape',
    () {
      final labels = CountryLabels({'PK': 'Pakistan', 'US': 'United States'});
      expect(labels.name('pk'), 'Pakistan');
      expect(labels.name('ZZ'), 'Global');
      expect(labels.name(null), 'Global');
      expect(labels.name('Pakistan'), 'Global');
    },
  );
  test('avatar selection ownership and balance are distinct', () {
    final player = PlayerProfile(
      id: 'p',
      displayName: 'Player',
      selectedPfp: 1,
      unlockedPfps: [0, 1, 2],
      coins: 250,
      createdAt: DateTime.utc(2026),
    );
    AvatarItem item(int id, int cost) =>
        AvatarItem(id: id, name: 'Avatar', rarity: 'common', cost: cost);
    expect(avatarOwnership(item(1, 0), player), AvatarOwnership.selected);
    expect(avatarOwnership(item(2, 250), player), AvatarOwnership.owned);
    expect(avatarOwnership(item(3, 250), player), AvatarOwnership.affordable);
    expect(avatarOwnership(item(4, 251), player), AvatarOwnership.insufficient);
    expect(
      AvatarItem.fromJson({
        'pfp_id': 13,
        'pfp_cost_in_coins': 80000,
        'avatar_name': 'Batman',
      }).name,
      'Batman',
    );
  });
}
