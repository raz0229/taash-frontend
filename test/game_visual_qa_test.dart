import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/core/websocket/room_session.dart';
import 'package:taash/features/game/game_screen.dart';
import 'package:taash/features/game/game_surfaces.dart';
import 'package:taash/features/game/shared/hand_view.dart';
import 'core/core_models_test.dart' show snapshotFixture;

// Rendering fixtures only. Real transport behavior is covered separately by
// room_session_test.dart; no fixture data or session subclass ships in the app.
class VisualSession extends RoomSession {
  VisualSession(this.value)
    : super(
        config: const AppConfig(backendUrl: 'https://example.test'),
        tokenProvider: () async => null,
        playerId: 'player-a',
        observeLifecycle: false,
      ) {
    state = RoomConnectionState.connected;
  }
  final RoomSnapshot value;
  @override
  RoomSnapshot get snapshot => value;
  @override
  String get roomId => value.room.id;
}

RoomSnapshot tableFixture(GameType game, String status) {
  final cards = game == GameType.tc
      ? ['h-2', 'h-3', 'h-4', 'h-5', 'c-7', 'e-7', 'p-7', 'p-g', 'p-b', 'p-k']
      : ['h-y', 'h-3', 'h-7', 'e-2', 'c-g', 'p-b', 'p-k'];
  final json = snapshotFixture(
    game: game.wire,
    status: status,
    hand: status == 'waiting' ? [] : cards,
    reveal: status == 'finished' && game == GameType.tc ? cards : [],
  );
  final count = game.maxPlayers;
  (json['room'] as Map<String, dynamic>).addAll({
    'max_players': count,
    'player_count': status == 'waiting' ? 2 : count,
  });
  json['players'] = List.generate(
    status == 'waiting' ? 2 : count,
    (i) => {
      'id': i == 0
          ? 'player-a'
          : i == 1
          ? 'player-b'
          : 'bot-$i',
      'display_name': [
        'Ayesha',
        'Hamza',
        'Meher',
        'Ali',
        'Sana',
        'Daniyal',
        'Noor',
      ][i],
      'seat': i,
      'hand_count': status == 'waiting' ? 0 : cards.length,
      'selectedPfp': i,
      'connected': true,
      'collection': game == GameType.daketi ? ['c-7', 'e-7'] : [],
    },
  );
  json['game_state'] = switch (game) {
    GameType.bhabhi => {
      'first_trick': false,
      'lead_suit': 'h',
      'trick': [
        {'player_id': 'player-b', 'card': 'h-5'},
      ],
    },
    GameType.bluff => {
      'pile_count': 8,
      'last_play_count': 2,
      'declared_rank': '7',
      'last_player_id': 'player-b',
    },
    GameType.daketi => {
      'stock_count': 19,
      'play_area': ['h-7', 'p-3', 'c-k'],
    },
    GameType.tc => {
      'stock_count': 31,
      'discard_count': 4,
      'discard_top': 'e-3',
      'indicator': 'h-k',
      'yarak_rank': 'y',
    },
  };
  return RoomSnapshot.fromJson(json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'DM Sans',
    )..addFont(rootBundle.load('assets/fonts/DMSans.ttf'))).load();
  });
  for (final game in GameType.values) {
    for (final size in ['small', 'normal', 'large_text']) {
      testWidgets('${game.wire} table fits $size', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size == 'small'
            ? const Size(320, 640)
            : const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = VisualSession(tableFixture(game, 'active'));
        await tester.pumpWidget(
          MaterialApp(
            theme: T.theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size == 'large_text' ? 2 : 1),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: GameScreen(session: session, onExit: () {}),
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
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/table_${game.wire}_$size.png'),
        );
        if (size != 'normal') {
          final scroll = find.byKey(const ValueKey('room-scroll'));
          if (size == 'large_text') {
            await tester.drag(scroll, const Offset(0, -1600));
            await tester.pump(const Duration(milliseconds: 400));
          } else {
            expect(scroll, findsNothing);
            expect(
              tester.getBottomLeft(find.byType(GameSurface)).dy,
              lessThanOrEqualTo(tester.getTopLeft(find.byType(HandView)).dy),
              reason:
                  'The public table must fit above the pinned private hand.',
            );
            expect(
              find.text('YOUR HAND  ·  ${session.value.you.hand.length}'),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          expect(find.text('Room chat').hitTestable(), findsOneWidget);
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              'goldens/table_${game.wire}_${size}_controls.png',
            ),
          );
        }
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      });
    }
  }
  for (final status in ['waiting', 'finished']) {
    testWidgets('TC $status screen fits', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = VisualSession(tableFixture(GameType.tc, status));
      await tester.pumpWidget(
        MaterialApp(
          theme: T.theme,
          home: GameScreen(session: session, onExit: () {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/table_tc_$status.png'),
      );
      if (status == 'finished') {
        await tester.tap(find.text('View final places'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/table_tc_places.png'),
        );
      }
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }
}
