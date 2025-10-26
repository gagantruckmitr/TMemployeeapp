import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/smart_calling_models.dart';
import '../../widgets/navigation_drawer.dart';
import 'dashboard_page.dart';
import 'screens/interested_screen.dart';
import 'screens/connected_calls_screen.dart';
import 'screens/call_backs_screen.dart';
import 'screens/call_back_later_screen.dart';
import 'screens/dynamic_profile_screen.dart';

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  NavigationSection _currentSection = NavigationSection.home;
  bool _isDrawerOpen = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _onSectionChanged(NavigationSection section) {
    if (section != _currentSection) {
      setState(() {
        _currentSection = section;
      });

      // Animate to the new page
      _pageController.animateToPage(
        section.index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );

      HapticFeedback.selectionClick();
    }
  }

  void _navigateToProfile() {
    _onSectionChanged(NavigationSection.profile);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Show exit confirmation dialog
        _showExitConfirmationDialog(context);
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
              // Main content
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardPage(onNavigateToProfile: _navigateToProfile),
                  const InterestedScreen(),
                  const ConnectedCallsScreen(),
                  const CallBacksScreen(),
                  const CallBackLaterScreen(),
                  const DynamicProfileScreen(),
                ],
              ),

              // Drawer overlay
              if (_isDrawerOpen)
                NavigationDrawerWidget(
                  currentSection: _currentSection,
                  onSectionChanged: _onSectionChanged,
                  onClose: _closeDrawer,
                ),

              // Back button for other screens
              if (_currentSection != NavigationSection.home && !_isDrawerOpen)
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
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Exit the app
                SystemNavigator.pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}
