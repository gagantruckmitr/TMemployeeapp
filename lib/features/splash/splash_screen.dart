import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/real_auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/telecaller_status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final isLoggedIn = await RealAuthService.instance.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // User is logged in, check their role and route accordingly
      final user = RealAuthService.instance.currentUser;
      final userRole = user?.role ?? '';

      // Set caller ID for API calls
      if (user?.id != null) {
        ApiService.setCallerId(user!.id);
        
        // Initialize status tracking for telecallers
        if (userRole.toLowerCase() == 'telecaller') {
          await TelecallerStatusService.instance.initialize(user!.id);
        }
      }

      if (userRole == 'manager') {
        // Manager goes to manager dashboard
        context.go('/manager-dashboard');
      } else {
        // Telecaller or other roles go to telecaller dashboard
        context.go('/dashboard');
      }
    } else if (hasSeenOnboarding) {
      // User has seen onboarding, go to login
      context.go('/login');
    } else {
      // First time user, show onboarding
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/image-removebg-preview (1).png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/truckmitr_logo.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_shipping,
                      size: 120,
                      color: AppTheme.primaryBlue,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
