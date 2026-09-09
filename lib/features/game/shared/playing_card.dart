import 'package:taash/l10n/copy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'hand_order.dart';

/// Supplied deck artwork, with wire identity and local-language semantics kept separate.
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    this.card,
    this.width = 68,
    this.selected = false,
    this.available = true,
    this.onTap,
    this.semanticLabel,
    this.faceDown = false,
  });
  final String? card;
  final double width;
  final bool selected, available, faceDown;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final identity = CardIdentity.parse(card ?? '');
    final back = faceDown || card == null;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticLabel ?? (back ? Copy.faceDownCard : identity.label),
      selected: selected,
      button: onTap != null,
      hint: onTap != null ? Copy.tapTo(selected ? 'deselect' : 'select') : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 120),
            width: width,
            height: width * 1.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * .105),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? .32 : .2),
                  blurRadius: selected ? 14 : 5,
                  offset: Offset(0, selected ? 6 : 3),
                ),
              ],
              border: selected
                  ? Border.all(color: const Color(0xffe9b95f), width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * .09),
              child: Opacity(
                opacity: available ? 1 : .76,
                child: back || identity.valid
                    ? SvgPicture.asset(
                        back
                            ? 'assets/cards/back-blue.svg'
                            : 'assets/cards/$card.svg',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      )
                    : const ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: Icon(Icons.question_mark, color: Colors.black),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primitive suit geometry, shared by original cards and room illustration.
void drawSuit(
  Canvas canvas,
  String suit,
  Offset center,
  double size,
  Color color,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(size / 24);
  final paint = Paint()..color = color;
  final path = Path();
  switch (suit) {
    case 'e':
      path
        ..moveTo(0, -12)
        ..lineTo(9, 0)
        ..lineTo(0, 12)
        ..lineTo(-9, 0)
        ..close();
    case 'p':
      path
        ..moveTo(0, 10)
        ..cubicTo(-20, -2, -9, -16, 0, -6)
        ..cubicTo(9, -16, 20, -2, 0, 10)
        ..close();
    case 'c':
      canvas.drawCircle(const Offset(0, -6), 6, paint);
      canvas.drawCircle(const Offset(-6, 2), 6, paint);
      canvas.drawCircle(const Offset(6, 2), 6, paint);
      path
        ..moveTo(-5, 12)
        ..quadraticBezierTo(0, 5, 0, 0)
        ..quadraticBezierTo(0, 5, 5, 12)
        ..close();
    default:
      path
        ..moveTo(0, -12)
        ..cubicTo(-8, -3, -15, 2, -9, 7)
        ..quadraticBezierTo(-4, 11, 0, 4)
        ..quadraticBezierTo(0, 9, -5, 12)
        ..lineTo(5, 12)
        ..quadraticBezierTo(0, 9, 0, 4)
        ..quadraticBezierTo(4, 11, 9, 7)
        ..cubicTo(15, 2, 8, -3, 0, -12)
        ..close();
  }
  canvas.drawPath(path, paint);
  canvas.restore();
}
