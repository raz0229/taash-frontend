import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import 'game_art.dart';

class GameTile extends StatelessWidget {
  const GameTile({super.key, required this.game, required this.focused});
  final GameType game;
  final bool focused;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: focused ? gameColor(game).withValues(alpha: .9) : Colors.white24,
        width: 1.5,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          gameColor(game),
          Color.lerp(gameColor(game), Colors.black, .55)!,
        ],
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: GameArt(game: game)),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xA01C1536),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${game.minPlayers}–${game.maxPlayers} PLAYERS',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
          color: const Color(0xff211A36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game.label,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                  ),
                  Icon(Icons.style_rounded, color: gameColor(game), size: 23),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                gameDescription(game),
                style: const TextStyle(color: Color(0xffC7BED9), fontSize: 11),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.toll, color: T.ochre, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${game.entryFee} entry',
                    style: const TextStyle(
                      color: T.ochre,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.people_outline, color: T.muted, size: 17),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
