import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Match Found!',
      'message': 'Perfect match for Pune to Surat route',
      'time': '2 mins ago',
      'type': 'match',
      'read': false,
    },
    {
      'title': 'Call Reminder',
      'message': 'Follow up with Ramesh Kumar',
      'time': '15 mins ago',
      'type': 'reminder',
      'read': false,
    },
    {
      'title': 'Job Alert',
      'message': 'New job posted: Delhi to Jaipur',
      'time': '1 hour ago',
      'type': 'job',
      'read': true,
    },
    {
      'title': 'Match Success',
      'message': 'Driver accepted your proposal',
      'time': '2 hours ago',
      'type': 'success',
      'read': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification['read'] = true;
                }
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(_notifications[index], index);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    final isRead = notification['read'] as bool;
    final type = notification['type'] as String;
    
    Color iconColor;
    IconData icon;
    
    switch (type) {
      case 'match':
        iconColor = AppColors.success;
        icon = Icons.handshake;
        break;
      case 'reminder':
        iconColor = AppColors.warning;
        icon = Icons.alarm;
        break;
      case 'job':
        iconColor = AppColors.info;
        icon = Icons.work;
        break;
      case 'success':
        iconColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      default:
        iconColor = AppColors.primary;
        icon = Icons.notifications;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? AppColors.secondary.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            notification['title'],
            style: TextStyle(
              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification['message'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notification['time'],
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            setState(() {
              notification['read'] = true;
            });
          },
        ),
      ),
    );
  }
}
