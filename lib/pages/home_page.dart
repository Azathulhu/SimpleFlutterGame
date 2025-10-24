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

  // Play Tab content (refined)
  Widget playTab() {
    if (loading) return const Center(child: CircularProgressIndicator());

    final pageController = PageController(viewportFraction: 0.56, initialPage: levels.indexOf(selectedLevel));

    return Column(
      children: [
        const SizedBox(height: 20),
        _glassCard(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose difficulty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.95)),
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
                          value = (1 - (value.abs() * 0.45)).clamp(0.0, 1.0);
                        } else {
                          value = index == levels.indexOf(selectedLevel) ? 1 : 0.7;
                        }
                        return Transform(
                          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY((pageController.position.haveDimensions ? pageController.page! - index : index - levels.indexOf(selectedLevel)) * 0.45),
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
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(level: selectedLevel)));
                          await _loadUnlocked();
                          await _loadCoins();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: AppTheme.primary.withOpacity(0.95),
                  ),
                  child: const Text('Start Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget levelCard(String level, bool enabled, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected ? LinearGradient(colors: [AppTheme.primary.withOpacity(0.95), AppTheme.accent.withOpacity(0.9)]) : LinearGradient(colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))] : [],
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(level == 'easy' ? Icons.looks_one : level == 'medium' ? Icons.looks_two : Icons.looks_3,
              size: 34, color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(height: 12),
          Text(level.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(enabled ? 'Unlocked' : 'Locked', style: TextStyle(color: isSelected ? Colors.white70 : Colors.white60, fontSize: 12)),
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
                    Expanded(child: Text('Leaderboard — ${selectedLevel.toUpperCase()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95)))),
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
                            CircleAvatar(backgroundColor: AppTheme.primary.withOpacity(0.14), child: Text('${idx + 1}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry['users']?['username'] ?? 'Unknown', style: const TextStyle(fontSize: 16))),
                            Text(displayTime, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // main build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // transparent so background widget shows
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // particle background
          const ParticleBackground(),
          // content safe area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // header with glass card
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
                                child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'G', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Hello, $username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95)))),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      await auth.signOut();
                                      if (!mounted) return;
                                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SignInPage()), (route) => false);
                                    },
                                    child: Text('Sign out', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
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
                  // page area
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => activeIndex = idx),
                      children: [
                        // use subtle AnimatedSwitcher to get futuristic transitions
                        AnimatedSwitcher(duration: const Duration(milliseconds: 650), transitionBuilder: (child, anim) {
                          final inAnim = Tween<Offset>(begin: const Offset(0.03, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                          return FadeTransition(opacity: anim, child: SlideTransition(position: inAnim, child: child));
                        }, child: SizedBox(key: ValueKey('play-$selectedLevel'), child: playTab())),
                        AnimatedSwitcher(duration: const Duration(milliseconds: 650), transitionBuilder: (child, anim) {
                          final inAnim = Tween<Offset>(begin: const Offset(0.03, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                          return FadeTransition(opacity: anim, child: SlideTransition(position: inAnim, child: child));
                        }, child: Container(key: const ValueKey('leaderboard'), child: leaderboardTab())),
                        AnimatedSwitcher(duration: const Duration(milliseconds: 650), transitionBuilder: (child, anim) {
                          final inAnim = Tween<Offset>(begin: const Offset(0.03, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                          return FadeTransition(opacity: anim, child: SlideTransition(position: inAnim, child: child));
                        }, child: Container(key: const ValueKey('shop'), child: shopTab())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 78), // leave space for the floating nav
                ],
              ),
            ),
          ),
          // confetti
          Positioned(top: 10, right: 8, child: ConfettiWidget(confettiController: confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, colors: [AppTheme.primary, AppTheme.accent, Colors.amber])),
          // floating bottom nav
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 22, offset: const Offset(0, 12))],
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(icon: Icons.play_circle_fill, label: 'Play', selected: activeIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.leaderboard, label: 'Leaders', selected: activeIndex == 1, onTap: () => onTap(1)),
              _CenterBlob(onPressed: () => onTap(2), active: activeIndex == 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: selected
            ? BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(14))
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: selected ? AppTheme.primary : Colors.white70),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: selected ? AppTheme.primary : Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _CenterBlob extends StatefulWidget {
  final VoidCallback onPressed;
  final bool active;
  const _CenterBlob({required this.onPressed, required this.active});

  @override
  State<_CenterBlob> createState() => _CenterBlobState();
}

class _CenterBlobState extends State<_CenterBlob> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Icon(Icons.storefront, color: Colors.white),
        ),
      ),
    );
  }
}

// ---------------- Particle Background ----------------
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});
  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Node> nodes = [];
  final Random rng = Random();

  static const int nodeCount = 28;
  static const double maxDist = 110;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ensureNodes(Size s) {
    if (nodes.isNotEmpty && nodes.first.screenSize == s) return;
    nodes.clear();
    for (var i = 0; i < nodeCount; i++) {
      nodes.add(_Node(
        pos: Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height),
        vel: Offset((rng.nextDouble() - 0.5) * 0.6, (rng.nextDouble() - 0.5) * 0.6),
        screenSize: s,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final s = Size(constraints.maxWidth, constraints.maxHeight);
      _ensureNodes(s);
      // update positions slightly
      for (final n in nodes) {
        n.pos += n.vel;
        if (n.pos.dx < 0 || n.pos.dx > s.width) n.vel = Offset(-n.vel.dx, n.vel.dy);
        if (n.pos.dy < 0 || n.pos.dy > s.height) n.vel = Offset(n.vel.dx, -n.vel.dy);
      }
      return CustomPaint(
        size: s,
        painter: _ParticlePainter(nodes: nodes, animation: _ctrl, maxDist: maxDist),
      );
    });
  }
}

class _Node {
  Offset pos;
  Offset vel;
  final Size screenSize;
  _Node({required this.pos, required this.vel, required this.screenSize});
}

class _ParticlePainter extends CustomPainter {
  final List<_Node> nodes;
  final Animation<double> animation;
  final double maxDist;
  _ParticlePainter({required this.nodes, required this.animation, required this.maxDist}) : super(repaint: animation);

  final Paint dotPaint = Paint()..color = Colors.white.withOpacity(0.85);
  final Paint linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    // backdrop subtle gradient
    final rect = Offset.zero & size;
    final grad = LinearGradient(colors: [const Color(0xFF081226).withOpacity(0.45), const Color(0xFF061222).withOpacity(0.45)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    canvas.drawRect(rect, Paint()..shader = grad.createShader(rect));

    for (int i = 0; i < nodes.length; i++) {
      final a = nodes[i].pos;
      // draw dot
      canvas.drawCircle(a, 2.3, dotPaint..color = Colors.white.withOpacity(0.85));
      // connect to others
      for (int j = i + 1; j < nodes.length; j++) {
        final b = nodes[j].pos;
        final d = (a - b).distance;
        if (d < maxDist) {
          final alpha = (1.0 - (d / maxDist)) * 0.55;
          linePaint.color = Colors.white.withOpacity(alpha * 0.9);
          canvas.drawLine(a, b, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

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
