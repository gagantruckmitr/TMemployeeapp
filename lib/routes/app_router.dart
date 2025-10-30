import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/auth/login_page.dart';
import '../features/telecaller/main_navigation_container.dart';
import '../features/telecaller/smart_calling_page.dart';
import '../features/telecaller/performance_analytics_page.dart';
import '../features/telecaller/screens/dynamic_profile_screen.dart';
import '../features/telecaller/screens/edit_profile_screen.dart';
import '../features/telecaller/screens/settings_screen.dart';
import '../features/telecaller/screens/driver_full_detail_page.dart';
import '../features/manager/manager_dashboard_page.dart';
import '../core/services/real_auth_service.dart';
import '../test_db_connection.dart';

// Wrapper to get manager info from auth service
class ManagerDashboardWrapper extends StatelessWidget {
  const ManagerDashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = RealAuthService.instance.currentUser;
    final managerId = int.tryParse(user?.id ?? '1') ?? 1;
    final managerName = user?.name ?? 'Manager';
    
    return ManagerDashboardPage(
      managerId: managerId,
      managerName: managerName,
    );
  }
}

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String smartCalling = '/dashboard/smart-calling';
  static const String performanceAnalytics = '/dashboard/performance-analytics';
  static const String profile = '/dashboard/profile';
  static const String editProfile = '/dashboard/profile/edit';
  static const String settings = '/dashboard/profile/settings';
  static const String driverDetail = '/dashboard/driver-detail';
  static const String testDb = '/test-db';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: managerDashboard,
        name: 'manager-dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManagerDashboardWrapper(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainNavigationContainer(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
              child: child,
            );
          },
        ),
        routes: [
          // Child routes of dashboard
          GoRoute(
            path: 'smart-calling',
            name: 'smart-calling',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SmartCallingPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: 'performance-analytics',
            name: 'performance-analytics',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PerformanceAnalyticsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: 'driver-detail/:driverId/:driverName',
            name: 'driver-detail',
            pageBuilder: (context, state) {
              final driverId = state.pathParameters['driverId'] ?? '';
              final driverName = state.pathParameters['driverName'] ?? 'Driver';
              return CustomTransitionPage(
                key: state.pageKey,
                child: DriverFullDetailPage(
                  driverId: driverId,
                  driverName: Uri.decodeComponent(driverName),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DynamicProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                  child: child,
                );
              },
            ),
            routes: [
              // Child routes of profile
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const EditProfileScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
                      child: child,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      // Database Test Route
      GoRoute(
        path: testDb,
        name: 'test-db',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DatabaseTestPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}