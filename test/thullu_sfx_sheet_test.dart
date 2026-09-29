import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taash/core/auth/auth_controller.dart';
import 'package:taash/core/config/app_config.dart';
import 'package:taash/core/models/models.dart';
import 'package:taash/core/network/api_client.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/features/shop/thullu_sfx_sheet.dart';
import 'package:taash/l10n/copy.dart';

/// The player owns only the free default plus Bhola Meme.
const profileJson = {
  'id': 'qa-user',
  'display_name': 'Ayesha Khan',
  'country': 'PK',
  'coins': 9000,
  'xp': 780,
  'selected_pfp': 1,
  'unlocked_pfps': [0, 1],
  'selected_thullu_sfx': 2,
  'unlocked_thullu_sfx': [0, 2],
  'created_at': '2026-09-01T12:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AuthController> pumpSheet(WidgetTester tester) async {
    final api = ApiClient(
      config: const AppConfig(backendUrl: 'https://example.test'),
      client: MockClient(
        (request) async => http.Response(jsonEncode(profileJson), 200),
      ),
    );
    api.tokenProvider = () async => 'test-token';
    addTearDown(api.close);
    final auth = AuthController(api: api)
      ..profile = PlayerProfile.fromJson(profileJson)
      ..status = AuthStatus.authenticated;
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: T.theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SafeArea(
            child: ThulluSfxSheet(auth: auth, api: api),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    for (
      var i = 0;
      i < 20 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 500));
    return auth;
  }

  testWidgets('in-room picker lists only owned sounds', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Bhola Meme'), findsOneWidget);

    // Everything else in the soundboard is still locked and must not appear.
    for (final locked in [
      'Ye Le Meme',
      'Baby Cry',
      'Dog Whine',
      'Vine Boom',
      'Bruh',
      'Clown Horn',
      'Bhola Meme 2',
    ]) {
      expect(find.text(locked), findsNothing, reason: '$locked is not owned');
    }
  });

  // The picker is a switch between owned sounds, not a store, so it must never
  // offer to spend coins.
  testWidgets('in-room picker never offers to unlock or charge', (tester) async {
    await pumpSheet(tester);

    expect(find.text(Copy.unlock), findsNothing);
    expect(find.text(Copy.unlockFree), findsNothing);
    expect(find.text(Copy.moreCoinsNeeded), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('in-room picker marks the current sound and selects the rest', (
    tester,
  ) async {
    await pumpSheet(tester);

    // The picked clip is read-only; the other owned clip offers Select.
    expect(find.text(Copy.selected), findsOneWidget);
    expect(find.text(Copy.select), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
