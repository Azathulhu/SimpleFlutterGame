import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestion = 0;
  int score = 0;

  // Example questions
  List<Map<String, dynamic>> questions = [
    {
      'text': 'Flutter is developed by?',
      'options': ['Apple', 'Google', 'Microsoft', 'Facebook'],
      'answer': 'Google',
      'difficulty': 'easy',
    },
    {
      'text': 'Dart is a ?',
      'options': ['Language', 'Database', 'Framework', 'Library'],
      'answer': 'Language',
      'difficulty': 'easy',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (currentQuestion >= questions.length) {
      return Scaffold(
        body: Center(child: Text('Quiz finished! Score: $score')),
      );
    }

    final q = questions[currentQuestion];
    return Scaffold(
      appBar: AppBar(title: Text('Quiz')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(q['text'], style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ...q['options'].map<Widget>(
              (opt) => ElevatedButton(
                onPressed: () {
                  if (opt == q['answer']) score++;
                  setState(() => currentQuestion++);
                },
                child: Text(opt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
