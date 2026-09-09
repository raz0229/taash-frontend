import 'dart:math' as math;
import 'package:flutter/material.dart';

class RoomBackdrop extends StatelessWidget {
  const RoomBackdrop({super.key});
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -.15),
        radius: 1.05,
        colors: [Color(0xff58359A), Color(0xff2B205C), Color(0xff16112F)],
        stops: [0, .6, 1],
      ),
    ),
    child: CustomPaint(painter: _DiamondRoom()),
  );
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
