// lib/pages/quiz_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  int totalTimeSeconds = 60; // default, will be set per difficulty
  int elapsedMs = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _determineTimeByDifficulty();
    _loadQuestions();
  }

  void _determineTimeByDifficulty() {
    switch (widget.level) {
      case 'easy':
        totalTimeSeconds = 60;
        break;
      case 'medium':
        totalTimeSeconds = 45;
        break;
      case 'hard':
        totalTimeSeconds = 30;
        break;
      default:
        totalTimeSeconds = 60;
    }
  }

  Future<void> _loadQuestions() async {
    // match QuizService expected question count (QuizService default is 5 unless you change)
    final fetched = await quizService.fetchQuestions(widget.level, quizService.defaultQuestionCount);
    setState(() {
      questions = fetched;
      loading = false;
      currentIndex = 0;
      score = 0;
      elapsedMs = 0;
      health = 1.0;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
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
    if (questions.isEmpty) return;
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
      // submit perfect run if applicable (QuizService will ignore non-perfect runs)
      await quizService.submitPerfectRun(
        userId: user.id,
        timeMs: elapsedMs,
        level: widget.level,
        totalQuestions: questions.length,
        score: score,
      );
    }

    Fluttertoast.showToast(msg: "Quiz Finished! Score: $score/${questions.length}");

    if (!mounted) return;
    // Replace route with leaderboard for this level so the leaderboard shows immediately
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LeaderboardPage(initialLevel: widget.level)),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Quiz - ${widget.level.toUpperCase()}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: health, minHeight: 10),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text("${(elapsedMs / 1000).toStringAsFixed(2)}s", style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 20),
            Text(
              "Q ${currentIndex + 1}/${questions.length}",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              currentQuestion.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...currentQuestion.options.map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _answer(o),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Align(alignment: Alignment.centerLeft, child: Text(o)),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text("Score: $score/${questions.length}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
