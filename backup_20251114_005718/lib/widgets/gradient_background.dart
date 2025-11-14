import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final List<Color>? colors;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              colors: colors ?? [AppTheme.lightGray, AppTheme.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
      ),
      child: child,
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Generate stops that match the number of colors
        List<double> stops = [];
        if (widget.colors.length > 1) {
          for (int i = 0; i < widget.colors.length; i++) {
            double baseStop = i / (widget.colors.length - 1);
            double animatedOffset = (_animation.value - 0.5) * 0.2;
            stops.add((baseStop + animatedOffset).clamp(0.0, 1.0));
          }
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: stops.isNotEmpty ? stops : null,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}