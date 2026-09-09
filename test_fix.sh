#!/bin/bash
sed -i '' 's/Future<void> playSfx(String name) async {/Future<void> playSfx(String name) async {\n    try {/g' lib/core/audio/audio_system.dart
sed -i '' 's/player.onPlayerComplete.listen((_) => player.dispose());/player.onPlayerComplete.listen((_) => player.dispose());\n    } catch (_) {}/g' lib/core/audio/audio_system.dart
