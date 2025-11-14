import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/smart_calling_models.dart';
import '../../widgets/navigation_drawer.dart';
import 'dashboard_page.dart';
import 'performance_analytics_page.dart';
import 'screens/dynamic_profile_screen.dart';
import 'screens/interested_screen.dart';
import 'screens/connected_calls_screen.dart';
import 'screens/call_backs_screen.dart';
import 'screens/call_back_later_screen.dart';
import 'screens/pending_calls_screen.dart';
import 'screens/call_history_screen.dart';

enum MainNavigationTab {
  home,
  analytics,
  profile,
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  MainNavigationTab _currentTab = MainNavigationTab.home;
  NavigationSection _currentSection = NavigationSection.home;
  bool _isDrawerOpen = false;
  late PageController _pageController;
  late PageController _subPageController;
  String? _callHistoryFilter;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _subPageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _subPageController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() {
      _isDrawerOpen = true;
    });
    HapticFeedback.lightImpact();
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
  }

  void _onTabChanged(MainNavigationTab tab) {
    if (tab != _currentTab) {
      setState(() {
        _currentTab = tab;
      });
      
      _pageController.animateToPage(
        tab.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      
      HapticFeedback.selectionClick();
    }
  }

  void _onSectionChanged(NavigationSection section, {String? filter}) {
    print('🔍 MainNav: section=$section, index=${section.index}, filter=$filter');
    
    setState(() {
      _currentSection = section;
      // Store filter for call history
      if (section == NavigationSection.callHistory && filter != null) {
        _callHistoryFilter = filter;
      }
    });
    
    // Animate to the new sub-page
    _subPageController.animateToPage(
      section.index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
        body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe right to open drawer
          if (details.primaryVelocity! > 0 && !_isDrawerOpen) {
            _openDrawer();
          }
          // Swipe left to close drawer
          else if (details.primaryVelocity! < 0 && _isDrawerOpen) {
            _closeDrawer();
          }
        },
        child: Stack(
          children: [
            // Main content with bottom navigation
            Column(
              children: [
                // Main pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Home tab - contains dashboard and sub-screens
                      _buildHomeTabContent(),
                      // Analytics tab
                      PerformanceAnalyticsPage(
                        onNavigateBack: () => _onTabChanged(MainNavigationTab.home),
                      ),
                      // Profile tab
                      DynamicProfileScreen(
                        onNavigateBack: () => _onTabChanged(MainNavigationTab.home),
                      ),
                    ],
                  ),
                ),
                // Bottom Navigation
                _buildBottomNavigation(),
              ],
            ),
            
            // Drawer overlay
            if (_isDrawerOpen)
              NavigationDrawerWidget(
                currentSection: _currentSection,
                onSectionChanged: _onSectionChanged,
                onClose: _closeDrawer,
              ),
            
            // Menu button for home tab
            if (_currentTab == MainNavigationTab.home && !_isDrawerOpen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openDrawer,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Back button for sub-screens
            if (_currentTab == MainNavigationTab.home && 
                _currentSection != NavigationSection.home && 
                !_isDrawerOpen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSectionChanged(NavigationSection.home),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ), // End of Stack
      ), // End of GestureDetector
    ), // End of Scaffold
    ); // End of PopScope
  }

  Widget _buildHomeTabContent() {
    return PageView(
      controller: _subPageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        DashboardPage(
          onOpenDrawer: _openDrawer,
          onNavigateToProfile: () => _onTabChanged(MainNavigationTab.profile),
          onNavigateToSection: _onSectionChanged,
        ),
        const InterestedScreen(),
        const ConnectedCallsScreen(),
        const CallBacksScreen(),
        const CallBackLaterScreen(),
        const PendingCallsScreen(),
        CallHistoryScreen(
          key: ValueKey(_callHistoryFilter),
          initialFilter: _callHistoryFilter,
        ),
        const DynamicProfileScreen(), // This won't be used since profile has its own tab
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: -3,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                MainNavigationTab.home,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
              ),
              _buildNavItem(
                MainNavigationTab.analytics,
                Icons.analytics_outlined,
                Icons.analytics_rounded,
                'Analytics',
              ),
              _buildNavItem(
                MainNavigationTab.profile,
                Icons.person_outline,
                Icons.person_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    MainNavigationTab tab,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentTab == tab;

    return GestureDetector(
      onTap: () => _onTabChanged(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? Colors.white
                    : AppTheme.gray.withValues(alpha: 0.7),
                size: isSelected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppTheme.gray.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackButton() {
    // Handle back button based on current state
    if (_isDrawerOpen) {
      // Close drawer if open
      _closeDrawer();
    } else if (_currentTab == MainNavigationTab.home && _currentSection != NavigationSection.home) {
      // Navigate back to home section if in sub-screen
      _onSectionChanged(NavigationSection.home);
    } else if (_currentTab != MainNavigationTab.home) {
      // Navigate back to home tab if in other tabs
      _onTabChanged(MainNavigationTab.home);
    } else {
      // If already on home tab and home section, show exit dialog
      _showExitDialog();
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Exit App',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to exit the app?',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Exit the app
                SystemNavigator.pop();
              },
              child: Text(
                'Exit',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension MainNavigationTabExtension on MainNavigationTab {
  int get index {
    switch (this) {
      case MainNavigationTab.home:
        return 0;
      case MainNavigationTab.analytics:
        return 1;
      case MainNavigationTab.profile:
        return 2;
    }
  }
}