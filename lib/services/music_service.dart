// lib/services/music_service.dart
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/widgets.dart';

class MusicService with WidgetsBindingObserver {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _startWatcher();
  }

  final AudioPlayer _player = AudioPlayer();
  Timer? _watcher;
  bool _isAppInForeground = true;

  Future<void> playLooping(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      _player.setLoopMode(LoopMode.one);
      if (_isAppInForeground) {
        _player.play();
      }
    } catch (e) {
      print("MusicService playLooping error: $e");
    }
  }

  void stop() {
    _player.stop();
  }

  void pause() {
    _player.pause();
  }

  void resume() {
    if (_isAppInForeground) _player.play();
  }

  // Watcher to auto-restart if music stops unexpectedly
  void _startWatcher() {
    _watcher = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isAppInForeground) return;
      if (_player.playing == false && _player.processingState == ProcessingState.ready) {
        try {
          await _player.play();
        } catch (_) {}
      }
    });
  }

  // Handle app foreground/background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (_isAppInForeground) {
      if (_player.playing == false && _player.processingState == ProcessingState.ready) {
        _player.play();
      }
    } else {
      _player.pause();
    }
  }

  void dispose() {
    _watcher?.cancel();
    _player.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
