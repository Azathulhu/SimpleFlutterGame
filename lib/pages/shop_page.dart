import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ShopService shop = ShopService();
  final AuthService auth = AuthService();

  List<Map<String, dynamic>> items = [];
  List<String> ownedItemIds = [];
  String? activeBackground;
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

    final shopItems = await shop.fetchShopItems();
    final userItems = await shop.fetchUserItems(user.id);

    final userRes = await shop.supabase.from('users').select('coins, active_background').eq('id', user.id).single();

    setState(() {
      items = shopItems;
      ownedItemIds = userItems.map((e) => e['item_id'] as String).toList();
      coins = userRes['coins'] as int? ?? 0;
      activeBackground = userRes['active_background'] as String?;
      loading = false;
    });
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      await shop.buyItem(user.id, item['id'], item['price']);
      await _loadShop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchased ${item['name']}!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setActive(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;
    await shop.setActiveBackground(user.id, item['id']);
    setState(() => activeBackground = item['id']);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Coins: $coins', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final owned = ownedItemIds.contains(item['id']);
                  final isActive = activeBackground == item['id'];
                  return GestureDetector(
                    onTap: owned ? () => _setActive(item) : () => _buyItem(item),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: isActive ? AppTheme.primary : Colors.grey, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(item['url']),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: owned
                          ? isActive
                              ? const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40))
                              : const SizedBox.shrink()
                          : Center(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: Colors.black.withOpacity(0.6),
                                child: Text('${item['price']} 💰', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    );
  }
}
