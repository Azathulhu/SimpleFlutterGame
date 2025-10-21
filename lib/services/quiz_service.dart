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

  /// Adds coins safely using RPC
  Future<void> addCoins(String userId, int coinsEarned) async {
    try {
      await supabase.rpc('increment_coins', params: {
        'user_id': userId,
        'amount': coinsEarned,
      });
    } catch (e) {
      throw Exception('Failed to add coins: $e');
    }
  }

  /// Submits score and optionally coins for perfect or non-perfect runs
  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
    int? timeMs, // optional for perfect runs
  }) async {
    // Fetch existing leaderboard entry
    final existing = await supabase
        .from('leaderboard')
        .select('score, time_ms')
        .eq('user_id', userId)
        .eq('level', level)
        .maybeSingle();

    final coinsEarned = _calculateCoins(score, level, timeMs);

    if (existing == null) {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'score': score,
        'level': level,
        'time_ms': timeMs,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final currentScore = (existing['score'] as int?) ?? 0;
      final currentTime = (existing['time_ms'] as int?) ?? 0;

      if (score > currentScore || (score == currentScore && (timeMs ?? 0) < currentTime)) {
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

    // Add coins to the user
    await addCoins(userId, coinsEarned);
  }

  /// Simple coin calculation based on level and optionally time
  int _calculateCoins(int score, String level, int? timeMs) {
    final base = level == 'easy'
        ? 10
        : level == 'medium'
            ? 20
            : 30;

    // Bonus for speed (perfect runs)
    if (timeMs != null) {
      final bonus = ((10000 / (timeMs + 1))).round(); // just an example formula
      return base + bonus;
    }

    return base * score; // regular run
  }

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
