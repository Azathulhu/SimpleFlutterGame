import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import '../theme.dart';
import '../animated_background.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService auth = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Sign Up'), backgroundColor: Colors.transparent, elevation: 0),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text('Create Account',
                            style: TextStyle(fontSize: 22, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                        TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                        const SizedBox(height: 12),
                        TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                        const SizedBox(height: 12),
                        TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                        const SizedBox(height: 16),
                        loading
                            ? const CircularProgressIndicator()
                            : ScaleOnTap(
                                onTap: () async {
                                  setState(() {
                                    loading = true;
                                    error = null;
                                  });
                                  try {
                                    await auth.signUp(
                                      username: usernameController.text.trim(),
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );
                                    Fluttertoast.showToast(msg: 'Account created!');
                                    if (!mounted) return;
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                                  } catch (e) {
                                    setState(() {
                                      error = e.toString();
                                    });
                                  } finally {
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // duplicate to keep button state visible
                                      setState(() {
                                        loading = true;
                                        error = null;
                                      });
                                      try {
                                        await auth.signUp(
                                          username: usernameController.text.trim(),
                                          email: emailController.text.trim(),
                                          password: passwordController.text.trim(),
                                        );
                                        Fluttertoast.showToast(msg: 'Account created!');
                                        if (!mounted) return;
                                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                                      } catch (e) {
                                        setState(() {
                                          error = e.toString();
                                        });
                                      } finally {
                                        setState(() {
                                          loading = false;
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text('Sign Up & Play'),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
