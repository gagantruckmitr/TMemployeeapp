import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';

class AnimatedBackground extends StatelessWidget {
  final Animation<double> animation;

  const AnimatedBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: TruckBackgroundPainter(animation.value),
          child: Container(),
        );
      },
    );
  }
}

class TruckBackgroundPainter extends CustomPainter {
  final double animationValue;

  TruckBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw moving truck icons
    for (int i = 0; i < 5; i++) {
      final x = (size.width * animationValue + i * size.width / 3) % (size.width + 100) - 50;
      final y = size.height * 0.2 + math.sin(animationValue * 2 * math.pi + i) * 50;
      
      _drawTruck(canvas, Offset(x, y), paint);
    }
  }

  void _drawTruck(Canvas canvas, Offset position, Paint paint) {
    final path = Path();
    // Simple truck shape
    path.moveTo(position.dx, position.dy);
    path.lineTo(position.dx + 30, position.dy);
    path.lineTo(position.dx + 30, position.dy + 15);
    path.lineTo(position.dx + 10, position.dy + 15);
    path.lineTo(position.dx + 10, position.dy + 20);
    path.lineTo(position.dx, position.dy + 20);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TruckBackgroundPainter oldDelegate) => true;
}
