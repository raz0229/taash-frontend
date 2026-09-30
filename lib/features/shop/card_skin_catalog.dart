import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/models/models.dart';

class CardSkinItem {
  const CardSkinItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.rarity,
    required this.directory,
  });
  factory CardSkinItem.fromJson(Map<String, dynamic> json) => CardSkinItem(
    id: jsonInt(json['skin_id'], -1),
    name: jsonString(json['skin_name']),
    cost: jsonInt(json['skin_cost_in_coins'], -1),
    rarity: jsonString(json['skin_rank'], 'common'),
    directory: jsonString(json['skin_directory_in_frontend'], 'cards/default'),
  );
  final int id, cost;
  final String name, rarity, directory;

  /// The catalog is bundled JSON that cannot change while the app runs, so it is
  /// read once and shared.
  ///
  /// Caching the in-flight future rather than the parsed list also means two
  /// screens that need skins at the same time — the profile and the shop — share
  /// a single asset read instead of racing to do it twice.
  static Future<List<CardSkinItem>>? _pending;

  static Future<List<CardSkinItem>> load() {
    return _pending ??= _read();
  }

  static Future<List<CardSkinItem>> _read() async {
    final decoded = jsonDecode(
      await rootBundle.loadString('assets/catalogs/card_skins.json'),
    );
    final items = jsonList(
      decoded,
      (value) => CardSkinItem.fromJson(jsonObject(value)),
    ).toList(growable: false);
    if (items.any((item) => item.id < 0 || item.cost < 0) ||
        items.map((i) => i.id).toSet().length != items.length) {
      // A malformed bundled catalog is a build error, and caching a rejected
      // future would make it permanent for the life of the process.
      _pending = null;
      throw const FormatException('Invalid card skin catalog');
    }
    return items;
  }
}

enum SkinOwnership { selected, owned, affordable, insufficient }

SkinOwnership skinOwnership(CardSkinItem item, PlayerProfile profile) {
  if (profile.selectedSkin == item.id) return SkinOwnership.selected;
  if (profile.unlockedSkins.contains(item.id)) return SkinOwnership.owned;
  return profile.coins >= item.cost
      ? SkinOwnership.affordable
      : SkinOwnership.insufficient;
}

// Asset paths are intentionally stable and validated against card_skins.json.
// This synchronous lookup keeps card rendering free of async frame delays.
const cardSkinDirectories = <int, String>{
  0: 'cards/default',
  1: 'cards/abyss',
  2: 'cards/basant',
  3: 'cards/amber',
  4: 'cards/frostforge',
  5: 'cards/green_room',
  6: 'cards/vintage',
  7: 'cards/midnight',
  8: 'cards/monsoon',
  9: 'cards/neon_city',
  10: 'cards/phool_patti',
  11: 'cards/pixel_quest',
  12: 'cards/starfall',
};

String cardSkinDirectory(int id) =>
    cardSkinDirectories[id] ?? cardSkinDirectories[0]!;
