// lib/services/quiz_service.dart
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class Question {
  final String id;
  final String text;
  final List<String> options;
  final String answer;
  final String difficulty;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answer,
    required this.difficulty,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List<dynamic>),
      answer: map['answer'] as String,
      difficulty: map['difficulty'] as String,
    );
  }
}

class QuizService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ---------------- Fetch Questions ----------------
  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    final List<Map<String, dynamic>> res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);

    final List<Question> questions = res
        .map((q) => Question.fromMap(Map<String, dynamic>.from(q)))
        .toList();

    questions.shuffle(Random());
    return questions;
  }

  // ---------------- Submit Perfect Run (All Correct + Fastest) ----------------
  Future<void> submitPerfectRun({
    required String userId,
    required int timeMs, // time in milliseconds
    required String level,
    required int totalQuestions,
    required int score,
  }) async {
    // Only perfect runs (score = total questions)
    if (score != totalQuestions) return;

    final List<Map<String, dynamic>> existing = await supabase
        .from('leaderboard')
        .select()
        .eq('user_id', userId)
        .eq('level', level);

    if (existing.isEmpty) {
      // Insert new perfect record
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'score': score,
        'level': level,
        'time_ms': timeMs,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Update if faster
      final currentTime = existing[0]['time_ms'] as int?;
      if (currentTime == null || timeMs < currentTime) {
        await supabase
            .from('leaderboard')
            .update({
              'time_ms': timeMs,
              'score': score,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('level', level);
      }
    }
  }

  // ---------------- Fetch Leaderboard by Level ----------------
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String level,
    int limit = 10,
  }) async {
    final List<Map<String, dynamic>> res = await supabase
        .from('leaderboard')
        .select('time_ms, score, users(username)')
        .eq('level', level)
        .not('time_ms', 'is', null)
        .order('time_ms', ascending: true)
        .limit(limit);

    return res;
  }

  // ---------------- Unlock Level ----------------
  Future<void> unlockLevel(String userId, String level) async {
    final List<Map<String, dynamic>> res = await supabase
        .from('users')
        .select('unlocked_levels')
        .eq('id', userId)
        .limit(1);

    if (res.isEmpty) return;

    final List<dynamic> unlocked = res[0]['unlocked_levels'] as List<dynamic>;
    if (!unlocked.contains(level)) {
      unlocked.add(level);
      await supabase
          .from('users')
          .update({'unlocked_levels': unlocked})
          .eq('id', userId);
    }
  }

  // ---------------- Fetch Unlocked Levels ----------------
  Future<List<String>> fetchUnlockedLevels(String userId) async {
    final List<Map<String, dynamic>> res = await supabase
        .from('users')
        .select('unlocked_levels')
        .eq('id', userId)
        .limit(1);

    if (res.isEmpty) return ['easy'];
    final List<dynamic> unlocked = res[0]['unlocked_levels'] as List<dynamic>;
    return unlocked.map((e) => e.toString()).toList();
  }
}
