import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/home/home_screen.dart';

void main() {
  testWidgets('home action bar swaps as the page scrolls', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      config: const AppConfig(backendUrl: 'https://example.test'),
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(api.close);
    final auth = AuthController(api: api)
      ..status = AuthStatus.authenticated
      ..profile = PlayerProfile(
        id: 'qa',
        displayName: 'Ayesha',
        coins: 2450,
        xp: 780,
        selectedPfp: 1,
        createdAt: DateTime(2026, 9, 1),
      );
    addTearDown(auth.dispose);

    var botsTapped = false;
    var learnTapped = false;
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
              onPlayBots: () => botsTapped = true,
              onLearn: () => learnTapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    double botsOpacity() =>
        tester.widget<Opacity>(find.byKey(const Key('botsBar'))).opacity;
    double howOpacity() =>
        tester.widget<Opacity>(find.byKey(const Key('howBar'))).opacity;

    // Resting at the top: the games action bar is fixed and the two lower
    // action bars have not popped up yet.
    expect(find.byKey(const Key('lobbyPlayButton')), findsOneWidget);
    expect(botsOpacity(), 0);
    expect(howOpacity(), 0);

    // Scroll down until the Play VS Bots tile is in view. The reveal is
    // recomputed from settled geometry in a post-frame callback that then
    // rebuilds the band on a following frame, so flush both.
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));

    // The bots button is fully popped up and tappable.
    expect(botsOpacity(), 1);
    expect(howOpacity(), lessThan(.01));
    await tester.tap(find.byKey(const Key('botsPlayButton')));
    expect(botsTapped, isTrue);

    // Scroll further up; the bots button slides away and the How-to button
    // takes over the action band.
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(howOpacity(), 1);
    await tester.tap(find.byKey(const Key('howToPlayButton')));
    expect(learnTapped, isTrue);

    // Scroll back to the top: the games action bar returns.
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(botsOpacity(), 0);
    expect(howOpacity(), 0);
    await tester.tap(find.byKey(const Key('lobbyPlayButton')));
    expect(tester.takeException(), isNull);
  });
}