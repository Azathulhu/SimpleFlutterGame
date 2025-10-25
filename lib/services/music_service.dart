import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  Future<void> playBackgroundMusic(String assetPath) async {
    await _configureAudioSession();

    try {
      await _player.setAsset(assetPath);
      _player.setLoopMode(LoopMode.all);
      await _player.play();
    } catch (e) {
      print('Error playing music: $e');
    }
  }

  void pause() => _player.pause();
  void stop() => _player.stop();
  void setVolume(double vol) => _player.setVolume(vol);
  AudioPlayer get player => _player;
}
