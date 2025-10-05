import 'package:flutter/material.dart';
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
  }
}
