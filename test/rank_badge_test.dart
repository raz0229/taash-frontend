import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taash/features/profile/rank.dart';
import 'package:taash/features/profile/rank_badge.dart';

void main() {
  testWidgets('every rank has a badge that loads', (tester) async {
    for (var i = 0; i < rankNames.length; i++) {
      final loader = SvgAssetLoader(RankBadge.assetFor(i));
      final picture = await tester.runAsync(() => vg.loadPicture(loader, null));
      expect(picture, isNotNull, reason: rankNames[i]);
      picture!.picture.dispose();
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [for (var i = 0; i < 16; i++) RankBadge(number: i)],
        ),
      ),
    );
    expect(find.byType(RankBadge), findsNWidgets(16));
    expect(tester.takeException(), isNull);
  });
}
