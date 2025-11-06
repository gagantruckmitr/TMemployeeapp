import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ActivityFeedItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityFeedItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDriver = activity['type'] == 'driver';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDriver 
                  ? AppColors.slateBlue.withOpacity(0.1)
                  : AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDriver ? Icons.person : Icons.business,
              color: isDriver ? AppColors.slateBlue : AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softGray.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity['tmid'],
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.softGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity['activity'],
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.softGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'],
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.softGray.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDriver ? const Color.fromARGB(255, 132, 132, 230) : AppColors.info,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
