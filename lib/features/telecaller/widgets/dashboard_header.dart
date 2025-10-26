import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String greeting;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderRow(),
              const SizedBox(height: 20),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Add space for hamburger icon
        // Icon is at left: 16px with width: 44px = 60px total
        // Header padding is 24px, so we need 60 - 24 = 36px + extra margin = 72px for safety
        const SizedBox(width: 72),
        Expanded(child: _buildWelcomeSection()),
        const SizedBox(width: AppConstants.paddingMedium),
        _buildProfileSection(),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
        const SizedBox(height: 2),
        Text(
              '$userName 👋',
              style: AppTheme.headingMedium.copyWith(
                color: Colors.grey.shade900,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 150.ms)
            .slideX(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNotificationButton(),
        const SizedBox(width: 12),
        _buildProfileAvatar(),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Colors.grey.shade700,
            size: 20,
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildProfileAvatar() {
    return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 450.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildSearchBar() {
    return Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: TextField(
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.grey.shade900,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search contacts, calls...',
              hintStyle: AppTheme.bodyLarge.copyWith(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade500,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
