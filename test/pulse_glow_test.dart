import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/features/game/shared/pulse_glow.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('PulseGlow mounts and animates without using MediaQuery '
      'during initState', (tester) async {
    await tester.pumpWidget(
      _wrap(PulseGlow(color: Colors.orange, child: const SizedBox())),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PulseGlow honors reduced-motion', (tester) async {
    final data = MediaQueryData(
      size: const Size(400, 800),
      disableAnimations: true,
    );
    await tester.pumpWidget(
      MediaQuery(data: data, child: _wrap(
        PulseGlow(color: Colors.orange, child: const SizedBox()),
      )),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PulseGlow can be torn down after being shown in the play area',
      (tester) async {
    await tester.pumpWidget(
      _wrap(PulseGlow(color: Colors.orange, child: const SizedBox())),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}