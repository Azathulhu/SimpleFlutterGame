// FILE: lib/services/admin_service.dart
// Admin service: manage questions, users, leaderboard


import 'package:supabase_flutter/supabase_flutter.dart';


class AdminService {
final SupabaseClient supabase = Supabase.instance.client;


// ----- Questions -----
Future<List<Map<String, dynamic>>> fetchQuestions({String? difficulty}) async {
final query = supabase.from('questions').select().order('created_at', ascending: false);
if (difficulty != null) query.eq('difficulty', difficulty);
final res = await query;
return List<Map<String, dynamic>>.from(res as List);
}


Future<void> addQuestion({
required String text,
required List<String> options,
required String answer,
required String difficulty,
}) async {
await supabase.from('questions').insert({
'text': text,
'options': options,
'answer': answer,
'difficulty': difficulty,
'created_at': DateTime.now().toIso8601String(),
});
}


Future<void> deleteQuestion(String id) async {
await supabase.from('questions').delete().eq('id', id);
}


// ----- Users -----
Future<List<Map<String, dynamic>>> fetchUsers() async {
final res = await supabase.from('users').select().order('created_at', ascending: false);
return List<Map<String, dynamic>>.from(res as List);
}


Future<void> updateUserRole(String userId, String role) async {
await supabase.from('users').update({'role': role}).eq('id', userId);
}


Future<void> setLeaderboardBan(String userId, bool banned) async {
// Adds/updates a column 'banned_from_leaderboard' on users table (see SQL below)
await supabase.from('users').update({'banned_from_leaderboard': banned}).eq('id', userId);


if (banned) {
// remove any existing leaderboard rows for that user
await supabase.from('leaderboard').delete().eq('user_id', userId);
}
}


Future<void> deleteLeaderboardEntry(String entryId) async {
await supabase.from('leaderboard').delete().eq('id', entryId);
}
}
