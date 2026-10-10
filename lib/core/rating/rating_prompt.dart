import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/taash_theme.dart';

/// Asks the player, now and then, to rate TaashOnline on Google Play.
///
/// The prompt is earned by finishing games: first after [firstAfterGames]
/// completed rooms, then — if the player picks "Remind me later" — again once
/// [snoozeGames] more rooms are done and [snoozeFor] has passed. Rating or
/// choosing "Don't ask again" stops it for good.
class RatingPrompt {
  RatingPrompt({SharedPreferences? store}) : _store = store;

  static const packageName = 'com.sheraztech.taash';
  static const firstAfterGames = 3;
  static const snoozeGames = 5;
  static const snoozeFor = Duration(days: 3);

  static const _gamesKey = 'rating.completedGames';
  static const _nextAtGamesKey = 'rating.nextAtGames';
  static const _snoozedUntilKey = 'rating.snoozedUntil';
  static const _doneKey = 'rating.done';

  SharedPreferences? _store;
  bool _open = false;

  Future<SharedPreferences> get _prefs async =>
      _store ??= await SharedPreferences.getInstance();

  /// Records a finished room and reports whether the prompt is now due.
  Future<bool> recordCompletedGame() async {
    try {
      final prefs = await _prefs;
      if (prefs.getBool(_doneKey) ?? false) return false;
      final games = (prefs.getInt(_gamesKey) ?? 0) + 1;
      await prefs.setInt(_gamesKey, games);
      final nextAt = prefs.getInt(_nextAtGamesKey) ?? firstAfterGames;
      final snoozedUntil = prefs.getInt(_snoozedUntilKey) ?? 0;
      return games >= nextAt &&
          DateTime.now().millisecondsSinceEpoch >= snoozedUntil;
    } catch (_) {
      return false;
    }
  }

  Future<void> show(BuildContext context) async {
    if (_open) return;
    _open = true;
    try {
      final choice = await showDialog<_RatingChoice>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _RatingDialog(),
      );
      await _apply(choice ?? _RatingChoice.later);
    } finally {
      _open = false;
    }
  }

  Future<void> _apply(_RatingChoice choice) async {
    try {
      final prefs = await _prefs;
      switch (choice) {
        case _RatingChoice.rate:
          await prefs.setBool(_doneKey, true);
          await _openStoreListing();
        case _RatingChoice.never:
          await prefs.setBool(_doneKey, true);
        case _RatingChoice.later:
          final games = prefs.getInt(_gamesKey) ?? 0;
          await prefs.setInt(_nextAtGamesKey, games + snoozeGames);
          await prefs.setInt(
            _snoozedUntilKey,
            DateTime.now().add(snoozeFor).millisecondsSinceEpoch,
          );
      }
    } catch (_) {
      // Storage is a convenience here; the worst case is an extra prompt.
    }
  }

  static Future<void> _openStoreListing() async {
    final market = Uri.parse('market://details?id=$packageName');
    final web = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    try {
      if (await launchUrl(market, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // No Play Store app; fall through to the web listing.
    }
    try {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

enum _RatingChoice { rate, later, never }

class _RatingDialog extends StatelessWidget {
  const _RatingDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, color: T.ochre, size: 30),
        Icon(Icons.star_rounded, color: T.ochre, size: 36),
        Icon(Icons.star_rounded, color: T.ochre, size: 42),
        Icon(Icons.star_rounded, color: T.ochre, size: 36),
        Icon(Icons.star_rounded, color: T.ochre, size: 30),
      ],
    ),
    title: const Text('Enjoying TaashOnline?'),
    content: const Text(
      'If you are having a good time at the table, a quick rating on '
      'Google Play helps more players find a seat. It only takes a moment.',
      textAlign: TextAlign.center,
    ),
    actionsAlignment: MainAxisAlignment.center,
    actionsOverflowButtonSpacing: 4,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, _RatingChoice.never),
        style: TextButton.styleFrom(foregroundColor: T.muted),
        child: const Text("Don't ask again"),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _RatingChoice.later),
        child: const Text('Remind me later'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _RatingChoice.rate),
        child: const Text('Rate now'),
      ),
    ],
  );
}
