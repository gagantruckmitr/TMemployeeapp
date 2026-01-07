import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../../core/services/real_auth_service.dart';
import '../../../routes/app_router.dart';

class DynamicProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateBack;

  const DynamicProfileScreen({super.key, this.onNavigateBack});

  @override
  State<DynamicProfileScreen> createState() => _DynamicProfileScreenState();
}

class _DynamicProfileScreenState extends State<DynamicProfileScreen> {
  // iOS System Colors
  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _systemGreen = Color(0xFF34C759);
  static const Color _systemRed = Color(0xFFFF3B30);
  static const Color _systemPurple = Color(0xFFAF52DE);
  static const Color _systemOrange = Color(0xFFFF9500);
  static const Color _systemTeal = Color(0xFF5AC8FA);
  static const Color _labelPrimary = Color(0xFF000000);
  static const Color _labelTertiary = Color(0xFF8E8E93);
  static const Color _separatorColor = Color(0xFFE5E5EA);
  static const Color _groupedBackground = Color(0xFFF2F2F7);

  UserProfile? _user;
  UserProfileWithStats? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user with employee details
      _user = RealAuthService.instance.currentUser;
      
      // Also try to get stats from API
      final profileData = await RealAuthService.instance.getProfile();
      if (mounted) {
        setState(() {
          _profileData = profileData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSettings() {
    context.push(AppRouter.settings);
  }

  void _showContactDetails() {
    final user = _user ?? _profileData?.user;
    if (user == null) return;
    final emp = user.employeeDetails;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _labelTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _labelPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildContactRow(
                      icon: Icons.phone_rounded,
                      label: 'Mobile',
                      value: emp?.mobile ?? user.mobile,
                      color: _systemGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildContactRow(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: emp?.email ?? user.email,
                      color: _systemBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildContactRow(
                      icon: Icons.badge_rounded,
                      label: 'Employee ID',
                      value: emp?.empId ?? 'TM-${user.id}',
                      color: _systemPurple,
                    ),
                    if (emp?.emergencyPhone != null) ...[
                      const SizedBox(height: 16),
                      _buildContactRow(
                        icon: Icons.emergency_rounded,
                        label: 'Emergency Contact (${emp?.emergencyRelation ?? ""})',
                        value: '${emp?.emergencyName ?? ""} - ${emp?.emergencyPhone ?? ""}',
                        color: _systemRed,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: _groupedBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _systemBlue,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _groupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _labelTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: _labelPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _labelTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(height: 1, color: _separatorColor),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: _systemRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _systemBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await RealAuthService.instance.logout();
        if (mounted) {
          context.go(AppRouter.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: _systemRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavigationBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _separatorColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (widget.onNavigateBack != null) {
                widget.onNavigateBack!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRouter.dashboard);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, color: _systemBlue, size: 20),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: _systemBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title
          const Expanded(
            child: Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  color: _labelPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          // Settings button
          GestureDetector(
            onTap: _navigateToSettings,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.settings_outlined,
                color: _systemBlue,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator.adaptive(
        valueColor: AlwaysStoppedAnimation<Color>(_systemBlue),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: _systemRed),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load profile',
              style: const TextStyle(
                fontSize: 15,
                color: _labelTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadProfile,
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: _systemBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Use current user with employee details, fallback to profile data
    final user = _user ?? _profileData?.user;
    if (user == null) return const SizedBox();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildProfileHeader(user),
          const SizedBox(height: 32),
          _buildEmployeeDetailsSection(user),
          const SizedBox(height: 24),
          _buildMenuSection(user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetailsSection(UserProfile user) {
    final emp = user.employeeDetails;
    if (emp == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _groupedBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (emp.empId != null)
              _buildDetailRow(
                icon: Icons.badge_rounded,
                label: 'Employee ID',
                value: emp.empId!,
                color: _systemPurple,
              ),
            if (emp.dob != null) ...[
              const Divider(height: 1, color: _separatorColor, indent: 56),
              _buildDetailRow(
                icon: Icons.cake_rounded,
                label: 'Date of Birth',
                value: emp.dob!,
                color: _systemOrange,
              ),
            ],
            if (emp.mobile != null) ...[
              const Divider(height: 1, color: _separatorColor, indent: 56),
              _buildDetailRow(
                icon: Icons.phone_rounded,
                label: 'Mobile',
                value: emp.mobile!,
                color: _systemGreen,
              ),
            ],
            if (emp.email != null) ...[
              const Divider(height: 1, color: _separatorColor, indent: 56),
              _buildDetailRow(
                icon: Icons.email_rounded,
                label: 'Email',
                value: emp.email!,
                color: _systemBlue,
              ),
            ],
            if (emp.workLocation != null) ...[
              const Divider(height: 1, color: _separatorColor, indent: 56),
              _buildDetailRow(
                icon: Icons.location_on_rounded,
                label: 'Work Location',
                value: emp.workLocation!,
                color: _systemRed,
              ),
            ],
            if (emp.currentAddress != null) ...[
              const Divider(height: 1, color: _separatorColor, indent: 56),
              _buildDetailRow(
                icon: Icons.home_rounded,
                label: 'Address',
                value: emp.currentAddress!,
                color: _systemTeal,
                isMultiLine: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _labelTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _labelPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: isMultiLine ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    final photoUrl = user.photoUrl;
    
    return Column(
      children: [
        // Avatar with photo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: photoUrl == null ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
            ) : null,
            boxShadow: [
              BoxShadow(
                color: _systemBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                    placeholder: (context, url) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _labelPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _systemGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            user.role.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _systemGreen,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Employee ID if available
        if (user.employeeDetails?.empId != null) ...[
          const SizedBox(height: 8),
          Text(
            user.employeeDetails!.empId!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _labelTertiary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }

  // Widget _buildSuccessRateCard(UserStats stats) {
  //   final successRate = stats.successRate;

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: BoxDecoration(
  //         gradient: const LinearGradient(
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //           colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
  //         ),
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                   'Success Rate',
  //                   style: TextStyle(
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w500,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   '${stats.connectedCalls} of ${stats.totalCalls} calls',
  //                   style: TextStyle(
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w400,
  //                     color: Colors.white.withValues(alpha: 0.8),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           SizedBox(
  //             width: 80,
  //             height: 80,
  //             child: CustomPaint(
  //               painter: _CircularProgressPainter(
  //                 progress: successRate / 100,
  //                 progressColor: Colors.white,
  //                 backgroundColor: Colors.white.withValues(alpha: 0.2),
  //               ),
  //               child: Center(
  //                 child: Text(
  //                   '${successRate.toStringAsFixed(0)}%',
  //                   style: const TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.w700,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMenuSection(UserProfile user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _groupedBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.contact_page_outlined,
              title: 'Contact Details',
              color: _systemBlue,
              onTap: _showContactDetails,
            ),
            const Divider(height: 1, color: _separatorColor, indent: 56),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: _systemRed,
              onTap: _handleLogout,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: isDestructive ? _systemRed : _labelPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _labelTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 6.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
