import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_in_page.dart';
import 'theme.dart';
import 'services/music_service.dart';

const String SUPABASE_URL = 'https://hwnrfdorpsazrujmoxhl.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bnJmZG9ycHNhenJ1am1veGhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDg1NDQsImV4cCI6MjA3NTEyNDU0NH0.iynHcMIAVTPxaoYL94OldQnLh7DD0SRJkaTXg7ckGc8';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);

  // Play background music at app start
  MusicService().play('assets/audio/analogmemory.mp3');

  runApp(const QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  const QuizMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLAC Quiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SignInPage(),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_in_page.dart';
import 'theme.dart';

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
      title: 'SLAC Quiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SignInPage(),
    );
  }
}*/
