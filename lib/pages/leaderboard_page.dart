import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final QuizService quizService = QuizService();
  final AuthService auth = AuthService();
  String selectedLevel = 'easy';
  final levels = ['easy', 'medium', 'hard'];
  bool loading = true;
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final res = await quizService.fetchLeaderboard(selectedLevel, 20);
    setState(() {
      entries = res;
      loading = false;
    });
  }

  Widget entryCard(Map<String, dynamic> row, int rank) {
    final username = ((row['users'] ?? {})['username']) ?? 'Unknown';
    final score = row['score'] ?? 0;
    final isMe = auth.currentUser != null; // (We could compare by user_id if returned)
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(child: Text('#${rank+1}')),
        title: Text(username),
        trailing: Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: levels.map((lvl) {
                final selected = lvl == selectedLevel;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => selectedLevel = lvl);
                        _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected ? AppTheme.primary : Colors.white,
                        foregroundColor: selected ? Colors.white : Colors.black87,
                        elevation: selected ? 6 : 2,
                      ),
                      child: Text(lvl.toUpperCase()),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            if (loading) const Center(child: CircularProgressIndicator()) else Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, idx) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: entryCard(entries[idx], idx),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
