import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/sign_in.dart';

final Color primaryBlue = Color(0xFF4A90E2);
final Color secondaryGreen = Color(0xFF50E3C2);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hwnrfdorpsazrujmoxhl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bnJmZG9ycHNhenJ1am1veGhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDg1NDQsImV4cCI6MjA3NTEyNDU0NH0.iynHcMIAVTPxaoYL94OldQnLh7DD0SRJkaTXg7ckGc8',
  );
  runApp(QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Master',
      theme: ThemeData(
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: SignInPage(),
    );
  }
}
