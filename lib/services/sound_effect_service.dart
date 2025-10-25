import 'package:just_audio/just_audio.dart';

class SoundEffectService {
  static final SoundEffectService _instance = SoundEffectService._internal();
  factory SoundEffectService() => _instance;
  SoundEffectService._internal();

  final AudioPlayer _player = AudioPlayer(); // separate player for SFX

  /// Play a short sound effect from assets
  Future<void> play(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      print('Error playing SFX: $e');
    }
  }
}
