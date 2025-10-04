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
      if (user == null) throw Exception('Failed to sign up');

      // Insert into users table
      await supabase.from('users').insert({
        'id': user.id,
        'email': email,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Improved error handling
      throw Exception('Sign Up Error: ${_getMessage(e)}');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool allowUnconfirmed = true, // NEW: allow testing before email confirmed
  }) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception('Sign in failed: user not found');
      }

      // Check email confirmation
      if (!allowUnconfirmed && !(res.user!.emailConfirmedAt != null)) {
        throw Exception('Email not confirmed yet');
      }
    } catch (e) {
      throw Exception('Sign In Error: ${_getMessage(e)}');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  String _getMessage(Object e) {
    if (e is AuthException) return e.message;
    return e.toString();
  }
}
