import 'package:supabase_flutter/supabase_flutter.dart';

class CoinService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch current user's coins
  Future<int> getCoins(String userId) async {
    final res = await supabase.from('user_coins').select('coins').eq('user_id', userId).maybeSingle();
    if (res == null) return 0;
    return res['coins'] as int? ?? 0;
  }

  /// Add coins to user after perfect quiz
  Future<void> addCoins({
    required String userId,
    required String level,
    required int timeMs, // time in milliseconds
  }) async {
    int baseCoins;
    switch (level) {
      case 'easy':
        baseCoins = 10;
        break;
      case 'medium':
        baseCoins = 20;
        break;
      case 'hard':
        baseCoins = 40;
        break;
      default:
        baseCoins = 10;
    }

    // Faster completion = bonus multiplier
    double timeFactor = 1.0;
    if (timeMs < 10000) {
      timeFactor = 1.5; // 50% bonus if finished under 10 seconds
    } else if (timeMs < 20000) {
      timeFactor = 1.2;
    }

    final earned = (baseCoins * timeFactor).ceil();

    // Upsert user coins
    final existing = await supabase.from('user_coins').select('coins').eq('user_id', userId).maybeSingle();
    if (existing == null) {
      await supabase.from('user_coins').insert({
        'user_id': userId,
        'coins': earned,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      final current = (existing['coins'] as int?) ?? 0;
      await supabase.from('user_coins').update({
        'coins': current + earned,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    }
  }
}
