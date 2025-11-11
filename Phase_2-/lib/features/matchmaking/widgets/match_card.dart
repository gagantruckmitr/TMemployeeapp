import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';

class MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final matchScore = match['matchScore'] as int;
    final scoreColor = matchScore >= 90
        ? AppColors.success
        : matchScore >= 80
            ? AppColors.primary
            : AppColors.warning;

    return GlassmorphicCard(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Match score circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: matchScore / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.secondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$matchScore%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    'Match',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Driver info
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scoreColor.withOpacity(0.1),
                child: Text(
                  match['driverName'].toString().substring(0, 1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          match['driverName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        if (match['verified'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified,
                              size: 18, color: AppColors.success),
                        ],
                      ],
                    ),
                    Text(
                      match['tmid'],
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.secondary.withOpacity(0.3)),
          const SizedBox(height: 20),

          // Match details
          _buildMatchDetail('Location Match', '${match['locationMatch']}%',
              Icons.location_on),
          const SizedBox(height: 12),
          _buildMatchDetail('Truck Type Match', '${match['truckTypeMatch']}%',
              Icons.local_shipping),
          const SizedBox(height: 12),
          _buildMatchDetail(
              'Availability', match['availability'], Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildMatchDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.accent,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
