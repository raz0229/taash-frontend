import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

/// Registers the device token after sign-in. Token registration is best
/// effort: challenges still appear in the Friends tab if notifications are
/// disabled or the device is offline.
Future<void> registerPushNotifications(
  ApiClient api, {
  ValueChanged<String>? onChallenge,
}) async {
  if (Firebase.apps.isEmpty) return;
  final messaging = FirebaseMessaging.instance;
  void handleChallenge(RemoteMessage message) {
    final id = message.data['challenge_id'];
    if (message.data['type'] == 'challenge' && id is String) {
      onChallenge?.call(id);
    }
  }

  // onMessage covers the foreground case (including when the player is
  // currently seated in another room); onMessageOpenedApp covers a tap from
  // the system notification tray.
  FirebaseMessaging.onMessage.listen(handleChallenge);
  FirebaseMessaging.onMessageOpenedApp.listen(handleChallenge);
  final initial = await messaging.getInitialMessage();
  if (initial != null) {
    final id = initial.data['challenge_id'];
    if (initial.data['type'] == 'challenge' && id is String) {
      onChallenge?.call(id);
    }
  }
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  final token = await messaging.getToken();
  if (token != null && token.isNotEmpty) await api.registerPushToken(token);
  messaging.onTokenRefresh.listen((next) async {
    if (next.isNotEmpty) {
      try {
        await api.registerPushToken(next);
      } catch (_) {}
    }
  });
}
