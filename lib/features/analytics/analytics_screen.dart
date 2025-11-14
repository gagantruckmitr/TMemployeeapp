import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dummy_data.dart';
import 'widgets/chart_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['This Week', 'This Month', 'This Year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedPeriod = period);
                      },
                      selectedColor: AppColors.slateBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Charts
            ChartCard(
              title: 'Job Posts Over Time',
              subtitle: 'Weekly trend',
              data: DummyData.analyticsData['jobPostsOverTime']!,
              color: AppColors.slateBlue,
            ),
            
            const SizedBox(height: 16),
            
            ChartCard(
              title: 'Match Conversion Funnel',
              subtitle: 'Success rate by stage',
              data: DummyData.analyticsData['matchConversion']!,
              color: AppColors.success,
            ),
            
            const SizedBox(height: 16),
            
            ChartCard(
              title: 'Calls Made by Day',
              subtitle: 'Daily activity',
              data: DummyData.analyticsData['callsByDay']!,
              color: AppColors.info,
            ),
            
            const SizedBox(height: 16),
            
            // Match Success Rate (Donut)
            Container(
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
                    'Match Success Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overall performance',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.softGray,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: 0.78,
                            strokeWidth: 12,
                            backgroundColor: AppColors.softGray.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '78%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                            Text(
                              'Success',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.softGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
