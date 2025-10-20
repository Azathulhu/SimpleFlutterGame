import 'dart:async';
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

  // Timer & Health
  static const int totalTime = 60; // total quiz seconds
  double healthPercent = 1.0;
  Timer? quizTimer;
  late DateTime startTime;

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
    quizTimer?.cancel();
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

    startTime = DateTime.now();
    healthPercent = 1.0;
    _startTimer();

    _controller.forward();
  }

  void _startTimer() {
    quizTimer?.cancel();
    quizTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      setState(() {
        healthPercent = 1 - (elapsed / totalTime);
      });
      if (healthPercent <= 0) {
        quizTimer?.cancel();
        _onComplete();
      }
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
      quizTimer?.cancel();
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    final elapsedTime = DateTime.now().difference(startTime).inSeconds;
    final user = auth.currentUser;
    if (user != null) {
      int? timeForPerfect;
      if (score == questions.length) timeForPerfect = elapsedTime;
      await quizService.submitScore(
        userId: user.id,
        score: score,
        level: widget.level,
        time: timeForPerfect,
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
            Text('Time: ${elapsedTime}s'),
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
              Navigator.of(context).pop();
              Navigator.of(context).pop();
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
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 10,
                          decoration: BoxDecoration(
                              color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * healthPercent,
                          height: 10,
                          decoration: BoxDecoration(
                              color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation),
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
                              Text('Q${currentIndex + 1}: ${q.text}', style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 12),
                              ...q.options.map(
                                (opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: ElevatedButton(
                                    onPressed: () => _answer(opt),
                                    child: Text(opt),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
