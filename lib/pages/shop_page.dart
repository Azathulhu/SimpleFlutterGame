import 'package:flutter/material.dart';
import '../animated_background.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AuthService auth = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> items = [];
  int coins = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() => loading = true);

    // Load items
    final res = await supabase.from('shop_items').select();
    // Load coins
    final c = await auth.fetchCoins();

    setState(() {
      items = List<Map<String, dynamic>>.from(res);
      coins = c;
      loading = false;
    });
  }
  Future<void> _purchaseItem(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;
  
    final price = (item['price'] as num).toInt();
    if (coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins!')));
      return;
    }
  
    try {
      await supabase.from('user_items').insert({
        'user_id': user.id,
        'item_id': item['id'],
      });
  
      // Deduct coins
      await auth.addCoins(-price);
      final newCoins = await auth.fetchCoins();
      setState(() => coins = newCoins);
  
      // Notify HomePage to update app bar
      widget.onCoinsChanged(newCoins);
  
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${item['name']}!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already owned!')));
    }
  }

  /*Future<void> _purchaseItem(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;

    final price = (item['price'] as num).toInt();
    if (coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins!')));
      return;
    }

    // Insert into user_items if not already acquired
    try {
      await supabase.from('user_items').insert({
        'user_id': user.id,
        'item_id': item['id'],
      });
      // Deduct coins
      await auth.addCoins(-price);
      final newCoins = await auth.fetchCoins();
      setState(() => coins = newCoins);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${item['name']}!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already owned!')));
    }
  }*/

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Shop'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 items per row
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, index) {
              final item = items[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          item['asset_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${item['price']} coins', style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: coins >= (item['price'] as num).toInt() ? () => _purchaseItem(item) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Buy'),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import '../animated_background.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AuthService auth = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;

  int coins = 0;
  bool loading = true;
  bool purchased = false;

  Map<String, dynamic>? item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await auth.fetchCoins();
    final fetchedItem = await supabase
        .from('shop_items')
        .select()
        .eq('type', 'background')
        .limit(1)
        .maybeSingle();

    final user = auth.currentUser;
    bool hasPurchased = false;
    if (user != null && fetchedItem != null) {
      final res = await supabase
          .from('user_items')
          .select()
          .eq('user_id', user.id)
          .eq('item_id', fetchedItem['id'])
          .maybeSingle();
      hasPurchased = res != null;
    }

    setState(() {
      coins = c;
      item = fetchedItem;
      purchased = hasPurchased;
      loading = false;
    });
  }

  Future<void> _buyItem() async {
    if (item == null) return;
    if (coins < item!['price']) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins!')));
      return;
    }

    final user = auth.currentUser;
    if (user == null) return;

    // Deduct coins
    await auth.addCoins(-item!['price']);

    // Insert into user_items
    await supabase.from('user_items').insert({
      'user_id': user.id,
      'item_id': item!['id'],
    });

    setState(() {
      //coins -= item!['price'];
      coins -= (item!['price'] as num).toInt();
      purchased = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Item purchased!')));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (item == null) return const Center(child: Text('No items in shop.'));

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Shop'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Coins: $coins', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(item!['name'], style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text('Price: ${item!['price']} coins'),
                      const SizedBox(height: 12),
                      purchased
                          ? const Text('Purchased', style: TextStyle(color: Colors.green))
                          : ElevatedButton(
                              onPressed: _buyItem,
                              child: const Text('Buy'),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
