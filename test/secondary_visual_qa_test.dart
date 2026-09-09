import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/preferences/preferences.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/about/about_screen.dart';
import 'package:taash/features/leaderboard/leaderboard_screen.dart';
import 'package:taash/features/profile/profile_screen.dart';
import 'package:taash/features/rooms/room_flow.dart';
import 'package:taash/features/settings/settings_screen.dart';
import 'package:taash/features/shop/shop_screen.dart';
import 'package:taash/main.dart' show LobbyShell;

// These isolated server-shaped fixtures are only for rendering verification.
const profileJson = {
  'id': 'qa-user',
  'display_name': 'Ayesha Khan',
  'country': 'PK',
  'coins': 2450,
  'xp': 780,
  'selected_pfp': 1,
  'unlocked_pfps': [0, 1, 2],
  'created_at': '2026-09-01T12:00:00Z',
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'DM Sans',
    )..addFont(rootBundle.load('assets/fonts/DMSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final name in [
    'lobby_shell',
    'profile',
    'shop',
    'leaderboard',
    'settings',
    'about',
    'create',
    'join',
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$name at ${scale}x text', (tester) async {
        rootBundle.evict('assets/catalogs/countries.json');
        rootBundle.evict('assets/catalogs/avatars.json');
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ApiClient(
          config: const AppConfig(backendUrl: 'https://example.test'),
          client: MockClient((request) async {
            final Object response;
            if (request.url.path.endsWith('/stats')) {
              response = {
                'stats': GameType.values
                    .map(
                      (g) => {
                        'game_type': g.wire,
                        'games_played': 12,
                        'games_won': 8,
                        'points': 2400,
                        'win_streak_count': 3,
                      },
                    )
                    .toList(),
              };
            } else if (request.url.path == '/leaderboard') {
              response = {
                'players': List.generate(
                  10,
                  (i) => {
                    'player_id': 'qa-$i',
                    'display_name': [
                      'Ayesha',
                      'Hamza',
                      'Meher',
                      'Ali',
                      'Sana',
                      'Noor',
                      'Daniyal',
                      'Saad',
                      'Zoya',
                      'Musa',
                    ][i],
                    'country': 'PK',
                    'selected_pfp': i,
                    'points': 9800 - i * 710,
                  },
                ),
              };
            } else {
              response = profileJson;
            }
            return http.Response(jsonEncode(response), 200);
          }),
        );
        final auth = AuthController(api: api)
          ..profile = PlayerProfile.fromJson(profileJson)
          ..status = AuthStatus.authenticated;
        api.tokenProvider = () async => 'test-token';
        final preferences = Preferences();
        final Widget child = switch (name) {
          'lobby_shell' => LobbyShell(
            auth: auth,
            api: api,
            preferences: preferences,
          ),
          'profile' => ProfileScreen(api: api, playerId: 'qa-user', own: true),
          'shop' => ShopScreen(auth: auth, api: api),
          'leaderboard' => LeaderboardScreen(api: api),
          'settings' => SettingsScreen(auth: auth, preferences: preferences),
          'about' => const AboutScreen(),
          _ => RoomFlow(
            mode: name == 'create' ? RoomFlowMode.create : RoomFlowMode.join,
            api: api,
            auth: auth,
            onJoin: (_) {},
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: T.theme,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(body: SafeArea(child: child)),
          ),
        );
        // Image and bundle I/O completes on the real event loop; allow that
        // work before waiting on the app's bounded UI transitions.
        await tester.runAsync(() async {
          final context = tester.element(find.byType(Scaffold).first);
          await Future.wait([
            for (var id = 0; id < 15; id++)
              precacheImage(
                ResizeImage(AssetImage('assets/pfps/$id.png'), width: 88),
                context,
              ),
          ]);
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.runAsync(() async {
          final context = tester.element(find.byType(Scaffold).first);
          await Future.wait(
            tester
                .widgetList<Image>(find.byType(Image))
                .where((image) => image.image is! NetworkImage)
                .map((image) => precacheImage(image.image, context)),
          );
        });
        await tester.pump();
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            'goldens/${name}_${scale == 1 ? 'normal' : 'large_text'}.png',
          ),
        );
        if (name == 'lobby_shell') {
          for (final label in ['Create room', 'Join by code']) {
            final trigger = find.text(label);
            if (scale > 1 && trigger.evaluate().isEmpty) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -650),
              );
              await tester.pump(const Duration(milliseconds: 500));
            }
            await tester.ensureVisible(trigger);
            await tester.tap(trigger);
            await tester.pump(const Duration(milliseconds: 500));
            expect(find.byType(BottomSheet), findsOneWidget);
            expect(find.byType(RoomFlow), findsOneWidget);
            expect(tester.takeException(), isNull);
            Navigator.of(tester.element(find.byType(RoomFlow))).pop();
            await tester.pump(const Duration(milliseconds: 500));
            expect(find.byType(RoomFlow), findsNothing);
          }
        }
        await tester.pumpWidget(const SizedBox());
        auth.dispose();
        preferences.dispose();
        api.close();
      });
    }
  }
}
