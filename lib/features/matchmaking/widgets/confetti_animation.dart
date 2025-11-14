import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';

class ConfettiAnimation extends StatefulWidget {
  const ConfettiAnimation({super.key});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Generate particles
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle());
    }

    _controller.forward();
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
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_particles, _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double rotation;
  final double velocity;

  ConfettiParticle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble() * 0.3,
        size = math.Random().nextDouble() * 10 + 5,
        color = [
          AppColors.success,
          AppColors.primary,
          AppColors.warning,
          AppColors.info,
        ][math.Random().nextInt(4)],
        rotation = math.Random().nextDouble() * 2 * math.pi,
        velocity = math.Random().nextDouble() * 0.5 + 0.5;
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress);

      final x = particle.x * size.width;
      final y = particle.y * size.height + (progress * size.height * particle.velocity);
      final rotation = particle.rotation + progress * 4 * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
