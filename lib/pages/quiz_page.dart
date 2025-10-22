import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';

const List<String> levelOrder = ['easy', 'medium', 'hard'];

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
  int coins = 0;
  bool loading = true;
  String? errorMessage;

  late ConfettiController _confettiController;
  late Stopwatch _stopwatch;
  Timer? _tickTimer;

  double healthPercent = 1.0;
  Duration timerDuration = const Duration(seconds: 60);

  List<Map<String, dynamic>> latestLeaderboard = [];

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
    _tickTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorMessage = null;
      currentIndex = 0;
      score = 0;
      healthPercent = 1.0;
      latestLeaderboard = [];
    });

    final fetched = await quizService.fetchQuestions(widget.level, 5);
    if (fetched.isEmpty) {
      setState(() {
        errorMessage = 'No questions available for ${widget.level}.';
        loading = false;
      });
      return;
    }

    timerDuration = widget.level == 'easy'
        ? const Duration(seconds: 60)
        : widget.level == 'medium'
            ? const Duration(seconds: 45)
            : const Duration(seconds: 30);

    setState(() {
      questions = fetched;
      loading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _tickTimer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();

    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = _stopwatch.elapsed;
      final remaining = timerDuration - elapsed;
      final percent = remaining.inMilliseconds / timerDuration.inMilliseconds;
      setState(() {
        healthPercent = percent.clamp(0.0, 1.0);
      });

      if (remaining <= Duration.zero) {
        _finishDueToTimeout();
      }
    });
  }

  void _answer(String selected) {
    if (loading || currentIndex >= questions.length) return;

    if (questions[currentIndex].answer == selected) score++;

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _completeQuizEarly();
    }
  }

  Future<void> _finishDueToTimeout() async {
    _tickTimer?.cancel();
    _stopwatch.stop();
    await _submitScore(recordPerfect: false);
    if (!mounted) return;
    _showCompletionDialog(recordedPerfect: false);
  }

  Future<void> _completeQuizEarly() async {
    _tickTimer?.cancel();
    _stopwatch.stop();

    final isPerfect = score == questions.length;
    await _submitScore(recordPerfect: isPerfect);

    if (!mounted) return;
    _showCompletionDialog(recordedPerfect: isPerfect);
  }

  Future<void> _submitScore({required bool recordPerfect}) async {
    final user = auth.currentUser;
    if (user == null) return;

    if (recordPerfect) {
      // Perfect run: submit score and time
      await quizService.submitPerfectTime(
        userId: user.id,
        level: widget.level,
        score: score,
        timeMs: _stopwatch.elapsedMilliseconds,
      );

      // Unlock current and next level only if perfect
      await auth.unlockLevel(widget.level);
      final currentIndex = levelOrder.indexOf(widget.level);
      if (currentIndex < levelOrder.length - 1) {
        final nextLevel = levelOrder[currentIndex + 1];
        await auth.unlockLevel(nextLevel);
      }
       // Award coins: formula = base * level multiplier / time seconds
      int base = 50; // base coins for easy
      int multiplier = widget.level == 'easy' ? 1 : widget.level == 'medium' ? 2 : 3;
      int timeSec = _stopwatch.elapsed.inSeconds.clamp(1, 999);
      int coinsEarned = ((base * multiplier) / timeSec * 10).ceil();
    
      await auth.addCoins(coinsEarned); // <-- Add coins
      _confettiController.play();
       // Refresh coins in UI
      if (mounted) {
        final newCoins = await auth.fetchCoins();
        setState(() => coins = newCoins);
      }
    } else {
      // Only submit score if not perfect (time ignored)
      await quizService.submitScore(
        userId: user.id,
        level: widget.level,
        score: score,
      );
    }

    latestLeaderboard = await quizService.fetchLeaderboard(level: widget.level, limit: 50);
    setState(() {});
  }

  void _showCompletionDialog({required bool recordedPerfect}) {
    final elapsedS = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);

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
            Text('Time: $elapsedS s'),
            const SizedBox(height: 12),
            if (recordedPerfect)
              Text('Congratulations!', style: TextStyle(color: AppTheme.primary)),
            if (!recordedPerfect)
              const Text('NOTE: Only perfect runs are recorded for fastest time.'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Top fastest perfect runs:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (latestLeaderboard.isEmpty) const Text('No perfect runs recorded yet.'),
            if (latestLeaderboard.isNotEmpty)
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: latestLeaderboard.length,
                  itemBuilder: (_, i) {
                    final e = latestLeaderboard[i];
                    final username = e['users']?['username'] ?? 'Unknown';
                    final timeMs = e['time_ms'] as int?;
                    final timeText = timeMs != null ? '${(timeMs / 1000).toStringAsFixed(2)}s' : '--';
                    return ListTile(
                      leading: Text('#${i + 1}'),
                      title: Text(username),
                      trailing: Text(timeText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
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
                          '${((timerDuration.inMilliseconds * healthPercent) / 1000).clamp(0, timerDuration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress, minHeight: 8),
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
