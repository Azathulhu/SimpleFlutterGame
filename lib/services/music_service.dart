import 'package:just_audio/just_audio.dart';

class MusicService {
  // Singleton pattern
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Start background music (loops automatically)
  Future<void> playBackgroundMusic(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      _player.setLoopMode(LoopMode.all);
      await _player.play();
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  /// Pause music
  void pause() => _player.pause();

  /// Stop music
  void stop() => _player.stop();

  /// Change volume (0.0 to 1.0)
  void setVolume(double vol) => _player.setVolume(vol);

  /// Get the player (optional)
  AudioPlayer get player => _player;
}
