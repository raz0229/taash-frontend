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
import 'shared/room_backdrop.dart';
import 'shared/bluff_challenge_animation.dart';
import 'shared/bhabhi_thullu_animation.dart';
import 'shared/daketi_steal_animation.dart';
import 'shared/stock_draw_animation.dart';

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
  @override
  String notice = '';
  String? takenDiscard;
  Timer? noticeTimer;
  // A6: Detect Thullu in Bhabhi and Bluff caught via broadcast. Bluff uses the
  // cinematic [BluffChallengeAnimation]; Bhabhi uses [BhabhiThulluAnimation].
  bool _lastThullu = false;
  // A13: Bluff challenge reveal, driven by the server broadcast to every seat.
  bool _bluffAnimationActive = false;
  String _lastBluffKey = '';
  OverlayEntry? _bluffOverlay;
  final GlobalKey _bluffPileKey = GlobalKey();
  final GlobalKey _playerStripKey = GlobalKey();
  // A6: Cinematic Thullu reveal in Bhabhi, shown in every seat.
  bool _thulluAnimationActive = false;
  OverlayEntry? _thulluOverlay;
  final GlobalKey _bhabhiTrickKey = GlobalKey();
  // Daketi steal: baseline card counts per player + play-area size, diffed on
  // every snapshot to detect a rake of cards off a collection or the table.
  Map<String, int>? _lastDaketiLengths;
  int? _lastDaketiPlayArea;
  bool _daketiStealActive = false;
  OverlayEntry? _daketiStealOverlay;
  final GlobalKey _daketiPlayAreaKey = GlobalKey();
  final GlobalKey _stockKey = GlobalKey();
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
    session.onBluffChallenge = _onBluffChallenge;
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
      if (_bluffAnimationActive || _thulluAnimationActive) {
        // Cinematic reveals freeze every seat's clock; resume afterwards.
        _turnTimer
          ..stop()
          ..value = 0;
      } else {
        _turnTimer.forward(from: 0);
      }
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

    // A6: Detect Thullu in Bhabhi.
    if (s.gameState is BhabhiState) {
      final bhabhi = s.gameState as BhabhiState;
      if (bhabhi.lastThullu && !_lastThullu) {
        _showBhabhiThulluAnimation(s, bhabhi);
        if (s.you.id == bhabhi.lastPickupPlayerId) {
          session.command('chat.send', payload: {'text': 'Thullu!'});
        }
      }
      _lastThullu = bhabhi.lastThullu;
    } else {
      _lastThullu = false;
    }

    if (s.gameState is DaketiState) {
      _detectDaketiSteal(s);
    } else {
      _lastDaketiLengths = null;
      _lastDaketiPlayArea = null;
    }
  }

  /// Compares the previous Daketi snapshot against [s] and, when cards were
  /// raked off another player's collection or off the play area, plays the
  /// quick hand-grab animation. Baselines are kept up to date every snapshot.
  void _detectDaketiSteal(RoomSnapshot s) {
    final state = s.gameState as DaketiState;
    final oldLengths = _lastDaketiLengths;
    final oldArea = _lastDaketiPlayArea;

    String stealerId = '';
    final victims = <String>[];
    for (final p in s.players) {
      final previous = oldLengths?[p.id];
      final now = p.collection.length;
      if (previous == null) continue;
      if (now < previous) victims.add(p.id);
      if (now > previous && stealerId.isEmpty) stealerId = p.id;
    }
    final areaCapture = oldArea != null && state.playArea.length < oldArea;

    _lastDaketiLengths = {for (final p in s.players) p.id: p.collection.length};
    _lastDaketiPlayArea = state.playArea.length;

    final hasSteal =
        stealerId.isNotEmpty && (victims.isNotEmpty || areaCapture);
    if (!hasSteal || !s.room.isActive) return;
    if (_daketiStealActive || MediaQuery.disableAnimationsOf(context)) return;

    final sorted = [...s.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final stealerSeat = sorted.indexWhere((p) => p.id == stealerId);
    final victimId = victims.isEmpty ? '' : victims.first;
    final victimInfo = victims.isEmpty
        ? null
        : s.players.where((p) => p.id == victimId).firstOrNull;
    final oldVictimCount = victimId.isEmpty ? 0 : oldLengths![victimId]!;

    _showDaketiStealAnimation(
      stealerSeat: stealerSeat < 0 ? 0 : stealerSeat,
      victimSeat: victimId.isEmpty
          ? -1
          : sorted.indexWhere((p) => p.id == victimId),
      areaCapture: areaCapture,
      areaCardCount: areaCapture
          ? (oldArea - state.playArea.length).clamp(1, 4)
          : 0,
      victimCardCount: victimInfo == null
          ? 0
          : (oldVictimCount - victimInfo.collection.length).clamp(1, 4),
    );
  }

  /// A12/Daketi: a non-blocking overlay that sweeps a hand from the stealer's
  /// seat toward whoever (or whatever) was robbed, then returns clutching the
  /// cards. It never pauses the turn clock and auto-removes itself.
  void _showDaketiStealAnimation({
    required int stealerSeat,
    required int victimSeat,
    required bool areaCapture,
    required int areaCardCount,
    required int victimCardCount,
  }) {
    setState(() => _daketiStealActive = true);
    _daketiStealOverlay?.remove();
    final entry = OverlayEntry(
      builder: (_) => DaketiStealAnimation(
        playerStripKey: _playerStripKey,
        playAreaKey: _daketiPlayAreaKey,
        stealerSeat: stealerSeat,
        victimSeat: victimSeat,
        areaCapture: areaCapture,
        areaCardCount: areaCardCount,
        victimCardCount: victimCardCount,
        onComplete: _onDaketiStealComplete,
      ),
    );
    _daketiStealOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _onDaketiStealComplete() {
    if (!mounted) return;
    _daketiStealOverlay?.remove();
    _daketiStealOverlay = null;
    setState(() => _daketiStealActive = false);
  }

  void changed() {
    if (!mounted) return;
    _reconcile();
    setState(() {});
  }

  @override
  void dispose() {
    session.onStockDecreased = null;
    session.onBluffChallenge = null;
    _stockDrawOverlay?.remove();
    _bluffOverlay?.remove();
    _thulluOverlay?.remove();
    _daketiStealOverlay?.remove();
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
    final s = session.snapshot;
    if (s == null) return;
    final sorted = [...s.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final drawerSeat = sorted.indexWhere((p) => p.id == s.currentPlayerId);
    final overlay = Overlay.of(context);
    _stockDrawOverlay?.remove();
    final entry = OverlayEntry(
      builder: (_) => StockDrawAnimation(
        playerStripKey: _playerStripKey,
        stockKey: _stockKey,
        drawerSeat: drawerSeat < 0 ? 0 : drawerSeat,
        onComplete: _onStockDrawComplete,
      ),
    );
    _stockDrawOverlay = entry;
    overlay.insert(entry);
  }

  void _onStockDrawComplete() {
    if (!mounted) return;
    _stockDrawOverlay?.remove();
    _stockDrawOverlay = null;
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

  // A13: Bluff challenge reveal. The same event reaches the challenger through
  // its command ack and every other seat through the server broadcast, so the
  // identity key deduplicates the two arrivals.
  void _onBluffChallenge(BluffChallengeEvent event) {
    if (!mounted || _bluffAnimationActive) return;
    if (event.dedupKey == _lastBluffKey) return;
    _lastBluffKey = event.dedupKey;
    _showBluffChallengeAnimation(event);
  }

  void _showBluffChallengeAnimation(BluffChallengeEvent event) {
    final s = session.snapshot;
    if (s == null) return;
    setState(() => _bluffAnimationActive = true);
    audio.playSfx('bluff_caught');
    _turnTimer.stop();

    final players = s.players;
    PublicPlayer? playerOf(String id) =>
        players.where((p) => p.id == id).firstOrNull;
    String nameOf(String id) {
      if (id == s.you.id) return Copy.you;
      return playerOf(id)?.displayName ?? id;
    }

    final challenger = playerOf(event.challenger);
    final challenged = playerOf(event.challenged);
    final sorted = [...players]..sort((a, b) => a.seat.compareTo(b.seat));
    final winnerIndex = sorted.indexWhere((p) => p.id == event.pileGoesTo);

    final sachaName = event.bluffCaught
        ? nameOf(event.challenger)
        : nameOf(event.challenged);
    final jhutaName = event.bluffCaught
        ? nameOf(event.challenged)
        : nameOf(event.challenger);

    final pileCount = switch (s.gameState) {
      final BluffState state => state.pileCount,
      _ => event.lastPlayCards.length,
    };

    _bluffOverlay?.remove();
    final entry = OverlayEntry(
      builder: (_) => BluffChallengeAnimation(
        challengerName: nameOf(event.challenger),
        challengerPfp: challenger?.selectedPfp ?? 0,
        challengedName: nameOf(event.challenged),
        challengedPfp: challenged?.selectedPfp ?? 0,
        declaredRank: event.declaredRank,
        lastPlayCards: event.lastPlayCards,
        pileCount: pileCount,
        sachaName: sachaName,
        jhutaName: jhutaName,
        pileStackKey: _bluffPileKey,
        playerStripKey: _playerStripKey,
        winnerSeatIndex: winnerIndex < 0 ? 0 : winnerIndex,
        onComplete: _onBluffAnimationComplete,
      ),
    );
    _bluffOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _onBluffAnimationComplete() {
    if (!mounted) return;
    _bluffOverlay?.remove();
    _bluffOverlay = null;
    setState(() => _bluffAnimationActive = false);
    final s = session.snapshot;
    if (s != null &&
        s.room.isActive &&
        s.currentPlayerId.isNotEmpty &&
        !_turnTimer.isAnimating) {
      _turnTimer.forward();
    }
  }

  // A6: Bhabhi Thullu reveal. The giver is the player who played the off-suit
  // card; the taker (`lastPickupPlayerId`) picks up the whole trick.
  void _showBhabhiThulluAnimation(RoomSnapshot s, BhabhiState bhabhi) {
    String giverId = '';
    for (final played in bhabhi.trick) {
      final identity = CardIdentity.parse(played.card);
      if (identity.valid && identity.suit != bhabhi.leadSuit) {
        giverId = played.playerId;
      }
    }
    final receiverId = bhabhi.lastPickupPlayerId;
    if (giverId.isEmpty || receiverId.isEmpty || bhabhi.trick.isEmpty) {
      announce(Copy.thullu);
      audio.playSfx('thullu_caught');
      return;
    }

    if (_thulluAnimationActive) return;
    setState(() => _thulluAnimationActive = true);
    audio.playSfx('thullu_caught');
    _turnTimer.stop();

    final players = s.players;
    String nameOf(String id) {
      if (id == s.you.id) return Copy.you;
      return players.where((p) => p.id == id).firstOrNull?.displayName ?? id;
    }

    final giver = players.where((p) => p.id == giverId).firstOrNull;
    final receiver = players.where((p) => p.id == receiverId).firstOrNull;
    final sorted = [...players]..sort((a, b) => a.seat.compareTo(b.seat));
    final receiverIndex = sorted.indexWhere((p) => p.id == receiverId);

    _thulluOverlay?.remove();
    final entry = OverlayEntry(
      builder: (_) => BhabhiThulluAnimation(
        giverName: nameOf(giverId),
        giverPfp: giver?.selectedPfp ?? 0,
        receiverName: nameOf(receiverId),
        receiverPfp: receiver?.selectedPfp ?? 0,
        trickCards: [for (final played in bhabhi.trick) played.card],
        pileCount: bhabhi.trick.length,
        trickKey: _bhabhiTrickKey,
        playerStripKey: _playerStripKey,
        winnerSeatIndex: receiverIndex < 0 ? 0 : receiverIndex,
        onComplete: _onThulluAnimationComplete,
      ),
    );
    _thulluOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _onThulluAnimationComplete() {
    if (!mounted) return;
    _thulluOverlay?.remove();
    _thulluOverlay = null;
    setState(() => _thulluAnimationActive = false);
    final s = session.snapshot;
    if (s != null &&
        s.room.isActive &&
        s.currentPlayerId.isNotEmpty &&
        !_turnTimer.isAnimating) {
      _turnTimer.forward();
    }
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
          // A5: The challenger also learns the outcome through this ack; the
          // full reveal is shared with everyone through the broadcast event.
          final event = BluffChallengeEvent.tryParse(result);
          if (event != null) _onBluffChallenge(event);
          if (caught) {
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
        pileKey: s.room.game == GameType.bluff ? _bluffPileKey : null,
        trickKey: s.room.game == GameType.bhabhi ? _bhabhiTrickKey : null,
        playAreaKey: s.room.game == GameType.daketi ? _daketiPlayAreaKey : null,
        stockKey: s.room.game == GameType.daketi || s.room.game == GameType.tc
            ? _stockKey
            : null,
        onCardDrop: (card) => play(card),
        canDrop: ready && mine,
        onInspectCollection: (p) => inspectCollection(context, p),
        onDrawStock: ready && mine
            ? () {
                if (s.room.game == GameType.daketi) {
                  send('daketi.draw');
                } else if (s.room.game == GameType.tc)
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
        backgroundColor: s == null
            ? const Color(0xff16112F)
            : roomBaseColor(s.room.game),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: RoomBackdrop(game: s?.room.game ?? GameType.bhabhi),
              ),
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
                            paused:
                                _bluffAnimationActive || _thulluAnimationActive,
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
                                key: _playerStripKey,
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
            ],
          ),
        ),
      ),
    );
  }
}

// Stock-draw, Daketi-steal and Thullu reveals all live in their own shared
// widgets (stock_draw_animation.dart, daketi_steal_animation.dart,
// bhabhi_thullu_animation.dart) and are driven by the overlays above.
