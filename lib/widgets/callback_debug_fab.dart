import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/callback_notification_service.dart';

/// Floating Action Button for debugging callback notifications
/// Add this temporarily to any screen to see notification status
class CallbackDebugFAB extends StatefulWidget {
  const CallbackDebugFAB({super.key});

  @override
  State<CallbackDebugFAB> createState() => _CallbackDebugFABState();
}

class _CallbackDebugFABState extends State<CallbackDebugFAB> {
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

  void _showDebugInfo() {
    final now = DateTime.now();
    final notifications = _service.activeNotifications;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Callback Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Time: ${DateFormat('hh:mm:ss a').format(now)}'),
              const SizedBox(height: 16),
              Text(
                'Active Notifications: ${notifications.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (notifications.isEmpty)
                const Text('No active notifications')
              else
                ...notifications.map((n) {
                  final diff = n.scheduledTime.difference(now);
                  final isWithin5Min =
                      diff.inSeconds > 0 && diff.inMinutes < 5;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWithin5Min
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isWithin5Min ? Colors.orange : Colors.grey,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.contactName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Phone: ${n.contactPhone}'),
                        Text(
                          'Scheduled: ${DateFormat('hh:mm a').format(n.scheduledTime)}',
                        ),
                        Text(
                          'Time diff: ${diff.inMinutes}m ${diff.inSeconds % 60}s',
                          style: TextStyle(
                            color: isWithin5Min ? Colors.orange : Colors.black,
                            fontWeight:
                                isWithin5Min ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isWithin5Min)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SHOULD BE VISIBLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _service.initialize();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed!')),
              );
            },
            child: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _service.activeNotifications;
    final now = DateTime.now();
    final within5Min = notifications.where((n) {
      final diff = n.scheduledTime.difference(now);
      return diff.inSeconds > 0 && diff.inMinutes < 5;
    }).length;

    return FloatingActionButton(
      onPressed: _showDebugInfo,
      backgroundColor: within5Min > 0 ? Colors.orange : Colors.blue,
      child: Stack(
        children: [
          const Center(child: Icon(Icons.bug_report)),
          if (notifications.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${notifications.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
