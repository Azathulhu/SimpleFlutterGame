import 'package:just_audio/just_audio.dart';
import 'package:flutter/widgets.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;

  late final AudioPlayer _player;
  bool _initialized = false;

  MusicService._internal() {
    _player = AudioPlayer();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // Keep the music app-exclusive by not using audio session
    await _player.setLoopMode(LoopMode.one);
  }

  Future<void> playBackground(String assetPath) async {
    await init();
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  bool get isPlaying => _player.playing;
}
