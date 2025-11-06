import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TransporterJobCard extends StatelessWidget {
  final Map<String, dynamic> transporter;
  final VoidCallback onCall;

  const TransporterJobCard({
    super.key,
    required this.transporter,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final job = transporter['jobs'][0];
    
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
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transporter['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transporter['tmid'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.softGray,
                      ),
                    ),
                  ],
                ),
              ),
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
          Divider(color: AppColors.softGray.withOpacity(0.3)),
          const SizedBox(height: 16),
          
          // Job Details
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.softGray),
              const SizedBox(width: 4),
              Text(
                '${job['from']} → ${job['to']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(Icons.local_shipping, job['truckType']),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(Icons.scale, job['load']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(Icons.currency_rupee, job['payRate']),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.people,
                  '${job['applicants']} Applied',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkGray,
                    side: BorderSide(color: AppColors.softGray),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.handshake, size: 18),
                  label: const Text('Auto-Match'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.softGray).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.softGray),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.softGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
