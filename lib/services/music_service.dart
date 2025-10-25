// lib/services/music_service.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicService with WidgetsBindingObserver {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  String? _currentAsset;

  /// Start playing music in loop
  Future<void> playBackgroundMusic(String assetPath) async {
    if (_currentAsset == assetPath && _playing) return;
    _currentAsset = assetPath;

    try {
      await _player.setAsset(assetPath);
      _player.setLoopMode(LoopMode.one);
      _player.play();
      _playing = true;
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  /// Stop music completely
  Future<void> stop() async {
    _playing = false;
    await _player.stop();
  }

  /// Pause music manually
  Future<void> pause() async {
    if (_playing) {
      await _player.pause();
      _playing = false;
    }
  }

  /// Resume music manually
  Future<void> resume() async {
    if (!_playing) {
      await _player.play();
      _playing = true;
    }
  }

  /// Listen to app lifecycle (pause/resume)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // user left the app temporarily -> pause music
      pause();
    } else if (state == AppLifecycleState.resumed) {
      // user returned to the app -> resume music
      resume();
    }
  }

  /// Clean up
  void dispose() {
    _player.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
