import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';
import 'leaderboard_page.dart';
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

  // Leaderboard data
  List<Map<String, dynamic>> leaderboard = [];
  bool leaderboardLoading = true;

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    tabController = TabController(length: 3, vsync: this);
    _loadUnlocked();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    confettiController.dispose();
    tabController.dispose();
    super.dispose();
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
    final res = await quizService.fetchLeaderboard(level: selectedLevel, limit: 20);
    setState(() {
      leaderboard = res;
      leaderboardLoading = false;
    });
  }

  Widget levelCard(String level, bool enabled) {
    final isSelected = selectedLevel == level;
    return GestureDetector(
      onTap: enabled
          ? () {
              setState(() => selectedLevel = level);
              _loadLeaderboard(); // refresh leaderboard for selected level
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: enabled
              ? isSelected
                  ? LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)])
                  : LinearGradient(colors: [Colors.white, Colors.white70])
              : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
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
                  color: enabled ? (isSelected ? Colors.white : Colors.black87) : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              enabled ? 'Unlocked' : 'Locked',
              style: TextStyle(
                  fontSize: 12,
                  color: enabled ? (isSelected ? Colors.white70 : Colors.black54) : Colors.grey),
            ),
          ],
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3),
                itemCount: levels.length,
                itemBuilder: (_, index) {
                  final lvl = levels[index];
                  return levelCard(lvl, unlocked.contains(lvl));
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: unlocked.contains(selectedLevel)
                          ? () async {
                              confettiController.play();
                              // navigate to QuizPage
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizPage(
                                    level: selectedLevel,
                                  ),
                                ),
                              );
                              // refresh unlocked levels and leaderboard after quiz
                              await _loadUnlocked();
                              await _loadLeaderboard();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: AppTheme.primary,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Start Quiz'),
                    ),
                  ),
                ],
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
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(entry['users']['username'] ?? 'Unknown', style: const TextStyle(fontSize: 16))),
                    //Text('${entry['time_ms']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      entry['time_ms'] != null
                          ? '${(entry['time_ms'] / 1000).toStringAsFixed(1)}s'
                          : '--',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              //'Welcome, ${auth.currentUser?.email ?? 'Guest'}',
              'Welcome, ${auth.currentUser?.email}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
      ),
    );
  }
}
