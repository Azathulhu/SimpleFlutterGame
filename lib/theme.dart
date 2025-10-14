import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette
  static const Color primary = Color(0xFF2E8BFF); // soft sky-blue
  static const Color accent = Color(0xFF4DD0E1); // light blue-green
  static const Color card = Colors.white;
  static const Color scaffold = Color(0xFFF7FEFF);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(
      primary: primary,
      secondary: accent,
      background: scaffold,
    ),
    scaffoldBackgroundColor: scaffold,
    useMaterial3: true,
    textTheme: GoogleFonts.quicksandTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white, // ensures text is visible
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardTheme(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Animated slow gradient background that can be placed behind pages.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget? child;
  const AnimatedGradientBackground({this.child, super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> {
  // list of palette pairs to cycle through slowly
  final List<List<Color>> palettes = [
    [Color(0xFFe6feff), Color(0xFFd9f7f6)],
    [Color(0xFFd9f7f6), Color(0xFFe0f7fa)],
    [Color(0xFFe0f7fa), Color(0xFFe6f4ff)],
    [Color(0xFFe6f4ff), Color(0xFFe8f9ff)],
  ];

  int index = 0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 6), (_) {
      setState(() => index = (index + 1) % palettes.length);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = palettes[index];
    final next = palettes[(index + 1) % palettes.length];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 6),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        // lerp colors
        final c1 = Color.lerp(colors[0], next[0], t)!;
        final c2 = Color.lerp(colors[1], next[1], t)!;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c1, c2],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shows a subtle ripple circle at each tap location — works globally when placed over content.
class GlobalTapRipple extends StatefulWidget {
  final Widget child;
  const GlobalTapRipple({required this.child, super.key});

  @override
  State<GlobalTapRipple> createState() => _GlobalTapRippleState();
}

class _Ripple {
  Offset pos;
  DateTime start;
  _Ripple(this.pos) : start = DateTime.now();
}

class _GlobalTapRippleState extends State<GlobalTapRipple> with TickerProviderStateMixin {
  final List<_Ripple> ripples = [];
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      // remove ripples older than 700ms
      ripples.removeWhere((r) => DateTime.now().difference(r.start) > const Duration(milliseconds: 700));
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails d) {
    final local = d.localPosition;
    setState(() => ripples.add(_Ripple(local)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTap,
      child: Stack(
        children: [
          widget.child,
          // render ripples
          IgnorePointer(
            child: CustomPaint(
              painter: _RipplePainter(ripples),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final List<_Ripple> ripples;
  _RipplePainter(this.ripples);
  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final r in ripples) {
      final dt = now.difference(r.start).inMilliseconds;
      final progress = dt / 700.0;
      final radius = 20 + progress * 80;
      final alpha = (150 * (1 - progress)).clamp(0, 150).toInt();
      final paint = Paint()..color = Color.fromARGB(alpha, 46, 139, 255);
      canvas.drawCircle(r.pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => true;
}

/// Small animated scale button wrapper
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final void Function()? onTap;
  final double downScale;
  const ScaleOnTap({required this.child, this.onTap, this.downScale = 0.96, super.key});

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  double scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = widget.downScale),
      onTapUp: (_) {
        setState(() => scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => scale = 1.0),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
