import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../l10n/copy.dart';
import '../game/shared/playing_card.dart';

const lobbyGames = [
  GameType.bhabhi,
  GameType.daketi,
  GameType.bluff,
  GameType.tc,
];
Color gameColor(GameType game) => switch (game) {
  GameType.bhabhi => const Color(0xff8A38EA),
  GameType.daketi => const Color(0xffE38D21),
  GameType.bluff => const Color(0xffD53969),
  GameType.tc => const Color(0xff187BE6),
};
String gamePromise(GameType game) => switch (game) {
  GameType.bhabhi => Copy.leaveTheCardsKeepTheCompany,
  GameType.daketi => 'A little strategy. A great big steal.',
  GameType.bluff => 'A straight face goes a long way.',
  GameType.tc => Copy.findYourWinningCombination,
};
String gameDescription(GameType game) => switch (game) {
  GameType.bhabhi => Copy.finishYourHandDodgeTheThullu,
  GameType.daketi => Copy.matchRanksCaptureCardsCollectPoints,
  GameType.bluff => Copy.playItCoolCallTheirBluff,
  GameType.tc => Copy.setsRunsAndALittleYarakMagic,
};

/// Composes the supplied portrait and card assets into a game-specific scene.
class GameArt extends StatelessWidget {
  const GameArt({super.key, required this.game});
  final GameType game;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final portrait = switch (game) {
          GameType.bhabhi => 10,
          GameType.daketi => 7,
          GameType.bluff => 12,
          GameType.tc => 14,
        };
        final cards = switch (game) {
          GameType.bhabhi => ['h-y', 'p-k', 'e-b'],
          GameType.daketi => ['h-7', 'c-7', 'e-7'],
          GameType.bluff => ['c-g', 'p-b', 'h-k'],
          GameType.tc => ['p-3', 'p-4', 'p-5'],
        };
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: CustomPaint(painter: _BurstPainter(game))),
            Positioned(
              right: -w * .18,
              top: 18,
              width: w * .95,
              height: w * .95,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, .6, 1],
                ).createShader(r),
                child: Image.asset(
                  'assets/pfps/$portrait.png',
                  fit: BoxFit.contain,
                  cacheWidth: 400,
                ),
              ),
            ),
            for (var i = 0; i < cards.length; i++)
              Positioned(
                left: w * .07 + i * w * .16,
                top: 76 + (i - 1).abs() * 12,
                child: Transform.rotate(
                  angle: (i - 1) * .22 - .10,
                  child: PlayingCard(
                    card: cards[i],
                    width: w * .34,
                    faceDown: game == GameType.bluff && i < 2,
                  ),
                ),
              ),
            if (game == GameType.daketi)
              Positioned(
                left: w * .60,
                top: 162,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xffFFE78B), Color(0xffEAAA23)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black38,
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xff935B09),
                    size: 28,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.game);
  final GameType game;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .64, size.height * .34);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: .30),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .75));
    canvas.drawRect(Offset.zero & size, glow);
    final ray = Paint()..color = Colors.white.withValues(alpha: .045);
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi / 7;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + math.cos(a) * size.height * 2,
            center.dy + math.sin(a) * size.height * 2,
          )
          ..lineTo(
            center.dx + math.cos(a + .14) * size.height * 2,
            center.dy + math.sin(a + .14) * size.height * 2,
          )
          ..close(),
        ray,
      );
    }
    for (var i = 0; i < 8; i++) {
      final x = (i * 67.0 + 29) % size.width;
      final y = (i * 43.0 + 18) % (size.height * .65);
      final r = i.isEven ? 3.0 : 1.8;
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r * 2)
          ..lineTo(x + r, y)
          ..lineTo(x, y + r * 2)
          ..lineTo(x - r, y)
          ..close(),
        Paint()..color = const Color(0xffFFE192).withValues(alpha: .7),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.game != game;
}
