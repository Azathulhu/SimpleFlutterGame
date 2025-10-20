import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../theme.dart';
import '../animated_background.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final QuizService quizService = QuizService();
  final levels = ['easy', 'medium', 'hard'];
  String selectedLevel = 'easy';
  bool loading = true;
  List<Map<String, dynamic>> leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => loading = true);
    final res = await quizService.fetchLeaderboardFastest(level: selectedLevel, limit: 20);
    setState(() {
      leaderboard = res;
      loading = false;
    });
  }

  Widget levelButton(String level) {
    final isSelected = selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() => selectedLevel = level);
        _loadLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
        ),
        child: Text(
          level.toUpperCase(),
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget leaderboardEntry(Map<String, dynamic> entry, int rank) {
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
          Text('#${rank + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(child: Text(entry['users']['username'] ?? 'Unknown', style: const TextStyle(fontSize: 16))),
          Text('${entry['time']}s', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Leaderboard'), backgroundColor: Colors.transparent, elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: levels.map((lvl) => levelButton(lvl)).toList()),
                    ),
                    const SizedBox(height: 24),
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : Expanded(
                            child: leaderboard.isEmpty
                                ? const Center(child: Text('No perfect runs yet!', style: TextStyle(fontSize: 16)))
                                : ListView.builder(
                                    itemCount: leaderboard.length,
                                    itemBuilder: (_, index) => leaderboardEntry(leaderboard[index], index),
                                  ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
