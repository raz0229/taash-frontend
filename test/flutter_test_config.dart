import 'dart:async';
import 'package:taash/core/audio/audio_system.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  audio.isTestMode = true;
  await testMain();
}
