// lib/pages/leaderboard_page.dart
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
    final res = await quizService.fetchLeaderboard(level: selectedLevel, limit: 50);
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

  String _formatTime(int ms) {
    if (ms < 1000) return '${ms}ms';
    final s = ms ~/ 1000;
    final remainder = ms % 1000;
    return '${s}s ${remainder}ms';
  }

  Widget leaderboardEntry(Map<String, dynamic> entry, int rank) {
    final username = (entry['users'] != null && entry['users']['username'] != null)
        ? entry['users']['username'] as String
        : 'Unknown';
    final timeMs = entry['time_ms'] as int?;
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
          Expanded(child: Text(username, style: const TextStyle(fontSize: 16))),
          if (timeMs != null)
            Text(_formatTime(timeMs), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                ? const Center(child: Text('No perfect runs recorded yet.'))
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
