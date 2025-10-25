import 'package:just_audio/just_audio.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Start playing background music in a loop
  Future<void> playLoopingMusic() async {
    try {
      await _player.setAsset('assets/audio/analogmemory.mp3');
      _player.setLoopMode(LoopMode.all); // loop indefinitely
      _player.play();
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  /// Stop music
  void stop() {
    _player.stop();
  }

  /// Pause music
  void pause() {
    _player.pause();
  }

  /// Resume music
  void resume() {
    _player.play();
  }

  /// Dispose player when app closes
  void dispose() {
    _player.dispose();
  }
}
