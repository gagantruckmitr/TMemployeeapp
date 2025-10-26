import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';

class KPITile extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color color;
  final int index;

  const KPITile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          onTap: () {
            // Handle KPI tile tap
          },
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    Icon(
                      Icons.trending_up,
                      color: AppTheme.white.withOpacity(0.8),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  value,
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: Duration(milliseconds: 200 * index))
        .slideX(begin: 0.3, end: 0)
        .then()
        .shimmer(
          duration: 2000.ms,
          delay: Duration(milliseconds: 1000 + 200 * index),
          color: AppTheme.white.withOpacity(0.3),
        );
  }
}