#!/bin/bash
sed -i '' '/import '\''dart:io'\'';/d' lib/core/audio/audio_system.dart
sed -i '' 's/bool get _isTest => Platform.environment.containsKey('\''FLUTTER_TEST'\'');/bool isTestMode = false;\n\n  bool get _isTest => isTestMode;/g' lib/core/audio/audio_system.dart
