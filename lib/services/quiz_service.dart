import 'package:supabase_flutter/supabase_flutter.dart';

class QuizService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch questions
  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    final List res = await supabase
        .from('questions')
        .select()
        .eq('difficulty', difficulty)
        .limit(limit);
    final questions = res.map((q) => Question.fromMap(q)).toList();
    questions.shuffle();
    return questions;
  }

  /// Submit score
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
      final currentScore = existing['score'] as int;
      if (score > currentScore) {
        await supabase.from('leaderboard').update({
          'score': score,
          'created_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId).eq('level', level);
      }
    }
  }

  /// Submit perfect-run time (fastest only)
  Future<void> submitPerfectTime({
    required String userId,
    required String level,
    required int score,
    required int timeMs,
  }) async {
    await supabase.from('leaderboard').upsert({
      'user_id': userId,
      'level': level,
      'score': score,
      'time_ms': timeMs,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: ['user_id', 'level'], merge: true);
  }

  /// Fetch leaderboard (fastest perfect runs)
  Future<List<Map<String, dynamic>>> fetchLeaderboard(String level) async {
    final res = await supabase
        .from('leaderboard')
        .select('score, time_ms, users(username)')
        .eq('level', level)
        .not('time_ms', 'is', null)
        .order('time_ms', ascending: true)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }
}
