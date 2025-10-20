import 'dart:async';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';

class QuizPage extends StatefulWidget {
  final String level;
  const QuizPage({super.key, required this.level});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  final QuizService quizService = QuizService();
  final AuthService auth = AuthService();

  List<Question> questions = [];
  int currentQuestion = 0;
  int score = 0;

  double health = 1.0; // Health bar 1.0 = full
  late Timer _tickTimer;
  late Stopwatch _stopwatch;
  bool loading = true;
  bool quizFinished = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => loading = true);
    questions = await quizService.fetchQuestions(widget.level, 10);
    _stopwatch = Stopwatch()..start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        health -= 0.0015; // adjust speed of health depletion
        if (health <= 0) {
          health = 0;
          _finishDueToTimeout();
        }
      });
    });
    setState(() => loading = false);
  }

  void _answerQuestion(String answer) {
    if (quizFinished) return;

    if (answer == questions[currentQuestion].answer) score++;
    currentQuestion++;

    if (currentQuestion >= questions.length) {
      _completeQuizEarly();
    }
  }

  Future<void> _completeQuizEarly() async {
    _tickTimer.cancel();
    _stopwatch.stop();
    final isPerfect = score == questions.length;

    if (isPerfect) {
      await quizService.submitScore(
        userId: auth.currentUser!.id,
        score: _stopwatch.elapsedMilliseconds,
        level: widget.level,
      );
    }

    await _unlockNextLevel();

    if (!mounted) return;
    _showCompletionDialog(perfect: isPerfect);
  }

  Future<void> _finishDueToTimeout() async {
    _tickTimer.cancel();
    _stopwatch.stop();

    await quizService.submitScore(
      userId: auth.currentUser!.id,
      score: _stopwatch.elapsedMilliseconds,
      level: widget.level,
    );

    if (!mounted) return;
    _showCompletionDialog(perfect: false);
  }

  Future<void> _unlockNextLevel() async {
    final allLevels = ['easy', 'medium', 'hard'];
    final nextIndex = allLevels.indexOf(widget.level) + 1;
    if (nextIndex < allLevels.length) {
      final nextLevel = allLevels[nextIndex];
      final unlockedLevels = await auth.fetchUnlockedLevels();
      if (!unlockedLevels.contains(nextLevel)) {
        unlockedLevels.add(nextLevel);
        await auth.unlockLevel(nextLevel);
      }
    }
  }

  void _showCompletionDialog({required bool perfect}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(perfect ? 'Perfect Score!' : 'Quiz Finished'),
        content: Text('Your score: $score/${questions.length}\nTime: ${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          )
        ],
      ),
    );
    setState(() => quizFinished = true);
  }

  @override
  void dispose() {
    _tickTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('${widget.level.toUpperCase()} Quiz'),
            centerTitle: true,
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    LinearProgressIndicator(value: health),
                    const SizedBox(height: 16),
                    if (!quizFinished && currentQuestion < questions.length) ...[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          questions[currentQuestion].text,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...questions[currentQuestion].options.map(
                        (opt) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ElevatedButton(
                            onPressed: () => _answerQuestion(opt),
                            child: Text(opt),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final String answer;
  final String difficulty;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answer,
    required this.difficulty,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      text: map['text'],
      options: List<String>.from(map['options']),
      answer: map['answer'],
      difficulty: map['difficulty'],
    );
  }
}
