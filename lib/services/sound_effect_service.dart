import 'package:just_audio/just_audio.dart';

class SoundEffectService {
  static final SoundEffectService _instance = SoundEffectService._internal();
  factory SoundEffectService() => _instance;
  SoundEffectService._internal();

  /// Play a short sound effect from assets using a new player each time
  Future<void> play(String assetPath) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(assetPath);
      await player.play();
      // Dispose automatically after playing
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
        }
      });
    } catch (e) {
      print('Error playing SFX: $e');
    }
  }
}
