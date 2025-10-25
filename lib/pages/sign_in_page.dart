import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'sign_up_page.dart';
import 'home_page.dart';
import '../theme.dart';
import '../animated_background.dart';

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
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  color: const Color(0xFF0A1F2E),
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text('I.T Quiz',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              shadows: [
                                Shadow(
                                  blurRadius: 12,
                                  color: AppTheme.primary.withOpacity(0.7),
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            )),
                        const SizedBox(height: 20),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(error!,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        _buildTextField(emailController, 'Email'),
                        const SizedBox(height: 16),
                        _buildTextField(passwordController, 'Password', obscureText: true),
                        const SizedBox(height: 24),
                        loading
                            ? const CircularProgressIndicator(
                                color: AppTheme.primary,
                              )
                            : _buildButton('Sign In & Play Quiz', () async {
                                setState(() {
                                  loading = true;
                                  error = null;
                                });
                                try {
                                  await auth.signIn(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );
                                  Fluttertoast.showToast(msg: 'Signed in!');
                                  if (!mounted) return;
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(builder: (_) => const HomePage()));
                                } catch (e) {
                                  setState(() {
                                    error = e.toString();
                                  });
                                } finally {
                                  setState(() {
                                    loading = false;
                                  });
                                }
                              }),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SignUpPage())),
                          child: Text(
                            'Create account',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: AppTheme.primary.withOpacity(0.6),
                                  offset: const Offset(0, 0),
                                ),
                              ],
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

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF102A3A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(
                    blurRadius: 12,
                    color: Colors.white38,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import 'sign_up_page.dart';
import 'home_page.dart';
import '../theme.dart';
import '../animated_background.dart';

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
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text('I.T Quiz',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        const SizedBox(height: 16),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(error!, style: const TextStyle(color: Colors.red)),
                          ),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
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
                                  setState(() {
                                    loading = true;
                                    error = null;
                                  });
                                  try {
                                    await auth.signIn(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );
                                    Fluttertoast.showToast(msg: 'Signed in!');
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
                                      setState(() {
                                        loading = true;
                                        error = null;
                                      });
                                      try {
                                        await auth.signIn(
                                          email: emailController.text.trim(),
                                          password: passwordController.text.trim(),
                                        );
                                        Fluttertoast.showToast(msg: 'Signed in!');
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
                                      child: Text('Sign In & Play Quiz'),
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }
}*/
