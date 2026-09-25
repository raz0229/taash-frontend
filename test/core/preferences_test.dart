import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taash/core/preferences/preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('background music defaults on for a new installation', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = Preferences();
    addTearDown(preferences.dispose);

    await preferences.load();

    expect(preferences.music, isTrue);
  });

  test('a saved music preference is preserved', () async {
    SharedPreferences.setMockInitialValues({'music': false});
    final preferences = Preferences();
    addTearDown(preferences.dispose);

    await preferences.load();

    expect(preferences.music, isFalse);
  });
}
