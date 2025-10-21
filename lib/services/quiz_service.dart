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

  // Fetch random questions of a difficulty
  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    final List res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);
    final List<Question> questions = res
        .map((q) => Question.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();
    questions.shuffle(Random());
    return questions;
  }

  // Submit a score (without time)
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
  }

  // Submit score + time for perfect runs
  Future<void> submitTime({
    required String userId,
    required String level,
    required int score,
    required int timeMs,
  }) async {
    final existing = await supabase
        .from('leaderboard')
        .select('score, time_ms')
        .eq('user_id', userId)
        .eq('level', level)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'level': level,
        'score': score,
        'time_ms': timeMs,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final currentScore = (existing['score'] as int?) ?? 0;
      final currentTime = (existing['time_ms'] as int?) ?? 0;

      // Only update if higher score OR same score but faster time
      if (score > currentScore || (score == currentScore && (currentTime == 0 || timeMs < currentTime))) {
        await supabase
            .from('leaderboard')
            .update({
              'score': score,
              'time_ms': timeMs,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('level', level);
      }
    }
  }

  // Fetch leaderboard for a level (fastest times first)
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String level,
    int limit = 10,
  }) async {
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
