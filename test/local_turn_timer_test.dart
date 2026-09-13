import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/features/game/shared/local_turn_timer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host({required int seconds, required VoidCallback onExpired}) =>
      MaterialApp(
        home: Scaffold(
          body: LocalTurnTimer(
            turnKey: 'turn:1',
            active: true,
            mine: true,
            seconds: seconds,
            onExpired: onExpired,
            accent: Colors.orange,
          ),
        ),
      );

  // The widget formats the remaining seconds as M:SS with a real Stopwatch, so
  // the countdown only advances with real wall time.
  String mmSs(WidgetTester tester) {
    final matches = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => RegExp(r'^\d+:\d{2}$').hasMatch(t));
    return matches.single;
  }

  int secondsOf(WidgetTester tester) {
    final parts = mmSs(tester).split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  testWidgets('resuming the app continues the countdown instead of resetting '
      'it', (tester) async {
    var expired = 0;
    await tester.pumpWidget(host(seconds: 90, onExpired: () => expired++));
    await tester.pump();

    // Let real time pass while foregrounded so the stopwatch records progress.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    // Poke the periodic tick so the display reflects the real elapsed time.
    await tester.pump(const Duration(seconds: 1));
    final beforePause = secondsOf(tester);

    // Minimize the app for a while.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 6)),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Background time must be excluded and the countdown must NOT restart.
    final afterResume = secondsOf(tester);
    expect(beforePause, lessThan(90));
    expect(beforePause, greaterThan(85));
    expect(afterResume, equals(beforePause));
    expect(afterResume, isNot(90));
    expect(expired, 0);
  });
}