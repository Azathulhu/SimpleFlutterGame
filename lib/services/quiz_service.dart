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
      id: map['id'],
      text: map['text'],
      options: List<String>.from(map['options']),
      answer: map['answer'],
      difficulty: map['difficulty'],
    );
  }
}

class QuizService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Default number of questions per quiz
  int get questionCount => 5;

  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    final res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);

    if (res is List) {
      final questions = res.map((q) => Question.fromMap(q as Map<String, dynamic>)).toList();
      questions.shuffle(Random());
      return questions;
    }
    return [];
  }

  // Submit perfect run (all correct, fastest time)
  Future<void> submitPerfectRun({
    required String userId,
    required int timeMs,
    required String level,
    required int totalQuestions,
    required int score,
  }) async {
    if (score != totalQuestions) return; // Only perfect runs

    final existing = await supabase
        .from('leaderboard')
        .select('id,time_ms')
        .eq('user_id', userId)
        .eq('level', level)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'level': level,
        'time_ms': timeMs,
        'score': score,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final existingTime = existing['time_ms'] as int? ?? 99999999;
      if (timeMs < existingTime) {
        await supabase
            .from('leaderboard')
            .update({'time_ms': timeMs, 'score': score, 'created_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
      }
    }
  }

  // Fetch leaderboard sorted by fastest time (perfect runs only)
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String level,
    int limit = 10,
  }) async {
    final res = await supabase
        .from('leaderboard')
        .select('score, time_ms, users(username)')
        .eq('level', level)
        .order('time_ms', ascending: true)
        .limit(limit);

    if (res is List) return List<Map<String, dynamic>>.from(res);
    return [];
  }
}
