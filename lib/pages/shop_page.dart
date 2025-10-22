import 'package:flutter/material.dart';
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
}

/*import 'package:flutter/material.dart';
import '../animated_background.dart';
import '../theme.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Shop'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Welcome to the Shop!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}*/
