/*import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class CoinService {
  final SupabaseClient supabase = Supabase.instance.client;

  
  Future<int> getCoins(String userId) async {
    final res = await supabase.from('user_coins').select('coins').eq('user_id', userId).maybeSingle();
    if (res == null) return 0;
    return res['coins'] as int? ?? 0;
  }

  Future<void> addCoins({
    required String userId,
    required String level,
    required int timeMs,
  }) async {
    // simple base mapping
    final int base = level == 'easy' ? 10 : level == 'medium' ? 20 : 40;
    double timeFactor = 1.0;
    if (timeMs < 10000) timeFactor = 1.5;
    else if (timeMs < 20000) timeFactor = 1.2;
    final int earned = (base * timeFactor).ceil();

    if (kDebugMode) {
      debugPrint('CoinService: awarding $earned coins to $userId (level=$level, timeMs=$timeMs)');
    }

    final existing = await supabase.from('user_coins').select('coins').eq('user_id', userId).maybeSingle();
    if (existing == null) {
      await supabase.from('user_coins').insert({
        'user_id': userId,
        'coins': earned,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) debugPrint('CoinService: inserted $earned for $userId');
    } else {
      final current = (existing['coins'] as int?) ?? 0;
      await supabase.from('user_coins').update({
        'coins': current + earned,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
      if (kDebugMode) debugPrint('CoinService: updated $userId coins ${current + earned}');
    }
  }
}
*/
