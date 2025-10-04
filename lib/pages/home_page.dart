import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'quiz_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService().currentUser?.email ?? 'Guest';
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome $userEmail!', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizPage()),
              ),
              child: const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
