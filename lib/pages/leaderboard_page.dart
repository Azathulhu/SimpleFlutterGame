import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../theme.dart';

class LeaderboardPage extends StatefulWidget {
  final String level;
  const LeaderboardPage({super.key, required this.level});

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
    final data = await quizService.fetchLeaderboard(level: widget.level, limit: 50);
    setState(() {
      leaderboard = data;
      loading = false;
    });
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final msRemainder = ms % 1000;
    return '${s}s ${msRemainder}ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : leaderboard.isEmpty
                ? const Center(child: Text('No perfect runs yet'))
                : ListView.builder(
                    itemCount: leaderboard.length,
                    itemBuilder: (context, index) {
                      final entry = leaderboard[index];
                      final username = (entry['users'] as Map)['username'] ?? 'Unknown';
                      return ListTile(
                        leading: Text('#${index + 1}'),
                        title: Text(username),
                        trailing: Text(_formatTime(entry['time_ms'] as int)),
                      );
                    },
                  ),
      ),
    );
  }
}
