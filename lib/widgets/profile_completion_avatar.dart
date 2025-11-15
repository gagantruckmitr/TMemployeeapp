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

  @override
  Widget build(BuildContext context) {
    return ProgressRingAvatar(
      profileImageUrl: profileImageUrl,
      userName: name,
      gender: gender,
      size: size,
      profileCompletion: completionPercentage ?? 0,
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
