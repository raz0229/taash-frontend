import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import 'shared/hand_order.dart';
import 'shared/playing_card.dart';

/// Public cards stay at the center; private cards only come from HandView.
class GameSurface extends StatelessWidget {
  const GameSurface({
    super.key,
    required this.snapshot,
    required this.onCardDrop,
    required this.canDrop,
    required this.onInspectCollection,
    this.onDrawStock,
    this.onTakeDiscard,
    this.pileKey,
    this.trickKey,
    this.compact = false,
  });
  final RoomSnapshot snapshot;
  final ValueChanged<String> onCardDrop;
  final bool canDrop;
  final ValueChanged<PublicPlayer> onInspectCollection;
  final VoidCallback? onDrawStock;
  final VoidCallback? onTakeDiscard;
  final Key? pileKey;

  /// Anchors the Bhabhi trick cards so Thullu animations can launch the pile
  /// from the real trick location on the table.
  final Key? trickKey;
  final bool compact;
  String name(String id) => id == snapshot.you.id
      ? Copy.you
      : snapshot.players.where((p) => p.id == id).firstOrNull?.displayName ??
            Copy.player;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (_) => canDrop,
    onAcceptWithDetails: (d) => onCardDrop(d.data),
    builder: (context, candidates, _) => AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : T.micro,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 16, 12, compact ? 6 : 14),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xff5239A0), Color(0xff271D5B)],
          radius: .85,
        ),
        borderRadius: BorderRadius.circular(64),
        border: Border.all(
          color: candidates.isNotEmpty ? T.ochre : const Color(0xff9B82E0),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xff0C0825),
            offset: Offset(0, 7),
            blurRadius: 2,
          ),
          BoxShadow(color: Color(0x406D4DDD), blurRadius: 22),
        ],
      ),
      child: switch (snapshot.gameState) {
        final BhabhiState state => _bhabhi(state),
        final BluffState state => _bluff(state),
        final DaketiState state => _daketi(state),
        final TcState state => _tc(state),
        null => const Text(
          Copy.waitingForTheLatestRoom,
          textAlign: TextAlign.center,
        ),
      },
    ),
  );

  Widget _label(String title, {String? detail}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: T.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      if (detail != null) ...[
        const SizedBox(height: 3),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xffC7BCE8), fontSize: 11),
        ),
      ],
    ],
  );
  Widget _cards(List<Widget> children) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: compact ? 3 : 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in children)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: child,
            ),
        ],
      ),
    ),
  );
  Widget _bhabhi(BhabhiState state) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(
        state.lastThullu
            ? Copy.thullu
            : state.trick.isEmpty
            ? 'Start the trick'
            : '${CardIdentity.suitNameFor(state.leadSuit)} leads',
        detail: state.lastThullu
            ? '${name(state.lastPickupPlayerId)} picks up'
            : '${state.trick.length} cards on the room',
      ),
      KeyedSubtree(
        key: trickKey,
        child: _cards(
          state.trick.isEmpty
              ? [PlayingCard(faceDown: true, width: compact ? 46 : 66)]
              : [
                  for (final play in state.trick)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedCard(
                          key: ValueKey('${play.playerId}:${play.card}'),
                          child: PlayingCard(
                            card: play.card,
                            width: compact ? 46 : 66,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: compact ? 50 : 70,
                          child: Text(
                            name(play.playerId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: T.mint, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                ],
        ),
      ),
      Text(
        state.firstTrick
            ? 'Open with Hukum ka Yakka'
            : 'Follow suit when you can',
        style: const TextStyle(color: Color(0xffC7BCE8), fontSize: 11),
      ),
    ],
  );
  Widget _bluff(BluffState state) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(
        state.declaredRank.isEmpty
            ? 'Make your opening play'
            : 'Declared Rank: ${CardIdentity.rankNameFor(state.declaredRank)}',
        detail: state.lastPlayCount > 0
            ? '${name(state.lastPlayerId)} played ${state.lastPlayCount} cards'
            : 'Choose 2–4 cards to open',
      ),
      SizedBox(height: compact ? 6 : 10),
      Semantics(
        label: Copy.hiddenPileCards(state.pileCount),
        key: pileKey,
        child: SizedBox(
          width: 110,
          height: compact ? 76 : 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < state.pileCount; i++)
                _pileCard(state.pileCount, i),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      _label(
        '${state.pileCount} cards in the pile',
        detail: compact ? null : 'Faces stay hidden',
      ),
      if (state.pendingWinnerId.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${name(state.pendingWinnerId)} is out · challenge is still open',
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.ochre, fontSize: 12),
          ),
        ),
      if (state.passedPlayerIds.isNotEmpty)
        Text(
          '${state.passedPlayerIds.length} passed',
          style: const TextStyle(color: T.mint, fontSize: 11),
        ),
    ],
  );

  // A face-down fan that grows with the real pile count: cards shrink, bunch
  // closer and flatten as the pile gets taller so the number drawn always
  // matches `state.pileCount`.
  Widget _pileCard(int total, int index) {
    final center = (total - 1) / 2;
    final step = total <= 4
        ? 5.0
        : total <= 10
        ? 4.0
        : 3.0;
    final rotate = total <= 4
        ? .09
        : total <= 10
        ? .05
        : total <= 20
        ? .032
        : .02;
    final rise = total <= 4
        ? 1.5
        : total <= 10
        ? 1.2
        : .8;
    final width = (110 - (total - 1) * step).clamp(
      compact ? 24.0 : 28.0,
      compact ? 46.0 : 65.0,
    );
    return Transform.rotate(
      angle: (index - center) * rotate,
      child: Transform.translate(
        offset: Offset((index - center) * step, (index - center) * rise),
        child: PlayingCard(faceDown: true, width: width),
      ),
    );
  }

  void _inspectOwnCollection() {
    final me = snapshot.players
        .where((p) => p.id == snapshot.you.id)
        .firstOrNull;
    if (me != null) onInspectCollection(me);
  }

  Widget _daketi(DaketiState state) => compact
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _label(
                    'Match a rank',
                    detail: '${state.stockCount} in stock',
                  ),
                ),
                IconButton(
                  tooltip: 'Your collection',
                  onPressed: _inspectOwnCollection,
                  icon: const Icon(
                    Icons.collections_bookmark_outlined,
                    color: T.ochre,
                  ),
                ),
              ],
            ),
            _cards([
              Container(
                decoration:
                    snapshot.isYourTurn &&
                        HandGuidance.daketiMayDraw(
                          snapshot.you.hand.length,
                          state.stockCount,
                        )
                    ? BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: T.ochre,
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(5),
                      )
                    : null,
                child: PlayingCard(
                  faceDown: true,
                  width: 44,
                  onTap: onDrawStock,
                ),
              ),
              for (final card in state.playArea)
                _AnimatedCard(
                  key: ValueKey(card),
                  child: PlayingCard(card: card, width: 44),
                ),
            ]),
            if (state.playArea.isEmpty)
              const Text(
                Copy.thePlayAreaIsClear,
                style: TextStyle(fontSize: 11),
              ),
          ],
        )
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _label(
              'Match a rank. Take the cards.',
              detail: '${state.stockCount} in stock',
            ),
            _cards([
              _pile(
                'Stock',
                '${state.stockCount}',
                null,
                back: true,
                glow:
                    snapshot.isYourTurn &&
                    HandGuidance.daketiMayDraw(
                      snapshot.you.hand.length,
                      state.stockCount,
                    ),
                onTap: onDrawStock,
              ),
              for (final card in state.playArea)
                _AnimatedCard(
                  key: ValueKey(card),
                  child: PlayingCard(card: card, width: compact ? 44 : 60),
                ),
            ]),
            if (state.playArea.isEmpty)
              const Text(
                Copy.thePlayAreaIsClear,
                style: TextStyle(color: T.mint, fontSize: 11),
              ),
            TextButton.icon(
              onPressed: _inspectOwnCollection,
              style: TextButton.styleFrom(
                foregroundColor: T.ochre,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.collections_bookmark_outlined, size: 17),
              label: const Text(
                'Your collection',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
  Widget _tc(TcState state) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(
        'Build 4 + 3 + 3',
        detail: '${CardIdentity.rankNameFor(state.yarakRank)} cards are Yarak',
      ),
      _cards([
        _pile(
          Copy.stock,
          '${state.stockCount} left',
          null,
          back: true,
          glow: snapshot.isYourTurn && state.stockCount > 0,
          onTap: onDrawStock,
        ),
        _pile(
          Copy.discard,
          '${state.discardCount} cards',
          state.discardTop,
          glow: snapshot.isYourTurn && state.discardTop != null,
          onTap: onTakeDiscard,
        ),
        Container(width: 1, height: compact ? 80 : 100, color: Colors.white24),
        _pile(Copy.indicator, 'Yarak rank', state.indicator),
      ]),
    ],
  );
  Widget _pile(
    String title,
    String detail,
    String? card, {
    bool back = false,
    bool glow = false,
    VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: T.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: glow
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: T.ochre.withValues(alpha: .5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(7),
                )
              : null,
          child: (card == null && !back)
              ? Container(
                  width: compact ? 44 : 60,
                  height: compact ? 61.6 : 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(Copy.empty, style: TextStyle(fontSize: 10)),
                )
              : PlayingCard(
                  card: card,
                  faceDown: back,
                  width: compact ? 44 : 60,
                ),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          style: const TextStyle(color: Color(0xffC7BCE8), fontSize: 10),
        ),
      ],
    ),
  );
}

Future<void> inspectCollection(BuildContext context, PublicPlayer player) =>
    showTaashSheet<void>(
      context,
      SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${player.displayName}’s collection',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                Copy.collectedCardsTheLastCardIsOn(player.collection.length),
              ),
              const SizedBox(height: 20),
              if (player.collection.isEmpty)
                const Text(Copy.noCardsCollectedYet)
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final card in player.collection)
                      PlayingCard(card: card, width: 58),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Opacity(opacity: val.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
    );
  }
}
