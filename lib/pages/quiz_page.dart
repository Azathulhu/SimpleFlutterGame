// lib/pages/quiz_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import 'leaderboard_page.dart';

class QuizPage extends StatefulWidget {
  final String level;
  const QuizPage({super.key, required this.level});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final QuizService quizService = QuizService();
  final AuthService authService = AuthService();

  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;

  // Timer and health
  Timer? _timer;
  double health = 1.0;
  int totalTimeSeconds = 60; // total quiz time
  int elapsedMs = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final fetched = await quizService.fetchQuestions(widget.level, 10); // default 10
    setState(() {
      questions = fetched;
      loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        elapsedMs += 100;
        health = 1 - (elapsedMs / (totalTimeSeconds * 1000));
        if (health <= 0) {
          health = 0;
          _endQuiz();
        }
      });
    });
  }

  void _answer(String selected) {
    if (selected == questions[currentIndex].answer) {
      score++;
    }

    if (currentIndex + 1 < questions.length) {
      setState(() => currentIndex++);
    } else {
      _endQuiz();
    }
  }

  Future<void> _endQuiz() async {
    _timer?.cancel();

    final user = authService.currentUser;
    if (user != null) {
      await quizService.submitPerfectRun(
        userId: user.id,
        timeMs: elapsedMs,
        level: widget.level,
        totalQuestions: questions.length,
        score: score,
      );
    }

    Fluttertoast.showToast(
        msg: "Quiz Finished! Score: $score/${questions.length}");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => LeaderboardPage(level: widget.level)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Quiz - ${widget.level}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: health, minHeight: 10),
            const SizedBox(height: 12),
            Text(
              "Time: ${(elapsedMs / 1000).toStringAsFixed(1)}s",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Text(
              currentQuestion.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...currentQuestion.options.map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: () => _answer(o),
                  child: Text(o),
                ),
              ),
            ),
            const Spacer(),
            Text("Score: $score/${questions.length}"),
          ],
        ),
      ),
    );
  }
}
