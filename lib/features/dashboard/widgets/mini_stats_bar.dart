import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MiniStatsBar extends StatelessWidget {
  const MiniStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniStat('24', Icons.phone, AppColors.success),
          const SizedBox(width: 16),
          _buildMiniStat('12', Icons.pending, AppColors.warning),
          const SizedBox(width: 16),
          _buildMiniStat('8', Icons.handshake, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
