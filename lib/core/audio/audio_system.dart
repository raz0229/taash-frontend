
import 'package:audioplayers/audioplayers.dart';

class AudioSystem {
  static final AudioSystem _instance = AudioSystem._internal();
  factory AudioSystem() => _instance;
  AudioSystem._internal();

  late final AudioPlayer _bgmPlayer;

  bool _bgmPlaying = false;

  bool isTestMode = false;

  bool get _isTest => isTestMode;

  Future<void> init() async {
    if (_isTest) return;
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBgm() async {
    if (_isTest) return;
    if (_bgmPlaying) return;
    _bgmPlaying = true;
    await _bgmPlayer.play(AssetSource('audio/background_music.ogg'));
  }

  Future<void> stopBgm() async {
    if (_isTest) return;
    if (!_bgmPlaying) return;
    _bgmPlaying = false;
    await _bgmPlayer.stop();
  }

  Future<void> playSfx(String name) async {
    if (_isTest) return;
    try {
    final player = AudioPlayer();
    await player.play(AssetSource('audio/$name.ogg'));
    player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {}
  }
}

final audio = AudioSystem();
