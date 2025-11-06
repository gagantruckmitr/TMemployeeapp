import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../screens/profile_completion_details_screen.dart';

class ProfileCompletionAvatar extends StatelessWidget {
  final String name;
  final int userId;
  final String userType; // 'driver' or 'transporter'
  final double size;
  final int? completionPercentage;

  const ProfileCompletionAvatar({
    super.key,
    required this.name,
    required this.userId,
    required this.userType,
    this.size = 50,
    this.completionPercentage,
  });

  Color _getCompletionColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
      child: Stack(
        children: [
          // Avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 134, 24, 185),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Completion percentage badge
          if (completionPercentage != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCompletionColor(completionPercentage!),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$completionPercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
