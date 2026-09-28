import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/news/in_game_news_service.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/core/widgets/in_game_news.dart';

const newsUrl = 'https://news.example.test/news.json';

final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

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

  testWidgets('news image keeps its frame across rebuilds', (tester) async {
    final news = InGameNews(
      headline: 'A fresh season begins',
      subtitle: 'Discover what is new in TaashOnline.',
      image: Uri.parse('https://images.example.test/news.jpg'),
    );
    Widget tree() => MaterialApp(
      theme: T.theme,
      home: Scaffold(
        body: InGameNewsDialog(news: news, imageProvider: MemoryImage(_png)),
      ),
    );

    await tester.pumpWidget(tree());
    await tester.runAsync(
      () => precacheImage(MemoryImage(_png), tester.element(find.byType(Image))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    final first = tester.widget<Image>(find.byType(Image)).image;

    await tester.pumpWidget(tree());
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(identical(tester.widget<Image>(find.byType(Image)).image, first),
        isTrue);
  });

  testWidgets('news image reports progress while downloading', (tester) async {
    final news = InGameNews(
      headline: 'A fresh season begins',
      subtitle: 'Discover what is new in TaashOnline.',
      image: Uri.parse('https://images.example.test/news.jpg'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        home: Scaffold(
          body: InGameNewsDialog(news: news, imageProvider: _PendingImage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(_PendingImage());

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Completer<ImageInfo>().future,
  );
}

String? _header(http.Request request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
