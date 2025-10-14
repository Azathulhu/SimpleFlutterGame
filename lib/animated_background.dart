// lib/widgets/animated_background.dart
import 'package:flutter/material.dart';

/// Animated soft gradient background
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);

    _color1 = ColorTween(
      begin: const Color(0xFFB2EBF2), // light cyan
      end: const Color(0xFFB2DFDB),   // light blue-green
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _color2 = ColorTween(
      begin: const Color(0xFF81D4FA), // light sky blue
      end: const Color(0xFF80CBC4),   // calm green
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
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_color1.value!, _color2.value!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Global tap ripple anywhere on screen
class GlobalTapRipple extends StatelessWidget {
  final Widget child;
  const GlobalTapRipple({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final overlay = Overlay.of(context);
        if (overlay == null) return;
        final entry = OverlayEntry(
          builder: (_) => Positioned(
            left: details.globalPosition.dx - 50,
            top: details.globalPosition.dy - 50,
            child: _RippleEffect(),
          ),
        );
        overlay.insert(entry);
        Future.delayed(const Duration(milliseconds: 600), entry.remove);
      },
      child: child,
    );
  }
}

class _RippleEffect extends StatefulWidget {
  @override
  State<_RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<_RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radius;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _radius = Tween<double>(begin: 0, end: 100).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.4, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: _radius.value * 2,
          height: _radius.value * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
