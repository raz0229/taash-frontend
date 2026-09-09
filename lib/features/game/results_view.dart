import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import 'game_copy.dart';
import 'shared/celebration_overlay.dart';
import 'shared/playing_card.dart';

class ResultsView extends StatefulWidget {
  const ResultsView({super.key, required this.snapshot, required this.onHome});
  final RoomSnapshot snapshot;
  final VoidCallback onHome;
  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  bool revealDone = false;
  // B6: Trigger confetti once when entering results.
  bool showConfetti = true;

  // A7: Explorable winner hand dialog for TC.
  void _exploreWinnerHand(BuildContext context) {
    final s = widget.snapshot;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GameCopy.revealTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1 / 1.4,
            shrinkWrap: true,
            children: s.winnerHand
                .map((c) => PlayingCard(card: c, width: 60))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Copy.viewFinalPlaces),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => revealDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final reveal =
        s.room.game == GameType.tc && s.winnerHand.isNotEmpty && !revealDone;
    final winners = [...s.winners]..sort((a, b) => a.place.compareTo(b.place));
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            // B6: Larger trophy icon with gold glow.
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      T.ochre.withValues(alpha: .25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 68,
                  color: T.ochre,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              reveal ? GameCopy.revealTitle : GameCopy.resultTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: T.white,
                fontWeight: FontWeight.w800,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reveal ? GameCopy.revealDetail : GameCopy.resultDetail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: T.mint),
            ),
            const SizedBox(height: 26),
            if (reveal) ...[
              // A7: Show winner hand as a tappable card wrap with explore button.
              Wrap(
                spacing: 12,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: s.winnerHand
                    .map((c) => PlayingCard(card: c, width: 68))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  TaashButton(
                    label: 'Explore Cards',
                    onPressed: () => _exploreWinnerHand(context),
                    icon: Icons.grid_view_rounded,
                    secondary: true,
                  ),
                  TaashButton(
                    label: Copy.viewFinalPlaces,
                    onPressed: () => setState(() => revealDone = true),
                  ),
                ],
              ),
            ] else ...[
              if (winners.isEmpty)
                const Text(
                  Copy.theServerHasNotProvidedFinalPlaces,
                  style: TextStyle(color: T.mint),
                ),
              // B6: Podium-style layout for top 3.
              for (final w in winners)
                Builder(
                  builder: (context) {
                    final player = s.players
                        .where((p) => p.id == w.playerId)
                        .firstOrNull;
                    final isFirst = w.place == 1;
                    final isTop3 = w.place <= 3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaashPanel(
                        color: isFirst
                            ? const Color(0xff554729)
                            : isTop3
                            ? T.surface.withValues(alpha: .8)
                            : T.surface,
                        child: Row(
                          children: [
                            // B6: Podium place with medal icon for top 3.
                            SizedBox(
                              width: 44,
                              child: Column(
                                children: [
                                  if (isTop3)
                                    Icon(
                                      Icons.emoji_events_rounded,
                                      color: isFirst
                                          ? T.ochre
                                          : w.place == 2
                                          ? const Color(0xffC0C0C0)
                                          : const Color(0xffCD7F32),
                                      size: 22,
                                    ),
                                  Text(
                                    '${w.place}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: isFirst ? 28 : 24,
                                      color: isFirst ? T.ochre : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TaashAvatar(id: player?.selectedPfp ?? 0, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.playerId == s.you.id
                                        ? Copy.you
                                        : player?.displayName ?? Copy.player,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: isFirst ? 16 : 14,
                                    ),
                                  ),
                                  Text(
                                    s.room.game == GameType.daketi ||
                                            s.room.game == GameType.tc
                                        ? '${w.points} points'
                                        : w.place == 1
                                        ? Copy.firstPlace
                                        : Copy.place(w.place),
                                    style: const TextStyle(color: T.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 18),
              TaashButton(
                label: Copy.backToTheLobby,
                onPressed: widget.onHome,
                icon: Icons.home_outlined,
              ),
            ],
          ],
        ),
        // B6: Confetti celebration overlay.
        Positioned.fill(
          child: CelebrationOverlay(
            active: showConfetti && !reveal,
            particleCount: 60,
            duration: const Duration(seconds: 4),
            onComplete: () {
              if (mounted) setState(() => showConfetti = false);
            },
          ),
        ),
      ],
    );
  }
}
