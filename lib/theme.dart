// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette
  static final Color primary = Color(0xFF2E8B8A); // teal-blue
  static final Color accent = Color(0xFF66C4BF);
  static final Color bgLight = Color(0xFFEFFAF9);
  static final Color card = Colors.white;

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primary,
      secondary: accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: bgLight,
    useMaterial3: true,
    textTheme: GoogleFonts.quicksandTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white, // ensures button text visible
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
  );
}

/// Small animated scale button wrapper with ripple support.
/// Usage: wrap a widget with ScaleOnTap(onTap: ..., child: ...).
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final void Function()? onTap;
  final Color? splashColor;
  final Duration duration;
  const ScaleOnTap({
    required this.child,
    this.onTap,
    this.splashColor,
    this.duration = const Duration(milliseconds: 120),
    super.key,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  double scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => scale = 0.96);
  void _onTapUp(TapUpDetails _) {
    setState(() => scale = 1.0);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => scale = 1.0);

  @override
  Widget build(BuildContext context) {
    // We use Material + InkWell to provide a ripple that matches the theme.
    final splash = widget.splashColor ?? AppTheme.accent.withOpacity(0.24);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: splash,
            highlightColor: splash.withOpacity(0.6),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
