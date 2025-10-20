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
    if (res == null) return [];
    final List questions = res as List;
    final List<Question> parsed = questions
        .map((q) => Question.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();
    parsed.shuffle(Random());
    return parsed;
  }

  // ---------------- Submit Score (keep existing score behavior) ----------------
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
      // Log but don't throw, to avoid breaking the quiz flow
      // ignore: avoid_print
      print('submitScore error: $e');
    }
  }

  // Helper: number of questions per quiz (used to validate perfect runs)
  int questionsCountForLevel(String level) {
    // If you change quiz length elsewhere, update this to match
    return 5;
  }

  // ---------------- Submit Perfect Time (robust upsert) ----------------
  /// Only call when the run was perfect (score == totalQuestions).
  /// timeMs is elapsed time in milliseconds.
  Future<void> submitPerfectTime({
    required String userId,
    required int timeMs,
    required String level,
    required int score, // pass totalQuestions to ensure perfection
  }) async {
    try {
      final expected = questionsCountForLevel(level);
      if (score != expected) {
        // Not a perfect run by expected question count - ignore.
        return;
      }

      // Try to find existing row for this user + level
      final existing = await supabase
          .from('leaderboard')
          .select('id, time_ms, score')
          .eq('user_id', userId)
          .eq('level', level)
          .maybeSingle();

      if (existing == null) {
        // Insert a new row with time_ms
        final insertRes = await supabase.from('leaderboard').insert({
          'user_id': userId,
          'score': score,
          'level': level,
          'time_ms': timeMs,
          'created_at': DateTime.now().toIso8601String(),
        }).execute();

        if (insertRes.error != null) {
          // ignore: avoid_print
          print('submitPerfectTime insert error: ${insertRes.error!.message}');
        }
      } else {
        final currentTime = existing['time_ms'] as int?;
        final currentScore = (existing['score'] as int?) ?? 0;

        // If no time recorded yet (null) OR new time is faster, update time_ms
        if (currentTime == null || timeMs < currentTime) {
          final updateRes = await supabase
              .from('leaderboard')
              .update({
                'time_ms': timeMs,
                'score': score,
                'created_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .eq('level', level)
              .execute();
          if (updateRes.error != null) {
            // ignore: avoid_print
            print('submitPerfectTime update error: ${updateRes.error!.message}');
          }
        } else if (score > currentScore) {
          // keep time but update score if somehow score improved
          final updateRes = await supabase
              .from('leaderboard')
              .update({
                'score': score,
                'created_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .eq('level', level)
              .execute();
          if (updateRes.error != null) {
            // ignore: avoid_print
            print('submitPerfectTime update score error: ${updateRes.error!.message}');
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('submitPerfectTime error: $e');
    }
  }

  // ---------------- Fetch Leaderboard (fastest perfect times only) ----------------
  /// Returns leaderboard entries for a level ordered by fastest perfect time (time_ms ASC).
  /// Only returns rows that have time_ms (i.e., perfect runs recorded).
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
          .limit(limit)
          .execute();

      if (res.error != null || res.data == null) {
        return [];
      }
      final List data = res.data as List;
      return List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (e) {
      // ignore: avoid_print
      print('fetchLeaderboard error: $e');
      return [];
    }
  }
}
