import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';

class QuizPage extends StatefulWidget {
  final String level;
  const QuizPage({required this.level, super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  final QuizService quizService = QuizService();
  final AuthService auth = AuthService();

  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool loading = true;
  String? errorMessage;

  late ConfettiController _confettiController;
  late Stopwatch _stopwatch;
  late Timer _tickTimer;

  double health = 1.0; // health bar 0.0-1.0
  static const int quizDuration = 60; // seconds

  List<Map<String, dynamic>> leaderboard = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _stopwatch = Stopwatch();
    _load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tickTimer.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
      health = 1.0;
      currentIndex = 0;
      score = 0;
      leaderboard = [];
    });

    final fetched = await quizService.fetchQuestions(widget.level, 5);
    if (fetched.isEmpty) {
      setState(() {
        errorMessage = 'No questions available for ${widget.level}.';
        loading = false;
      });
      return;
    }

    setState(() {
      questions = fetched;
      loading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();

    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      setState(() {
        health -= 0.0033; // roughly 1.0 in 60 sec
        if (health <= 0) {
          health = 0;
          _onComplete();
        }
      });
    });
  }

  void _answer(String selected) {
    if (currentIndex >= questions.length) return;
    final current = questions[currentIndex];
    final correct = current.answer == selected;
    if (correct) score++;

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    _tickTimer.cancel();
    _stopwatch.stop();

    final user = auth.currentUser;
    if (user != null) {
      await quizService.submitScore(userId: user.id, score: score, level: widget.level);

      // only perfect runs
      if (score == questions.length) {
        final elapsedMs = _stopwatch.elapsedMilliseconds;
        await quizService.submitPerfectTime(
          userId: user.id,
          level: widget.level,
          score: score,
          timeMs: elapsedMs,
        );
      }

      leaderboard = await quizService.fetchLeaderboard(widget.level);
      _confettiController.play();
      setState(() {}); // refresh UI
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score / ${questions.length}'),
            const SizedBox(height: 8),
            Text('Percent: ${(100 * (score / questions.length)).toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            const Text('Leaderboard (Fastest Perfect Runs)'),
            ...leaderboard.map((e) {
              final username = e['users']?['username'] ?? 'Unknown';
              final timeMs = e['time_ms'] as int?;
              return Text('$username — ${timeMs != null ? (timeMs / 1000).toStringAsFixed(2) + "s" : "--"}');
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Home')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _load();
              },
              child: const Text('Retry')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (errorMessage != null) return Scaffold(body: Center(child: Text(errorMessage!)));

    final q = questions[currentIndex];
    final progress = currentIndex / questions.length;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('${widget.level.toUpperCase()} Quiz'), backgroundColor: Colors.transparent),
        body: Column(
          children: [
            LinearProgressIndicator(value: healt
