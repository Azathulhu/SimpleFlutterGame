import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Sign up user (this will not require confirmation if disabled in Supabase dashboard)
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) throw Exception('Sign up failed: No user returned.');

      // Insert into custom "users" table
      await supabase.from('users').insert({
        'id': user.id,
        'email': email,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Automatically sign the user in
      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      print('AUTH ERROR: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      throw Exception('Unexpected error during signup: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception('Sign-in failed: user not found.');
      }
    } on AuthException catch (e) {
      print('AUTH ERROR: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      throw Exception('Unexpected error during sign-in: $e');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
