import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> data;
  final Color color;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Extract numeric values from the data maps
    final values = data.map((item) {
      final value = item['value'] ?? item['calls'] ?? 0;
      return value is int ? value : int.tryParse(value.toString()) ?? 0;
    }).toList();
    
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.softGray,
            ),
          ),
          const SizedBox(height: 24),
          
          // Simple Bar Chart
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: values.asMap().entries.map((entry) {
                final value = entry.value;
                final height = maxValue > 0 ? (value / maxValue) * 150 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
