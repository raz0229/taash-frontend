import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/news/in_game_news_service.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/core/widgets/in_game_news.dart';

const newsUrl = 'https://news.example.test/news.json';

Map<String, Object> newsJson() => {
  'headline': 'A fresh season begins',
  'subtitle': 'Discover what is new in TaashOnline.',
  'image': 'https://images.example.test/news.jpg',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('news loads once with explicit no-cache headers', () async {
    var calls = 0;
    late http.Request capturedRequest;
    final service = InGameNewsService(
      config: const AppConfig(
        backendUrl: 'https://api.example.test',
        inGameNewsJson: newsUrl,
      ),
      client: MockClient((request) async {
        calls++;
        capturedRequest = request;
        return http.Response(jsonEncode(newsJson()), 200);
      }),
    );
    addTearDown(service.dispose);

    await Future.wait([service.load(), service.load()]);

    expect(calls, 1);
    expect(capturedRequest.url.toString(), newsUrl);
    expect(_header(capturedRequest, 'accept'), 'application/json');
    expect(_header(capturedRequest, 'cache-control'), contains('no-cache'));
    expect(_header(capturedRequest, 'cache-control'), contains('no-store'));
    expect(_header(capturedRequest, 'pragma'), 'no-cache');
    expect(service.status, InGameNewsStatus.ready);
    expect(service.news?.headline, 'A fresh season begins');
    expect(service.news?.subtitle, 'Discover what is new in TaashOnline.');
  });

  test('invalid news data is ignored quietly', () async {
    final service = InGameNewsService(
      config: const AppConfig(
        backendUrl: 'https://api.example.test',
        inGameNewsJson: newsUrl,
      ),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'headline': 'Headline',
            'subtitle': 'Subtitle',
            'image': 'javascript:alert(1)',
          }),
          200,
        ),
      ),
    );
    addTearDown(service.dispose);

    await service.load();

    expect(service.status, InGameNewsStatus.invalid);
    expect(service.news, isNull);
  });

  test('an unavailable news endpoint does not issue a request', () async {
    var calls = 0;
    final service = InGameNewsService(
      config: const AppConfig(backendUrl: 'https://api.example.test'),
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.dispose);

    await service.load();

    expect(calls, 0);
    expect(service.status, InGameNewsStatus.unavailable);
  });

  testWidgets('news dialog presents once and stays closed', (tester) async {
    final service = InGameNewsService(
      config: const AppConfig(
        backendUrl: 'https://api.example.test',
        inGameNewsJson: newsUrl,
      ),
      client: MockClient(
        (_) async => http.Response(jsonEncode(newsJson()), 200),
      ),
    );
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        home: InGameNewsCoordinator(
          service: service,
          imageProvider: const AssetImage('assets/brand/icon.png'),
          child: const Scaffold(body: Text('App content')),
        ),
      ),
    );

    unawaited(service.load());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('inGameNewsDialog')), findsOneWidget);
    expect(find.text('A fresh season begins'), findsOneWidget);
    expect(find.text('Discover what is new in TaashOnline.'), findsOneWidget);
    expect(service.consumed, isTrue);

    await tester.tap(find.byKey(const ValueKey('closeInGameNews')));
    await tester.pumpAndSettle();
    unawaited(service.load());
    await tester.pump();

    expect(find.byKey(const ValueKey('inGameNewsDialog')), findsNothing);
  });
}

String? _header(http.Request request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
