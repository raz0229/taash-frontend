import '../../core/audio/audio_system.dart';

import 'package:taash/l10n/copy.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/preferences/preferences.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/websocket/room_session.dart';
import '../../core/widgets/taash_widgets.dart';
import '../chat/chat_sheet.dart';
import '../chat/reactions.dart';
import 'game_copy.dart';
import 'game_surfaces.dart';
import 'results_view.dart';
import 'shared/hand_order.dart';
import 'shared/hand_view.dart';
import 'shared/local_turn_timer.dart';
import 'shared/player_strip.dart';
import 'shared/playing_card.dart';
import 'shared/room_backdrop.dart';
import 'shared/celebration_overlay.dart';

part 'game_menus.dart';
part 'game_status.dart';
part 'game_actions.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.session,
    required this.onExit,
    this.coinBalance,
    this.onPlayerProfile,
    this.preferences,
  });
  final RoomSession session;
  final VoidCallback onExit;
  final int Function()? coinBalance;
  final ValueChanged<String>? onPlayerProfile;
  final Preferences? preferences;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, _GameMenus, _GameStatus, _GameActions {
  @override
  final hand = HandOrder();
  @override
  bool muted = false;
  @override
  bool chatOpen = false;
  @override
  bool leaving = false;
  bool working = false;
  @override
  int readCount = 0;
  int turnSerial = 0;
  String lastTurn = '';
  int _lastHandCount = -1;
  int _lastPlayAreaLength = -1;
  String? _lastCelebratedChatId;
  @override
  String notice = '';
  String? takenDiscard;
  Timer? noticeTimer;
  // A5/A6: Celebration state for Thullu and bluff caught events.
  bool showCelebration = false;
  String? celebrationText;
  Color celebrationColor = T.ochre;
  bool _lastThullu = false;
  @override
  RoomSession get session => widget.session;
  bool _played10sSound = false;
  late final AnimationController _turnTimer =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))
        ..addListener(() {
          if (!mounted || !(session.snapshot?.isYourTurn ?? false)) return;
          final remaining =
              (_turnTimer.duration!.inMilliseconds * (1 - _turnTimer.value))
                  .round();
          if (remaining <= 10000 && remaining > 0 && !_played10sSound) {
            _played10sSound = true;
            audio.playSfx('10_seconds_remaining_until_your_turn_expires');
          }
        })
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed &&
              (session.snapshot?.isYourTurn ?? false)) {
            leave(expired: true);
          }
        });

  @override
  void initState() {
    super.initState();
    session.onStockDecreased = _onStockDecreased;
    session.addListener(changed);
    _reconcile();
  }

  void _resetTurnTimer() {
    final s = session.snapshot;
    if (s == null) return;
    turnSerial++;
    _turnTimer.duration = Duration(
      seconds: s.room.game == GameType.tc ? 120 : 60,
    );
    _played10sSound = false;
    if (s.room.isActive && s.currentPlayerId.isNotEmpty) {
      _turnTimer.forward(from: 0);
    } else {
      _turnTimer.stop();
      _turnTimer.value = 0;
    }
  }

  void _reconcile() {
    final s = session.snapshot;
    if (s == null) return;
    hand.reconcile(s.you.hand);

    final currentPlayer = s.players
        .where((p) => p.id == s.currentPlayerId)
        .firstOrNull;
    final handCount = currentPlayer?.handCount ?? 0;

    if (lastTurn != s.currentPlayerId) {
      lastTurn = s.currentPlayerId;
      takenDiscard = null;
      _lastHandCount = handCount;
      _lastPlayAreaLength = s.gameState is DaketiState
          ? (s.gameState as DaketiState).playArea.length
          : -1;
      _resetTurnTimer();
    } else if (_lastHandCount != handCount) {
      _lastHandCount = handCount;
      _resetTurnTimer();
    } else if (s.gameState is DaketiState) {
      final playAreaLength = (s.gameState as DaketiState).playArea.length;
      if (_lastPlayAreaLength != playAreaLength) {
        _lastPlayAreaLength = playAreaLength;
        _resetTurnTimer();
      }
    }

    if (s.you.hand.length == 10) takenDiscard = null;

    final lastChat = session.chat.lastOrNull;
    if (lastChat != null &&
        lastChat.text == 'Bluff Caught!' &&
        lastChat.id != _lastCelebratedChatId) {
      _lastCelebratedChatId = lastChat.id;
      if (lastChat.playerId != session.playerId) {
        _triggerCelebration('BLUFF', T.coral);
      }
    }
    // A6: Detect Thullu in Bhabhi.
    if (s.gameState is BhabhiState) {
      final bhabhi = s.gameState as BhabhiState;
      if (bhabhi.lastThullu && !_lastThullu) {
        _triggerCelebration('THULLU!', T.ochre);
        if (s.you.id == bhabhi.lastPickupPlayerId) {
          session.command('chat.send', payload: {'text': 'Thullu!'});
        }
      }
      _lastThullu = bhabhi.lastThullu;
    } else {
      _lastThullu = false;
    }
  }

  void changed() {
    if (!mounted) return;
    _reconcile();
    setState(() {});
  }

  @override
  void dispose() {
    session.onStockDecreased = null;
    _stockDrawOverlay?.remove();
    session.removeListener(changed);
    noticeTimer?.cancel();
    _turnTimer.dispose();
    super.dispose();
  }

  void _onStockDecreased() {
    if (!mounted) return;
    _showStockDrawAnimation();
  }

  OverlayEntry? _stockDrawOverlay;
  void _showStockDrawAnimation() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final overlay = Overlay.of(context);
    _stockDrawOverlay?.remove();
    final entry = OverlayEntry(builder: (_) => const _StockDrawAnimation());
    _stockDrawOverlay = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_stockDrawOverlay == entry) {
        _stockDrawOverlay = null;
        entry.remove();
      }
    });
  }

  @override
  void announce(String text) {
    if (!mounted) return;
    noticeTimer?.cancel();
    setState(() => notice = text);
    noticeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => notice = '');
    });
  }

  @override
  void dismissBanner() {
    noticeTimer?.cancel();
    session.clearError();
    if (mounted && notice.isNotEmpty) setState(() => notice = '');
  }

  void _triggerCelebration(String text, Color color) {
    if (!mounted) return;
    if (text == 'THULLU!') audio.playSfx('thullu_caught');
    if (text == 'BLUFF') audio.playSfx('bluff_caught');
    setState(() {
      showCelebration = true;
      celebrationText = text;
      celebrationColor = color;
    });
  }

  @override
  Future<void> leave({bool expired = false}) async {
    if (leaving) return;
    if (!expired && !(session.snapshot?.room.isFinished ?? false)) {
      if (!await confirmAction(
            context,
            title: GameCopy.leaveTitle,
            message: GameCopy.leaveMessage,
            confirmLabel: Copy.leaveRoom,
          ) ||
          !mounted) {
        return;
      }
    }
    setState(() => leaving = true);
    if (expired) announce(GameCopy.timerExpired);
    try {
      // A4: Auto-send 'Leaving' chat message before leaving an active room.
      if (session.connected &&
          (session.snapshot?.room.isActive ?? false) &&
          session.canSend) {
        try {
          await session.command('chat.send', payload: {'text': 'Leaving'});
        } catch (_) {
          // Best-effort: don't block the leave if chat fails.
        }
      }
      await session.leave();
      if (mounted) widget.onExit();
    } catch (_) {
      if (mounted) {
        setState(() => leaving = false);
        announce(Copy.weCouldNotConfirmLeavingCheckYour);
      }
    }
  }

  @override
  Future<void> send(String command, {Map<String, dynamic>? payload}) async {
    if (working || !session.canSend) return;
    final beforeState = session.snapshot?.gameState;
    final pickedDiscard = command == 'tc.take_discard' && beforeState is TcState
        ? beforeState.discardTop
        : null;
    setState(() => working = true);
    try {
      final response = await session.command(command, payload: payload);
      final result = response['result'];
      if (result is Map && result['type'] == 'bluff.challenge_result') {
        final data = result['data'];
        if (data is Map) {
          final caught = data['bluff_caught'] == true;
          announce(
            caught
                ? Copy.bluffCaughtThePreviousPlayerTakesThe
                : Copy.anHonestPlayYouTakeThePile,
          );
          // A5: Trigger bluff caught animation.
          if (caught) {
            _triggerCelebration('BLUFF', T.coral);
            session.command('chat.send', payload: {'text': 'Bluff Caught!'});
          }
        }
      }
      if (command == 'tc.take_discard') takenDiscard = pickedDiscard;
      if (command != 'chat.anim' &&
          session.connected &&
          !(session.snapshot?.room.isFinished ?? false)) {
        await session.requestSnapshot();
      }
      if (mounted) {
        hand.clearSelection();
        widget.preferences?.selection();
      }
    } on AppFailure catch (e) {
      announce(e.message);
    } catch (_) {
      announce(GameCopy.actionFailed);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  bool allowed(String card) {
    final s = session.snapshot;
    if (s == null) return false;
    final state = s.gameState;
    if (state is BhabhiState) {
      return HandGuidance.bhabhiCardAllowed(
        card,
        s.you.hand,
        firstTrick: state.firstTrick,
        trick: state.trick.map((p) => p.card).toList(),
      );
    }
    if (state is TcState) {
      return HandGuidance.tcMayDiscard(s.you.hand.length, card, takenDiscard);
    }
    return true;
  }

  @override
  Future<void> play([String? dropped]) async {
    final s = session.snapshot;
    if (s == null || !s.isYourTurn || !session.canSend || working) return;
    if (dropped != null && !hand.selected.contains(dropped)) {
      hand.toggle(dropped, limit: s.room.game == GameType.bluff ? 4 : 1);
      setState(() {});
    }
    final cards = hand.selected.toList();
    if (cards.isEmpty) return;
    switch (s.room.game) {
      case GameType.bhabhi:
        if (allowed(cards.single)) {
          await send('bhabhi.play_card', payload: {'card': cards.single});
        } else {
          announce(Copy.followTheLeadSuitWhenYouHave);
        }
      case GameType.daketi:
        await send('daketi.play_card', payload: {'card': cards.single});
      case GameType.tc:
        if (!allowed(cards.single)) {
          announce(GameCopy.tcPickupRule);
          return;
        }
        if (await confirmAction(
              context,
              title: Copy.discard2(CardIdentity.parse(cards.single).label),
              message: Copy.thisEndsYourTurnYourRemainingCards,
              confirmLabel: Copy.discard,
            ) &&
            mounted) {
          await send('tc.discard', payload: {'card': cards.single});
        }
      case GameType.bluff:
        final state = s.gameState as BluffState;
        if (!HandGuidance.bluffSelectionAllowed(
          cards.length,
          emptyPile: state.pileCount == 0,
        )) {
          announce(GameCopy.bluffOpening);
          return;
        }
        String? rank = state.declaredRank;
        if (state.pileCount == 0) {
          rank = await showTaashSheet<String>(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Copy.whatRankDoYouDeclare,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(Copy.yourCardsStayHiddenThisIsThe(cards.length)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CardIdentity.ranks
                      .map(
                        (r) => ActionChip(
                          label: Text(CardIdentity.rankNameFor(r)),
                          onPressed: () => Navigator.pop(context, r),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        }
        if (rank == null || !mounted) return;
        await send(
          'bluff.play_cards',
          payload: {
            'cards': cards,
            if (state.pileCount == 0) 'declared_rank': rank,
          },
        );
    }
  }

  Widget _roomArea(RoomSnapshot s, bool ready, bool mine) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        child: Row(
          children: [
            Icon(
              mine ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
              color: T.ochre,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mine
                    ? Copy.yourTurn2(_instruction(s))
                    : '${s.players.where((p) => p.id == s.currentPlayerId).firstOrNull?.displayName ?? 'Another player'}’s turn',
                style: const TextStyle(
                  color: T.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      GameSurface(
        snapshot: s,
        compact:
            MediaQuery.sizeOf(context).height < 720 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.4,
        onCardDrop: (card) => play(card),
        canDrop: ready && mine,
        onInspectCollection: (p) => inspectCollection(context, p),
        onDrawStock: ready && mine
            ? () {
                if (s.room.game == GameType.daketi)
                  send('daketi.draw');
                else if (s.room.game == GameType.tc)
                  send('tc.draw_stock');
              }
            : null,
        onTakeDiscard: ready && mine ? () => send('tc.take_discard') : null,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = session.snapshot;
    final finished = s?.room.isFinished ?? false;
    final active = s?.room.isActive ?? false;
    final terminal = [
      RoomConnectionState.roomUnavailable,
      RoomConnectionState.sessionExpired,
      RoomConnectionState.closed,
    ].contains(session.state);
    final ready = active && session.canSend && !working && !leaving;
    final mine = s?.isYourTurn ?? false;
    return PopScope(
      // A12: Allow back when room is finished; block during active play.
      canPop: finished,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xff16112F),
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: RoomBackdrop()),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s?.room.game.label ?? Copy.taashonline,
                                style: const TextStyle(
                                  color: T.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                session.roomId ?? Copy.connecting,
                                style: const TextStyle(
                                  color: T.mint,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          LocalTurnTimer(
                            turnKey: '$lastTurn:$turnSerial',
                            active: session.connected && !terminal,
                            mine: mine,
                            seconds: s!.room.game == GameType.tc ? 120 : 60,
                            onExpired: () => leave(expired: true),
                          ),
                        IconButton(
                          tooltip: Copy.roomOptions,
                          onPressed: options,
                          icon: const Icon(Icons.more_horiz, color: T.white),
                        ),
                      ],
                    ),
                  ),
                  if (!session.connected ||
                      notice.isNotEmpty ||
                      session.error != null)
                    _banner(terminal),
                  if (s == null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!terminal)
                                const CircularProgressIndicator(color: T.ochre),
                              const SizedBox(height: 20),
                              Text(
                                terminal
                                    ? Copy.yourSeatIsUnavailable
                                    : GameCopy.syncing,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: T.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 23,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                session.error?.message ??
                                    Copy.weReWaitingForTheServerTo,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: T.mint),
                              ),
                              const SizedBox(height: 24),
                              TaashButton(
                                label: Copy.backToLobby,
                                secondary: false,
                                onPressed: () => leave(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (finished)
                    Expanded(
                      child: ResultsView(snapshot: s, onHome: () => leave()),
                    )
                  else
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Keep the hand and actions in reach on phones. Enlarged
                          // text can use a single scrolling layout without clipping.
                          final scrollPage =
                              active &&
                              (constraints.maxHeight < 460 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.4);
                          final content = Column(
                            children: [
                              PlayerStrip(
                                snapshot: s,
                                onPlayerTap: playerMenu,
                                onEmojiTap: reactionPicker,
                                turnTimer: _turnTimer,
                              ),
                              if (s.room.isWaiting)
                                Expanded(child: _waiting(s))
                              else if (scrollPage)
                                _roomArea(s, ready, mine)
                              else
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _roomArea(s, ready, mine),
                                  ),
                                ),
                              if (active)
                                HandView(
                                  hand: hand,
                                  onChanged: () => setState(() {}),
                                  multiSelect: s.room.game == GameType.bluff,
                                  canSelect: ready && mine,
                                  canPlay: allowed,
                                  isYourTurn: mine,
                                  allowSort:
                                      s.room.game == GameType.bhabhi ||
                                      s.room.game == GameType.bluff,
                                  sortByRank: s.room.game == GameType.bluff,
                                ),
                              if (active)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: scrollPage
                                        ? double.infinity
                                        : MediaQuery.sizeOf(context).height *
                                              .25,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        4,
                                      ),
                                      child: _actions(s, ready && mine),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: openChat,
                                        icon: Badge(
                                          label: Text(
                                            '${(session.chat.length - readCount).clamp(0, 200)}',
                                          ),
                                          isLabelVisible:
                                              !chatOpen &&
                                              !muted &&
                                              session.chat.length > readCount,
                                          child: const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 19,
                                          ),
                                        ),
                                        label: Text(
                                          muted
                                              ? Copy.chatMuted
                                              : session.chat.isEmpty
                                              ? Copy.roomChat
                                              : '${session.chat.last.playerId == session.playerId ? 'You' : session.chat.last.displayName}: ${session.chat.last.text}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: T.mint,
                                        ),
                                      ),
                                    ),
                                    if (session.busy || working)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: SizedBox(
                                          width: 17,
                                          height: 17,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: T.ochre,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                          return scrollPage
                              ? SingleChildScrollView(
                                  key: const ValueKey('room-scroll'),
                                  child: content,
                                )
                              : content;
                        },
                      ),
                    ),
                ],
              ),
              if (s != null)
                Positioned.fill(
                  child: ReactionOverlay(
                    events: session.animations,
                    players: s.players,
                    selfId: session.playerId,
                    muted: muted,
                  ),
                ),
              // A5/A6: Celebration overlay for Thullu and bluff caught.
              Positioned.fill(
                child: CelebrationOverlay(
                  active: showCelebration,
                  text: celebrationText,
                  textColor: celebrationColor,
                  onComplete: () {
                    if (mounted) setState(() => showCelebration = false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a face-down card flying up from the stock pile to the current
/// player's seat (the strip at the top) when the stock decreases.
class _StockDrawAnimation extends StatefulWidget {
  const _StockDrawAnimation();

  @override
  State<_StockDrawAnimation> createState() => _StockDrawAnimationState();
}

class _StockDrawAnimationState extends State<_StockDrawAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const cardWidth = 52.0;
    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeIn.transform(_controller.value);
              return Positioned(
                left: size.width / 2 - cardWidth / 2,
                top: size.height * .58 - t * size.height * .52,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: const SizedBox(
              width: cardWidth,
              height: cardWidth * 1.4,
              child: PlayingCard(faceDown: true),
            ),
          ),
        ],
      ),
    );
  }
}
