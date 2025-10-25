// lib/services/sound_effect_service.dart
import 'package:just_audio/just_audio.dart';

class SoundEffectService {
  static final SoundEffectService _instance = SoundEffectService._internal();
  factory SoundEffectService() => _instance;
  SoundEffectService._internal();

  /// Play a short SFX from assets without interfering with MusicService
  Future<void> play(String assetPath) async {
    final player = AudioPlayer(
      // This ensures it doesn’t take audio focus from your music player
      audioSource: null,
      handleInterruptions: false,
    );

    try {
      await player.setAsset(assetPath);
      await player.play();

      // Dispose after completion safely
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          player.dispose();
        }
      });
    } catch (e) {
      print('SFX play error: $e');
      player.dispose();
    }
  }
}
