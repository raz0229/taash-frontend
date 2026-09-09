import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences extends ChangeNotifier {
  SharedPreferences? _store;
  bool sfx = true, music = false, haptics = true, reducedMotion = false;
  static const audioAvailable = true;
  Future<void> load() async {
    _store = await SharedPreferences.getInstance();
    sfx = _store!.getBool('sfx') ?? true;
    music = _store!.getBool('music') ?? false;
    haptics = _store!.getBool('haptics') ?? true;
    reducedMotion = _store!.getBool('reducedMotion') ?? false;
    notifyListeners();
  }

  Future<void> set(String key, bool value) async {
    switch (key) {
      case 'sfx':
        sfx = value;
      case 'music':
        music = value;
      case 'haptics':
        haptics = value;
      case 'reducedMotion':
        reducedMotion = value;
    }
    notifyListeners();
    await _store?.setBool(key, value);
  }

  void selection() {
    if (haptics) HapticFeedback.selectionClick();
  }
}
