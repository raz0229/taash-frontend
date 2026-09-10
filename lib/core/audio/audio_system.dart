import 'package:audioplayers/audioplayers.dart';

class AudioSystem {
  static final AudioSystem _instance = AudioSystem._internal();
  factory AudioSystem() => _instance;
  AudioSystem._internal();

  late final AudioPlayer _bgmPlayer;
  final Set<AudioPlayer> _sfxPlayers = <AudioPlayer>{};

  bool _bgmPlaying = false;
  bool sfxEnabled = true;

  bool isTestMode = false;

  bool get _isTest => isTestMode;

  static final _bgmContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.music,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  static final _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Future<void> init() async {
    if (_isTest) return;
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setAudioContext(_bgmContext);
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
    if (!sfxEnabled) return;
    final player = AudioPlayer();
    _sfxPlayers.add(player);
    try {
      await player.setAudioContext(_sfxContext);
      player.onPlayerComplete.listen((_) {
        _sfxPlayers.remove(player);
        player.dispose();
      });
      await player.play(AssetSource('audio/$name.ogg'));
    } catch (_) {
      _sfxPlayers.remove(player);
      await player.dispose();
    }
  }
}

final audio = AudioSystem();
