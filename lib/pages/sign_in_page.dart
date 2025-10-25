import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
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

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _welcomeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();

    // Fade out sign-in panel
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Welcome text animation
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
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

      // Start panel fade-out
      await _fadeController.forward();
      setState(() => _showWelcome = true);

      // Animate welcome text
      await _welcomeController.forward();
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: GlobalTapRipple(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: _showWelcome
                ? ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 30,
                            color: Colors.white.withOpacity(0.8),
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            blurRadius: 60,
                            color: Colors.blueAccent.withOpacity(0.5),
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            blurRadius: 90,
                            color: Colors.cyan.withOpacity(0.4),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(_fadeAnimation),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        color: const Color(0xFF0A1F2E),
                        elevation: 12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Text('I.T Quiz',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 12,
                                            color: AppTheme.primary.withOpacity(0.6),
                                            offset: const Offset(0, 0))
                                      ])),
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
                                      onTap: _handleSignIn,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _handleSignIn,
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Text(
                                              'Sign In & Play Quiz',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
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
