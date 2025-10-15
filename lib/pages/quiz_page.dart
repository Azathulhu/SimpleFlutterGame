import 'package:flutter/material.dart';
import '../animated_background.dart';

class QuizPage extends StatefulWidget {
  final String level;
  const QuizPage({super.key, required this.level});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool completed = false;

  void finishLevel() {
    setState(() => completed = true);
    Navigator.pop(context, true); // return true to trigger refresh
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ElevatedButton(
              onPressed: finishLevel,
              child: Text("Finish ${widget.level}"),
            ),
          ),
        ),
      ),
    );
  }
}
