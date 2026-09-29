import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/features/shop/thullu_sfx_catalog.dart';

const profileJson = {
  'id': 'qa-user',
  'display_name': 'Ayesha Khan',
  'country': 'PK',
  'coins': 6000,
  'xp': 780,
  'selected_pfp': 1,
  'unlocked_pfps': [0, 1],
  'selected_thullu_sfx': 2,
  'unlocked_thullu_sfx': [0, 2],
  'created_at': '2026-09-01T12:00:00Z',
};

PlayerProfile profile() => PlayerProfile.fromJson(profileJson);

void main() {
  group('thullu sfx catalog', () {
    test('parses id, cost, name and asset key', () {
      final item = ThulluSfxItem.fromJson(const {
        'thullu_id': 2,
        'cost_in_coins': 5000,
        'name': 'Bhola Meme',
        'sfx_to_play': 'audio/thullu-soundboard/2.ogg',
      });
      expect(item.id, 2);
      expect(item.cost, 5000);
      expect(item.name, 'Bhola Meme');
      // playSfx prepends "audio/", so the key must not repeat it.
      expect(item.sfxKey, 'thullu-soundboard/2');
    });

    test('strips assets/ and the extension from the catalog path', () {
      expect(
        ThulluSfxItem.sfxKeyFor('assets/audio/thullu-soundboard/7.ogg', 7),
        'thullu-soundboard/7',
      );
    });

    test('falls back to the default key when the path is unusable', () {
      expect(ThulluSfxItem.sfxKeyFor('', 5), '0');
    });

    test('rejects a negative id or cost', () {
      expect(
        () => ThulluSfxItem.fromJson(const {
          'thullu_id': -1,
          'cost_in_coins': 10,
        }),
        throwsFormatException,
      );
      expect(
        () => ThulluSfxItem.fromJson(const {'thullu_id': 1, 'cost_in_coins': -5}),
        throwsFormatException,
      );
    });

    test('resolves a server id straight to a soundboard asset key', () {
      expect(ThulluSfxItem.sfxKeyForId(0), 'thullu-soundboard/0');
      expect(ThulluSfxItem.sfxKeyForId(13), 'thullu-soundboard/13');
    });

    // A hostile or corrupt id must never build a path that escapes the
    // soundboard directory.
    test('clamps a negative server id to the default sound', () {
      expect(ThulluSfxItem.sfxKeyForId(-7), 'thullu-soundboard/0');
    });
  });

  group('thullu sfx ownership', () {
    ThulluSfxItem item(int id, int cost) =>
        ThulluSfxItem(id: id, name: 'S$id', cost: cost, sfxKey: 'thullu-soundboard/$id');

    test('selected, owned, affordable and insufficient are distinct', () {
      final p = profile();
      expect(
        thulluSfxOwnership(item(2, 5000), p),
        ThulluSfxOwnership.selected,
      );
      expect(
        thulluSfxOwnership(item(0, 0), p),
        ThulluSfxOwnership.owned,
      );
      expect(
        thulluSfxOwnership(item(5, 1500), p),
        ThulluSfxOwnership.affordable,
      );
      expect(
        thulluSfxOwnership(item(9, 99999), p),
        ThulluSfxOwnership.insufficient,
      );
    });

    test('an owned sound the player has not picked is still selectable', () {
      final ownedButNotPicked = PlayerProfile.fromJson(Map<String, dynamic>.of(profileJson)
        ..['selected_thullu_sfx'] = 0);
      expect(
        thulluSfxOwnership(
          const ThulluSfxItem(
            id: 2,
            name: 'Bhola',
            cost: 5000,
            sfxKey: 'thullu-soundboard/2',
          ),
          ownedButNotPicked,
        ),
        ThulluSfxOwnership.owned,
      );
    });
  });

  group('player profile thullu fields', () {
    test('reads unlocked and selected sounds', () {
      final p = profile();
      expect(p.unlockedThulluSfx, [0, 2]);
      expect(p.selectedThulluSfx, 2);
    });

    // Accounts predating the migration have no thullu columns at all. They must
    // still get a playable sound rather than an empty inventory.
    test('defaults to the free sound when the columns are missing', () {
      final legacy = PlayerProfile.fromJson(const {
        'id': 'qa-user',
        'display_name': 'Old Account',
        'created_at': '2026-09-01T12:00:00Z',
      });
      expect(legacy.unlockedThulluSfx, [0]);
      expect(legacy.selectedThulluSfx, 0);
    });
  });

  group('bhabhi thullu broadcast', () {
    test('reads the server-resolved giver and sound', () {
      final state = BhabhiState.fromJson(const {
        'last_thullu': true,
        'last_thullu_giver': 'player-a',
        'last_thullu_sfx': 4,
        'last_pickup_player_id': 'player-b',
      });
      expect(state.lastThullu, isTrue);
      expect(state.lastThulluGiverId, 'player-a');
      expect(state.lastThulluSfx, 4);
    });

    // A room broadcast by a server without the soundboard must still play the
    // default clip instead of going silent.
    test('falls back to the default sound on an older server payload', () {
      final state = BhabhiState.fromJson(const {
        'last_thullu': true,
        'last_pickup_player_id': 'player-b',
      });
      expect(state.lastThullu, isTrue);
      expect(state.lastThulluGiverId, isEmpty);
      expect(state.lastThulluSfx, 0);
    });
  });

  group('public player seat', () {
    test('carries the seat snapshot of the selected sound', () {
      final p = PublicPlayer.fromJson(const {
        'id': 'player-a',
        'display_name': 'A',
        'selectedThulluSfx': 6,
      });
      expect(p.selectedThulluSfx, 6);
    });

    test('defaults to the free sound for older payloads', () {
      final p = PublicPlayer.fromJson(const {
        'id': 'player-a',
        'display_name': 'A',
      });
      expect(p.selectedThulluSfx, 0);
    });
  });
}
