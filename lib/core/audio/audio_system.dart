import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

class AudioSystem with WidgetsBindingObserver {
  static final AudioSystem _instance = AudioSystem._internal();
  factory AudioSystem() => _instance;
  AudioSystem._internal();

  late final AudioPlayer _bgmPlayer;
  final Set<AudioPlayer> _sfxPlayers = <AudioPlayer>{};
  AudioPlayer? _loopPlayer;
  AudioPlayer? _previewPlayer;

  bool _bgmPlaying = false;
  bool _bgmPausedByLifecycle = false;
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
    WidgetsBinding.instance.addObserver(this);
    if (_isTest) return;
    _bgmPlayer = AudioPlayer();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setAudioContext(_bgmContext);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_bgmPausedByLifecycle) {
        _bgmPausedByLifecycle = false;
        _resumeBgm();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_bgmPlaying && !_bgmPausedByLifecycle) {
        _bgmPausedByLifecycle = true;
        _pauseBgm();
      }
    }
  }

  Future<void> playBgm() async {
    if (_isTest) return;
    if (_bgmPlaying) return;
    _bgmPlaying = true;
    _bgmPausedByLifecycle = false;
    await _bgmPlayer.play(AssetSource('audio/background_music.ogg'));
  }

  Future<void> stopBgm() async {
    if (_isTest) return;
    if (!_bgmPlaying) return;
    _bgmPlaying = false;
    _bgmPausedByLifecycle = false;
    await _bgmPlayer.stop();
  }

  Future<void> _pauseBgm() async {
    if (_isTest) return;
    await _bgmPlayer.pause();
  }

  Future<void> _resumeBgm() async {
    if (_isTest) return;
    await _bgmPlayer.resume();
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

  /// Plays a clip as a shop preview and reports when it ends so the caller can
  /// drop its playing indicator. Kept separate from [playSfx] so a preview can
  /// be stopped early without cutting off gameplay sound.
  Future<void> previewSfx(String name, {VoidCallback? onComplete}) async {
    if (_isTest) return;
    if (!sfxEnabled) return;
    await stopPreviewSfx();
    final player = AudioPlayer();
    _previewPlayer = player;
    var settled = false;
    Future<void> settle() async {
      if (settled) return;
      settled = true;
      if (identical(_previewPlayer, player)) _previewPlayer = null;
      _sfxPlayers.remove(player);
      try {
        await player.dispose();
      } catch (_) {}
      onComplete?.call();
    }

    try {
      await player.setAudioContext(_sfxContext);
      player.onPlayerComplete.listen((_) => settle());
      await player.play(AssetSource('audio/$name.ogg'));
    } catch (_) {
      await settle();
    }
  }

  /// True while a preview clip is still playing.
  bool get isPreviewing => _previewPlayer != null;

  Future<void> stopPreviewSfx() async {
    final player = _previewPlayer;
    _previewPlayer = null;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    _sfxPlayers.remove(player);
    try {
      await player.dispose();
    } catch (_) {}
  }

  /// Plays a looping clip (e.g. a machine sound) until [stopLoopingSfx] is
  /// called. Only one such player exists at a time.
  Future<void> playLoopingSfx(String name) async {
    if (_isTest) return;
    if (!sfxEnabled) return;
    await stopLoopingSfx();
    final player = AudioPlayer();
    _loopPlayer = player;
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setAudioContext(_sfxContext);
      await player.play(AssetSource('audio/$name.ogg'));
    } catch (_) {
      if (_loopPlayer == player) _loopPlayer = null;
      await player.dispose();
    }
  }

  Future<void> stopLoopingSfx() async {
    final player = _loopPlayer;
    _loopPlayer = null;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }
}

final audio = AudioSystem();
