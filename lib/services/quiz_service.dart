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

  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
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
  //new shit for currency
  Future<void> awardCoins(String userId, String level, int score, int timeMs, int totalQuestions) async {
    int base = 0;
    switch(level) {
      case 'easy':
        base = 10;
        break;
      case 'medium':
        base = 20;
        break;
      case 'hard':
        base = 50;
        break;
    }
  
    // Reward bonus for faster completion (less time)
    final bonus = ((totalQuestions / (timeMs / 1000)) * 5).round();
    final coinsEarned = base + bonus;
  
    // Fetch current coins
    final userRes = await supabase.from('users').select('coins').eq('id', userId).single();
    final currentCoins = userRes['coins'] as int? ?? 0;
  
    // Update coins manually
    await supabase.from('users').update({
      'coins': currentCoins + coinsEarned,
    }).eq('id', userId);
  }
  /// This is the **perfect-time submission method** used by QuizPage.
  Future<void> submitPerfectTime({
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

      // Only overwrite if new score higher, OR same score but faster time
      if (score > currentScore || (score == currentScore && timeMs < currentTime)) {
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
