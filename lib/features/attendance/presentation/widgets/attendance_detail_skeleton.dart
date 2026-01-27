import 'package:flutter/material.dart';

/// Skeleton loading widget for attendance history list
class AttendanceHistorySkeleton extends StatelessWidget {
  const AttendanceHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(width: 150, height: 16),
                  _buildShimmerBox(width: 70, height: 24, borderRadius: 8),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimeCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimeCard()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildShimmerBox(width: 16, height: 16),
                  const SizedBox(width: 6),
                  _buildShimmerBox(width: 120, height: 13),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 20, height: 20),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 60, height: 11),
            ],
          ),
          const SizedBox(height: 8),
          _buildShimmerBox(width: 80, height: 14),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
