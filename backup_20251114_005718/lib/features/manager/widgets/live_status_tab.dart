import 'package:flutter/material.dart';
import 'dart:async';

class LiveStatusTab extends StatefulWidget {
  final List<Map<String, dynamic>> statuses;
  final VoidCallback onRefresh;

  const LiveStatusTab({
    super.key,
    required this.statuses,
    required this.onRefresh,
  });

  @override
  State<LiveStatusTab> createState() => _LiveStatusTabState();
}

class _LiveStatusTabState extends State<LiveStatusTab> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every second
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        widget.onRefresh();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.statuses.where((s) => (s['display_status'] ?? s['current_status']) == 'online' && (s['is_inactive'] != true && s['is_inactive'] != 1)).length;
    final onBreak = widget.statuses.where((s) => (s['display_status'] ?? s['current_status']) == 'break').length;
    final offline = widget.statuses.where((s) => (s['display_status'] ?? s['current_status']) == 'offline').length;

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(online, onBreak, offline),
          const SizedBox(height: 20),
          ...widget.statuses.map((status) => _buildStatusCard(status)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int online, int onBreak, int offline) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Online',
            online.toString(),
            Colors.green,
            Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'On Break',
            onBreak.toString(),
            Colors.orange,
            Icons.coffee_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Offline',
            offline.toString(),
            Colors.grey,
            Icons.circle_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> status) {
    // Use display_status if available, otherwise fall back to current_status
    final statusType = status['display_status'] ?? status['current_status'] ?? 'offline';
    final isInactive = status['is_inactive'] == true || status['is_inactive'] == 1;
    
    Color statusColor;
    Color borderColor;
    IconData statusIcon;
    
    switch (statusType) {
      case 'online':
        if (isInactive) {
          statusColor = Colors.orange;
          borderColor = Colors.orange.withValues(alpha: 0.3);
          statusIcon = Icons.warning_rounded;
        } else {
          statusColor = Colors.green;
          borderColor = Colors.green.withValues(alpha: 0.5);
          statusIcon = Icons.check_circle_rounded;
        }
        break;
      case 'break':
        statusColor = Colors.orange;
        borderColor = Colors.orange.withValues(alpha: 0.3);
        statusIcon = Icons.coffee_rounded;
        break;
      default:
        statusColor = Colors.grey;
        borderColor = Colors.grey.withValues(alpha: 0.1);
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: statusType == 'online' && !isInactive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status['telecaller_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (isInactive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoGrid(status),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Map<String, dynamic> status) {
    return IntrinsicHeight(
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoItem(
                Icons.login_rounded,
                'Login',
                _formatTime(status['login_time']),
              ),
              const SizedBox(width: 4),
              _buildInfoItem(
                Icons.timer_rounded,
                'Online',
                _formatDuration(status['online_duration_seconds']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem(
                Icons.coffee_rounded,
                'Break',
                _formatDuration(status['total_break_seconds_today']),
              ),
              const SizedBox(width: 4),
              _buildInfoItem(
                Icons.access_time_rounded,
                'Activity',
                _formatDuration(status['inactive_seconds']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem(
                Icons.phone_rounded,
                'Calls',
                '${status['today_calls'] ?? 0}',
              ),
              const SizedBox(width: 4),
              _buildInfoItem(
                Icons.check_circle_rounded,
                'Connected',
                '${status['today_connected'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null) return '00:00:00';
    try {
      final int sec = seconds is int ? seconds : int.tryParse(seconds.toString()) ?? 0;
      final hours = sec ~/ 3600;
      final minutes = (sec % 3600) ~/ 60;
      final secs = sec % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } catch (e) {
      return '00:00:00';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime == 'null') return '--:--';
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '--:--';
    }
  }
}
