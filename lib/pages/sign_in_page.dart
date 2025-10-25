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

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  final AuthService auth = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  // Animation states
  bool showPanel = true;
  bool showWelcome = false;

  // Helper for text fields
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white70,
          shadows: [
            Shadow(
              blurRadius: 6,
              color: Colors.blueAccent.withOpacity(0.5),
              offset: const Offset(0, 0),
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.blueGrey.shade900.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  // Helper for buttons
  Widget _buildButton(String text, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.blueAccent.shade700,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            shadowColor: Colors.blueAccent.withOpacity(0.6),
            elevation: 6,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 12,
                  color: Colors.blueAccent,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sign-in Panel
                AnimatedOpacity(
                  opacity: showPanel ? 1 : 0,
                  duration: const Duration(seconds: 1),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        color: const Color(0xFF0A1F2E),
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
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
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold)),
                                ),
                              _buildTextField(emailController, 'Email'),
                              const SizedBox(height: 16),
                              _buildTextField(passwordController, 'Password',
                                  obscureText: true),
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
                                          password:
                                              passwordController.text.trim(),
                                        );
                                        // Fade out panel
                                        setState(() {
                                          showPanel = false;
                                        });
                                        await Future.delayed(
                                            const Duration(seconds: 1));
                                        // Fade in Welcome
                                        setState(() {
                                          showWelcome = true;
                                        });
                                        await Future.delayed(
                                            const Duration(milliseconds: 1500));
                                        if (!mounted) return;
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const HomePage()));
                                      } catch (e) {
                                        setState(() {
                                          error = e.toString();
                                          showPanel = true;
                                        });
                                      } finally {
                                        setState(() {
                                          loading = false;
                                        });
                                      }
                                    }),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SignUpPage())),
                                child: Text(
                                  'Create account',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 6,
                                        color:
                                            AppTheme.primary.withOpacity(0.6),
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

                // Welcome Text
                AnimatedOpacity(
                  opacity: showWelcome ? 1 : 0,
                  duration: const Duration(seconds: 1),
                  child: Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      shadows: [
                        Shadow(
                            blurRadius: 20,
                            color: AppTheme.primary.withOpacity(0.8),
                            offset: const Offset(0, 0)),
                        Shadow(
                            blurRadius: 30,
                            color: AppTheme.primary.withOpacity(0.6),
                            offset: const Offset(0, 0)),
                      ],
                    ),
                  ),
                ),
              ],
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
