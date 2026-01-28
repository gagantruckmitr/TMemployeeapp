import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/auth/role_selection_page.dart';
import '../../features/auth/telecaller_login_page.dart';
import '../../features/auth/margdarshak_login_page.dart';
import '../../features/telecaller/main_navigation_container.dart';
import '../../features/margdarshak/screens/navigation/index.dart';
import '../../features/telecaller/smart_calling_page.dart';
import '../../features/telecaller/performance_analytics_page.dart';
import '../../features/telecaller/subscriptions/subscriptions_screen.dart';
import '../../features/telecaller/screens/dynamic_profile_screen.dart';
import '../../features/telecaller/screens/edit_profile_screen.dart';
import '../../features/telecaller/screens/settings_screen.dart';
import '../../features/telecaller/screens/driver_full_detail_page.dart';
import '../../features/telecaller/screens/leave_break_management_screen.dart';
import '../../features/manager/manager_dashboard_page.dart';
import '../../features/drivers/driver_bucket_screen.dart';
import '../../core/services/real_auth_service.dart';
import '../../test_db_connection.dart';
import '../../features/dashboard/interested_dashboard_wrapper.dart';
import '../../widgets/callback_notification_overlay.dart'
    show callbackNavigatorKey;
import '../../features/attendance/presentation/pages/attendance_screen.dart';

// Wrapper to get manager info from auth service
class ManagerDashboardWrapper extends StatelessWidget {
  const ManagerDashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = RealAuthService.instance.currentUser;
    final managerId = int.tryParse(user?.id ?? '1') ?? 1;
    final managerName = user?.name ?? 'Manager';

    return ManagerDashboardPage(managerId: managerId, managerName: managerName);
  }
}

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String telecallerLogin = '/telecaller-login';
  static const String margdarshakLogin = '/margdarshak-login';
  static const String dashboard = '/dashboard';
  static const String margdarshakDashboard = '/margdarshak-dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String smartCalling = '/dashboard/smart-calling';
  static const String subscriptions = '/dashboard/subscriptions';
  static const String performanceAnalytics = '/dashboard/performance-analytics';
  static const String profile = '/dashboard/profile';
  static const String editProfile = '/dashboard/profile/edit';
  static const String settings = '/dashboard/profile/settings';
  static const String driverDetail = '/dashboard/driver-detail';
  static const String testDb = '/test-db';
  static const String interestedDashboard = '/dashboard/interested-dashboard';
  static const String driverBucket = '/driver-bucket';
  static const String leaveBreak = '/leave-break';
  static const String attendance = '/attendance';

  static final GoRouter router = GoRouter(
    navigatorKey: callbackNavigatorKey,
    initialLocation: splash,
    redirect: (context, state) async {
      final isLoggedIn = await RealAuthService.instance.isLoggedIn();
      final isOnRoleSelectionPage = state.matchedLocation == roleSelection;
      final isOnTelecallerLoginPage = state.matchedLocation == telecallerLogin;
      final isOnMargdarshakLoginPage =
          state.matchedLocation == margdarshakLogin;
      final isOnSplashPage = state.matchedLocation == splash;
      final isOnOnboardingPage = state.matchedLocation == onboarding;

      // If not logged in and trying to access protected routes, redirect to role selection
      if (!isLoggedIn &&
          !isOnRoleSelectionPage &&
          !isOnTelecallerLoginPage &&
          !isOnMargdarshakLoginPage &&
          !isOnSplashPage &&
          !isOnOnboardingPage) {
        return roleSelection;
      }

      return null; // No redirect needed
    },
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
        path: roleSelection,
        name: 'role-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoleSelectionPage(),
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
        path: telecallerLogin,
        name: 'telecaller-login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TelecallerLoginPage(),
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
        path: margdarshakLogin,
        name: 'margdarshak-login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MargdarshakLoginPage(),
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
            pageBuilder: (context, state) {
              final tcFor = state.uri.queryParameters['tc_for'];
              return CustomTransitionPage(
                key: state.pageKey,
                child: SmartCallingPage(tcFor: tcFor),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurveTween(
                                curve: Curves.easeOutCubic,
                              ).animate(animation),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: 'subscriptions',
            name: 'subscriptions',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SubscriptionsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurveTween(
                              curve: Curves.easeOutCubic,
                            ).animate(animation),
                          ),
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
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(
                            CurveTween(
                              curve: Curves.easeOutCubic,
                            ).animate(animation),
                          ),
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
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurveTween(
                                curve: Curves.easeOutCubic,
                              ).animate(animation),
                            ),
                        child: child,
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: 'interested-dashboard',
            name: 'interested-dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const InterestedDashboardWrapper(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurveTween(
                              curve: Curves.easeOutCubic,
                            ).animate(animation),
                          ),
                      child: child,
                    );
                  },
            ),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DynamicProfileScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurveTween(
                              curve: Curves.easeOutCubic,
                            ).animate(animation),
                          ),
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
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurveTween(
                                  curve: Curves.easeOutCubic,
                                ).animate(animation),
                              ),
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
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(
                                CurveTween(
                                  curve: Curves.easeOutCubic,
                                ).animate(animation),
                              ),
                          child: child,
                        );
                      },
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: margdarshakDashboard,
        name: 'margdarshak-dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: MargdarshakNavigationContainer(key: margdarshakNavigationKey),
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
      // Driver Bucket Route
      GoRoute(
        path: driverBucket,
        name: 'driver-bucket',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DriverBucketScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Leave & Break Management Route
      GoRoute(
        path: leaveBreak,
        name: 'leave-break',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LeaveBreakManagementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Attendance Route
      GoRoute(
        path: attendance,
        name: 'attendance',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AttendanceScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
