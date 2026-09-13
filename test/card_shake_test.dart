import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/features/game/shared/card_shake.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Offset _shakeOffset(WidgetTester tester) {
  final transform = tester.widget<Transform>(find.byType(Transform).first);
  final translation = transform.transform.getTranslation();
  return Offset(translation.x, translation.y);
}

void main() {
  testWidgets('CardShake mounts without touching MediaQuery during initState',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const CardShake(child: SizedBox(width: 40, height: 60))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('CardShake wiggles during the shake segment, then rests',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const CardShake(child: SizedBox(width: 40, height: 60))),
    );
    await tester.pump();
    // Within the first 40% of the 1600ms cycle the card is moving.
    await tester.pump(const Duration(milliseconds: 200));
    expect(_shakeOffset(tester).dx.abs(), greaterThan(0));
    // By ~75% of the cycle the card has settled at rest.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_shakeOffset(tester).dx, moreOrLessEquals(0, epsilon: 0.0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('CardShake holds still when reduced motion is enabled',
      (tester) async {
    final data = MediaQueryData(
      size: const Size(800, 600),
      disableAnimations: true,
    );
    await tester.pumpWidget(
      MediaQuery(
        data: data,
        child: _wrap(
          const CardShake(child: SizedBox(width: 40, height: 60)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_shakeOffset(tester).dx, moreOrLessEquals(0, epsilon: 0.0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('CardShake can be torn down without leaking tickers',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const CardShake(child: SizedBox(width: 40, height: 60))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}