import 'package:supabase_flutter/supabase_flutter.dart';

class ShopService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchShopItems() async {
    final res = await supabase.from('shop_items').select();
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchUserItems(String userId) async {
    final res = await supabase
        .from('user_shop')
        .select('item_id')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> buyItem(String userId, String itemId, int price) async {
    final user = await supabase.from('users').select('coins').eq('id', userId).single();
    final coins = user['coins'] as int? ?? 0;

    if (coins < price) throw Exception('Not enough coins!');

    await supabase.from('users').update({
      'coins': SupabaseFilterBuilder.increment('coins', -price),
    }).eq('id', userId);

    await supabase.from('user_shop').insert({
      'user_id': userId,
      'item_id': itemId,
      'purchased_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setActiveBackground(String userId, String itemId) async {
    await supabase.from('users').update({'active_background': itemId}).eq('id', userId);
  }
}
