import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:taash/l10n/copy.dart';

import '../../core/models/models.dart';

/// One purchasable clip on the Bhabhi thullu soundboard.
///
/// The catalog drives both the shop list and the in-game picker, so a sound
/// unlocked in one place is immediately usable in the other.
class ThulluSfxItem {
  const ThulluSfxItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.sfxKey,
  });

  factory ThulluSfxItem.fromJson(Map<String, dynamic> json) {
    final id = jsonInt(json['thullu_id'], -1);
    final cost = jsonInt(json['cost_in_coins'], -1);
    if (id < 0 || cost < 0) {
      throw const FormatException(Copy.invalidThulluSfxCatalog);
    }
    return ThulluSfxItem(
      id: id,
      cost: cost,
      name: jsonString(json['name']),
      sfxKey: ThulluSfxItem.sfxKeyFor(
        jsonString(json['sfx_to_play']),
        id,
      ),
    );
  }

  /// The sound every account owns and starts with. It is also the fallback
  /// used when a sound id arrives that the catalog does not know about, which
  /// keeps a stale client playable instead of silent.
  static const int defaultId = 0;

  /// The soundboard asset directory, relative to `assets/audio/`.
  static const String assetDir = 'thullu-soundboard';

  final int id, cost;
  final String name, sfxKey;

  /// Resolves a server-broadcast sound id straight to an asset key, so a room
  /// can play the clip without first loading the catalog. Ids are clamped to
  /// non-negative integers so a malformed or hostile value can never escape the
  /// soundboard directory; anything unusable falls back to the default clip.
  static String sfxKeyForId(int id) =>
      '$assetDir/${id < 0 ? defaultId : id}';

  /// Translates a catalog `sfx_to_play` path such as
  /// `audio/thullu-soundboard/2.ogg` into the `thullu-soundboard/2` key that
  /// `AudioSystem.playSfx` expects, since it prepends `audio/` itself.
  static String sfxKeyFor(String sfxToPlay, int id) {
    var key = sfxToPlay;
    if (key.startsWith('assets/')) key = key.substring('assets/'.length);
    if (key.startsWith('audio/')) key = key.substring('audio/'.length);
    if (key.endsWith('.ogg')) key = key.substring(0, key.length - 4);
    if (key.isEmpty) return '$defaultId';
    return key;
  }

  static Future<List<ThulluSfxItem>> load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/catalogs/thullu_soundboard.json'),
    );
    final result = jsonList(
      json,
      (value) => ThulluSfxItem.fromJson(jsonObject(value)),
    );
    if (result.map((item) => item.id).toSet().length != result.length) {
      throw const FormatException(Copy.duplicateThulluSfxIDs);
    }
    if (!result.any((item) => item.id == defaultId)) {
      throw const FormatException(Copy.missingDefaultThulluSfx);
    }
    return result;
  }
}

List<ThulluSfxItem>? _thulluSfxCache;

/// Loads the soundboard once per app run and shares it, so the Shop tab and the
/// in-room picker never disagree about names, prices, or asset keys.
Future<List<ThulluSfxItem>> loadThulluSfxCatalog() async =>
    _thulluSfxCache ??= await ThulluSfxItem.load();

/// The display name for a sound id, or null when the catalog has no such entry.
Future<String?> thulluSfxName(int id) async {
  final items = await loadThulluSfxCatalog();
  for (final item in items) {
    if (item.id == id) return item.name;
  }
  return null;
}

enum ThulluSfxOwnership { selected, owned, affordable, insufficient }

ThulluSfxOwnership thulluSfxOwnership(
  ThulluSfxItem item,
  PlayerProfile player,
) {
  if (player.selectedThulluSfx == item.id) {
    return ThulluSfxOwnership.selected;
  }
  if (player.unlockedThulluSfx.contains(item.id)) {
    return ThulluSfxOwnership.owned;
  }
  return player.coins >= item.cost
      ? ThulluSfxOwnership.affordable
      : ThulluSfxOwnership.insufficient;
}
