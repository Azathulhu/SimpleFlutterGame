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
    final res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);
    if (res.data == null) return [];
    final List questions = res.data as List;
    final List<Question> parsed = questions
        .map((q) => Question.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();
    parsed.shuffle(Random());
    return parsed;
  }

  // ---------------- Submit Score ----------------
  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
  }) async {
    try {
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
        });
      } else {
        final currentScore = (existing['score'] as int?) ?? 0;
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
    } catch (e) {
      print('submitScore error: $e');
    }
  }

  // Helper: number of questions per quiz
  int questionsCountForLevel(String level) {
    return 5;
  }

  // ---------------- Submit Perfect Time ----------------
  Future<void> submitPerfectTime({
    required String userId,
    required int timeMs,
    required String level,
    required int score,
  }) async {
    try {
      final expected = questionsCountForLevel(level);
      if (score != expected) return;

      final existing = await supabase
          .from('leaderboard')
          .select('id, time_ms, score')
          .eq('user_id', userId)
          .eq('level', level)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('leaderboard').insert({
          'user_id': userId,
          'score': score,
          'level': level,
          'time_ms': timeMs,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        final currentTime = existing['time_ms'] as int?;
        final currentScore = (existing['score'] as int?) ?? 0;

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
        } else if (score > currentScore) {
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
    } catch (e) {
      print('submitPerfectTime error: $e');
    }
  }

  // ---------------- Fetch Leaderboard ----------------
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String level,
    int limit = 10,
  }) async {
    try {
      final res = await supabase
          .from('leaderboard')
          .select('time_ms, score, users(username)')
          .eq('level', level)
          .not('time_ms', 'is', null)
          .order('time_ms', ascending: true)
          .limit(limit);

      if (res.data == null) return [];
      final List data = res.data as List;
      return List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (e) {
      print('fetchLeaderboard error: $e');
      return [];
    }
  }
}
