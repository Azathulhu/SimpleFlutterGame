import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final AuthService auth = AuthService();

  List<Map<String, dynamic>> items = [];
  Set<String> purchasedItemIds = {};
  String? selectedItemId;
  int coins = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() => loading = true);

    final user = auth.currentUser;
    if (user == null) return;

    // Fetch coins
    final userRes = await supabase.from('users').select('coins').eq('id', user.id).single();
    coins = userRes['coins'] as int? ?? 0;

    // Fetch shop items
    final res = await supabase.from('shop_items').select().order('created_at', ascending: true);
    items = List<Map<String, dynamic>>.from(res);

    // Fetch purchased items
    final purchased = await supabase.from('user_shop').select('item_id').eq('user_id', user.id);
    purchasedItemIds = purchased.map<String>((e) => e['item_id'].toString()).toSet();

    // Set default selected
    selectedItemId = purchasedItemIds.isNotEmpty ? purchasedItemIds.first : null;

    setState(() => loading = false);
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;

    final price = item['price'] as int;
    final itemId = item['id'] as String;

    if (coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins')));
      return;
    }

    // Deduct coins
    await supabase.from('users').update({'coins': coins - price}).eq('id', user.id);

    // Add purchase
    await supabase.from('user_shop').insert({'user_id': user.id, 'item_id': itemId});

    // Update local state
    purchasedItemIds.add(itemId);
    coins -= price;
    selectedItemId = itemId;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Shop'), backgroundColor: Colors.transparent, elevation: 0),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Coins: $coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final item = items[i];
                            final itemId = item['id'] as String;
                            final purchased = purchasedItemIds.contains(itemId);
                            final selected = selectedItemId == itemId;

                            return GestureDetector(
                              onTap: () {
                                if (purchased) {
                                  setState(() {
                                    selectedItemId = itemId;
                                  });
                                } else {
                                  _buyItem(item);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 3),
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: NetworkImage(item['url']),
                                    fit: BoxFit.cover,
                                    colorFilter: purchased
                                        ? null
                                        : const ColorFilter.mode(Colors.black45, BlendMode.darken),
                                  ),
                                ),
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.black38,
                                  child: Text(
                                    purchased ? 'Owned' : '${item['price']} coins',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
