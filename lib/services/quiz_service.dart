// lib/services/quiz_service.dart
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

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
    final List res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);
    final List<Question> questions = res.map((q) => Question.fromMap(Map<String, dynamic>.from(q as Map))).toList();
    questions.shuffle(Random());
    return questions;
  }

  // ---------------- Submit Score (Upsert) ----------------
  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
  }) async {
    // Keep original behavior for score tracking (non-perfect runs included).
    final existing = await supabase
        .from('leaderboard')
        .select('score, time_ms')
        .eq('user_id', userId)
        .eq('level', level)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'score': score,
        'level': level,
        'created_at': DateTime.now().toIso8601String(),
        // time_ms remains null for non-perfect or not-yet-recorded perfect
      });
    } else {
      final currentScore = existing['score'] as int? ?? 0;
      if (score > currentScore) {
        await supabase
            .from('leaderboard')
            .update({
              'score': score,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('level', level);
      }
    }
  }

  // ---------------- Submit Perfect Time (fastest perfect run) ----------------
  /// Only call this when the run was perfect (score == totalQuestions).
  /// timeMs is elapsed time in milliseconds.
  Future<void> submitPerfectTime({
    required String userId,
    required int timeMs,
    required String level,
    required int score, // total questions
  }) async {
    // Ensure perfect score
    if (score != questionsCountForLevel(level)) return; // helper function to get number of questions
  
    // Upsert the fastest perfect run
    final res = await supabase.from('leaderboard').upsert({
      'user_id': userId,
      'level': level,
      'score': score,
      'time_ms': timeMs,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: ['user_id', 'level']).execute();
  
    if (res.error != null) {
      print('Failed to upsert perfect time: ${res.error!.message}');
    }
  }

  // ---------------- Fetch Leaderboard ----------------
  /// Returns leaderboard entries for a level ordered by fastest perfect time (time_ms ASC).
  /// Only returns rows that have time_ms (i.e., perfect runs recorded).
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String level,
    int limit = 10,
  }) async {
    // We select time_ms and user's username. Order by time_ms ascending (fastest first).
    final List res = await supabase
        .from('leaderboard')
        .select('time_ms, score, users(username)')
        .eq('level', level)
        .not('time_ms', 'is', null)
        .order('time_ms', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }
}
