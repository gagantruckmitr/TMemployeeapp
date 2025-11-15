import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onContactAdmin;

  const AccessDeniedScreen({
    super.key,
    this.title = 'Access Restricted',
    this.message = 'This feature is not available for your account',
    this.icon = Icons.lock_outline,
    this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: 80,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    title,
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          message,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.gray,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please contact your administrator for access',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back button
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.white,
                          foregroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (onContactAdmin != null) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: onContactAdmin,
                          icon: const Icon(Icons.support_agent),
                          label: const Text('Contact Admin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Specific screen for Match Making access denied
class MatchMakingAccessDenied extends StatelessWidget {
  const MatchMakingAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessDeniedScreen(
      title: 'Match Making Not Available',
      message: 'Match Making feature is not available for your account type.\n\nThis feature is only accessible to authorized users.',
      icon: Icons.person_search_outlined,
      onContactAdmin: () {
        // Could open email, phone, or support chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please contact your administrator'),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
