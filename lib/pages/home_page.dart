import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';
import 'leaderboard_page.dart';
import 'sign_in_page.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService auth = AuthService();
  List<String> unlocked = ['easy'];
  String selectedLevel = 'easy';
  bool loading = true;

  final levels = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _loadUnlocked();
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
    return ScaleOnTap(
      onTap: enabled
          ? () => setState(() => selectedLevel = level)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        width: 120,
        decoration: BoxDecoration(
          color: enabled ? (isSelected ? AppTheme.primary : Colors.white) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,4))] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(level.toUpperCase(), style: TextStyle(color: enabled ? (isSelected ? Colors.white : Colors.black87) : Colors.grey)),
            const SizedBox(height: 8),
            Text(enabled ? 'Unlocked' : 'Locked', style: TextStyle(fontSize: 12, color: enabled ? (isSelected ? Colors.white70 : Colors.black54) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = auth.currentUser?.email ?? 'Guest';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => SignInPage()), (route) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${auth.currentUser?.email ?? 'Guest'}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 18),
                  const Text('Choose Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: levels.map((lvl) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: levelCard(lvl, unlocked.contains(lvl)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ScaleOnTap(
                          onTap: unlocked.contains(selectedLevel) ? () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(level: selectedLevel)));
                          } : null,
                          child: ElevatedButton(
                            onPressed: null,
                            child: const Text('Start Quiz'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ScaleOnTap(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage())),
                        child: ElevatedButton(
                          onPressed: null,
                          child: const Text('Leaderboard'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
/*import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService().currentUser?.email ?? 'Guest';
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome $userEmail!', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizPage()),
              ),
              child: const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}*/
