import 'package:taash/l10n/copy.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/models/models.dart';

class AvatarItem {
  const AvatarItem({
    required this.id,
    required this.name,
    required this.rarity,
    required this.cost,
  });
  factory AvatarItem.fromJson(Map<String, dynamic> json) {
    final id = jsonInt(json['pfp_id'], -1);
    final cost = jsonInt(json['pfp_cost_in_coins'], -1);
    if (id < 0 || id > 14 || cost < 0) {
      throw const FormatException(Copy.invalidAvatarCatalog);
    }
    return AvatarItem(
      id: id,
      cost: cost,
      name: jsonString(json['avatar_name']),
      rarity: jsonString(json['avatar_rank'], 'common'),
    );
  }
  final int id, cost;
  final String name, rarity;
  static Future<List<AvatarItem>> load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/catalogs/avatars.json'),
    );
    final result = jsonList(
      json,
      (value) => AvatarItem.fromJson(jsonObject(value)),
    );
    if (result.map((item) => item.id).toSet().length != result.length) {
      throw const FormatException(Copy.duplicateAvatarIDs);
    }
    return result;
  }
}

enum AvatarOwnership { selected, owned, affordable, insufficient }

AvatarOwnership avatarOwnership(AvatarItem item, PlayerProfile player) {
  if (player.selectedPfp == item.id) return AvatarOwnership.selected;
  if (player.unlockedPfps.contains(item.id)) return AvatarOwnership.owned;
  return player.coins >= item.cost
      ? AvatarOwnership.affordable
      : AvatarOwnership.insufficient;
}
