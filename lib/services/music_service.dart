import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class MusicService {
  // Singleton so music persists across pages
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    // Pause when headphones unplugged
    session.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });

    // Handle interruptions like external music
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _player.pause();
      } else if (event.end) {
        _player.play();
      }
    });
  }

  Future<void> play(String assetPath) async {
    await init();
    try {
      await _player.setAsset(assetPath);
      _player.setLoopMode(LoopMode.one); // Loop forever
      await _player.play();
    } catch (e) {
      print('Error playing background music: $e');
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
}
