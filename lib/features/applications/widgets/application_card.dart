import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const ApplicationCard({
    super.key,
    required this.application,
  });

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
        child: Row(
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(
                application['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Applicant Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Verification Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          application['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBeige,
                          ),
                        ),
                      ),
                      if (application['verified'])
                        const Icon(
                          Icons.verified,
                          color: AppColors.success,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // TM ID
                  Text(
                    application['tmid'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.softGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Call Statistics
                  Row(
                    children: [
                      Icon(
                        Icons.call,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${application['callCount']} calls',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkBeige,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        application['lastCallDuration'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkBeige,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location and Experience
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.softGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${application['city']}, ${application['state']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.softGray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.work_history,
                        size: 16,
                        color: AppColors.softGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        application['experience'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.softGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View Profile Button
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showProfileDialog(context, application);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),

                // Availability Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: application['availability'] == 'Available'
                        ? AppColors.success
                        : AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    application['availability'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(
      BuildContext context, Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  application['avatar'],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application['name'],
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      application['tmid'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.softGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileItem('Phone', application['phone']),
              _buildProfileItem('Location',
                  '${application['city']}, ${application['state']}'),
              _buildProfileItem('Experience', application['experience']),
              _buildProfileItem('Truck Type', application['truckType']),
              _buildProfileItem(
                  'Profile Completion', '${application['profileCompletion']}%'),
              _buildProfileItem(
                  'Applied Jobs', '${application['appliedJobs'].length}'),
              _buildProfileItem('Total Calls', '${application['callCount']}'),
              _buildProfileItem(
                  'Last Call Duration', application['lastCallDuration']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${application['name']}...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.darkBeige,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.softGray),
            ),
          ),
        ],
      ),
    );
  }
}
