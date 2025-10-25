import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  final int coins;
  final Function(int) onCoinsChanged;
  final Function(String?)? onEquipBackground;

  const ShopPage({
    super.key,
    required this.coins,
    required this.onCoinsChanged,
    this.onEquipBackground,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  final AuthService auth = AuthService();
  final supabase = Supabase.instance.client;

  late int coins;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> userItems = [];

  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
    _loadItems();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
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

    await supabase
        .from('user_items')
        .update({'equipped': false})
        .eq('user_id', userId);

    await supabase
        .from('user_items')
        .update({'equipped': true})
        .eq('user_id', userId)
        .eq('item_id', item['id']);

    await _loadItems();

    widget.onEquipBackground?.call(item['asset_url']);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Keep your existing background here
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00FFC8), Color(0xFF1DE9B6)],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(
                'Shop',
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.tealAccent.withOpacity(0.7),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
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
                    return AnimatedBuilder(
                      animation: _hoverController,
                      builder: (context, child) {
                        final floatY = 4 * (0.5 - (_hoverController.value));
                        return Transform.translate(
                          offset: Offset(0, floatY),
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.tealAccent.withOpacity(0.3),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.tealAccent.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    child: Image.network(
                                      item['asset_url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                              child: Icon(
                                                  Icons.broken_image,
                                                  size: 48)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        item['name'],
                                        style: GoogleFonts.nunitoSans(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.tealAccent.withOpacity(0.8),
                                              blurRadius: 8,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['price']} coins',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isOwned(item)
                                              ? (_isEquipped(item) ? null : () => _toggleEquip(item))
                                              : () => _purchaseItem(item),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            backgroundColor: _isOwned(item)
                                                ? (_isEquipped(item)
                                                    ? Colors.grey.shade700
                                                    : const Color(0xFF00FFC8))
                                                : const Color(0xFF1DE9B6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 6,
                                            shadowColor: Colors.tealAccent.withOpacity(0.4),
                                          ),
                                          child: Text(
                                            _isOwned(item)
                                                ? (_isEquipped(item) ? 'Equipped' : 'Equip')
                                                : 'Buy',
                                            style: GoogleFonts.nunitoSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white.withOpacity(0.3),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/*import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  final int coins;
  final Function(int) onCoinsChanged;
  final Function(String?)? onEquipBackground;

  const ShopPage({
    super.key,
    required this.coins,
    required this.onCoinsChanged,
    this.onEquipBackground,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  final AuthService auth = AuthService();
  final supabase = Supabase.instance.client;

  late int coins;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> userItems = [];

  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
    _loadItems();

    // subtle hover/floating animation for cards
    _hoverController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
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

    await supabase
        .from('user_items')
        .update({'equipped': false})
        .eq('user_id', userId);

    await supabase
        .from('user_items')
        .update({'equipped': true})
        .eq('user_id', userId)
        .eq('item_id', item['id']);

    await _loadItems();

    widget.onEquipBackground?.call(item['asset_url']);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ParticleBackground(), // use your homepage particle background
        Scaffold(
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
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return AnimatedBuilder(
                      animation: _hoverController,
                      builder: (context, child) {
                        final floatY = 4 * (0.5 - (_hoverController.value));
                        return Transform.translate(
                          offset: Offset(0, floatY),
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.02)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    child: Image.network(
                                      item['asset_url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                              child: Icon(
                                                  Icons.broken_image,
                                                  size: 48)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Text(item['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text('${item['price']} coins',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.6))),
                                      const SizedBox(height: 8),
                                      _isOwned(item)
                                          ? ElevatedButton(
                                              onPressed: _isEquipped(item)
                                                  ? null
                                                  : () =>
                                                      _toggleEquip(item),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary
                                                    .withOpacity(0.9),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14)),
                                              ),
                                              child: Text(_isEquipped(item)
                                                  ? 'Equipped'
                                                  : 'Equip'),
                                            )
                                          : ElevatedButton(
                                              onPressed: () =>
                                                  _purchaseItem(item),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary
                                                    .withOpacity(0.9),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14)),
                                              ),
                                              child: const Text('Buy'),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}*/


/*import 'package:flutter/material.dart';
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
}*/
