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
      id: map['id'],
      text: map['text'],
      options: List<String>.from(map['options'] ?? []),
      answer: map['answer'],
      difficulty: map['difficulty'],
    );
  }
}

class QuizService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    try {
      final List res = await supabase
          .from('questions')
          .select()
          .eq('difficulty', difficulty)
          .limit(limit);

      final questions = res.map((q) => Question.fromMap(q)).toList();
      questions.shuffle(Random());
      return questions;
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }

  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
  }) async {
    try {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'score': score,
        'level': level,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(
    String level,
    int limit,
  ) async {
    final List res = await supabase
        .from('leaderboard')
        .select('score, level, users(username)')
        .eq('level', level)
        .order('score', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }
}
/*import 'dart:math';
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
      id: map['id'],
      text: map['text'],
      options: List<String>.from(map['options'] ?? []),
      answer: map['answer'],
      difficulty: map['difficulty'],
    );
  }
}

class QuizService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Question>> fetchQuestions(String difficulty, int limit) async {
    try {
      final List res = await supabase
          .from('questions')
          .select()
          .eq('difficulty', difficulty)
          .limit(limit);

      print('Fetched ${res.length} questions from Supabase.');

      final questions = res.map((q) => Question.fromMap(q)).toList();
      questions.shuffle(Random());
      return questions;
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }

  Future<void> submitScore({
    required String userId,
    required int score,
    required String level,
  }) async {
    try {
      await supabase.from('leaderboard').insert({
        'user_id': userId,
        'score': score,
        'level': level,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(int limit) async {
    final List res = await supabase
        .from('leaderboard')
        .select('score, level, users(username)')
        .order('score', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }
}
*/