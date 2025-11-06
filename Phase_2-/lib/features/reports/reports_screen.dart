import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            'Daily Performance Report',
            'View today\'s call statistics and matches',
            Icons.today,
            AppColors.primary,
            () {},
          ),
          _buildReportCard(
            'Weekly Summary',
            'Last 7 days performance overview',
            Icons.calendar_view_week,
            AppColors.success,
            () {},
          ),
          _buildReportCard(
            'Monthly Analytics',
            'Comprehensive monthly report',
            Icons.calendar_month,
            AppColors.info,
            () {},
          ),
          _buildReportCard(
            'Driver Performance',
            'Top performing drivers this month',
            Icons.person_outline,
            AppColors.warning,
            () {},
          ),
          _buildReportCard(
            'Transporter Activity',
            'Active transporters and job postings',
            Icons.business,
            AppColors.accent,
            () {},
          ),
          _buildReportCard(
            'Match Success Rate',
            'Conversion and success metrics',
            Icons.handshake,
            AppColors.success,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.softGray,
            ),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }
}
