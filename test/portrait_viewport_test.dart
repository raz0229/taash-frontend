import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/core/widgets/portrait_viewport.dart';

Future<Size> _canvasOn(WidgetTester tester, Size screen) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late Size seen;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => PortraitViewport(child: child!),
      home: Builder(
        builder: (context) {
          seen = MediaQuery.sizeOf(context);
          return const SizedBox.expand();
        },
      ),
    ),
  );
  return seen;
}

void main() {
  testWidgets('portrait phones pass through unchanged', (tester) async {
    expect(await _canvasOn(tester, const Size(411, 891)), const Size(411, 891));
  });

  testWidgets('landscape tablets get a centred portrait canvas', (
    tester,
  ) async {
    final canvas = await _canvasOn(tester, const Size(1280, 800));
    expect(
      canvas.width / canvas.height,
      closeTo(PortraitViewport.maxAspect, .001),
    );
    expect(canvas.height, 800);
  });

  testWidgets('portrait tablets are scaled up, not stretched', (tester) async {
    final canvas = await _canvasOn(tester, const Size(820, 1180));
    expect(canvas.width, closeTo(PortraitViewport.designWidth, .001));
    expect(
      canvas.width / canvas.height,
      closeTo(PortraitViewport.maxAspect, .001),
    );
  });
}
