import '../../core/audio/audio_system.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ads/ad_service.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/reward_sheet.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/copy.dart';
import '../../l10n/strings.dart';
import 'game_art.dart';
import 'game_tile.dart';
import 'sidelocks_wheel.dart';

/// Height of the games action band; the fixed-band slot the scroll-driven
/// action bars swap inside. Tallest of the three bars.
const _bandHeight = 132.0;

/// Pixels of vertical travel an incoming tile must cover after breaking the
/// bottom edge before the action-bar swap begins. Sized to keep every
/// supported device (small→large, normal→200% text) resting with the games
/// bar fully out — no mid-transition state on the first frame.
const _bandDeadZone = 338.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.onProfile,
    required this.onSettings,
    required this.onQuickMatch,
    required this.onCreate,
    required this.onJoin,
    required this.onPlayBots,
    required this.onLearn,
    this.adService,
  });
  final AuthController auth;
  final VoidCallback onProfile, onSettings, onJoin, onPlayBots, onLearn;
  final ValueChanged<GameType> onQuickMatch, onCreate;
  final AdService? adService;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int index = 0;
  double drag = 0;
  late final AnimationController _pulseController;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  final GlobalKey _botsKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();
  final ValueNotifier<({double bots, double how})> _actionProgress =
      ValueNotifier(const (bots: 0, how: 0));

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.9,
      upperBound: 1.15,
    )..repeat(reverse: true);
    _scheduleReveal();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    _actionProgress.dispose();
    super.dispose();
  }

  void advance(int delta) {
    final next = (index + delta).clamp(0, lobbyCards.length - 1);
    if (next != index) {
      audio.playSfx('generic_button_press');
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _claimReward() async {
    audio.playSfx('generic_button_press');
    final auth = widget.auth;
    if (auth.profile == null) return;
    await showSidelocksWheel(context, auth: auth);
    if (!mounted) return;
    // The wheel already knows the new balance, but refresh so the live chip
    // and any stale cached profile stay in sync with the server.
    await auth.refreshProfile();
  }

  void _showRewardModal() {
    final adService = widget.adService;
    final profile = widget.auth.profile;
    if (adService == null || profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => RewardSheet(adService: adService, auth: widget.auth),
    );
  }

  /// Play the focused game. A player who can't afford the entry is sent to
  /// the reward sheet instead of matchmaking.
  void _onPlay(GameType game) {
    audio.playSfx('generic_button_press');
    if ((widget.auth.profile?.coins ?? 0) < game.entryFee) {
      _showRewardModal();
      return;
    }
    widget.onQuickMatch(game);
  }

  /// Fraction (0–1) the tile under [key] has been pulled into the slot above
  /// the fixed action band. Rises to 1 while the tile is fully in view and the
  /// fixed band swaps to its action.
  ///
  /// Read the tile's position at layout time, not through a scroll
  /// notification: viewport children are painted through the previous frame's
  /// paint offset, so global transforms read stale geometry mid-fling. A
  /// post-frame recompute (see [_scheduleReveal]) always measures settled
  /// positions.
  double _revealFraction(GlobalKey key) {
    final ctx = key.currentContext;
    final box = ctx?.findRenderObject();
    final barBox = _barKey.currentContext?.findRenderObject();
    if (box is! RenderBox || barBox is! RenderBox) return 0;
    final tileTop = box.localToGlobal(Offset.zero).dy;
    final tileHeight = box.size.height;
    final barTop = barBox.localToGlobal(Offset.zero).dy;
    final barHeight = barBox.size.height;
    // How far the tile's top has risen above the bottom edge of the band.
    final slide = barTop + barHeight - tileTop;
    final window = barHeight + tileHeight - _bandDeadZone;
    if (window <= 0) return slide > 0 ? 1 : 0;
    return ((slide - _bandDeadZone) / window).clamp(0.0, 1.0);
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _actionProgress.value = _computeActionProgress();
    });
  }

  ({double bots, double how}) _computeActionProgress() =>
      (bots: _revealFraction(_botsKey), how: _revealFraction(_howKey));

  bool _onScroll(ScrollNotification notification) {
    _scheduleReveal();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.auth.profile!;
    final game = switch (lobbyCards[index]) {
      GameLobbyCard(:final game) => game,
    };
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final short = MediaQuery.sizeOf(context).height < 720;
    final tileHeight = large ? 460.0 : short ? 254.0 : 310.0;

    // Bots action: single distinct teal "Play VS Bots" button.
    final gamesBar = Container(
      height: _bandHeight,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xff131224),
        border: Border(top: BorderSide(color: Color(0xff38304F))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('lobbyPlayButton'),
              style: FilledButton.styleFrom(
                backgroundColor: T.ochre,
                foregroundColor: const Color(0xff2B1B35),
                side: const BorderSide(color: Color(0xffFFE7A0)),
                elevation: 5,
                shadowColor: const Color(0xff090812),
              ),
              onPressed: () => _onPlay(game),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Play ${game.label} · ${game.entryFee} coins'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TaashButton(
                    label: S.createRoom,
                    secondary: true,
                    icon: Icons.add_circle_outline,
                    onPressed: () {
                      audio.playSfx('generic_button_press');
                      widget.onCreate(game);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TaashButton(
                    label: S.joinRoom,
                    secondary: true,
                    icon: Icons.vpn_key_outlined,
                    onPressed: () {
                      audio.playSfx('generic_button_press');
                      widget.onJoin();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Bots action: single distinct teal "Play VS Bots" button.
    final botsBar = Container(
      height: _bandHeight,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xff131224),
        border: Border(top: BorderSide(color: Color(0xff38304F))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            Copy.practiceAgainstBots,
            textAlign: TextAlign.center,
            style: TextStyle(color: T.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('botsPlayButton'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff0E9F8E),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xff7FF3E4)),
                elevation: 5,
                shadowColor: const Color(0xff090812),
              ),
              onPressed: () {
                audio.playSfx('generic_button_press');
                widget.onPlayBots();
              },
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text(Copy.playVSBots),
            ),
          ),
        ],
      ),
    );

    // Learn action: single distinct coral "How to Play" button.
    final howBar = Container(
      height: _bandHeight,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xff131224),
        border: Border(top: BorderSide(color: Color(0xff38304F))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            Copy.stepByStepLessonsForAllFour,
            textAlign: TextAlign.center,
            style: TextStyle(color: T.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('howToPlayButton'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffA581FF),
                foregroundColor: const Color(0xff24164A),
                side: const BorderSide(color: Color(0xffD9CBFF)),
                elevation: 5,
                shadowColor: const Color(0xff090812),
              ),
              onPressed: () {
                audio.playSfx('generic_button_press');
                widget.onLearn();
              },
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text(Copy.howToPlay),
            ),
          ),
        ],
      ),
    );

    final discovery = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Row(
          children: [
            Semantics(
              label: Copy.openYourProfile,
              button: true,
              child: GestureDetector(
                onTap: () {
                  audio.playSfx('generic_button_press');
                  widget.onProfile();
                },
                child: TaashAvatar(id: profile.selectedPfp, size: 46),
              ),
            ),
            IconButton(
              tooltip: Copy.settings,
              onPressed: () {
                audio.playSfx('generic_button_press');
                widget.onSettings();
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xffCBBEEA),
              ),
            ),
            ScaleTransition(
              scale: _pulseController,
              child: IconButton(
                tooltip: 'Claim Reward',
                onPressed: _claimReward,
                icon: const Icon(Icons.card_giftcard, color: T.ochre),
              ),
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 5,
                children: [
                  GestureDetector(
                    onTap: () {
                      audio.playSfx('generic_button_press');
                      _showRewardModal();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TaashCurrencyChip(value: profile.coins),
                        const SizedBox(width: 4),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: T.ochre.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: T.ochre, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: T.ochre,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TaashCurrencyChip(value: profile.xp, xp: true),
                ],
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/brand/icon.png',
                width: 46,
                height: 46,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TaashOnline',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.8,
                      ),
                    ),
                  ),
                  Text(
                    'YOUR FRIENDS. YOUR ROOM.',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                      color: T.ochre.withValues(alpha: .9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Pick your room',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${index + 1} / ${lobbyCards.length}',
              style: const TextStyle(color: T.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Semantics(
          label: '${game.label}. ${gameDescription(game)}. '
              'Game ${index + 1} of ${lobbyCards.length}',
          onIncrease: index < lobbyCards.length - 1 ? () => advance(1) : null,
          onDecrease: index > 0 ? () => advance(-1) : null,
          child: SizedBox(
            height: tileHeight,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => index = i),
              itemCount: lobbyCards.length,
              itemBuilder: (context, i) {
                final GameLobbyCard(:game) = lobbyCards[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GameTile(game: game, focused: i == index),
                );
              },
            ),
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: Copy.previousGame,
            onPressed: index > 0 ? () => advance(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          ...List.generate(
            lobbyCards.length,
            (i) => AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : T.micro,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? T.ochre : T.outline,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          IconButton(
            tooltip: Copy.nextGame,
            onPressed: index < lobbyCards.length - 1 ? () => advance(1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.5),
          radius: 1.2,
          colors: [Color(0xff32224F), Color(0xff171429), Color(0xff10111E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                onRefresh: widget.auth.refreshProfile,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: _bandHeight + 28),
                  children: [
                    ...discovery,
                    const SizedBox(height: 12),
                    Padding(
                      key: _botsKey,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: SizedBox(
                        height: tileHeight,
                        child: const BotsGameTile(focused: true),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      key: _howKey,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: SizedBox(
                        height: tileHeight,
                        child: const HowToPlayTile(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            key: _barKey,
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<({double bots, double how})>(
              valueListenable: _actionProgress,
              builder: (context, p, _) {
                final easeBots = Curves.easeOutCubic.transform(p.bots);
                final easeHow = Curves.easeOutCubic.transform(p.how);
                return SizedBox(
                  height: _bandHeight,
                  child: Stack(
                    children: [
                      // Games bar slides down out of view as the bots tile
                      // pulls into the band slot.
                      Transform.translate(
                        offset: Offset(0, _bandHeight * easeBots),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: gamesBar,
                        ),
                      ),
                      // Bots bar pops up as the bots tile arrives, then
                      // slides out as the How-to tile takes over.
                      Transform.translate(
                        offset: Offset(0, _bandHeight * easeHow),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Opacity(
                            key: const Key('botsBar'),
                            opacity: p.bots,
                            child: Transform.scale(
                              alignment: Alignment.bottomCenter,
                              scale: .7 + .3 * easeBots,
                              child: IgnorePointer(
                                ignoring: p.bots < .01,
                                child: botsBar,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // How-to bar pops up as the How-to tile arrives.
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Opacity(
                          key: const Key('howBar'),
                          opacity: p.how,
                          child: Transform.scale(
                            alignment: Alignment.bottomCenter,
                            scale: .7 + .3 * easeHow,
                            child: IgnorePointer(
                              ignoring: p.how < .01,
                              child: howBar,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}