import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Home')),
      body: Center(
        child: Text('Welcome ${AuthService().currentUser?.email ?? ''}'),
      ),
    );
  }
}
