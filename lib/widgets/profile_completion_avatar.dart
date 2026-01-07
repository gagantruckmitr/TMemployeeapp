import 'package:flutter/material.dart';
import '../screens/profile_completion_loader_screen.dart';
import 'progress_ring_avatar.dart';

class ProfileCompletionAvatar extends StatelessWidget {
  final String name;
  final int userId;
  final String userType; // 'driver' or 'transporter'
  final double size;
  final int? completionPercentage;
  final String? profileImageUrl;
  final String? gender;
  final String? tmId;
  final Map<String, dynamic>? profileData;

  const ProfileCompletionAvatar({
    super.key,
    required this.name,
    required this.userId,
    required this.userType,
    this.size = 70,
    this.completionPercentage,
    this.profileImageUrl,
    this.gender,
    this.tmId,
    this.profileData,
  });

  // Get ring color based on profile completion percentage
  Color _getRingColorByPercentage(int percentage) {
    if (percentage <= 50) {
      return const Color(0xFFE53935); // Red for 1-50%
    } else if (percentage <= 80) {
      return const Color(0xFFFFA726); // Orange for 51-80%
    } else {
      return const Color(0xFF43A047); // Green for 81-100%
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = completionPercentage ?? 0;
    return ProgressRingAvatar(
      profileImageUrl: profileImageUrl,
      userName: name,
      gender: gender,
      size: size,
      profileCompletion: percentage,
      ringColor: _getRingColorByPercentage(percentage),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileCompletionLoaderScreen(
              userId: userId,
              userName: name,
              userType: userType,
              tmId: tmId,
            ),
          ),
        );
      },
    );
  }
}
