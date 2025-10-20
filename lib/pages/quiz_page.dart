import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';

class QuizPage extends StatefulWidget {
  final String level;
  final Function(String)? onLevelUnlocked;

  const QuizPage({required this.level, this.onLevelUnlocked, super.key});

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

  late AnimationController _controller;
  late ConfettiController _confettiController;

  Timer? _timer;
  double health = 1.0; // 100%
  static const int totalTimeSeconds = 60; // total quiz duration
  int elapsedSeconds = 0;

  static const double unlockThreshold = 0.6; // 60%

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
      currentIndex = 0;
      score = 0;
      health = 1.0;
      elapsedSeconds = 0;
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
    _controller.forward();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
        health = (totalTimeSeconds - elapsedSeconds) / totalTimeSeconds;
        if (health <= 0) {
          _timer?.cancel();
          _onComplete();
        }
      });
    });
  }

  void _answer(String selected) {
    final current = questions[currentIndex];
    final correct = current.answer == selected;
    if (!correct) {
      // Any wrong answer ends the quiz
      _timer?.cancel();
      _onComplete();
      return;
    }
    score++;
    _controller.forward(from: 0);

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _timer?.cancel();
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    final user = auth.currentUser;
    final allCorrect = score == questions.length;
    final completionTime = elapsedSeconds.toDouble();

    if (user != null && allCorrect) {
      // Only submit if all answers correct
      await quizService.submitFastestTime(
        userId: user.id,
        score: score,
        level: widget.level,
        fastestTime: completionTime,
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score / ${questions.length}'),
            const SizedBox(height: 8),
            Text('Time: ${elapsedSeconds}s'),
            if (!allCorrect) const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('You got some answers wrong. No leaderboard record.'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _load();
            },
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (errorMessage != null) {
      return AnimatedGradientBackground(
        child: GlobalTapRipple(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text('Quiz')),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ),
          ),
        ),
      );
    }

    final q = questions[currentIndex];
    final progress = (currentIndex) / questions.length;

    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('${widget.level.toUpperCase()} Quiz'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: progress, minHeight: 8),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: health,
                      minHeight: 12,
                      color: Colors.redAccent,
                      backgroundColor: Colors.red.shade100,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      key: ValueKey(q.id),
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question ${currentIndex + 1}/${questions.length}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...q.options.map((opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: ElevatedButton(
                                    onPressed: () => _answer(opt),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    ),
                                    child: Align(alignment: Alignment.centerLeft, child: Text(opt)),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Score: $score', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                      emissionFrequency: 0.05,
                      numberOfParticles: 15,
                      gravity: 0.3,
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
