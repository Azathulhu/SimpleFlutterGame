// lib/pages/quiz_page.dart
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

  // Timer / Health settings
  static const Duration defaultTimerDuration = Duration(seconds: 60);
  Duration timerDuration = defaultTimerDuration;
  Timer? _tickTimer;
  late Stopwatch _stopwatch;
  double healthPercent = 1.0; // 1.0 = full health, 0.0 = dead
  bool quizEnded = false;

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
    _tickTimer?.cancel();
    try {
      _stopwatch.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
      quizEnded = false;
    });
    final fetched = await quizService.fetchQuestions(widget.level, quizService.questionsCountForLevel(widget.level));
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
      timerDuration = widget.level == 'easy'
          ? const Duration(seconds: 60)
          : widget.level == 'medium'
              ? const Duration(seconds: 45)
              : const Duration(seconds: 30);
      healthPercent = 1.0;
    });

    _stopwatch = Stopwatch()..start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    _controller.forward();
  }

  void _onTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    final elapsed = _stopwatch.elapsed;
    final remaining = timerDuration - elapsed;
    final newHealth = remaining.inMilliseconds / timerDuration.inMilliseconds;
    setState(() {
      healthPercent = newHealth.clamp(0.0, 1.0);
    });

    if (remaining <= Duration.zero && !quizEnded) {
      quizEnded = true;
      _finishBecauseTimeout();
    }
  }

  void _answer(String selected) {
    if (quizEnded) return;
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

  Future<void> _finishBecauseTimeout() async {
    _tickTimer?.cancel();
    _stopwatch.stop();

    final user = auth.currentUser;
    if (user != null) {
      await quizService.submitScore(userId: user.id, score: score, level: widget.level);
    }

    if (!mounted) return;
    _showCompletionDialog(timeMs: _stopwatch.elapsedMilliseconds);
  }

  Future<void> _onComplete() async {
    _tickTimer?.cancel();
    _stopwatch.stop();

    final user = auth.currentUser;
    if (user != null) {
      await quizService.submitScore(userId: user.id, score: score, level: widget.level);

      if (score == questions.length) {
        final elapsedMs = _stopwatch.elapsedMilliseconds;
        await quizService.submitPerfectTime(
          userId: user.id,
          timeMs: elapsedMs,
          level: widget.level,
          score: score,
        );
        _confettiController.play();
      }
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
    _showCompletionDialog(timeMs: _stopwatch.elapsedMilliseconds, unlockedNext: unlockedNext);
  }

  void _showCompletionDialog({required int timeMs, bool unlockedNext = false}) {
    final seconds = (timeMs / 1000).toStringAsFixed(2);
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
            Text('Time: $seconds s'),
            if (score == questions.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Perfect run! Time recorded on leaderboard.', style: TextStyle(color: AppTheme.primary)),
              ),
            if (!(score == questions.length))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Only perfect runs are recorded in the leaderboard.'),
              ),
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
              Navigator.of(context).pop(true); // exit quiz to home; return true to indicate completion
            },
            child: const Text('Back to Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                currentIndex = 0;
                score = 0;
                quizEnded = false;
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
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: healthPercent,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${((timerDuration.inMilliseconds * healthPercent) / 1000).ceil()}s',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress, minHeight: 8),
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
