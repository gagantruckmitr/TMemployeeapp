import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/callback_notification_service.dart';
import '../core/theme/app_theme.dart';

class CallbackDebugScreen extends StatefulWidget {
  const CallbackDebugScreen({super.key});

  @override
  State<CallbackDebugScreen> createState() => _CallbackDebugScreenState();
}

class _CallbackDebugScreenState extends State<CallbackDebugScreen> {
  final CallbackNotificationService _service = CallbackNotificationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final notifications = _service.activeNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Callback Notifications Debug'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _service.initialize();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(
              'Current Time',
              DateFormat('MMM dd, yyyy hh:mm:ss a').format(now),
              Icons.access_time,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Total Notifications',
              '${notifications.length}',
              Icons.notifications,
              Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Active Notifications',
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              _buildEmptyState()
            else
              ...notifications.map((n) => _buildNotificationCard(n, now)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _service.initialize();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshed notifications')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Notifications',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule a callback to see it here',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(CallbackNotification notification, DateTime now) {
    final difference = notification.scheduledTime.difference(now);
    final isUpcoming = difference.inSeconds > 0;
    final isWithin5Min = isUpcoming && difference.inMinutes < 5;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isUpcoming) {
      statusColor = Colors.red;
      statusText = 'OVERDUE';
      statusIcon = Icons.warning;
    } else if (isWithin5Min) {
      statusColor = Colors.orange;
      statusText = 'ACTIVE (Within 5 min)';
      statusIcon = Icons.alarm;
    } else {
      statusColor = Colors.blue;
      statusText = 'SCHEDULED';
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.contactName,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      notification.contactPhone,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today,
            'Scheduled',
            DateFormat('MMM dd, yyyy hh:mm a')
                .format(notification.scheduledTime),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.timer,
            'Time Difference',
            isUpcoming
                ? '${difference.inMinutes}m ${difference.inSeconds % 60}s remaining'
                : '${difference.abs().inMinutes}m ${difference.abs().inSeconds % 60}s overdue',
          ),
          if (notification.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.notes,
              'Remarks',
              notification.remarks,
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.badge,
            'TMID',
            notification.contactTmid,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
