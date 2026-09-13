import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../home/game_art.dart';

/// Game-tinted palette shared by the room backdrop and every front element on
/// the table. Uses the game's hue at a fixed, modest saturation — the same
/// recipe as the backdrop — so Bhabhi stays violet, Daketi amber, Bluff rose
/// and TC blue while the raised panels, highlights, buttons and chat pick up
/// matching shades instead of the old, always-purple paint.
class GameTint {
  const GameTint(this.game);
  final GameType game;

  double get _hue => HSLColor.fromColor(gameColor(game)).hue;
  Color _at(double lightness, {double saturation = .48}) =>
      HSLColor.fromAHSL(1, _hue, saturation, lightness).toColor();

  /// Darkest room band behind the backdrop edges (keeps the status and
  /// navigation inset areas in tune with the game).
  Color get base => _at(.12);

  /// Deep tray backgrounds: hand rail, other players' chat bubbles, name chips.
  Color get tray => _at(.16);

  /// Raised panel mid shade: play-area gradient start, hand border, room-code
  /// card base.
  Color get surface => _at(.40);

  /// Brighter front of the room-code card.
  Color get surfaceLight => _at(.54, saturation: .56);

  /// Outlines and raised tiles.
  Color get edge => _at(.50, saturation: .42);

  /// Soft tinted secondary text.
  Color get tint => _at(.74, saturation: .30);

  /// Bright game accent for glows, active turns, primary buttons and your chat
  /// bubbles.
  Color get accent => _at(.60, saturation: .62);

  /// Readable dark ink drawn on top of [accent].
  Color get onAccent => _at(.15);
}