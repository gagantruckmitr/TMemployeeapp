import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/manager_models.dart';
import '../../../core/theme/app_theme.dart';

class RealTimeMonitor extends StatefulWidget {
  final Map<String, dynamic> realTimeStatus;
  final VoidCallback onRefresh;

  const RealTimeMonitor({
    Key? key,
    required this.realTimeStatus,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<RealTimeMonitor> createState() => _RealTimeMonitorState();
}

class _RealTimeMonitorState extends State<RealTimeMonitor> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        widget.onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statuses = (widget.realTimeStatus['statuses'] as List?)
        ?.map((e) => RealTimeStatus.fromJson(e))
        .toList() ?? [];
    final counts = widget.realTimeStatus['counts'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSummary(counts),
            const SizedBox(height: 20),
            _buildLiveIndicator(),
            const SizedBox(height: 16),
            ...statuses.map((status) => _buildStatusCard(status)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary(Map<String, dynamic> counts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCountBadge('Online', counts['online'] ?? 0, Colors.green),
          _buildCountBadge('On Call', counts['on_call'] ?? 0, Colors.blue),
          _buildCountBadge('Break', counts['break'] ?? 0, Colors.orange),
          _buildCountBadge('Offline', counts['offline'] ?? 0, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'LIVE MONITORING',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          'Auto-refresh: 10s',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(RealTimeStatus status) {
    final isOnCall = status.currentStatus == TelecallerStatus.onCall;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnCall ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: isOnCall ? 2 : 1,
        ),
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
              _buildStatusAvatar(status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status.mobile,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(status.currentStatus),
            ],
          ),
          if (isOnCall && status.currentCallDriver != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calling: ${status.currentCallDriver}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          status.currentCallMobile ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status.currentCallStart != null)
                    Text(
                      _getCallDuration(status.currentCallStart!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (status.lastActivity != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last activity: ${_formatTime(status.lastActivity!)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusAvatar(RealTimeStatus status) {
    Color color;
    switch (status.currentStatus) {
      case TelecallerStatus.online:
        color = Colors.green;
        break;
      case TelecallerStatus.onCall:
        color = Colors.blue;
        break;
      case TelecallerStatus.break_:
        color = Colors.orange;
        break;
      case TelecallerStatus.busy:
        color = Colors.amber;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          status.name[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(TelecallerStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case TelecallerStatus.online:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TelecallerStatus.onCall:
        color = Colors.blue;
        icon = Icons.phone_in_talk;
        break;
      case TelecallerStatus.break_:
        color = Colors.orange;
        icon = Icons.coffee;
        break;
      case TelecallerStatus.busy:
        color = Colors.amber;
        icon = Icons.work;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getCallDuration(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
