import 'core/audio/audio_system.dart';

import 'package:taash/l10n/copy.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/ads/ad_service.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/google_auth.dart';
import 'core/config/app_config.dart';
import 'core/errors/app_failure.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/models/models.dart';
import 'core/network/api_client.dart';
import 'core/preferences/preferences.dart';
import 'core/theme/taash_theme.dart';
import 'core/websocket/room_session.dart';
import 'core/widgets/taash_widgets.dart';
import 'core/update/app_update_service.dart';
import 'core/widgets/app_update_banner.dart';
import 'features/about/about_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/how_to_play/learn_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/rooms/room_flow.dart';
import 'features/settings/settings_screen.dart';
import 'features/shop/shop_screen.dart';
import 'l10n/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'DM Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await audio.init();
  final config = AppConfig.fromEnvironment();
  await bootstrapFirebase(config);
  final admobInit = MobileAds.instance.initialize();
  runApp(TaashApp(
    config: config,
    admobInitialization: admobInit,
  ));
}

Future<void> _noopAdmobInit() async {}

class TaashApp extends StatefulWidget {
  const TaashApp({
    super.key,
    required this.config,
    this.admobInitialization,
    this.auth,
    this.googleAuth,
    this.preferences,
  });
  final AppConfig config;
  final Future<void>? admobInitialization;
  final AuthController? auth;
  final GoogleAuth? googleAuth;
  final Preferences? preferences;
  @override
  State<TaashApp> createState() => _TaashAppState();
}

class _TaashAppState extends State<TaashApp> {
  late final api = () {
    final client = widget.auth?.api ?? ApiClient(config: widget.config);
    if (widget.config.enableAppCheck && !widget.config.mock) {
      client.appCheckTokenProvider = appCheckTokenProvider;
    }
    return client;
  }();
  late final googleAuth = widget.googleAuth ??
      GoogleAuth(webClientId: widget.config.firebaseWebClientId);
  late final auth =
      widget.auth ?? AuthController(api: api, googleAuth: googleAuth);
  late final preferences = widget.preferences ?? Preferences();
  late final updateService = InAppUpdateService();
  late final adService = widget.config.adMobRewardedAdUnitId.isNotEmpty ||
          widget.config.adMobInterstitialAdUnitId.isNotEmpty
      ? AdService(
          adUnitId: widget.config.adMobRewardedAdUnitId,
          interstitialAdUnitId: widget.config.adMobInterstitialAdUnitId,
          initialization: widget.admobInitialization ??
              // If a test harness provided no init future, fall back to a
              // completed future so loading starts immediately.
              _noopAdmobInit(),
        )
      : null;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await preferences.load();
    } catch (_) {
      /* Preferences remain usable in memory if storage is unavailable. */
    }
    audio.sfxEnabled = preferences.sfx;
    unawaited(updateService.checkForUpdate());
    await Future.wait([
      auth.restore(),
      Future<void>.delayed(const Duration(milliseconds: 650)),
    ]);
    if (mounted) setState(() => ready = true);
  }

  @override
  void dispose() {
    if (widget.auth == null) {
      auth.dispose();
      api.close();
    }
    if (widget.preferences == null) preferences.dispose();
    adService?.dispose();
    updateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) => MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: T.theme,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      builder: (context, child) => AppUpdateCoordinator(
        service: updateService,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.disableAnimationsOf(context) ||
                preferences.reducedMotion,
          ),
          child: child!,
        ),
      ),
      home: !ready
          ? const BootScreen()
          : _AppGate(auth: auth, api: api, preferences: preferences, adService: adService),
    ),
  );
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with SingleTickerProviderStateMixin {
  int tip = DateTime.now().second % S.tips.length;
  Timer? tipTimer;
  bool splashDone = false;
  late final AnimationController _cardSpin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => splashDone = true);
    });
    tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => tip = (tip + 1) % S.tips.length);
    });
  }

  @override
  void dispose() {
    tipTimer?.cancel();
    _cardSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Pure splash — white background with splash-screen.png
    if (!splashDone) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            'assets/brand/splash-screen.png',
            width: 200,
            height: 200,
            cacheWidth: 600,
          ),
        ),
      );
    }
    // Phase 2: Loading — dark themed with icon, card-back spinner, rotating tips
    return Scaffold(
      backgroundColor: T.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/brand/icon.png',
                  width: 100,
                  height: 100,
                  cacheWidth: 300,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                S.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: T.ink,
                ),
              ),
              const SizedBox(height: 32),
              // Card-themed loading spinner
              SizedBox(
                width: 56,
                height: 56,
                child: AnimatedBuilder(
                  animation: _cardSpin,
                  builder: (context, child) => Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .001)
                      ..rotateY(_cardSpin.value * 6.283),
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: T.coral,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: T.ochre, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: T.coral.withValues(alpha: .3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.style_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                S.loading,
                style: TextStyle(fontWeight: FontWeight.w700, color: T.muted),
              ),
              const Spacer(flex: 2),
              AnimatedSwitcher(
                duration: T.standard,
                child: Text(
                  S.tips[tip],
                  key: ValueKey(tip),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: T.mint, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return AnimatedBuilder(
                      animation: _cardSpin,
                      builder: (context, _) {
                        final v = (_cardSpin.value * 4 - i).abs();
                        final active = v < 1 || v > 3;
                        return Container(
                          width: 24,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: active ? T.ochre : T.outline,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: active ? Colors.white : Colors.transparent,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate({
    required this.auth,
    required this.api,
    required this.preferences,
    this.adService,
  });
  final AuthController auth;
  final ApiClient api;
  final Preferences preferences;
  final AdService? adService;
  void learn(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text(Copy.learnTheGames)),
        body: const SafeArea(child: LearnScreen()),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) {
      if (!api.config.isConfigured) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TaashEmpty(
                    title: S.noServerTitle,
                    message: S.noServerBody,
                    icon: Icons.chair_alt_outlined,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: TaashButton(
                    label: Copy.learnTheFourGames,
                    onPressed: () => learn(context),
                    icon: Icons.auto_stories_outlined,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (auth.isSignedIn) {
        return LobbyShell(auth: auth, api: api, preferences: preferences, adService: adService);
      }
      if (auth.status == AuthStatus.maintenance ||
          auth.status == AuthStatus.offline) {
        return Scaffold(
          body: SafeArea(
            child: TaashEmpty(
              title: auth.status == AuthStatus.maintenance
                  ? S.maintenance
                  : Copy.letSGetYouConnected,
              message: auth.error?.message ?? S.maintenanceMessage,
              onRetry: auth.restore,
              icon: auth.status == AuthStatus.maintenance
                  ? Icons.free_breakfast_outlined
                  : Icons.wifi_off,
            ),
          ),
        );
      }
      return AuthScreen(auth: auth, onLearn: () => learn(context));
    },
  );
}

class LobbyShell extends StatefulWidget {
  const LobbyShell({
    super.key,
    required this.auth,
    required this.api,
    required this.preferences,
    this.adService,
  });
  final AuthController auth;
  final ApiClient api;
  final Preferences preferences;
  final AdService? adService;
  @override
  State<LobbyShell> createState() => _LobbyShellState();
}

class _LobbyShellState extends State<LobbyShell> {
  int tab = 2;
  RoomSession? room;
  bool joining = false;

  @override
  void initState() {
    super.initState();
    if (widget.preferences.music) audio.playBgm();
  }

  Future<V?> panel<V>(Widget Function(BuildContext) builder) =>
      showModalBottomSheet<V>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        clipBehavior: Clip.antiAlias,
        builder: (sheetContext) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .9,
          child: builder(sheetContext),
        ),
      );
  void profile(String id) => panel<void>(
    (_) => ProfileScreen(
      api: widget.api,
      playerId: id,
      own: id == widget.auth.profile?.id,
    ),
  );

  Future<void> openRoom(
    RoomFlowMode mode, [
    GameType game = GameType.bhabhi,
  ]) async {
    if (joining || room != null) return;
    final summary = await panel<RoomSummary>(
      (flowContext) => RoomFlow(
        mode: mode,
        api: widget.api,
        auth: widget.auth,
        game: game,
        onJoin: (summary) => Navigator.pop(flowContext, summary),
      ),
    );
    if (summary != null && mounted) await join(summary);
  }

  Future<void> join(RoomSummary summary) async {
    if (joining || room != null) return;
    joining = true;
    final session = RoomSession(
      config: widget.api.config,
      tokenProvider: widget.auth.freshToken,
      appCheckTokenProvider: widget.api.appCheckTokenProvider,
      playerId: widget.auth.profile!.id,
      onEconomyChanged: widget.auth.refreshProfile,
    );
    audio.stopBgm();
    setState(() => room = session);
    try {
      await session.join(summary);
      await widget.auth.refreshProfile();
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    } catch (_) {
      if (mounted) {
        showNotice(context, Copy.weCouldNotConnectToTheRoom(summary.id));
      }
    } finally {
      joining = false;
    }
  }

  Future<void> exitRoom() async {
    final session = room;
    if (session == null) return;
    session.dispose();
    audio.playSfx('leave_room');
    if (widget.preferences.music) audio.playBgm();
    if (mounted) setState(() => room = null);
    _tryShowInterstitial();
    try {
      await widget.auth.refreshProfile();
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  /// Attempts to show an interstitial ad. If the ad hasn't loaded yet, waits
  /// up to 3 seconds for it to become ready before giving up.
  void _tryShowInterstitial() {
    final adService = widget.adService;
    if (adService == null) return;
    if (adService.isInterstitialReady) {
      adService.showInterstitialAd();
      return;
    }
    // Ad still loading — wait for it with a short timeout.
    late final void Function() listener;
    listener = () {
      if (adService.isInterstitialReady) {
        adService.removeListener(listener);
        adService.showInterstitialAd();
      }
    };
    adService.addListener(listener);
    Future.delayed(const Duration(seconds: 3), () {
      adService.removeListener(listener);
    });
  }

  @override
  void dispose() {
    room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (room != null) {
      return GameScreen(
        session: room!,
        preferences: widget.preferences,
        onExit: exitRoom,
        coinBalance: () => widget.auth.profile?.coins ?? 0,
        onPlayerProfile: profile,
      );
    }
    final child = switch (tab) {
      0 => const LearnScreen(),
      1 => ShopScreen(auth: widget.auth, api: widget.api),
      3 => LeaderboardScreen(api: widget.api),
      4 => const AboutScreen(),
      _ => HomeScreen(
        auth: widget.auth,
        adService: widget.adService,
        onProfile: () => profile(widget.auth.profile!.id),
        onSettings: () => panel<void>(
          (_) => SettingsScreen(
            auth: widget.auth,
            preferences: widget.preferences,
          ),
        ),
        onQuickMatch: (g) => openRoom(RoomFlowMode.quick, g),
        onCreate: (g) => openRoom(RoomFlowMode.create, g),
        onJoin: () => openRoom(RoomFlowMode.join),
      ),
    };
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          widget.preferences.selection();
          setState(() => tab = i);
        },
        height: 74,
        backgroundColor: T.surface,
        indicatorColor: T.coral.withValues(alpha: .3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            label: S.learn,
          ),
          NavigationDestination(
            icon: Icon(Icons.face_retouching_natural),
            label: S.shop,
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: S.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            label: S.leaders,
          ),
          NavigationDestination(icon: Icon(Icons.info_outline), label: S.about),
        ],
      ),
    );
  }
}
