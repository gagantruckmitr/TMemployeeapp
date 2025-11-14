import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'match_suggestions_modal.dart';

class DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onCall;

  const DriverCard({
    super.key,
    required this.driver,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.slateBlue.withOpacity(0.1),
                child: Text(
                  driver['name'].toString().substring(0, 1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slateBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driver['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        if (driver['verified'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified,
                              size: 16, color: AppColors.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${driver['city']}, ${driver['state']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.softGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softGray.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        driver['tmid'],
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.softGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Call Button
              IconButton(
                onPressed: onCall,
                icon: Icon(Icons.phone, color: AppColors.slateBlue),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.slateBlue.withOpacity(0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile Completion
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile Completion',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.softGray,
                          ),
                        ),
                        Text(
                          '${driver['profileCompletion']}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: driver['profileCompletion'] / 100,
                        backgroundColor: AppColors.softGray.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          driver['profileCompletion'] >= 80
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(Icons.local_shipping, driver['truckType']),
              _buildChip(Icons.work_history, driver['experience']),
              _buildChip(
                Icons.circle,
                driver['availability'],
                color: driver['availability'] == 'Available'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Applied Jobs
          if (driver['appliedJobs'].isNotEmpty) ...[
            Text(
              'Applied Jobs',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (driver['appliedJobs'] as List).map((jobId) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.slateBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jobId,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.slateBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Match Transporter Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const MatchSuggestionsModal(),
                );
              },
              icon: Icon(Icons.handshake, size: 18),
              label: const Text('Match Transporter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slateBlue,
                side: BorderSide(color: AppColors.slateBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.softGray).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.softGray),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.softGray,
            ),
          ),
        ],
      ),
    );
  }
}
