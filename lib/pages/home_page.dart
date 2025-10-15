import 'package:flutter/material.dart';
import '../animated_background.dart';
import 'quiz_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> unlockedLevels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProgress();
  }

  Future<void> fetchUserProgress() async {
    // Example data, replace with real Supabase or DB call
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      unlockedLevels = ['Level 1', 'Level 2']; // dynamic data here
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Your Progress",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Level Buttons
                        Column(
                          children: unlockedLevels
                              .map(
                                (level) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.15),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 28),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final completed = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QuizPage(level: level),
                                        ),
                                      );

                                      if (completed == true) {
                                        setState(() {
                                          fetchUserProgress();
                                        });
                                      }
                                    },
                                    child: Center(
                                      child: Text(
                                        level,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: 50),
                        Text(
                          "Tap anywhere for ripple animation",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
