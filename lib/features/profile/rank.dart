import 'package:taash/l10n/copy.dart';
import '../../core/models/models.dart';

class RankProgress {
  const RankProgress({
    required this.number,
    required this.name,
    required this.points,
    required this.start,
    this.next,
    this.ambiguous = false,
  });
  final int number, points, start;
  final String name;
  final int? next;
  final bool ambiguous;
  bool get isMaximum => !ambiguous && number == 15;
  double get fraction => ambiguous
      ? 0
      : next == null
      ? 1
      : ((points - start) / (next! - start)).clamp(0.0, 1.0);
  int? get remaining => next == null ? null : (next! - points).clamp(0, next!);
}

const rankNames = <String>[
  Copy.unranked,
  Copy.newbie,
  Copy.rookie,
  Copy.apprentice,
  Copy.tinkerer,
  Copy.amateur,
  Copy.upNComer,
  Copy.veteran,
  Copy.hotShot,
  Copy.pro,
  Copy.expert,
  Copy.elite,
  Copy.master,
  Copy.grandmaster,
  Copy.legend,
  Copy.mythic,
];

const _standardThresholds = <int>[
  50,
  100,
  150,
  350,
  1000,
  2000,
  3000,
  5000,
  8000,
  11000,
  15000,
  20000,
  26000,
  35000,
  50000,
];
const _daketiThresholds = <int>[
  250,
  800,
  1500,
  1800,
  3000,
  6000,
  10000,
  15000,
  22000,
  30000,
  39000,
  49000,
  55000,
  75000,
  99999,
];

RankProgress rankFor(GameType game, int points) {
  // The brief's Pro threshold is non-monotonic for Bluff and zero for
  // Daketi. Do not invent progress through the disputed interval.
  final ambiguousStart = game == GameType.bluff ? 5000 : 15000;
  final ambiguousEnd = game == GameType.bluff ? 11000 : 30000;
  if ((game == GameType.bluff || game == GameType.daketi) &&
      points >= ambiguousStart &&
      points < ambiguousEnd) {
    return RankProgress(
      number: 8,
      name: rankNames[8],
      points: points,
      start: ambiguousStart,
      ambiguous: true,
    );
  }
  final thresholds = game == GameType.daketi
      ? _daketiThresholds
      : _standardThresholds;

  var number = 0;
  for (var i = 0; i < thresholds.length; i++) {
    if (thresholds[i] >= 0 && points >= thresholds[i]) number = i + 1;
  }
  return RankProgress(
    number: number,
    name: rankNames[number],
    points: points,
    start: number == 0 ? 0 : thresholds[number - 1],
    next: number == 15 ? null : thresholds[number],
  );
}
