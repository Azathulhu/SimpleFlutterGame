import 'package:flutter/material.dart';
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

  /*Widget playTab() {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: levels.length,
            itemBuilder: (_, index) {
              final lvl = levels[index];
              return levelCard(lvl, unlocked.contains(lvl));
            },
          ),
        ),
        const SizedBox(height: 20),
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
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                backgroundColor: AppTheme.primary,
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Start Quiz'),
            ),
          ),
        ),
      ],
    );
  }*/

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
              ShopPage(),
            ],
          ),
        ),
      ),
    );
  }
}
