import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/auth/auth_screen.dart';
import 'package:taash/features/home/home_screen.dart';
import 'package:taash/features/home/game_tile.dart';
import 'package:taash/features/how_to_play/learn_screen.dart';
import 'package:taash/features/leaderboard/leaderboard_screen.dart';

// Test-only fixtures. These players and statistics never enter the production app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('DM Sans')
      ..addFont(rootBundle.load('assets/fonts/DMSans.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final sizes = {
    'small': const Size(320, 640),
    'normal': const Size(390, 844),
    'tall': const Size(412, 915),
    'large': const Size(480, 960),
  };
  for (final entry in sizes.entries) {
    testWidgets('Lobby ${entry.key} fits and captures', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = entry.value;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient(
        config: const AppConfig(backendUrl: 'https://example.test'),
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      final auth = AuthController(api: api)
        ..status = AuthStatus.authenticated
        ..profile = PlayerProfile(
          id: 'qa-user',
          displayName: 'Ayesha',
          coins: 2450,
          xp: 780,
          selectedPfp: 1,
          createdAt: DateTime(2026, 9, 1),
        );
      await tester.pumpWidget(
        MaterialApp(
          theme: T.theme,
          home: Scaffold(
            body: SafeArea(
              child: HomeScreen(
                auth: auth,
                onProfile: () {},
                onSettings: () {},
                onQuickMatch: (_) {},
                onCreate: (_) {},
                onJoin: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        await Future.wait(
          tester
              .widgetList<Image>(find.byType(Image))
              .map((image) => precacheImage(image.image, context)),
        );
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/lobby_${entry.key}.png'),
      );
      await tester.drag(find.text('Bhabhi'), const Offset(-260, 0));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Daketi'), findsOneWidget);
      expect(
        tester
            .widgetList<GameTile>(find.byType(GameTile))
            .where((tile) => tile.focused)
            .single
            .game,
        GameType.daketi,
      );
      expect(find.byType(GameTile), findsWidgets);
      if (entry.key == 'normal') {
        for (final game in [GameType.daketi, GameType.bluff, GameType.tc]) {
          expect(
            tester
                .widgetList<GameTile>(find.byType(GameTile))
                .singleWhere((tile) => tile.focused)
                .game,
            game,
          );
          await tester.runAsync(() async {
            final context = tester.element(find.byType(Scaffold));
            await Future.wait(
              tester
                  .widgetList<Image>(find.byType(Image))
                  .map((image) => precacheImage(image.image, context)),
            );
          });
          await tester.pump(const Duration(milliseconds: 500));
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile('goldens/lobby_${game.wire}.png'),
          );
          if (game != GameType.tc) {
            await tester.tap(find.byTooltip('Next game'));
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      api.close();
    });
  }
  testWidgets('Auth and learn survive 200 percent text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      config: const AppConfig(backendUrl: 'https://example.test'),
    );
    final auth = AuthController(api: api)..status = AuthStatus.signedOut;
    Widget wrap(Widget child) => MaterialApp(
      theme: T.theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
        child: child!,
      ),
      home: child,
    );
    await tester.pumpWidget(wrap(AuthScreen(auth: auth, onLearn: () {})));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/auth_large_text.png'),
    );
    await tester.pumpWidget(wrap(const Scaffold(body: LearnScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/learn_large_text.png'),
    );
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    api.close();
  });
  testWidgets('Leaderboard empty result explains the state', (tester) async {
    final api = ApiClient(
      config: const AppConfig(backendUrl: 'https://example.test'),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'players': []}), 200),
      ),
    )..tokenProvider = () async => 'test-token';
    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        home: Scaffold(body: LeaderboardScreen(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    api.close();
  });
}
