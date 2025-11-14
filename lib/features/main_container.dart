import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../core/theme/app_colors.dart';
import 'dashboard/dynamic_dashboard_screen.dart';
import 'jobs/dynamic_jobs_screen.dart';
import 'calls/call_history_hub_screen.dart';
import 'analytics/call_analytics_screen.dart';
import 'profile/profile_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DynamicDashboardScreen(),
      DynamicJobsScreen(
        onBackToDashboard: () => setState(() => _currentIndex = 0),
      ),
      const CallHistoryHubScreen(),
      const CallAnalyticsScreen(),
      const ProfileScreen(),
    ];
  }

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.work_rounded,
    Icons.history_rounded,
    Icons.analytics_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = [
    'Dashboard',
    'Jobs',
    'History',
    'Analytics',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: AnimatedBottomNavigationBar.builder(
            itemCount: _icons.length,
            tabBuilder: (int index, bool isActive) {
              return _buildNavItem(index, _icons[index], _labels[index], isActive);
            },
            activeIndex: _currentIndex,
            gapLocation: GapLocation.none,
            notchSmoothness: NotchSmoothness.softEdge,
            leftCornerRadius: 20,
            rightCornerRadius: 20,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            splashColor: AppColors.primary.withValues(alpha: 0.2),
            splashSpeedInMilliseconds: 300,
            height: 80,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(isActive ? 8 : 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.softGray,
              size: isActive ? 24 : 20,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: isActive ? 11 : 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.softGray,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
