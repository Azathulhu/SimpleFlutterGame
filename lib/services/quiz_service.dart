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

  // ---------------- Fetch Questions ----------------
  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    final List res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);
    final List<Question> questions = res.map((q) => Question.fromMap(q)).toList();
    questions.shuffle(Random());
    return questions;
  }

  // ---------------- Submit Score (Upsert) ----------------
  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
  }) async {
    final existing = await supabase
        .from('leaderboard')
        .select('score')
        .eq('user_id', userId)
        .eq('level', level)
        .single()
        .maybeSingle();

    if (existing == null) {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'score': score,
        'level': level,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final currentScore = existing['score'] as int;
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

  // ---------------- Fetch Leaderboard ----------------
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String level,
    int limit = 10,
  }) async {
    final List res = await supabase
        .from('leaderboard')
        .select('score, users(username)')
        .eq('level', level)
        .order('score', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }
}
