import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String transporterName;
  final String transporterPhone;

  const JobCard({
    super.key,
    required this.job,
    required this.transporterName,
    required this.transporterPhone,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.white, AppColors.lightBeige],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Job ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job['jobId'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBeige,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route Information
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${job['from']} → ${job['to']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBeige,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Job Details Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.local_shipping,
                    label: 'Truck Type',
                    value: job['truckType'],
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.scale,
                    label: 'Load',
                    value: job['load'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.currency_rupee,
                    label: 'Salary',
                    value: job['payRate'],
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.people,
                    label: 'Drivers Required',
                    value: '${job['applicants']} Applied',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Experience Required (assuming from dummy data)
            _buildInfoItem(
              icon: Icons.work_history,
              label: 'Experience Required',
              value: '5+ years', // This could be dynamic
            ),
            const SizedBox(height: 16),

            // Transporter Info and Call Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transporterName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkBeige,
                        ),
                      ),

                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(transporterPhone),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.softGray,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkBeige,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
