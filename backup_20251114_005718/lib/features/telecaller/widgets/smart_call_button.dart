import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class SmartCallButton extends StatefulWidget {
  final VoidCallback onPressed;

  const SmartCallButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<SmartCallButton> createState() => _SmartCallButtonState();
}

class _SmartCallButtonState extends State<SmartCallButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Smart Call Button with Enhanced Effects
        GestureDetector(
          onTap: () {
            _rippleController.forward().then((_) {
              _rippleController.reset();
            });
            widget.onPressed();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Multiple Ripple Effects
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          final delay = index * 0.3;
                          final animationValue = (_rippleAnimation.value - delay).clamp(0.0, 1.0);
                          
                          return Container(
                            width: 160 + (animationValue * 80),
                            height: 160 + (animationValue * 80),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(
                                  0.4 * (1 - animationValue),
                                ),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    // Outer Glow Circles
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1 * _glowAnimation.value),
                            AppTheme.primaryBlue.withOpacity(0.3 * _glowAnimation.value),
                            AppTheme.accentOrange.withOpacity(0.2 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentOrange.withOpacity(0.1 * _glowAnimation.value),
                            AppTheme.primaryBlue.withOpacity(0.2 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Main Button
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.accentOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppTheme.accentOrange.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(70),
                          onTap: () {
                            _rippleController.forward().then((_) {
                              _rippleController.reset();
                            });
                            widget.onPressed();
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: AppTheme.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'START SMART',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: AppTheme.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'CALLING',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: AppTheme.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms, delay: 400.ms)
            .scale(begin: const Offset(0.8, 0.8))
            .then()
            .shimmer(duration: 3000.ms, color: AppTheme.white.withOpacity(0.3)),
      ],
    );
  }
}