import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'rank.dart';

/// The vector badge for a rank number (0 = Unranked … 15 = Mythic). Each
/// rank has its own emblem; the frame and metal step up every few ranks.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.number, this.size = 56});
  final int number;
  final double size;

  static String assetFor(int number) =>
      'assets/badges/rank_${number.clamp(0, rankNames.length - 1)}.svg';

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${rankNames[number.clamp(0, rankNames.length - 1)]} badge',
    child: SvgPicture.asset(assetFor(number), width: size, height: size),
  );
}
