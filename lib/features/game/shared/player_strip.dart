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
  static const _passGreen = Color(0xff16A34A);
  static const _playBlue = Color(0xff2E6BE6);

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

  /// Exact on-screen centre of the avatar for the player at [seatIndex] (the
  /// players sorted by seat), including the strip's own horizontal scroll so
  /// animations leave from and land on the true seat. Null while the strip
  /// isn't laid out yet.
  Offset? seatGlobalCenter(int seatIndex) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final slotWidth = (size.width - 24) / 3;
    final offset = _scroll.hasClients ? _scroll.offset : 0;
    final x = origin.dx + 12 + seatIndex * slotWidth - offset + slotWidth / 2;
    final y = origin.dy + (compact ? 27 : 37);
    return Offset(x, y);
  }

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
    // Bluff round badges: "PASS" on everyone who passed, "+N" on the last
    // player to play. Both remain until the pile empties / a new rank is
    // declared (the server clears the round state).
    final bluff = s.gameState is BluffState ? s.gameState as BluffState : null;
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
            final passed = bluff?.passedPlayerIds.contains(p.id) ?? false;
            final playedCount =
                (bluff != null && !passed && p.id == bluff.lastPlayerId)
                ? bluff.lastPlayCount
                : 0;
            final avatarSize = compact ? 38.0 : 52.0;
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width - 24) / 3,
              child: Semantics(
                label:
                    '${p.displayName}${me ? ', you' : ''}${p.isBot ? ', bot' : ''}, '
                    '${p.handCount} cards'
                    '${passed ? ', passed' : ''}'
                    '${playedCount > 0 ? ', played $playedCount cards' : ''}'
                    '${turn ? ', current turn' : ''}',
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
                          if (passed || playedCount > 0)
                            IgnorePointer(
                              child: Container(
                                width: avatarSize,
                                height: avatarSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (passed ? _passGreen : _playBlue)
                                      .withValues(alpha: .78),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .6),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  passed ? 'PASS' : '+$playedCount',
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: passed
                                        ? avatarSize * .3
                                        : avatarSize * .34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: passed ? .5 : 0,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 5,
                            bottom: 7,
                            child: GestureDetector(
                              onTap: collection
                                  ? () {
                                      import_game_surfaces.inspectCollection(
                                        context,
                                        p,
                                      );
                                    }
                                  : null,
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
                                      card: collection
                                          ? p.collection.last
                                          : null,
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

/// Looks up the exact on-screen centre of a player seat from the strip's own
/// layout, so overlays can fly to the true avatar position even while the strip
/// is scrolled horizontally.
Offset? stripSeatGlobalCenter(GlobalKey stripKey, int seatIndex) {
  final state = stripKey.currentState;
  return state is _PlayerStripState ? state.seatGlobalCenter(seatIndex) : null;
}
