import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/smart_calling_models.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/full_width_bottom_nav.dart';
import '../../features/dashboard/interested_dashboard_wrapper.dart';
import 'dashboard_page.dart';
import 'screens/dynamic_profile_screen.dart';
import 'screens/interested_screen.dart';
import 'screens/connected_calls_screen.dart';
import 'screens/call_backs_screen.dart';
import 'screens/call_back_later_screen.dart';
import 'screens/pending_calls_screen.dart';
import 'screens/call_history_screen.dart';
import 'callback_requests/callback_requests_screen.dart';
import 'social_media/social_media_screen.dart';
import 'toll_free/toll_free_search_screen.dart';

enum MainNavigationTab { welcomeCall, tollFree, matchMaking, callback, social }

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  MainNavigationTab _currentTab = MainNavigationTab.welcomeCall;
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
    print(
      '🔍 MainNav: section=$section, index=${section.index}, filter=$filter',
    );

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
                        // Welcome Call tab - contains dashboard and sub-screens
                        _buildHomeTabContent(),
                        // Toll-free tab content
                        const TollFreeSearchScreen(),
                        // Matchmaking tab content - Phase 2 Dynamic Dashboard
                        const InterestedDashboardWrapper(),
                        // Callback tab content
                        const CallbackRequestsScreen(),
                        // Social tab content
                        const SocialMediaScreen(),
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
              if (_currentTab == MainNavigationTab.welcomeCall &&
                  !_isDrawerOpen)
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
              if (_currentTab == MainNavigationTab.welcomeCall &&
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
          onNavigateToProfile: () => _onTabChanged(MainNavigationTab.social),
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
    return FullWidthBottomNavBar(
      initialIndex: _currentTab.index,
      onIndexChanged: (index) => _onTabChanged(MainNavigationTab.values[index]),
    );
  }

  void _handleBackButton() {
    // Handle back button based on current state
    if (_isDrawerOpen) {
      // Close drawer if open
      _closeDrawer();
    } else if (_currentTab == MainNavigationTab.welcomeCall &&
        _currentSection != NavigationSection.home) {
      // Navigate back to home section if in sub-screen
      _onSectionChanged(NavigationSection.home);
    } else if (_currentTab != MainNavigationTab.welcomeCall) {
      // Navigate back to home tab if in other tabs
      _onTabChanged(MainNavigationTab.welcomeCall);
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
            style: AppTheme.bodyLarge.copyWith(color: Colors.grey.shade600),
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
      case MainNavigationTab.welcomeCall:
        return 0;
      case MainNavigationTab.tollFree:
        return 1;
      case MainNavigationTab.matchMaking:
        return 2;
      case MainNavigationTab.callback:
        return 3;
      case MainNavigationTab.social:
        return 4;
    }
  }
}
