import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';
import 'leaderboard_page.dart';
import '../theme.dart';
import 'package:confetti/confetti.dart';
import 'sign_in_page.dart';
import '../animated_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final AuthService auth = AuthService();
  List<String> unlocked = ['easy'];
  String selectedLevel = 'easy';
  bool loading = true;
  final levels = ['easy', 'medium', 'hard'];

  late ConfettiController confettiController;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    tabController = TabController(length: 3, vsync: this);
    _loadUnlocked();
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

  Widget levelCard(String level, bool enabled) {
    final isSelected = selectedLevel == level;
    return GestureDetector(
      onTap: enabled ? () => setState(() => selectedLevel = level) : null,
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
              Text(
                'Select a Level',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          ? () {
                              confettiController.play();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          QuizPage(level: selectedLevel)));
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
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.blue,
                    Colors.red,
                    Colors.yellow,
                    Colors.pink,
                    Colors.green
                  ],
                  numberOfParticles: 25,
                  maxBlastForce: 30,
                  minBlastForce: 10,
                  emissionFrequency: 0.05,
                ),
              ),
            ],
          );
  }

  Widget shopTab() {
    return const Center(
      child: Text(
        'Shop Coming Soon!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget leaderboardTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LeaderboardPage())),
        child: const Text('Go to Leaderboard'),
      ),
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
              'Welcome, ${auth.currentUser?.email ?? 'Guest'}',
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
                Tab(text: 'Shop'),
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
                shopTab(),
                leaderboardTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
