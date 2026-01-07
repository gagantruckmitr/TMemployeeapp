import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceDetailSkeleton extends StatelessWidget {
  const AttendanceDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attendance Details',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.textPrimary),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card Skeleton
            _buildSkeletonCard(height: 80),
            const SizedBox(height: 16),

            // Check In and Check Out Times
            Row(
              children: [
                Expanded(child: _buildSkeletonCard(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: _buildSkeletonCard(height: 100)),
              ],
            ),
            const SizedBox(height: 16),

            // Work Hours Skeleton
            _buildSkeletonCard(height: 70),
            const SizedBox(height: 16),

            // Shift ID Skeleton
            _buildSkeletonCard(height: 70),
            const SizedBox(height: 16),

            // Check In Address Skeleton
            _buildSkeletonText(width: 150, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonCard(height: 60),
            const SizedBox(height: 16),

            // Check Out Address Skeleton
            _buildSkeletonText(width: 150, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonCard(height: 60),
            const SizedBox(height: 16),

            // Selfie Skeleton
            _buildSkeletonText(width: 120, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonCard(height: 250),
            const SizedBox(height: 16),

            // Remark Skeleton
            _buildSkeletonText(width: 100, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonCard(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildShimmer(),
    );
  }

  Widget _buildSkeletonText({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildShimmer(),
    );
  }

  Widget _buildShimmer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
