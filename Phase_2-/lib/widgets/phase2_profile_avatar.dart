import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Phase2ProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String userName;
  final String gender; // "male" or "female"
  final double size;
  final int? completionPercentage;
  final bool showCompletionBadge;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;

  const Phase2ProfileAvatar({
    super.key,
    this.profileImageUrl,
    required this.userName,
    required this.gender,
    this.size = 56,
    this.completionPercentage,
    this.showCompletionBadge = true,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContent;

    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      // Show network image with fallback
      avatarContent = CachedNetworkImage(
        imageUrl: profileImageUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => _buildLoadingState(),
        errorWidget: (context, url, error) => _buildFallbackAvatar(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    } else {
      // Show fallback avatar immediately
      avatarContent = _buildFallbackAvatar();
    }

    // Wrap with gesture detector if tappable
    Widget avatar = onTap != null
        ? GestureDetector(
            onTap: onTap,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 100),
              child: avatarContent,
            ),
          )
        : avatarContent;

    // Add border and shadow
    avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: avatarContent),
    );

    // Add badges if needed
    if (showCompletionBadge && completionPercentage != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildCompletionBadge(),
          ),
        ],
      );
    } else if (showOnlineStatus) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildOnlineStatusIndicator(),
          ),
        ],
      );
    }

    return Semantics(
      label: profileImageUrl != null
          ? 'Profile photo of $userName'
          : '$userName\'s profile avatar',
      hint: onTap != null ? 'Tap to view profile' : null,
      child: avatar,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final iconSize = size * 0.5;
    final icon = gender.toLowerCase() == 'female'
        ? Icons.person_outline
        : Icons.person;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: const Color(0xFF757575),
        ),
      ),
    );
  }

  Widget _buildCompletionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$completionPercentage%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOnlineStatusIndicator() {
    final indicatorSize = size * 0.25;
    final color = isOnline ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E);

    return Container(
      width: indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
