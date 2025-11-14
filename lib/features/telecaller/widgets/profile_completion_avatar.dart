import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProfileCompletionAvatar extends StatelessWidget {
  final String name;
  final int completionPercentage;
  final VoidCallback onTap;
  final double size;
  final String? imageUrl;

  const ProfileCompletionAvatar({
    super.key,
    required this.name,
    required this.completionPercentage,
    required this.onTap,
    this.size = 54,
    this.imageUrl,
  });

  Color _getProgressColor() {
    if (completionPercentage >= 80) {
      return const Color(0xFF4CAF50); // Green
    } else if (completionPercentage >= 50) {
      return const Color(0xFFFFC107); // Orange
    } else {
      return const Color(0xFFF44336); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 30, // Extra space for badge
        height: size + 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Circular progress ring
            Positioned(
              left: 0,
              child: SizedBox(
                width: size + 8,
                height: size + 8,
                child: CustomPaint(
                  painter: CircularProgressPainter(
                    progress: completionPercentage / 100,
                    color: _getProgressColor(),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),

            // Avatar
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: imageUrl == null
                    ? Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // Percentage badge - Positioned to the right with no clipping
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getProgressColor(),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$completionPercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle (gray)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
