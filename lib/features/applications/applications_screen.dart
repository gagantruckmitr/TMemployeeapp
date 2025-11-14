import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dummy_data.dart';
import 'widgets/application_card.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock application data with call history
    final applications = DummyData.drivers.map((driver) => {
      ...driver,
      'callCount': (driver['name'].hashCode % 10) + 1, // Mock call count
      'lastCallDuration': '${(driver['name'].hashCode % 15) + 1}m ${(driver['name'].hashCode % 60)}s', // Mock duration
      'avatar': driver['name'][0].toUpperCase(),
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Applications',
          style: TextStyle(
            color: AppColors.darkBeige,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBeige),
      ),
      body: Column(
        children: [
          // Total Applications Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Applications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${applications.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Applications List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ApplicationCard(application: application),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}