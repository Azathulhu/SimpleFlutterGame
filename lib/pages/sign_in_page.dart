import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'sign_up_page.dart';
import 'home_page.dart';
import '../theme.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService auth = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('Quiz Master', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  loading
                      ? const CircularProgressIndicator()
                      : ScaleOnTap(
                          onTap: () async {
                            setState(() { loading = true; error = null; });
                            try {
                              await auth.signIn(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                              Fluttertoast.showToast(msg: 'Signed in!');
                              if (!mounted) return;
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                            } catch (e) {
                              setState(() { error = e.toString(); });
                            } finally {
                              setState(() { loading = false; });
                            }
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(onPressed: null, child: const Text('Sign In & Play Quiz')),
                          ),
                        ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                    child: const Text('Create account'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
