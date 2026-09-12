import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../home/game_art.dart';

/// Darkest tier of the game-tinted room, used behind the backdrop (status-bar
/// and navigation inset bands) so those never show an off-tune purple.
Color roomBaseColor(GameType game) => HSLColor.fromAHSL(
  1,
  HSLColor.fromColor(gameColor(game)).hue,
  .48,
  .12,
).toColor();

/// Room backdrop tinted to the game being played. Every game reuses the same
/// recipe as the original purple room — the game's hue at a fixed, darkened
/// saturation — so Daketi glows amber, Bluff rose, and TC blue while the room
/// keeps a single, cohesive mood.
class RoomBackdrop extends StatelessWidget {
  const RoomBackdrop({super.key, required this.game});
  final GameType game;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -.15),
        radius: 1.05,
        stops: const [0, .6, 1],
        colors: _tones,
      ),
    ),
    child: const CustomPaint(painter: _DiamondRoom()),
  );

  /// Dark, desaturated stops that keep only the game's hue.
  List<Color> get _tones {
    final hue = HSLColor.fromColor(gameColor(game)).hue;
    Color tone(double l) => HSLColor.fromAHSL(1, hue, .48, l).toColor();
    return [tone(.40), tone(.24), tone(.12)];
  }
}

class _DiamondRoom extends CustomPainter {
  const _DiamondRoom();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .025);
    const unit = 62.0;
    for (double y = -unit; y < size.height + unit; y += unit) {
      for (double x = -unit; x < size.width + unit; x += unit) {
        if (((x / unit).round() + (y / unit).round()).isOdd) continue;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(const Rect.fromLTWH(-22, -22, 44, 44), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_DiamondRoom old) => false;
}
