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
import 'package:taash/features/friends/friends_screen.dart';
import 'package:taash/features/home/home_screen.dart';
import 'package:taash/features/leaderboard/leaderboard_screen.dart';
import 'package:taash/features/shop/shop_screen.dart';
import 'package:taash/l10n/copy.dart';
import 'package:taash/main.dart' show LobbyShell;

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

const emptySocialJson = {
  'friends': <Object>[],
  'requests': <Object>[],
  'challenges': <Object>[],
  'sent_request_ids': <Object>[],
};

const leaderboardJson = {'leaders': <Object>[], 'total': 0};

/// Delivers a real `popRoute` platform message, the same way Android's back
/// button reaches the Flutter engine.
Future<void> pressSystemBack(WidgetTester tester) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    const MethodCall('popRoute'),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (ByteData? _) {},
  );
  await tester.pump();
}

/// The bottom-navigation destinations of the lobby shell, in tab order.
List<NavigationDestination> navigationDestinations(WidgetTester tester) => tester
    .widgetList<NavigationDestination>(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(NavigationDestination),
      ),
    )
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ApiClient buildApi() {
    final api = ApiClient(
      config: const AppConfig(backendUrl: 'https://example.test'),
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/social')) {
          return http.Response(jsonEncode(emptySocialJson), 200);
        }
        if (path.endsWith('/leaderboard')) {
          return http.Response(jsonEncode(leaderboardJson), 200);
        }
        if (path.endsWith('/stats')) {
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
    api.tokenProvider = () async => 'test-token';
    addTearDown(api.close);
    return api;
  }

  /// Counts the `SystemNavigator.pop` calls the shell makes, which is how the
  /// app actually leaves the foreground.
  List<MethodCall> recordAppExits(WidgetTester tester) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return calls;
  }

  Future<void> pumpLobby(WidgetTester tester) async {
    final api = buildApi();
    final auth = AuthController(api: api)
      ..profile = PlayerProfile.fromJson(profileJson)
      ..status = AuthStatus.authenticated;
    addTearDown(auth.dispose);
    final preferences = Preferences();
    addTearDown(preferences.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LobbyShell(auth: auth, api: api, preferences: preferences),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HomeScreen), findsOneWidget);
  }

  /// The label of the selected bottom-navigation destination.
  String selectedTab(WidgetTester tester) {
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    return navigationDestinations(tester)[bar.selectedIndex].label;
  }

  /// Taps the bottom-navigation destination carrying [label].
  Future<void> tapTab(WidgetTester tester, String label) async {
    final destination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.widgetWithText(NavigationDestination, label),
    );
    expect(destination, findsOneWidget, reason: 'no "$label" destination');
    await tester.tap(destination);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('back from each lobby tab returns to Home', (tester) async {
    final exits = recordAppExits(tester);
    await pumpLobby(tester);

    const offHome = <({String label, Type screen})>[
      (label: 'Friends', screen: FriendsScreen),
      (label: Copy.shop, screen: ShopScreen),
      (label: Copy.leaders, screen: LeaderboardScreen),
      (label: Copy.about, screen: AboutScreen),
    ];

    for (final destination in offHome) {
      await tapTab(tester, destination.label);
      expect(find.byType(destination.screen), findsOneWidget);
      expect(selectedTab(tester), destination.label);

      await pressSystemBack(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(destination.screen),
        findsNothing,
        reason: 'back from ${destination.label} must leave that tab',
      );
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(selectedTab(tester), Copy.home);
      expect(exits, isEmpty, reason: 'back must never leave the app');
    }
  });

  testWidgets('back on Home hints, and a second back inside the window exits', (
    tester,
  ) async {
    final exits = recordAppExits(tester);
    await pumpLobby(tester);

    await pressSystemBack(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(Copy.pressAgainToExitTheGame), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(exits, isEmpty, reason: 'the first back must only arm the exit');

    await pressSystemBack(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(exits, hasLength(1), reason: 'the second back exits the app');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a late back re-arms instead of exiting', (tester) async {
    final exits = recordAppExits(tester);
    await pumpLobby(tester);

    await pressSystemBack(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(Copy.pressAgainToExitTheGame), findsOneWidget);

    // Let both the hint and the arm window lapse.
    await tester.pump(const Duration(seconds: 3));
    for (
      var i = 0;
      i < 20 && find.text(Copy.pressAgainToExitTheGame).evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text(Copy.pressAgainToExitTheGame), findsNothing);

    await pressSystemBack(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(exits, isEmpty, reason: 'the arm window lapsed, so nothing exits');
    expect(find.text(Copy.pressAgainToExitTheGame), findsOneWidget);
  });

  testWidgets('an exit armed on Home is dropped when a tab is opened', (
    tester,
  ) async {
    final exits = recordAppExits(tester);
    await pumpLobby(tester);

    await pressSystemBack(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(Copy.pressAgainToExitTheGame), findsOneWidget);

    await tapTab(tester, Copy.about);
    expect(find.byType(AboutScreen), findsOneWidget);

    await pressSystemBack(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(exits, isEmpty);
    // The detour re-arms the hint instead of turning that back into an exit.
    expect(find.text(Copy.pressAgainToExitTheGame), findsOneWidget);
  });
}
