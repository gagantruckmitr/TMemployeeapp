import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/smart_calling_models.dart';
import '../../widgets/navigation_drawer.dart';
import '../../core/services/pending_feedback_service.dart';
import 'dashboard_page.dart';
import 'screens/interested_screen.dart';
import 'screens/connected_calls_screen.dart';
import 'screens/call_backs_screen.dart';
import 'screens/call_back_later_screen.dart';
import 'screens/pending_calls_screen.dart';
import 'screens/call_history_screen.dart';
import 'screens/dynamic_profile_screen.dart';

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> with WidgetsBindingObserver {
  NavigationSection _currentSection = NavigationSection.home;
  bool _isDrawerOpen = false;
  late PageController _pageController;
  String? _callHistoryFilter;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    _checkPendingFeedbackOnStart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check for pending feedback when app resumes
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking for pending feedback');
      _checkAndShowPendingFeedback();
    }
  }

  /// Check for pending feedback on app start
  Future<void> _checkPendingFeedbackOnStart() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _checkAndShowPendingFeedback();
  }

  /// Check and show pending feedback modal
  Future<void> _checkAndShowPendingFeedback() async {
    final hasPending = await PendingFeedbackService.instance.hasPendingFeedback();
    
    if (hasPending && mounted) {
      final pendingData = await PendingFeedbackService.instance.getPendingFeedback();
      
      if (pendingData != null) {
        final timeSince = DateTime.now().difference(
          DateTime.parse(pendingData['timestamp'] as String),
        );
        
        print('⏰ Pending feedback found - Time since call: ${timeSince.inMinutes}m');
        
        // Navigate to smart calling page with pending feedback
        if (mounted) {
          // Use internal navigation instead of go_router
          _onSectionChanged(NavigationSection.home);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _onSectionChanged(NavigationSection section, {String? filter}) {
    print('🔍 Navigation: section=$section, index=${section.index}, filter=$filter');
    
    setState(() {
      _currentSection = section;
      // Store filter for call history screen
      if (section == NavigationSection.callHistory && filter != null) {
        _callHistoryFilter = filter;
      }
    });

    // Animate to the new page
    _pageController.animateToPage(
      section.index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );

    HapticFeedback.selectionClick();
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
            // Only allow swipe right to open drawer when on home screen
            if (details.primaryVelocity! > 0 &&
                !_isDrawerOpen &&
                _currentSection == NavigationSection.home) {
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
                  DashboardPage(
                    onNavigateToProfile: _navigateToProfile,
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
