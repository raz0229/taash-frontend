import '../../core/audio/audio_system.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ads/ad_service.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/copy.dart';
import '../../l10n/strings.dart';
import 'game_art.dart';
import 'game_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.onProfile,
    required this.onSettings,
    required this.onQuickMatch,
    required this.onCreate,
    required this.onJoin,
    this.adService,
  });
  final AuthController auth;
  final VoidCallback onProfile, onSettings, onJoin;
  final ValueChanged<GameType> onQuickMatch, onCreate;
  final AdService? adService;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int index = 0;
  double drag = 0;
  late final AnimationController _pulseController;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.9,
      upperBound: 1.15,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void advance(int delta) {
    final next = (index + delta).clamp(0, lobbyGames.length - 1);
    if (next != index) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _claimReward() async {
    final auth = widget.auth;
    final playerId = auth.profile?.id;
    if (playerId == null) return;
    try {
      final coins = await auth.api.claimThreeHourlyReward(playerId);
      await auth.refreshProfile();
      audio.playSfx('coins_added_in_hourly_reward');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claimed $coins coins!')),
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
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
      builder: (ctx) => _RewardSheet(
        adService: adService,
        auth: widget.auth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.auth.profile!, game = lobbyGames[index];
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final short = MediaQuery.sizeOf(context).height < 720;
    final actions = Container(
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
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: T.ochre,
                foregroundColor: const Color(0xff2B1B35),
                side: const BorderSide(color: Color(0xffFFE7A0)),
                elevation: 5,
                shadowColor: const Color(0xff090812),
              ),
              onPressed: () => widget.onQuickMatch(game),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Play ${game.label} · ${game.entryFee} coins'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TaashButton(
                  label: S.createRoom,
                  secondary: true,
                  icon: Icons.add_circle_outline,
                  onPressed: () => widget.onCreate(game),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TaashButton(
                  label: S.joinRoom,
                  secondary: true,
                  icon: Icons.vpn_key_outlined,
                  onPressed: widget.onJoin,
                ),
              ),
            ],
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
                onTap: widget.onProfile,
                child: TaashAvatar(id: profile.selectedPfp, size: 46),
              ),
            ),
            IconButton(
              tooltip: Copy.settings,
              onPressed: widget.onSettings,
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
                icon: const Icon(
                  Icons.card_giftcard,
                  color: T.ochre,
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 5,
                children: [
                  GestureDetector(
                    onTap: _showRewardModal,
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
              '${index + 1} / 4',
              style: const TextStyle(color: T.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Semantics(
          label:
              '${game.label}. ${gameDescription(game)}. Game ${index + 1} of 4',
          onIncrease: index < 3 ? () => advance(1) : null,
          onDecrease: index > 0 ? () => advance(-1) : null,
          child: SizedBox(
            height: large
                ? 460
                : short
                ? 254
                : 310,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => index = i),
              itemCount: 4,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GameTile(
                    game: lobbyGames[i],
                    focused: i == index,
                  ),
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
            4,
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
            onPressed: index < 3 ? () => advance(1) : null,
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
      child: large
          ? RefreshIndicator(
              onRefresh: widget.auth.refreshProfile,
              child: ListView(children: [...discovery, actions]),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.auth.refreshProfile,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: discovery,
                    ),
                  ),
                ),
                actions,
              ],
            ),
    );
  }
}

class _RewardSheet extends StatefulWidget {
  const _RewardSheet({required this.adService, required this.auth});
  final AdService adService;
  final AuthController auth;

  @override
  State<_RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends State<_RewardSheet> {
  bool _loading = false;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.adService.addListener(_onAdChanged);
  }

  @override
  void dispose() {
    widget.adService.removeListener(_onAdChanged);
    super.dispose();
  }

  void _onAdChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _watchAd() async {
    if (_loading || _processing) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessionId = await widget.auth.api.startRewardSession();
      final playerId = widget.auth.profile?.id ?? '';

      if (!mounted) return;
      setState(() => _loading = false);

      final shown = await widget.adService.showRewardedAd(
        customData: sessionId,
        userId: playerId,
        onUserEarnedReward: (amount) {
          // The reward itself arrives via the AdMob SSV callback. In local
          // development (no AdMob account / SSV callback URL yet) the callback
          // never fires, so a dev-only grant endpoint mimics it. It must be
          // disabled in production: it trusts the client.
          if (widget.auth.api.needsDevRewardGrant) {
            widget.auth.api.devGrantReward(sessionId).catchError((Object e) {});
          }
        },
      );

      if (!shown) {
        if (!mounted) return;
        setState(() => _error = 'Ad could not be shown. Please try again.');
        return;
      }

      if (!mounted) return;
      setState(() => _processing = true);

      // Poll for balance update from SSV callback
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        try {
          await widget.auth.refreshProfile();
        } catch (_) {}
        if (!mounted) return;
        if (!mounted) break;
      }

      if (!mounted) return;
      setState(() => _processing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your reward is being processed. Please check your balance shortly.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = widget.auth.profile?.coins ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: T.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.toll_rounded,
            size: 48,
            color: T.ochre,
          ),
          const SizedBox(height: 16),
          Text(
            'Need more coins?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a short ad to earn 100 coins',
            style: TextStyle(color: T.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Current balance: $coins coins',
            style: TextStyle(
              color: T.ochre,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          if (_processing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Processing your reward...',
              style: TextStyle(color: T.muted),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: T.ochre,
                  foregroundColor: const Color(0xff2B1B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (widget.adService.isReady && !_loading)
                    ? _watchAd
                    : null,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(
                  _loading ? 'Preparing...' : 'Watch Ad +100 Coins',
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (!widget.adService.isReady && !_loading) ...[
              const SizedBox(height: 12),
              Text(
                'No ad available right now. Try again shortly.',
                style: TextStyle(color: T.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
