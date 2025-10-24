import 'package:flutter/material.dart';
import '../animated_background.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  final int coins;
  final Function(int) onCoinsChanged;
  final Function(String?)? onEquipBackground; // callback to update equipped background

  const ShopPage({
    super.key,
    required this.coins,
    required this.onCoinsChanged,
    this.onEquipBackground,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AuthService auth = AuthService();
  final supabase = Supabase.instance.client;

  late int coins;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> userItems = [];

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
    _loadItems();
  }

  Future<void> _loadItems() async {
    final res = await supabase.from('shop_items').select();
    final ownedRes = await supabase.from('user_items').select();
    setState(() {
      items = List<Map<String, dynamic>>.from(res);
      userItems = List<Map<String, dynamic>>.from(ownedRes);
    });
  }

  bool _isOwned(Map<String, dynamic> item) {
    final user = auth.currentUser;
    if (user == null) return false;
    return userItems.any((ui) =>
        ui['item_id'] == item['id'] &&
        ui['user_id'] == user.id);
  }

  bool _isEquipped(Map<String, dynamic> item) {
    final user = auth.currentUser;
    if (user == null) return false;
    return userItems.any((ui) =>
        ui['item_id'] == item['id'] &&
        ui['user_id'] == user.id &&
        (ui['equipped'] == true));
  }

  Future<void> _purchaseItem(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;

    final price = (item['price'] as num).toInt();
    if (coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!')),
      );
      return;
    }

    try {
      await supabase.from('user_items').insert({
        'user_id': user.id,
        'item_id': item['id'],
        'equipped': false,
      });

      await auth.addCoins(-price);
      final newCoins = await auth.fetchCoins();
      setState(() => coins = newCoins);
      widget.onCoinsChanged(newCoins);

      await _loadItems();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${item['name']}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already owned!')),
      );
    }
  }

  Future<void> _toggleEquip(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    // Unequip all items for this user
    await supabase
        .from('user_items')
        .update({'equipped': false})
        .eq('user_id', userId);

    // Equip selected item
    await supabase
        .from('user_items')
        .update({'equipped': true})
        .eq('user_id', userId)
        .eq('item_id', item['id']);

    await _loadItems();

    // Update QuizPage / HomePage
    widget.onEquipBackground?.call(item['asset_url']);
  }

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
        body: items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.network(
                              item['asset_url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, size: 48)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(item['name'],
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${item['price']} coins',
                                  style: const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 8),
                              _isOwned(item)
                                  ? ElevatedButton(
                                      onPressed: _isEquipped(item)
                                          ? null
                                          : () => _toggleEquip(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text(_isEquipped(item)
                                          ? 'Equipped'
                                          : 'Equip'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _purchaseItem(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Buy'),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import '../animated_background.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  final int coins;
  final Function(int) onCoinsChanged; // callback to update coins in HomePage

  const ShopPage({super.key, required this.coins, required this.onCoinsChanged});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AuthService auth = AuthService();
  final supabase = Supabase.instance.client;
  late int coins;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
    _loadItems();
  }

  Future<void> _loadItems() async {
    final res = await supabase.from('shop_items').select();
    setState(() {
      items = List<Map<String, dynamic>>.from(res);
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
        body: items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Image.network(
                          item['asset_url'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(height: 150, child: Center(child: Icon(Icons.image_not_supported))),
                        ),
                        ListTile(
                          title: Text(item['name']),
                          subtitle: Text('Price: ${item['price']} coins'),
                          trailing: ElevatedButton(
                            onPressed: () => _purchaseItem(item),
                            child: const Text('Buy'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}*/
