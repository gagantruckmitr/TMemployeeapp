import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

// Global overlay entry for mini mode
OverlayEntry? _globalMiniOverlay;

/// Modern IVR call waiting overlay with animations and mini mode support
class IVRCallWaitingOverlay extends StatefulWidget {
  final String driverName;
  final String? referenceId;
  final VoidCallback onCallEnded;
  final bool allowMinimize;

  const IVRCallWaitingOverlay({
    super.key,
    required this.driverName,
    this.referenceId,
    required this.onCallEnded,
    this.allowMinimize = true,
  });

  @override
  State<IVRCallWaitingOverlay> createState() => _IVRCallWaitingOverlayState();
  
  // Static method to remove mini overlay
  static void removeMiniOverlay() {
    _globalMiniOverlay?.remove();
    _globalMiniOverlay = null;
  }
}

class _IVRCallWaitingOverlayState extends State<IVRCallWaitingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  String _currentStatus = 'Initiating IVR call...';
  int _currentStep = 0;
  bool _isMinimized = false; // Start in full screen, user can minimize

  final List<String> _statusMessages = [
    'Initiating IVR call...',
    'Connecting to IVR system...',
    'Calling your phone...',
    'Waiting for you to answer...',
    'Connecting to driver...',
    'Call in progress...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _waveController.repeat();

    _startStatusUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startStatusUpdates() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _currentStep < _statusMessages.length - 1) {
        setState(() {
          _currentStep++;
          _currentStatus = _statusMessages[_currentStep];
        });
        return true;
      }
      return false;
    });
  }
  
  void _minimizeToFloating(BuildContext context) {
    // Remove any existing mini overlay
    IVRCallWaitingOverlay.removeMiniOverlay();
    
    // Pop the current full-screen overlay
    Navigator.of(context).pop();
    
    // Create and insert mini overlay
    _globalMiniOverlay = OverlayEntry(
      builder: (context) => _MiniFloatingWidget(
        driverName: widget.driverName,
        pulseAnimation: _pulseAnimation,
        onExpand: () {
          // Remove mini overlay
          IVRCallWaitingOverlay.removeMiniOverlay();
          
          // Show full screen again
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: widget.driverName,
                  referenceId: widget.referenceId,
                  onCallEnded: widget.onCallEnded,
                  allowMinimize: widget.allowMinimize,
                ),
              ),
            ),
          );
        },
        onCallEnded: () {
          IVRCallWaitingOverlay.removeMiniOverlay();
          widget.onCallEnded();
        },
      ),
    );
    
    // Insert into overlay
    Overlay.of(context).insert(_globalMiniOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return Stack(
        children: [
          // Dismiss overlay when tapping outside
          GestureDetector(
            onTap: () {
              // Tapping background does nothing, user must use buttons
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          _buildMiniMode(context),
        ],
      );
    }
    
    return Material(
      color: Colors.black.withValues(alpha: 0.95),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F2027),
              const Color(0xFF203A43),
              const Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_phone,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'IVR Call',
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (widget.referenceId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Ref: ${widget.referenceId!.length > 8 ? '${widget.referenceId!.substring(0, 8)}...' : widget.referenceId}',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (widget.allowMinimize) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          _minimizeToFloating(context);
                        },
                        icon: const Icon(
                          Icons.minimize,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Minimize',
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Animated Call Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _DottedCirclePainter(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Pulsing waves
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final delay = index * 0.3;
                        final animationValue =
                            (_waveController.value - delay).clamp(0.0, 1.0);

                        return Container(
                          width: 140 + (animationValue * 60),
                          height: 140 + (animationValue * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentOrange.withValues(
                                alpha: 0.4 * (1 - animationValue),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Center pulsing icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.accentOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.phone_in_talk,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Driver Name
              Text(
                widget.driverName,
                style: AppTheme.headingMedium.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Status Message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey<String>(_currentStatus),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _currentStatus,
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Instructions
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInstructionStep(
                      '1',
                      'Answer your phone when it rings',
                      Icons.phone_callback,
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '2',
                      'IVR will connect you to the driver',
                      Icons.swap_calls,
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '3',
                      'Complete call and submit feedback',
                      Icons.rate_review,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // End Call Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton(
                  onPressed: widget.onCallEnded,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Call Ended - Submit Feedback',
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMode(BuildContext context) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMinimized = false;
          });
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A90E2),
                  const Color(0xFF357ABD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_in_talk,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IVR Call',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.driverName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _isMinimized = false;
                        });
                      },
                      icon: const Icon(
                        Icons.open_in_full,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Expand',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status row
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'In Progress',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // End call button
                    ElevatedButton(
                      onPressed: widget.onCallEnded,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A90E2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'End Call',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
      ],
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  final Color color;

  _DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dotCount = 12;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi / dotCount) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Mini floating widget that appears in the overlay
class _MiniFloatingWidget extends StatefulWidget {
  final String driverName;
  final Animation<double> pulseAnimation;
  final VoidCallback onExpand;
  final VoidCallback onCallEnded;

  const _MiniFloatingWidget({
    required this.driverName,
    required this.pulseAnimation,
    required this.onExpand,
    required this.onCallEnded,
  });

  @override
  State<_MiniFloatingWidget> createState() => _MiniFloatingWidgetState();
}

class _MiniFloatingWidgetState extends State<_MiniFloatingWidget> {
  double _top = 80;
  double _left = 16;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const widgetWidth = 360.0;
    const widgetHeight = 150.0;
    
    return Positioned(
      top: _top,
      left: _left,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _left += details.delta.dx;
              _top += details.delta.dy;
              
              // Keep widget within screen bounds with safe clamping
              final maxLeft = (screenSize.width - widgetWidth).clamp(0.0, screenSize.width);
              final maxTop = (screenSize.height - widgetHeight).clamp(0.0, screenSize.height);
              
              _left = _left.clamp(0.0, maxLeft);
              _top = _top.clamp(0.0, maxTop);
            });
          },
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A90E2),
                  const Color(0xFF357ABD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: widget.pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.pulseAnimation.value,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_in_talk,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'IVR Call',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.drag_indicator,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.driverName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onExpand,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'In Progress',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: widget.onCallEnded,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A90E2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'End Call',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
