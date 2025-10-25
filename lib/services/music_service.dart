import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    final session = await AudioSession.instance;
    // For audio_session ^0.1.x, just use .configure() without iOS-specific params
    await session.configure(AudioSessionConfiguration.music());
    
    _player.setLoopMode(LoopMode.all);
  }

  Future<void> play(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void stop() => _player.stop();
  void pause() => _player.pause();
  void dispose() => _player.dispose();
}
