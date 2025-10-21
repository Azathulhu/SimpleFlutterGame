import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';
import '../theme.dart';
import 'package:confetti/confetti.dart';
import 'sign_in_page.dart';
import '../animated_background.dart';
import '../services/quiz_service.dart';

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

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    tabController = TabController(length: 2, vsync: this);

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
  }

  @override
  void dispose() {
    confettiController.dispose();
    tabController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
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
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.05 : 1.0,
      child: GestureDetector(
        onTap: enabled
            ? () {
                setState(() => selectedLevel = level);
                _loadLeaderboard();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: enabled
                ? isSelected
                    ? LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white, Colors.white70],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                level.toUpperCase(),
                style: TextStyle(
                  color: enabled
                      ? (isSelected ? Colors.white : Colors.black87)
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                enabled ? 'Unlocked' : 'Locked',
                style: TextStyle(
                  fontSize: 14,
                  color: enabled
                      ? (isSelected ? Colors.white70 : Colors.black54)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget playTab() {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Select a Level',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 32),
              ScaleTransition(
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor: AppTheme.primary,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Center(child: Text('Start Quiz')),
                ),
              ),
            ],
          );
  }

  Widget leaderboardTab() {
    return leaderboardLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (_, index) {
              final entry = leaderboard[index];
              final timeMs = entry['time_ms'] as int?;
              final displayTime =
                  timeMs != null ? '${(timeMs / 1000).toStringAsFixed(2)}s' : '--';

              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 400 + index * 100),
                tween: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero),
                builder: (context, Offset offset, child) {
                  return Transform.translate(
                    offset: Offset(0, offset.dy * 50),
                    child: child,
                  );
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: 1,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold),
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
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Hello, $username 👋',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                await auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                    (route) => false);
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
            )
          ],
          bottom: TabBar(
            controller: tabController,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey.shade500,
            tabs: const [
              Tab(text: 'Play'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: TabBarView(
            controller: tabController,
            children: [
              playTab(),
              leaderboardTab(),
            ],
          ),
        ),
      ),
    );
  }
}
