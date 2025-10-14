import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await supabase.auth.signUp(email: email, password: password);
      final user = res.user;
      if (user == null) throw Exception('Sign up failed.');

      // Insert into users, set unlocked_levels to ['easy'] by default
      await supabase.from('users').insert({
        'id': user.id,
        'email': email,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
        'unlocked_levels': ['easy'],
      });

      // Auto sign-in
      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabase.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) throw Exception('Sign-in failed.');
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in error: $e');
    }
  }

  Future<void> signOut() async => supabase.auth.signOut();

  User? get currentUser => supabase.auth.currentUser;

  /// Read unlocked levels for current user
  Future<List<String>> fetchUnlockedLevels() async {
    final user = currentUser;
    if (user == null) return ['easy'];
    final res = await supabase.from('users').select('unlocked_levels').eq('id', user.id).single();
    if (res == null) return ['easy'];
    final levels = (res['unlocked_levels'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    return levels ?? ['easy'];
  }

  /// Unlock next level for this user
  Future<void> unlockLevel(String level) async {
    final user = currentUser;
    if (user == null) return;
    final current = await fetchUnlockedLevels();
    if (!current.contains(level)) {
      current.add(level);
      await supabase.from('users').update({'unlocked_levels': current}).eq('id', user.id);
    }
  }
}


  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}

