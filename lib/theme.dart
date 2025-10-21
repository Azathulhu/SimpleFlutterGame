import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6EC1E4); // soft blue
  static const Color accent = Color(0xFF81E6D9);  // mint green

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
      secondary: accent,
    ),
    textTheme: GoogleFonts.quicksandTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 5,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 8,
      margin: EdgeInsets.all(8),
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);

    _color1 = ColorTween(
      begin: const Color(0xFFD7F9F8), // soft mint
      end: const Color(0xFFB3E5FC),   // light sky blue
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _color2 = ColorTween(
      begin: const Color(0xFFE1F5FE), // bluish white
      end: const Color(0xFFCCF2F4),   // light green
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color1.value!, _color2.value!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class RippleTouchEffect extends StatefulWidget {
  final Widget child;
  const RippleTouchEffect({super.key, required this.child});

  @override
  State<RippleTouchEffect> createState() => _RippleTouchEffectState();
}

class _RippleTouchEffectState extends State<RippleTouchEffect> {
  Offset? _tapPosition;
  double _rippleRadius = 0;
  bool _isRippling = false;
  Timer? _timer;

  void _startRipple(Offset position) {
    setState(() {
      _tapPosition = position;
      _rippleRadius = 0;
      _isRippling = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() => _rippleRadius += 20);
      if (_rippleRadius > 300) {
        _isRippling = false;
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _startRipple(details.localPosition),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          if (_isRippling && _tapPosition != null)
            Positioned(
              left: _tapPosition!.dx - _rippleRadius / 2,
              top: _tapPosition!.dy - _rippleRadius / 2,
              child: AnimatedOpacity(
                opacity: _isRippling ? 0.3 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: _rippleRadius,
                  height: _rippleRadius,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final void Function()? onTap;
  const ScaleOnTap({required this.child, this.onTap, super.key});

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.96),
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
