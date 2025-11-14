import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';

class ProgressRingAvatar extends StatefulWidget {
  final String? profileImageUrl;
  final String userName;
  final int profileCompletion; // 0-100
  final double size;
  final VoidCallback? onTap;
  final Color ringColor;
  final Color backgroundColor;
  final String? gender;

  const ProgressRingAvatar({
    super.key,
    this.profileImageUrl,
    required this.userName,
    required this.profileCompletion,
    this.size = 70,
    this.onTap,
    Color? ringColor, // Make nullable to allow dynamic color
    this.backgroundColor = const Color(0xFF7B1FA2), // Purple
    this.gender,
  }) : ringColor = ringColor ?? const Color(0xFFFFA726); // Default if not provided

  @override
  State<ProgressRingAvatar> createState() => _ProgressRingAvatarState();
}

class _ProgressRingAvatarState extends State<ProgressRingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.profileCompletion.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(ProgressRingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileCompletion != widget.profileCompletion) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.profileCompletion.toDouble(),
        end: widget.profileCompletion.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _ringStrokeWidth {
    if (widget.size >= 100) return 5.0;
    if (widget.size >= 60) return 4.0;
    if (widget.size >= 48) return 3.5;
    return 3.0;
  }

  double get _whiteBorderWidth {
    if (widget.size >= 100) return 4.0;
    if (widget.size >= 60) return 3.0;
    return 2.5;
  }

  double get _badgeSize {
    // Optimized badge sizes for better readability
    if (widget.size >= 100) return widget.size * 0.32; // 120dp → 38dp
    if (widget.size >= 60) return widget.size * 0.40;  // 70dp → 28dp (Job Postings)
    if (widget.size >= 48) return widget.size * 0.43;  // 56dp → 24dp (Applicants)
    return widget.size * 0.42; // Small avatars
  }

  String get _initial {
    if (widget.userName.isEmpty) return '?';
    return widget.userName[0].toUpperCase();
  }

  // Get color based on profile completion percentage
  Color get _dynamicRingColor {
    if (widget.profileCompletion >= 80) {
      return Colors.green; // 80-100%: Green
    } else if (widget.profileCompletion >= 50) {
      return const Color(0xFFFFA726); // 50-79%: Orange/Amber
    } else {
      return Colors.red; // 0-49%: Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = widget.size + (_ringStrokeWidth * 2) + 4;
    final ringColor = _dynamicRingColor; // Use dynamic color

    Widget avatar = GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: totalSize,
          height: totalSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress Ring Layer
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(totalSize, totalSize),
                    painter: _ProgressRingPainter(
                      progress: _progressAnimation.value,
                      ringColor: ringColor, // Use dynamic color
                      strokeWidth: _ringStrokeWidth,
                    ),
                  );
                },
              ),

              // Avatar Content Layer
              Center(
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: _whiteBorderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.profileImageUrl != null &&
                            widget.profileImageUrl!.isNotEmpty
                        ? _buildPhotoAvatar()
                        : _buildInitialAvatar(),
                  ),
                ),
              ),

              // Completion Badge Layer
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildCompletionBadge(),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: widget.profileImageUrl != null
          ? 'Profile photo of ${widget.userName}, ${widget.profileCompletion}% complete'
          : '${widget.userName}\'s profile avatar, ${widget.profileCompletion}% complete',
      hint: widget.onTap != null ? 'Tap to improve profile' : null,
      child: avatar,
    );
  }

  Widget _buildPhotoAvatar() {
    return CachedNetworkImage(
      imageUrl: widget.profileImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFFE0E0E0),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.3,
            height: widget.size * 0.3,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildInitialAvatar(),
    );
  }

  Widget _buildInitialAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.backgroundColor,
            widget.backgroundColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionBadge() {
    // Calculate optimal text size based on badge size
    double textSize;
    if (_badgeSize >= 35) {
      textSize = 13; // Large avatars (120dp)
    } else if (_badgeSize >= 26) {
      textSize = 11; // Medium avatars (70dp) - Job Postings
    } else if (_badgeSize >= 22) {
      textSize = 10; // Small-medium avatars (56dp) - Applicants
    } else {
      textSize = 9; // Small avatars
    }

    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: _dynamicRingColor, // Use dynamic color for badge too
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3), // Increased border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${widget.profileCompletion}%',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3, // Tighter spacing for better fit
            height: 1.0, // Line height to prevent vertical offset
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0-100
  final Color ringColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.ringColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Draw background track (grey circle)
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc (gold)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = ringColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = (progress / 100) * 2 * math.pi;
      const startAngle = -math.pi / 2; // Start from top (12 o'clock)

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
