import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/features/friends/friends_screen.dart';

void main() {
  Future<void> pumpFriends(
    WidgetTester tester, {
    String displayName = 'Friend',
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = ApiClient(
      config: const AppConfig(backendUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/v1/friends') {
          return http.Response(
            '{"friends":[{"id":"friend-1","display_name":'
            '"$displayName","country":"PK","selected_pfp":0,'
            '"online":true}],"requests":[],"sent_requests":[],'
            '"challenges":[]}',
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    final auth = AuthController(api: api);
    api.tokenProvider = () async => 'test-token';
    auth.profile = PlayerProfile(
      id: 'player-1',
      displayName: 'Player',
      coins: 1000,
      xp: 0,
      country: 'PK',
      selectedPfp: 0,
      createdAt: DateTime(2026),
    );
    addTearDown(api.close);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: FriendsScreen(
              auth: auth,
              api: api,
              onFriendProfile: (_) {},
              onRoom: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cancelling Add Friend closes without an assertion', (
    tester,
  ) async {
    await pumpFriends(tester);

    await tester.tap(find.byTooltip('Add friend by email'));
    await tester.pumpAndSettle();
    expect(find.text('Add a friend'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Add a friend'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long online friend names stay within 17 characters', (
    tester,
  ) async {
    await pumpFriends(tester, displayName: 'Abcdefghijklmnopqrstuvwxyz');

    expect(find.text('Abcdefghijklmnop…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choose a game moves character artwork up by 2 rem', (
    tester,
  ) async {
    await pumpFriends(tester);

    await tester.tap(find.text('Challenge Friends'));
    await tester.pumpAndSettle();

    final transformFinder = find.byKey(
      const ValueKey('choose-game-art-bhabhi'),
    );
    expect(transformFinder, findsOneWidget);
    final transform = tester.widget<Transform>(transformFinder);
    expect(transform.transform.getTranslation().y, -32);
  });
}
