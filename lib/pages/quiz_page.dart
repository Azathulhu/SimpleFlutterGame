import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
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

  static const double unlockThreshold = 0.6; // 60%

  // --- Timer & Health ---
  double health = 1.0;
  Timer? healthTimer;
  static const int totalTimeSeconds = 60; // total quiz time
  late Timer countdownTimer;
  int timeLeft = totalTimeSeconds;

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
    healthTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
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
    });
    _controller.forward();

    // Start timers
    health = 1.0;
    timeLeft = totalTimeSeconds;
    healthTimer?.cancel();
    countdownTimer?.cancel();
    healthTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        health -= 0.0016; // approx 60s to zero
        if (health <= 0) {
          health = 0;
          _onComplete();
          healthTimer?.cancel();
        }
      });
    });
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          _onComplete();
          countdownTimer.cancel();
        }
      });
    });
  }

  void _answer(String selected) {
    final current = questions[currentIndex];
    final correct = current.answer == selected;
    if (correct) score++;
    _controller.forward(from: 0);

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    healthTimer?.cancel();
    countdownTimer?.cancel();

    final user = auth.currentUser;
    if (user != null) {
      await quizService.submitScore(
        userId: user.id,
        score: score,
        level: widget.level,
      );
    }

    final totalQuestions = questions.length;
    final percent = totalQuestions > 0 ? score / totalQuestions : 0;
    final unlockedNext = percent >= unlockThreshold;

    String? nextLevel;

    // Check for perfect run
    final recordPerfect = score == totalQuestions;

    // Unlock next level ONLY on perfect run
    if (recordPerfect) {
      if (widget.level == 'easy') nextLevel = 'medium';
      if (widget.level == 'medium') nextLevel = 'hard';

      if (nextLevel != null) {
        if (user != null) await auth.unlockLevel(nextLevel);
        if (widget.onLevelUnlocked != null) widget.onLevelUnlocked!(nextLevel);
        _confettiController.play();
      }
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
            Text('Score: $score / $totalQuestions'),
            const SizedBox(height: 8),
            Text('Percent: ${(100 * (totalQuestions == 0 ? 0 : score / totalQuestions)).toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            Text('Time Left: $timeLeft s'),
            if (recordPerfect)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Congrats — you unlocked the next level!',
                    style: TextStyle(color: AppTheme.primary)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // back to home reliably
            },
            child: const Text('Back to Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                currentIndex = 0;
                score = 0;
              });
              _load();
            },
            child: const Text('Retry'),
          ),
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
                    LinearProgressIndicator(value: health, minHeight: 12),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero)
                            .animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Card(
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
                              Text(q.text,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ...q.options.map(
                                (opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: ElevatedButton(
                                    onPressed: () => _answer(opt),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 12),
                                    ),
                                    child: Align(
                                        alignment: Alignment.centerLeft, child: Text(opt)),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      colors: const [
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.orange,
                        Colors.purple
                      ],
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
