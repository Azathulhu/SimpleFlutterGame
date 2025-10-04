import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<bool> signUp(String email, String password, String username) async {
    final res = await supabase.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await supabase.from('users').insert({
        'id': res.user!.id,
        'email': email,
        'username': username,
      });
      return true;
    }
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user != null;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
