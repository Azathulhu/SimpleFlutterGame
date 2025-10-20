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

  String selectedLevel = 'easy';
  List<Map<String, dynamic>> leaderboard = [];
  bool loading = true;

  final List<String> levels = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => loading = true);
    final data = await quizService.fetchLeaderboard(level: selectedLevel, limit: 50);
    setState(() {
      leaderboard = data;
      loading = false;
    });
  }

  Widget _buildLeaderboardList() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (leaderboard.isEmpty) return const Center(child: Text('No records yet.'));

    return ListView.builder(
      shrinkWrap: true,
      itemCount: leaderboard.length,
      itemBuilder: (_, index) {
        final entry = leaderboard[index];
        final username = entry['users']?['username'] ?? 'Unknown';
        final timeMs = entry['time_ms'] as int?;
        final score = entry['score'] as int? ?? 0;

        return ListTile(
          leading: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Score: $score | Time: ${timeMs != null ? (timeMs / 1000).toStringAsFixed(2) + 's' : '--'}'),
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
          title: const Text('Leaderboard'),
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: levels.map((lvl) {
                  final isSelected = lvl == selectedLevel;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? AppTheme.primary : Colors.grey[300],
                          foregroundColor: isSelected ? Colors.white : Colors.black,
                        ),
                        onPressed: () async {
                          setState(() => selectedLevel = lvl);
                          await _loadLeaderboard();
                        },
                        child: Text(lvl.toUpperCase()),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildLeaderboardList()),
              ElevatedButton(
                onPressed: _loadLeaderboard,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Refresh'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
