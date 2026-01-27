import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/smart_calling_models.dart';
import '../core/services/real_auth_service.dart';
import '../app/router/app_router.dart';

/// Apple-style minimal sidebar for TMConnect
/// Following iOS Human Interface Guidelines
class NavigationDrawerWidget extends StatefulWidget {
  final NavigationSection currentSection;
  final Function(NavigationSection) onSectionChanged;
  final VoidCallback onClose;

  const NavigationDrawerWidget({
    super.key,
    required this.currentSection,
    required this.onSectionChanged,
    required this.onClose,
  });

  @override
  State<NavigationDrawerWidget> createState() => _NavigationDrawerWidgetState();
}

class _NavigationDrawerWidgetState extends State<NavigationDrawerWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _slideController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  // iOS system blue color
  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _systemRed = Color(0xFFFF3B30);
  static const Color _labelPrimary = Color(0xFF000000);
  static const Color _separatorColor = Color(0xFFC6C6C8);
  static const Color _backgroundPrimary = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController!,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
    );

    _slideController!.forward();
  }

  @override
  void dispose() {
    _slideController?.dispose();
    super.dispose();
  }

  void _closeDrawer() {
    _slideController?.reverse().then((_) {
      widget.onClose();
    });
  }

  void _onSectionTap(NavigationSection section) {
    HapticFeedback.lightImpact();
    widget.onSectionChanged(section);
    _closeDrawer();
  }

  void _navigateToDriverBucket() {
    HapticFeedback.lightImpact();
    context.push('/driver-bucket');
    _closeDrawer();
  }

  void _navigateToWelcomeCall() {
    HapticFeedback.lightImpact();
    context.push(AppRouter.smartCalling);
    _closeDrawer();
  }

  void _navigateToProfile() {
    HapticFeedback.lightImpact();
    context.push(AppRouter.profile);
    _closeDrawer();
  }

  void _navigateToLeaveBreak() {
    HapticFeedback.lightImpact();
    context.push('/leave-break');
    _closeDrawer();
  }

  void _navigateToAttendance() {
    HapticFeedback.lightImpact();
    context.push('/attendance');
    _closeDrawer();
  }

  void _navigateToSettings() {
    HapticFeedback.lightImpact();
    context.push(AppRouter.settings);
    _closeDrawer();
  }

  Future<void> _handleLogout() async {
    HapticFeedback.mediumImpact();
    await RealAuthService.instance.logout();
    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // Slimmer drawer - 72% of screen width
    final drawerWidth = screenWidth * 0.72;

    // Ensure animations are initialized
    if (_slideAnimation == null || _fadeAnimation == null) {
      _initAnimations();
    }

    return Stack(
      children: [
        // Semi-transparent overlay with blur effect simulation
        FadeTransition(
          opacity: _fadeAnimation!,
          child: GestureDetector(
            onTap: _closeDrawer,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ),

        // Drawer content - starts below status bar
        Positioned(
          top: statusBarHeight,
          left: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideAnimation!,
            child: Container(
              width: drawerWidth,
              decoration: BoxDecoration(
                color: _backgroundPrimary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(4, 0),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 32,
                    offset: const Offset(8, 0),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildMenuList()),
                    _buildFooter(),
                    // Bottom safe area padding
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final user = RealAuthService.instance.currentUser;
    final userName = user?.name ?? 'User';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final photoUrl = user?.photoUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: const BoxDecoration(
        color: _systemBlue,
        borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Rounded avatar with photo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (context, url) => Center(
                        child: Text(
                          userInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          userInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Name and role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'TeleChamp',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: _closeDrawer,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        // Main navigation items
        _buildMenuItem(
          icon: Icons.home_outlined,
          title: 'Home',
          section: NavigationSection.home,
        ),
        // Driver Bucket - navigates to dedicated screen
        _buildMenuItemAction(
          icon: Icons.local_shipping_outlined,
          title: 'Driver Bucket',
          onTap: _navigateToDriverBucket,
        ),
        // Welcome Call - navigates to smart calling page
        _buildMenuItemAction(
          icon: Icons.phone_in_talk_outlined,
          title: 'Welcome Call',
          onTap: _navigateToWelcomeCall,
        ),
        _buildMenuItem(
          icon: Icons.dialpad_outlined,
          title: 'Toll Free',
          section: NavigationSection.tollFree,
        ),
        _buildMenuItem(
          icon: Icons.work_outline,
          title: 'Job Matching',
          section: NavigationSection.jobMatching,
        ),
        _buildMenuItem(
          icon: Icons.schedule_outlined,
          title: 'Callback Request',
          section: NavigationSection.callbackRequest,
        ),
        _buildMenuItem(
          icon: Icons.share_outlined,
          title: 'Social Media Leads',
          section: NavigationSection.socialMediaLeads,
        ),

        // Thin separator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(height: 0.5, color: _separatorColor),
        ),

        // Leave & Break Management
        _buildMenuItemAction(
          icon: Icons.coffee_outlined,
          title: 'Leave & Break',
          onTap: _navigateToLeaveBreak,
        ),

        // Attendance
        _buildMenuItemAction(
          icon: Icons.fingerprint_outlined,
          title: 'Attendance',
          onTap: _navigateToAttendance,
        ),

        // Profile item
        _buildMenuItemAction(
          icon: Icons.person_outline,
          title: 'My Profile',
          onTap: _navigateToProfile,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required NavigationSection section,
  }) {
    final isActive = widget.currentSection == section;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSectionTap(section),
        splashColor: _systemBlue.withValues(alpha: 0.1),
        highlightColor: _systemBlue.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? _systemBlue.withValues(alpha: 0.08) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? _systemBlue
                    : _labelPrimary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? _systemBlue : _labelPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: _systemBlue.withValues(alpha: 0.1),
        highlightColor: _systemBlue.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: textColor ?? _labelPrimary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textColor ?? _labelPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: _separatorColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildMenuItemAction(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: _navigateToSettings,
          ),
          _buildMenuItemAction(
            icon: Icons.logout_outlined,
            title: 'Logout',
            onTap: _handleLogout,
            textColor: _systemRed,
          ),
        ],
      ),
    );
  }
}
