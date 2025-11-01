import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/smart_calling_models.dart';
import '../core/services/smart_calling_service.dart';
import '../core/services/real_auth_service.dart';
import '../routes/app_router.dart';

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
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Map<NavigationSection, int> _contactCounts = {};

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
    _loadContactCounts();
  }

  Future<void> _loadContactCounts() async {
    try {
      final counts = await SmartCallingService.instance.getContactCounts();
      if (mounted) {
        setState(() {
          _contactCounts = counts;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contactCounts = {
            NavigationSection.home: 0,
            NavigationSection.interested: 0,
            NavigationSection.connectedCalls: 0,
            NavigationSection.callBacks: 0,
            NavigationSection.callBackLater: 0,
            NavigationSection.profile: 0,
          };
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _closeDrawer() {
    _slideController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _onSectionTap(NavigationSection section) {
    if (section != widget.currentSection) {
      HapticFeedback.lightImpact();
      widget.onSectionChanged(section);
      _closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 600 ? 280.0 : 280.0;

    return Stack(
      children: [
        // Overlay
        GestureDetector(
          onTap: _closeDrawer,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Drawer content
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: drawerWidth,
            height: double.infinity,
            color: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  _buildDrawerHeader(),
                  Expanded(child: _buildNavigationMenu()),
                  _buildDrawerFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader() {
    final user = RealAuthService.instance.currentUser;
    final userName = user?.name ?? 'User';
    final userRole = user?.role.toUpperCase() ?? 'TELECALLER';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              userInitial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userRole,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _closeDrawer,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildNavigationItem(
          NavigationSection.home,
          'Home',
          Icons.home_outlined,
        ),
        _buildNavigationItem(
          NavigationSection.interested,
          'Interested',
          Icons.star_outline,
        ),
        _buildNavigationItem(
          NavigationSection.connectedCalls,
          'Connected Calls',
          Icons.phone_outlined,
        ),
        _buildNavigationItem(
          NavigationSection.callBacks,
          'Call Backs',
          Icons.refresh_outlined,
        ),
        _buildNavigationItem(
          NavigationSection.callBackLater,
          'Call Back Later',
          Icons.schedule_outlined,
        ),
        const Divider(height: 24, thickness: 1),
        _buildNavigationItem(
          NavigationSection.callHistory,
          'Call History',
          Icons.history,
        ),
        _buildNavigationItem(
          NavigationSection.profile,
          'My Profile',
          Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildNavigationItem(
    NavigationSection section,
    String title,
    IconData icon,
  ) {
    final isActive = widget.currentSection == section;
    final count = _getContactCount(section);

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryBlue : Colors.grey.shade700,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryBlue : Colors.grey.shade800,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: count > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBlue : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          : null,
      selected: isActive,
      selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
      onTap: () => _onSectionTap(section),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: Colors.grey.shade700,
              size: 24,
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRouter.settings);
              _closeDrawer();
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.red.shade600,
              size: 24,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              HapticFeedback.lightImpact();
              await RealAuthService.instance.logout();
              if (context.mounted) {
                context.go(AppRouter.login);
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ],
      ),
    );
  }

  int _getContactCount(NavigationSection section) {
    return _contactCounts[section] ?? 0;
  }
}
