import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local learning progress: finished lessons and best practice streaks.
/// Purely cosmetic; nothing here is sent to the server.
class LearnProgress extends ChangeNotifier {
  LearnProgress._();
  static final instance = LearnProgress._();

  static const _doneKey = 'learn.completed.v1';
  static const _bestKey = 'learn.bestStreak.v1';

  final Set<String> _done = {};
  final Map<String, int> _best = {};
  SharedPreferences? _store;
  bool _loading = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      final store = _store = await SharedPreferences.getInstance();
      _done.addAll(store.getStringList(_doneKey) ?? const []);
      for (final entry in store.getStringList(_bestKey) ?? const <String>[]) {
        final split = entry.lastIndexOf(':');
        if (split <= 0) continue;
        final value = int.tryParse(entry.substring(split + 1));
        if (value != null) _best[entry.substring(0, split)] = value;
      }
      notifyListeners();
    } catch (_) {
      // Progress is a convenience; lessons work without storage.
    }
  }

  bool isDone(String lessonId) => _done.contains(lessonId);
  int doneCount(Iterable<String> lessonIds) => lessonIds.where(isDone).length;
  int bestStreak(String practiceId) => _best[practiceId] ?? 0;

  Future<void> complete(String lessonId) async {
    if (!_done.add(lessonId)) return;
    notifyListeners();
    try {
      await _store?.setStringList(_doneKey, _done.toList());
    } catch (_) {}
  }

  Future<void> recordStreak(String practiceId, int streak) async {
    if (streak <= bestStreak(practiceId)) return;
    _best[practiceId] = streak;
    notifyListeners();
    try {
      await _store?.setStringList(_bestKey, [
        for (final e in _best.entries) '${e.key}:${e.value}',
      ]);
    } catch (_) {}
  }
}
