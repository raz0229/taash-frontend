import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/core/websocket/room_session.dart';
import 'package:taash/features/game/game_screen.dart';
import 'package:taash/l10n/copy.dart';
import 'core/core_models_test.dart' show snapshotFixture;

// Rendering fixture only; the underlying RoomSession is never connected.
class NotYourTurnSession extends RoomSession {
  NotYourTurnSession(this.value)
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

RoomSnapshot tcOutOfTurn() {
  final json = snapshotFixture(
    game: 'tc',
    hand: const ['h-2', 'h-3', 'h-4', 'h-5', 'c-7', 'e-7', 'p-7', 'p-g', 'p-b', 'p-k'],
  );
  json['current_player_id'] = 'player-b';
  return RoomSnapshot.fromJson(json);
}

RoomSnapshot daketiOutOfTurn() {
  final json = snapshotFixture(
    game: 'daketi',
    hand: const ['h-y', 'h-3', 'h-7', 'e-2'],
  );
  json['current_player_id'] = 'player-b';
  json['game_state'] = {
    'stock_count': 19,
    'play_area': <String>[],
  };
  return RoomSnapshot.fromJson(json);
}

Widget _host(RoomSnapshot s) => MaterialApp(
  theme: T.theme,
  home: GameScreen(session: NotYourTurnSession(s), onExit: () {}),
);

Future<void> _pumpNotYourTurn(WidgetTester tester, RoomSnapshot s) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(s));
  await tester.pump();
}

void main() {
  testWidgets('an action button out of turn shows a brief Wait-for-turn hint',
      (tester) async {
    await _pumpNotYourTurn(tester, tcOutOfTurn());

    await tester.tap(find.text('Claim victory'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Copy.waitForYourTurn), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // Let the hint's own timer elapse so nothing is left pending.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('the Daketi stock pile taps also hint while it is not your turn',
      (tester) async {
    await _pumpNotYourTurn(tester, daketiOutOfTurn());

    await tester.tap(find.text('Stock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Copy.waitForYourTurn), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}