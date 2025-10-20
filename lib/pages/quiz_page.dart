import 'dart:async';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import '../animated_background.dart';
import '../theme.dart';

class QuizPage extends StatefulWidget {
  final String level;
  const QuizPage({super.key, required this.level});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final QuizService quizService = QuizService();
  final AuthService auth = AuthService();

  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;

  double health = 1.0; // health bar from 1.0 to 0.0
  late Timer healthTimer;
  late Stopwatch stopwatch;

  bool loading = true;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    healthTimer.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => loading = true);
    questions = await quizService.fetchQuestions(widget.level, 10);
    currentIndex = 0;
    score = 0;
    health = 1.0;
    stopwatch = Stopwatch()..start();

    // health slowly decreases over time
    healthTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        health -= 0.002; // adjust speed here
        if (health <= 0) {
          health = 0;
          _finishQuiz();
        }
      });
    });

    setState(() => loading = false);
  }

  void _answer(String answer) {
    if (finished) return;

    if (answer == questions[currentIndex].answer) {
      score++;
      currentIndex++;
      if (currentIndex >= questions.length) {
        _finishQuiz();
      }
    } else {
      // wrong answer ends quiz
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    if (finished) return;

    finished = true;
    healthTimer.cancel();
    stopwatch.stop();

    // unlock next level if finished all questions correctly
    if (score == questions.length) {
      final levels = ['easy', 'medium', 'hard'];
      final nextIndex = levels.indexOf(widget.level) + 1;
      if (nextIndex < levels.length) {
        await auth.unlockLevel(levels[nextIndex]);
      }
      // submit leaderboard only if all answers correct
      await quizService.submitScore(
        userId: auth.currentUser!.id,
        score: stopwatch.elapsedMilliseconds,
        level: widget.level,
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Finished'),
        content: Text('Your score: $score / ${questions.length}\n'
            'Time: ${stopwatch.elapsed.inSeconds}.${(stopwatch.elapsed.inMilliseconds % 1000) ~/ 100}s'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (finished) {
      return const SizedBox.shrink(); // dialog handles finished state
    }

    final question = questions[currentIndex];

    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              '${widget.level.toUpperCase()} Quiz',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: health,
                  minHeight: 12,
                  backgroundColor: Colors.red.shade100,
                  valueColor: AlwaysStoppedAnimation(Colors.green),
                ),
                const SizedBox(height: 20),
                Text(
                  'Question ${currentIndex + 1} of ${questions.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  question.text,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ...question.options.map((opt) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: () => _answer(opt),
                        child: Text(opt),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    )),
                const Spacer(),
                Text(
                  'Score: $score',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
