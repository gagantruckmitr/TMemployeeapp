import 'package:flutter/material.dart';
import '../screens/profile_completion_details_screen.dart';
import 'progress_ring_avatar.dart';

class ProfileCompletionAvatar extends StatelessWidget {
  final String name;
  final int userId;
  final String userType; // 'driver' or 'transporter'
  final double size;
  final int? completionPercentage;
  final String? profileImageUrl;
  final String? gender;

  const ProfileCompletionAvatar({
    super.key,
    required this.name,
    required this.userId,
    required this.userType,
    this.size = 70,
    this.completionPercentage,
    this.profileImageUrl,
    this.gender,
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
        // Debug: Show what we're passing
        print('=== AVATAR TAPPED ===');
        print('userId: $userId (${userId.runtimeType})');
        print('userName: $name');
        print('userType: $userType');
        print('====================');
        
        // Validate userId before navigation
        if (userId == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid user ID (0). Cannot view profile details.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileCompletionDetailsScreen(
              userId: userId,
              userName: name,
              userType: userType,
            ),
          ),
        );
      },
    );
  }
}
