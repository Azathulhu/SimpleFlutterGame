import 'package:flutter/material.dart';
import '../quiz/quiz_page.dart';
import '../auth_service.dart';

class HomePage extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Master'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Start Quiz'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuizPage()),
          ),
        ),
      ),
    );
  }
}
