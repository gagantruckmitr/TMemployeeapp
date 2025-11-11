import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

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
      decoration: const BoxDecoration(
        color: Colors.white,
        // Removed all shadows and elevation for flat design
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopNavBar(),
              const SizedBox(height: 16),
              _buildGreetingSection(),
              const SizedBox(height: 20),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Row(
      children: [
        // Menu button (hamburger icon) - flat design, no shadow
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white, // Flat white background, no shadow
          ),
          child: Icon(Icons.menu, color: Colors.grey.shade700, size: 24),
        ),
        // Expanded center section for "Home" title
        Expanded(
          child: Center(
            child:
                Text(
                      'Home',
                      style: AppTheme.headingMedium.copyWith(
                        color: Colors.grey.shade900,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
          ),
        ),
        // Right side profile section
        _buildProfileSection(),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
        ), // Left padding for proper alignment
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi $userName!',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryColor, // Blue color
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 4),
            Text(
                  greeting,
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 150.ms)
                .slideX(begin: -0.2, end: 0),
          ],
        ),
      ),
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
          decoration: const BoxDecoration(
            color: Colors.white, // Flat white background, no shadow or border
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Colors.grey.shade700,
            size: 22,
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
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20), // Circular avatar
          ),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              hintText: 'Search here...',
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
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
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
