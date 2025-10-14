import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'dart:math';

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
  bool loading = true;
  String? errorMessage;
  late AnimationController _controller;
  late ConfettiController _confettiController;

  // progression threshold: percent to unlock next level
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; errorMessage = null; });
    final fetched = await quizService.fetchQuestions(widget.level, 5);
    if (fetched.isEmpty) {
      setState(() {
        errorMessage = 'No questions available for ${widget.level}.';
        loading = false;
      });
      return;
    }
    setState(() { questions = fetched; loading = false; });
    _controller.forward();
  }

  void _answer(String selected) {
    final current = questions[currentIndex];
    final correct = current.answer == selected;
    if (correct) score++;
    // animate a small success
    _controller.forward(from: 0);
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      // Completed quiz
      _onComplete();
    }
  }

  Future<void> _onComplete() async {
    // submit score first
    final user = auth.currentUser;
    if (user != null) {
      await quizService.submitScore(userId: user.id, score: score, level: widget.level);
    }
    final percent = questions.isNotEmpty ? score / questions.length : 0;
    final unlockedNext = (widget.level == 'easy' && percent >= unlockThreshold) ||
        (widget.level == 'medium' && percent >= unlockThreshold);
    if (unlockedNext) {
      // unlock the next level if applicable
      final next = widget.level == 'easy' ? 'medium' : (widget.level == 'medium' ? 'hard' : null);
      if (next != null) {
        await auth.unlockLevel(next);
      }
      _confettiController.play();
    }

    // show result dialog
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
            if (unlockedNext) Padding(
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
              // restart quiz
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
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final q = questions[currentIndex];
    final progress = (currentIndex) / questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.level.toUpperCase()} Quiz'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                          Text('Question ${currentIndex + 1}/${questions.length}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 8),
                          Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ...q.options.map((opt) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ScaleOnTap(
                              onTap: () => _answer(opt),
                              child: ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                ),
                                child: Align(alignment: Alignment.centerLeft, child: Text(opt)),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text('Score: $score', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              emissionFrequency: 0.05,
              numberOfParticles: 15,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
/*import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final QuizService quizService = QuizService();
  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final fetched = await quizService.fetchQuestions('easy', 5);
      if (fetched.isEmpty) {
        throw Exception('No questions found in database.');
      }
      setState(() {
        questions = fetched;
      });
    } catch (e) {
      print('Error fetching questions: $e');
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void answer(String selected) {
    if (questions[currentIndex].answer == selected) score++;
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      quizService.submitScore(
        userId: AuthService().currentUser!.id,
        score: score,
        level: 'easy',
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Quiz Completed!'),
          content: Text('Score: $score/${questions.length}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loadQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentIndex + 1}/${questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(q.text, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ...q.options.map(
              (opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => answer(opt),
                  child: Text(opt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }*/
}
