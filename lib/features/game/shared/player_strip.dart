
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/taash_theme.dart';
import '../../../core/widgets/taash_widgets.dart';
import '../../../l10n/copy.dart';
import 'playing_card.dart';
import '../game_surfaces.dart' as import_game_surfaces;

class PlayerStrip extends StatefulWidget {
  const PlayerStrip({
    super.key,
    required this.snapshot,
    required this.onPlayerTap,
    this.onEmojiTap,
    this.turnTimer,
  });
  final RoomSnapshot snapshot;
  final ValueChanged<PublicPlayer> onPlayerTap;
  final ValueChanged<PublicPlayer>? onEmojiTap;
  final Animation<double>? turnTimer;
  @override
  State<PlayerStrip> createState() => _PlayerStripState();
}

class _PlayerStripState extends State<PlayerStrip>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  bool userScrolling = false;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void initState() {
    super.initState();
    revealTurn();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlayerStrip old) {
    super.didUpdateWidget(old);
    if (old.snapshot.currentPlayerId != widget.snapshot.currentPlayerId) {
      revealTurn();
    }
  }

  void revealTurn() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scroll.hasClients || userScrolling) return;
    final players = [...widget.snapshot.players]
      ..sort((a, b) => a.seat.compareTo(b.seat));
    final index = players.indexWhere(
      (p) => p.id == widget.snapshot.currentPlayerId,
    );
    if (index < 0) return;
    final stride = (MediaQuery.sizeOf(context).width - 24) / 3;
    _scroll.animateTo(
      (index * stride).clamp(0, _scroll.position.maxScrollExtent),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : T.standard,
      curve: Curves.easeOutCubic,
    );
  });
  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final players = [...s.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final compact = MediaQuery.sizeOf(context).height < 720;
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return SizedBox(
      height: large
          ? 156
          : compact
          ? 86
          : 116,
      child: NotificationListener<ScrollNotification>(
        onNotification: (e) {
          if (e is ScrollStartNotification && e.dragDetails != null) {
            userScrolling = true;
          }
          if (e is ScrollEndNotification) userScrolling = false;
          return false;
        },
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final p = players[index], me = p.id == s.you.id;
            final turn = s.room.isActive && p.id == s.currentPlayerId;
            final collection =
                s.room.game == GameType.daketi && p.collection.isNotEmpty;
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width - 24) / 3,
              child: Semantics(
                label:
                    '${p.displayName}${me ? ', you' : ''}${p.isBot ? ', bot' : ''}, ${p.handCount} cards${turn ? ', current turn' : ''}',
                child: Column(
                  children: [
                    SizedBox(
                      height: compact ? 54 : 74,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) => Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: turn
                                      ? T.ochre
                                      : const Color(0xff7A659E),
                                  width: turn ? 2 : 1,
                                ),
                                boxShadow: turn
                                    ? [
                                        BoxShadow(
                                          color: T.ochre.withValues(
                                            alpha: .12 + _pulse.value * .15,
                                          ),
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: InkWell(
                                onTap: () => widget.onPlayerTap(p),
                                customBorder: const CircleBorder(),
                                child: TaashAvatar(
                                  id: p.selectedPfp,
                                  size: compact ? 38 : 52,
                                ),
                              ),
                            ),
                          ),
                          if (turn && widget.turnTimer != null)
                            IgnorePointer(
                              child: SizedBox(
                                width: compact ? 50 : 68,
                                height: compact ? 50 : 68,
                                child: AnimatedBuilder(
                                  animation: widget.turnTimer!,
                                  builder: (context, _) =>
                                      CircularProgressIndicator(
                                        value: 1 - widget.turnTimer!.value,
                                        strokeWidth: 2,
                                        color: T.ochre,
                                        backgroundColor: Colors.white12,
                                      ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 5,
                            bottom: 7,
                            child: GestureDetector(
                              onTap: collection ? () {
                                import_game_surfaces.inspectCollection(context, p);
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff21153D),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xff9A81C3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PlayingCard(
                                      card: collection ? p.collection.last : null,
                                      faceDown: !collection,
                                      width: 11,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${collection ? p.collection.length : p.handCount}',
                                      textScaler: TextScaler.noScaling,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!p.connected && !p.isBot)
                            const Positioned(
                              left: 8,
                              top: 8,
                              child: Icon(
                                Icons.cloud_off,
                                color: T.ochre,
                                size: 16,
                              ),
                            ),
                          if (widget.onEmojiTap != null)
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  tooltip:
                                      'Send a reaction to ${me ? 'yourself' : p.displayName}',
                                  onPressed: () => widget.onEmojiTap!(p),
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(40, 40),
                                    backgroundColor: const Color(0xff332251),
                                  ),
                                  icon: const Icon(
                                    Icons.add_reaction_outlined,
                                    size: 18,
                                    color: T.ochre,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: turn ? T.ochre : const Color(0xff30234F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        me ? Copy.you : p.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: turn ? const Color(0xff291833) : T.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (large) const SizedBox(height: 3),
                    if (!compact || large)
                      Text(
                        turn
                            ? 'YOUR TURN'.replaceFirst(
                                'YOUR',
                                me ? 'YOUR' : 'THEIR',
                              )
                            : p.isBot
                            ? 'BOT'
                            : 'SEAT ${p.seat + 1}',
                        style: TextStyle(
                          color: turn ? T.ochre : const Color(0xffB2A4CD),
                          fontSize: 8,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
