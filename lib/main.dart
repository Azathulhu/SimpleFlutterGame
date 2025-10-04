import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_in_page.dart';

const String SUPABASE_URL = 'https://hwnrfdorpsazrujmoxhl.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bnJmZG9ycHNhenJ1am1veGhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDg1NDQsImV4cCI6MjA3NTEyNDU0NH0.iynHcMIAVTPxaoYL94OldQnLh7DD0SRJkaTXg7ckGc8';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  runApp(const QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  const QuizMasterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Master',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.green[50],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const SignInPage(),
    );
  }
}
