import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../services/auth_service.dart';
import '../services/quiz_service.dart';
import 'quiz_page.dart';
import 'shop_page.dart';
import '../theme.dart';
import 'sign_in_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final AuthService auth = AuthService();
  final QuizService quizService = QuizService();

  List<String> unlocked = ['easy'];
  String selectedLevel = 'easy';
  bool loading = true;
  final levels = ['easy', 'medium', 'hard'];

  late ConfettiController confettiController;

  String username = 'Guest';
  int coins = 0;

  // Tab management
  int activeIndex = 0;
  late PageController _pageController;

  // button subtle breathe animation
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _pageController = PageController();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _breatheAnim =
        Tween<double>(begin: 0.98, end: 1.03).animate(CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut));

    _loadUsername();
    _loadUnlocked();
    _loadCoins();
  }

  @override
  void dispose() {
    confettiController.dispose();
    _pageController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    final c = await auth.fetchCoins();
    if (!mounted) return;
    setState(() => coins = c);
  }

  Future<void> _loadUsername() async {
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    final res = await auth.supabase.from('users').select('username').eq('id', userId).maybeSingle();
    setState(() {
      username = res?['username'] ?? 'Guest';
    });
  }

  Future<void> _loadUnlocked() async {
    setState(() => loading = true);
    final u = await auth.fetchUnlockedLevels();
    setState(() {
      unlocked = u;
      if (!unlocked.contains(selectedLevel)) selectedLevel = unlocked.first;
      loading = false;
    });
  }

  // Public update coins for ShopPage
  void updateCoins(int newCoins) => setState(() => coins = newCoins);

  // simple helper for nav tap
  void _onNavTap(int idx) {
    setState(() => activeIndex = idx);
    _pageController.animateToPage(idx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
  }

  // ---------- Glow Text Helper ----------
  TextStyle glowText(double size, {FontWeight weight = FontWeight.bold}) {
    return TextStyle(
      color: Colors.white,
      fontSize: size,
      fontWeight: weight,
      fontFamily: 'Orbitron', // make sure to add Orbitron font in pubspec.yaml
      shadows: [
        Shadow(
          blurRadius: 10,
          color: Colors.white.withOpacity(0.8),
          offset: const Offset(0, 0),
        ),
        Shadow(
          blurRadius: 20,
          color: Colors.blueAccent.withOpacity(0.4),
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // Play Tab content
  Widget playTab() {
    if (loading) return const Center(child: CircularProgressIndicator());

    final pageController = PageController(
      viewportFraction: 0.56,
      initialPage: levels.indexOf(selectedLevel),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glassCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose difficulty',
                        textAlign: TextAlign.center,
                        style: glowText(20, weight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.settings, color: Colors.white.withOpacity(0.65)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: levels.length,
                    onPageChanged: (idx) {
                      setState(() => selectedLevel = levels[idx]);
                      _loadUnlocked();
                    },
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final enabled = unlocked.contains(level);
                      return AnimatedBuilder(
                        animation: pageController,
                        builder: (context, child) {
                          double value = 0;
                          if (pageController.position.haveDimensions) {
                            value = pageController.page! - index;
                            value = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
                          } else {
                            value = index == levels.indexOf(selectedLevel) ? 1 : 0.7;
                          }
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY((pageController.position.haveDimensions
                                      ? pageController.page! - index
                                      : index - levels.indexOf(selectedLevel)) *
                                  0.25),
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (value * 0.25),
                                child: levelCard(level, enabled, isSelected: selectedLevel == level),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                ScaleTransition(
                  scale: _breatheAnim,
                  child: ElevatedButton(
                    onPressed: unlocked.contains(selectedLevel)
                        ? () async {
                            confettiController.play();
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => QuizPage(level: selectedLevel)));
                            await _loadUnlocked();
                            await _loadCoins();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppTheme.primary.withOpacity(0.95),
                    ),
                    child: Text('Start Quiz', style: glowText(16, weight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget levelCard(String level, bool enabled, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [AppTheme.primary.withOpacity(0.95), AppTheme.accent.withOpacity(0.9)])
            : LinearGradient(
                colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))]
            : [],
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              level == 'easy'
                  ? Icons.looks_one
                  : level == 'medium'
                      ? Icons.looks_two
                      : Icons.looks_3,
              size: 34,
              color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(height: 12),
          Text(level.toUpperCase(), style: glowText(16)),
          const SizedBox(height: 8),
          Text(enabled ? 'Unlocked' : 'Locked', style: glowText(12, weight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget leaderboardTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: quizService.fetchLeaderboard(level: selectedLevel, limit: 20),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final leaderboard = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _glassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Leaderboard — ${selectedLevel.toUpperCase()}', style: glowText(18))),
                    Icon(Icons.leaderboard, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    itemCount: leaderboard.length,
                    itemBuilder: (_, idx) {
                      final entry = leaderboard[idx];
                      final timeMs = entry['time_ms'] as int?;
                      final displayTime = timeMs != null ? '${(timeMs / 1000).toStringAsFixed(2)}s' : '--';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.02)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.14),
                                child: Text('${idx + 1}', style: glowText(14, weight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry['users']?['username'] ?? 'Unknown', style: glowText(16))),
                            Text(displayTime, style: glowText(14, weight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget shopTab() {
    return ShopPage(coins: coins, onCoinsChanged: (newCoins) => updateCoins(newCoins));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ParticleBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _glassCard(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppTheme.primary.withOpacity(0.12),
                                child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'G',
                                    style: glowText(18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Hello, $username', style: glowText(18))),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text('$coins', style: glowText(14, weight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      await auth.signOut();
                                      if (!mounted) return;
                                      Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (_) => const SignInPage()),
                                          (route) => false);
                                    },
                                    child: Text('Sign out', style: glowText(12, weight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => activeIndex = idx),
                      children: [
                        AnimatedSwitcher(
                            duration: const Duration(milliseconds: 650),
                            transitionBuilder: (child, anim) {
                              final inAnim = Tween<Offset>(begin: const Offset(0.03, 0.08), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                              return FadeTransition(opacity: anim, child: SlideTransition(position: inAnim, child: child));
                            },
                            child: SizedBox(key: ValueKey('play-$selectedLevel'), child: playTab())),
                        AnimatedSwitcher(
                            duration: const Duration(milliseconds: 650),
                            transitionBuilder: (child, anim) {
                              final inAnim = Tween<Offset>(begin: const Offset(0.03, 0.08), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                              return FadeTransition(opacity: anim, child: SlideTransition(position: inAnim, child: child));
                            },
                            child: Container(key: const ValueKey('leaderboard'), child: leaderboardTab())),
                        AnimatedSwitcher(
                            duration: const Duration(milliseconds: 650),
                            transitionBuilder: (child, anim) {
                              final inAnim = Tween<Offset>(begin: const Offset(0.03, 0.08), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                              return FadeTransition(opacity: anim, child: SlideTransition(position: inAnim, child: child));
                            },
                            child: Container(key: const ValueKey('shop'), child: shopTab())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 78),
                ],
              ),
            ),
          ),
          Positioned(
              top: 10,
              right: 8,
              child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: [AppTheme.primary, AppTheme.accent, Colors.amber])),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Center(
              child: _FloatingGlassNav(
                activeIndex: activeIndex,
                onTap: _onNavTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Floating glass nav (curved blob style) ----------
class _FloatingGlassNav extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;
  const _FloatingGlassNav({required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (idx) {
              final active = idx == activeIndex;
              final icon = idx == 0
                  ? Icons.play_circle_fill
                  : idx == 1
                      ? Icons.leaderboard
                      : Icons.storefront;
              return IconButton(
                  onPressed: () => onTap(idx),
                  icon: Icon(icon, color: active ? AppTheme.primary : Colors.white70));
            }),
          ),
        ),
      ),
    );
  }
}

// Dummy particle background for completeness
class ParticleBackground extends StatelessWidget {
  const ParticleBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black87);
  }
}



// --------- Floating nav, particle background etc remain unchanged ---------

/*import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';
import '../theme.dart';
import 'sign_in_page.dart';
import 'shop_page.dart';
import '../animated_background.dart';
import '../services/quiz_service.dart';
import 'package:confetti/confetti.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final AuthService auth = AuthService();
  final QuizService quizService = QuizService();

  List<String> unlocked = ['easy'];
  String selectedLevel = 'easy';
  bool loading = true;
  final levels = ['easy', 'medium', 'hard'];

  late ConfettiController confettiController;
  late TabController tabController;

  List<Map<String, dynamic>> leaderboard = [];
  bool leaderboardLoading = true;
  String username = 'Guest';

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  int coins = 0;

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    tabController = TabController(length: 3, vsync: this);

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _buttonScaleAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadUsername();
    _loadUnlocked();
    _loadLeaderboard();
    _loadCoins();
  }
  //new
  void updateCoins(int newCoins) {
    setState(() => coins = newCoins);
  }

  @override
  void dispose() {
    confettiController.dispose();
    tabController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    final c = await auth.fetchCoins();
    if (!mounted) return;
    setState(() => coins = c);
  }
  
  Future<void> _loadUsername() async {
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final res = await auth.supabase
        .from('users')
        .select('username')
        .eq('id', userId)
        .maybeSingle();

    setState(() {
      username = res?['username'] ?? 'Guest';
    });
  }

  Future<void> _loadUnlocked() async {
    setState(() => loading = true);
    final u = await auth.fetchUnlockedLevels();
    setState(() {
      unlocked = u;
      if (!unlocked.contains(selectedLevel)) selectedLevel = unlocked.first;
      loading = false;
    });
  }

  Future<void> _loadLeaderboard() async {
    setState(() => leaderboardLoading = true);
    final res =
        await quizService.fetchLeaderboard(level: selectedLevel, limit: 20);
    setState(() {
      leaderboard = res;
      leaderboardLoading = false;
    });
  }

  Widget levelCard(String level, bool enabled) {
    final isSelected = selectedLevel == level;

    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      scale: isSelected ? 1.1 : 1.0,
      child: GestureDetector(
        onTap: enabled
            ? () {
                setState(() => selectedLevel = level);
                _loadLeaderboard();
              }
            : null,
        child: Container(
          width: 120,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade200]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppTheme.primary.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                level == 'easy'
                    ? Icons.looks_one
                    : level == 'medium'
                        ? Icons.looks_two
                        : Icons.looks_3,
                color: isSelected ? Colors.white : Colors.black54,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                level.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                enabled ? 'Unlocked' : 'Locked',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget playTab() {
    if (loading) return const Center(child: CircularProgressIndicator());
  
    final pageController = PageController(viewportFraction: 0.5, initialPage: levels.indexOf(selectedLevel));
  
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: pageController,
            itemCount: levels.length,
            onPageChanged: (index) {
              setState(() => selectedLevel = levels[index]);
              _loadLeaderboard();
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double value = 0;
                  if (pageController.position.haveDimensions) {
                    value = pageController.page! - index;
                    value = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
                  } else {
                    value = index == levels.indexOf(selectedLevel) ? 1 : 0.6;
                  }
  
                  double rotationY = (pageController.position.haveDimensions
                          ? pageController.page! - index
                          : index - levels.indexOf(selectedLevel)) *
                      0.5; // adjust for rotation
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(rotationY),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: levelCard(levels[index], unlocked.contains(levels[index])),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: ScaleTransition(
            scale: _buttonScaleAnimation,
            child: ElevatedButton(
              onPressed: unlocked.contains(selectedLevel)
                  ? () async {
                      confettiController.play();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPage(level: selectedLevel),
                        ),
                      );
                      await _loadUnlocked();
                      await _loadLeaderboard();
                      await _loadCoins();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                backgroundColor: AppTheme.primary,
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Start'),
            ),
          ),
        ),
      ],
    );
  }

  Widget leaderboardTab() {
    if (leaderboardLoading)
      return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Leaderboard — ${selectedLevel.toUpperCase()}',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (_, index) {
              final entry = leaderboard[index];
              final timeMs = entry['time_ms'] as int?;
              final displayTime =
                  timeMs != null ? '${(timeMs / 1000).toStringAsFixed(2)}s' : '--';

              Color bgColor;
              switch (index) {
                case 0:
                  bgColor = Colors.amber.shade300;
                  break;
                case 1:
                  bgColor = Colors.grey.shade300;
                  break;
                case 2:
                  bgColor = Colors.brown.shade300;
                  break;
                default:
                  bgColor = Colors.white;
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.2),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                            color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        entry['users']['username'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      displayTime,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Hello, $username 👋',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          actions: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    await auth.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign out',
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey.shade500,
            tabs: const [
              Tab(text: 'Play'),
              Tab(text: 'Leaderboard'),
              Tab(text: 'Shop'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TabBarView(
            controller: tabController,
            children: [
              playTab(),
              leaderboardTab(),
              ShopPage(
                coins: coins,
                onCoinsChanged: (newCoins) => setState(() => coins = newCoins),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
