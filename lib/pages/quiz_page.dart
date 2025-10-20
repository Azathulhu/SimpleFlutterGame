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

  double health = 100; // health bar percentage
  Timer? timer;
  int totalTimeSeconds = 60; // total quiz time
  int remainingTime = 60;

  late ConfettiController _confettiController;

  static const double unlockThreshold = 0.6; // 60%

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    remainingTime = totalTimeSeconds;
    health = 100;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0 && health > 0) {
        setState(() {
          remainingTime--;
          health = (remainingTime / totalTimeSeconds) * 100;
        });
      } else {
        _onComplete();
        t.cancel();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
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
      currentIndex = 0;
      score = 0;
    });
    _startTimer();
  }

  void _answer(String selected) {
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
    timer?.cancel();
    final user = auth.currentUser;
    if (user != null) {
      await quizService.submitPerfectScore(
        userId: user.id,
        score: score,
        level: widget.level,
        totalQuestions: questions.length,
      );
    }

    final percent = questions.isNotEmpty ? score / questions.length : 0;
    final unlockedNext = (widget.level == 'easy' && percent >= unlockThreshold) ||
        (widget.level == 'medium' && percent >= unlockThreshold);

    String? next;
    if (unlockedNext) {
      if (widget.level == 'easy') next = 'medium';
      if (widget.level == 'medium') next = 'hard';
      if (next != null) {
        await auth.unlockLevel(next);
        if (widget.onLevelUnlocked != null) widget.onLevelUnlocked!(next);
        _confettiController.play();
      }
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
            Text('Percent: ${(100 * (questions.isEmpty ? 0 : score / questions.length)).toStringAsFixed(0)}%'),
            if (unlockedNext)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Congrats — you unlocked the next level!', style: TextStyle(color: AppTheme.primary)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // exit quiz to home
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
    final progress = currentIndex / questions.length;

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
                    const SizedBox(height: 12),
                    Text('Time: $remainingTime s', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: health / 100, minHeight: 8, color: Colors.red),
                    const SizedBox(height: 12),
                    Card(
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
