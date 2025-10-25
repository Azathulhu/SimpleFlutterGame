import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sound_effect_service.dart';

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
  String? equippedBackgroundUrl;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _stopwatch = Stopwatch();
    _loadEquippedBackground();
    _load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tickTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadEquippedBackground() async {
    final user = auth.currentUser;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from('user_items')
        .select('shop_items(asset_url)')
        .eq('user_id', user.id)
        .eq('equipped', true)
        .maybeSingle();

    if (res != null) {
      setState(() {
        equippedBackgroundUrl = res['shop_items']['asset_url'];
      });
    } else {
      setState(() {
        equippedBackgroundUrl = null;
      });
    }
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
        errorMessage = 'No questions available for ${widget.level}';
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

    final user = auth.currentUser;
    if (user != null) {
      final isPerfect = score == questions.length;

      if (isPerfect) {
        await quizService.submitPerfectTime(
          userId: user.id,
          level: widget.level,
          score: score,
          timeMs: _stopwatch.elapsedMilliseconds,
        );
        await auth.addCoins(score);
      } else {
        await quizService.submitScore(
          userId: user.id,
          level: widget.level,
          score: score,
        );
      }

      latestLeaderboard = await quizService.fetchLeaderboard(
        level: widget.level,
        limit: 50,
      );
      setState(() {});
    }

    _showCompletionDialog(recordedPerfect: score == questions.length);
  }

  Future<void> _completeQuizEarly() async {
    _tickTimer?.cancel();
    _stopwatch.stop();

    final isPerfect = score == questions.length;
    final user = auth.currentUser;
    if (user != null) {
      if (isPerfect) {
        await quizService.submitPerfectTime(
          userId: user.id,
          level: widget.level,
          score: score,
          timeMs: _stopwatch.elapsedMilliseconds,
        );
        await auth.addCoins(score);

        // Unlock levels
        await auth.unlockLevel(widget.level);
        final idx = levelOrder.indexOf(widget.level);
        if (idx < levelOrder.length - 1) {
          await auth.unlockLevel(levelOrder[idx + 1]);
        }

        _confettiController.play();
      } else {
        await quizService.submitScore(
          userId: user.id,
          level: widget.level,
          score: score,
        );
      }

      latestLeaderboard = await quizService.fetchLeaderboard(
        level: widget.level,
        limit: 50,
      );
      setState(() {});
    }

    _showCompletionDialog(recordedPerfect: isPerfect);
  }

  void _showCompletionDialog({required bool recordedPerfect}) {
    final elapsedS = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00FFC8), Color(0xFF1DE9B6)],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Quiz Completed',
            style: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.tealAccent.withOpacity(0.9),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score / ${questions.length}',
                style: GoogleFonts.nunitoSans(
                    fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Time: $elapsedS s',
                style: GoogleFonts.nunitoSans(
                    fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 12),
            if (recordedPerfect)
              Text('Congratulations!',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1DE9B6),
                    shadows: [
                      Shadow(
                        color: Colors.tealAccent.withOpacity(0.8),
                        blurRadius: 10,
                      ),
                    ],
                  )),
            const SizedBox(height: 12),
            const Divider(color: Colors.tealAccent),
            const SizedBox(height: 8),
            const Text('Top fastest perfect runs:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 8),
            if (latestLeaderboard.isEmpty)
              const Text('No perfect runs recorded yet.',
                  style: TextStyle(color: Colors.white54)),
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
                    final timeText =
                        timeMs != null ? '${(timeMs / 1000).toStringAsFixed(2)}s' : '--';
                    return ListTile(
                      leading: Text('#${i + 1}',
                          style: const TextStyle(color: Colors.white70)),
                      title: Text(username,
                          style: const TextStyle(color: Colors.white)),
                      trailing: Text(timeText,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.tealAccent)),
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
      );
    }

    final q = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            '${widget.level.toUpperCase()} Quiz',
            style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                shadows: [
                  Shadow(
                      color: Colors.tealAccent.withOpacity(0.7),
                      blurRadius: 12)
                ]),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            image: equippedBackgroundUrl != null
                ? DecorationImage(
                    image: NetworkImage(equippedBackgroundUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: healthPercent,
                              minHeight: 14,
                              backgroundColor: Colors.grey.shade800,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF00FFC8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${((timerDuration.inMilliseconds * healthPercent) / 1000).clamp(0, timerDuration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Colors.tealAccent.withOpacity(0.7),
                                  blurRadius: 6)
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade800,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      key: ValueKey(q.id),
                      color: const Color(0xFF0D1B2A).withOpacity(0.85),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: Colors.tealAccent.withOpacity(0.4), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question ${currentIndex + 1}/${questions.length}',
                                style: GoogleFonts.nunitoSans(
                                    fontSize: 16,
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          color: Colors.tealAccent.withOpacity(0.7),
                                          blurRadius: 8)
                                    ])),
                            const SizedBox(height: 8),
                            Text(q.text,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        color: Colors.tealAccent.withOpacity(0.5),
                                        blurRadius: 6)
                                  ],
                                )),
                            const SizedBox(height: 16),
                            ...q.options.map((opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: ElevatedButton(
                                    
                                    onPressed: (){
                                      SoundEffectService().play('assets/sfx/tap.mp3');
                                      _answer(opt);
                                    },
                                    //onPressed: () => _answer(opt),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF00FFC8).withOpacity(0.15),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                            color: Colors.tealAccent.withOpacity(0.6),
                                            width: 1.5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 16),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        opt,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.tealAccent,
                                          shadows: [
                                            Shadow(
                                                color:
                                                    Colors.tealAccent.withOpacity(0.6),
                                                blurRadius: 8)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Score: $score',
                        style: GoogleFonts.nunitoSans(
                            fontSize: 18,
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Colors.tealAccent.withOpacity(0.7),
                                  blurRadius: 8)
                            ])),
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

/*import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../animated_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
  String? equippedBackgroundUrl;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _stopwatch = Stopwatch();
    _loadEquippedBackground();
    _load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tickTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadEquippedBackground() async {
    final user = auth.currentUser;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from('user_items')
        .select('shop_items(asset_url)')
        .eq('user_id', user.id)
        .eq('equipped', true)
        .maybeSingle();

    if (res != null) {
      setState(() {
        equippedBackgroundUrl = res['shop_items']['asset_url'];
      });
    } else {
      setState(() {
        equippedBackgroundUrl = null;
      });
    }
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

    final user = auth.currentUser;
    if (user != null) {
      final isPerfect = score == questions.length;

      if (isPerfect) {
        await quizService.submitPerfectTime(
          userId: user.id,
          level: widget.level,
          score: score,
          timeMs: _stopwatch.elapsedMilliseconds,
        );
        await auth.addCoins(score);
      } else {
        await quizService.submitScore(
          userId: user.id,
          level: widget.level,
          score: score,
        );
      }

      latestLeaderboard = await quizService.fetchLeaderboard(
        level: widget.level,
        limit: 50,
      );
      setState(() {});
    }

    _showCompletionDialog(recordedPerfect: score == questions.length);
  }

  Future<void> _completeQuizEarly() async {
    _tickTimer?.cancel();
    _stopwatch.stop();

    final isPerfect = score == questions.length;
    final user = auth.currentUser;
    if (user != null) {
      if (isPerfect) {
        await quizService.submitPerfectTime(
          userId: user.id,
          level: widget.level,
          score: score,
          timeMs: _stopwatch.elapsedMilliseconds,
        );
        await auth.addCoins(score);

        // Unlock levels
        await auth.unlockLevel(widget.level);
        final idx = levelOrder.indexOf(widget.level);
        if (idx < levelOrder.length - 1) {
          await auth.unlockLevel(levelOrder[idx + 1]);
        }

        _confettiController.play();
      } else {
        await quizService.submitScore(
          userId: user.id,
          level: widget.level,
          score: score,
        );
      }

      latestLeaderboard = await quizService.fetchLeaderboard(
        level: widget.level,
        limit: 50,
      );
      setState(() {});
    }

    _showCompletionDialog(recordedPerfect: isPerfect);
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
          body: Container(
            decoration: BoxDecoration(
              image: equippedBackgroundUrl != null
                  ? DecorationImage(
                      image: NetworkImage(equippedBackgroundUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Center(
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
      ),
    );
  }
}*/
