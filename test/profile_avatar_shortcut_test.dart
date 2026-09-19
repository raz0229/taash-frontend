import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/preferences/preferences.dart';
import 'package:taash/core/storage/session_store.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/core/widgets/taash_widgets.dart';
import 'package:taash/features/profile/profile_screen.dart';
import 'package:taash/features/shop/shop_screen.dart';
import 'package:taash/l10n/copy.dart';
import 'package:taash/main.dart' show LobbyShell;

class _MemoryStore implements SessionStore {
  AuthSession? session;
  @override
  Future<AuthSession?> read() async => session;
  @override
  Future<void> write(AuthSession value) async => session = value;
  @override
  Future<void> clear() async => session = null;
}

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

  ApiClient buildApi() => ApiClient(
    config: const AppConfig(backendUrl: 'https://example.test'),
    client: MockClient((request) async {
      if (request.url.path.endsWith('/stats')) {
        return http.Response(
          jsonEncode({
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
          }),
          200,
        );
      }
      return http.Response(jsonEncode(profileJson), 200);
    }),
  );

  Future<void> pumpProfile(
    WidgetTester tester, {
    required bool own,
    VoidCallback? onAvatarTap,
  }) async {
    final api = buildApi();
    api.tokenProvider = () async => 'test-token';
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SafeArea(
            child: ProfileScreen(
              api: api,
              playerId: 'qa-user',
              own: own,
              onAvatarTap: onAvatarTap,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var i = 0; i < 20 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('own profile avatar opens Avatars when tapped', (tester) async {
    var tapped = false;
    await pumpProfile(tester, own: true, onAvatarTap: () => tapped = true);

    expect(find.text('Ayesha Khan'), findsOneWidget);
    final avatar = find.byTooltip(Copy.avatars);
    expect(avatar, findsOneWidget);
    await tester.tap(avatar);
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('own profile without onAvatarTap keeps avatar inert', (tester) async {
    await pumpProfile(tester, own: true);

    expect(find.byTooltip(Copy.avatars), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("other player's profile never navigates to Avatars", (tester) async {
    var tapped = false;
    await pumpProfile(tester, own: false, onAvatarTap: () => tapped = true);

    expect(find.byTooltip(Copy.avatars), findsNothing);
    await tester.tap(find.byType(TaashAvatar).first);
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('lobby own-profile avatar lands on the Avatars tab', (tester) async {
    final api = buildApi();
    addTearDown(api.close);
    final store = _MemoryStore()
      ..session = AuthSession(
        idToken: 'test-token',
        refreshToken: 'test-refresh',
        userId: 'qa-user',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
    final auth = AuthController(api: api, store: store);
    addTearDown(auth.dispose);
    await tester.runAsync(() => auth.restore());
    final preferences = Preferences();
    addTearDown(preferences.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LobbyShell(auth: auth, api: api, preferences: preferences),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byType(TaashAvatar).first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 400));

    Finder avatarTooltip() => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byTooltip(Copy.avatars),
    );
    for (var i = 0; i < 20 && avatarTooltip().evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(avatarTooltip(), findsOneWidget);

    await tester.tap(avatarTooltip());
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0;
        i < 20 && find.byType(BottomSheet).evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(ShopScreen), findsOneWidget);
  });
}