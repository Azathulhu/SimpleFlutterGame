import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../theme.dart';
import '../animated_background.dart';

class LeaderboardPage extends StatefulWidget {
  final String level;
  const LeaderboardPage({required this.level, super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final QuizService quizService = QuizService();
  bool loading = true;
  List<Map<String, dynamic>> leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => loading = true);
    leaderboard = await quizService.fetchLeaderboard(level: widget.level, limit: 20);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text('${widget.level.toUpperCase()} Leaderboard'), backgroundColor: Colors.transparent, elevation: 0),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : leaderboard.isEmpty
                  ? const Center(child: Text('No records yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: leaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = leaderboard[index];
                        final username = entry['users']['username'] ?? 'Unknown';
                        final score = entry['score'] ?? 0;
                        return Card(
                          elevation: 4,
                          child: ListTile(
                            leading: Text('#${index + 1}'),
                            title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text('Score: $score'),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
