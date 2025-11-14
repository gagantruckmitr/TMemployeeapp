import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/telecaller_status_service.dart';
import '../../../core/theme/app_theme.dart';

class LiveStatusWidget extends StatefulWidget {
  const LiveStatusWidget({super.key});

  @override
  State<LiveStatusWidget> createState() => _LiveStatusWidgetState();
}

class _LiveStatusWidgetState extends State<LiveStatusWidget> {
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _statuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadStatuses();
    });
  }

  Future<void> _loadStatuses() async {
    final statuses = await TelecallerStatusService.instance.getAllStatuses();
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'on_call':
        return Colors.blue;
      case 'break':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      case 'offline':
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Icons.check_circle;
      case 'on_call':
        return Icons.phone_in_talk;
      case 'break':
        return Icons.coffee;
      case 'inactive':
        return Icons.access_time;
      case 'offline':
      default:
        return Icons.circle_outlined;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final time = DateTime.parse(timestamp);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Telecallers Found',
              style: AppTheme.headingMedium.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with refresh button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.wifi_tethering, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Live Status',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-refresh 10s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadStatuses,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Now',
              ),
            ],
          ),
        ),

        // Status cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statuses.length,
            itemBuilder: (context, index) {
              final status = _statuses[index];
              final actualStatus = status['actual_status'] ?? 'offline';
              final statusColor = _getStatusColor(actualStatus);
              final statusIcon = _getStatusIcon(actualStatus);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (status['telecaller_name'] ?? 'T')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name and status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status['telecaller_name'] ?? 'Unknown',
                                  style: AppTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(statusIcon, size: 14, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      (actualStatus == 'active' ? 'ONLINE' : actualStatus.toUpperCase()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Live indicator
                          if (actualStatus == 'online' || actualStatus == 'on_call')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'ONLINE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Time info
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Login Time',
                                  _formatTime(status['login_time']),
                                  Icons.login,
                                  Colors.blue,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Online',
                                  _formatDuration(status['online_duration_seconds']),
                                  Icons.timer,
                                  Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Break',
                                  _formatDuration(status['total_break_seconds_today'] ?? status['total_break_duration']),
                                  Icons.coffee,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Call stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Total Calls',
                                  status['today_calls']?.toString() ?? '0',
                                  Icons.phone,
                                  Colors.purple,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Connected',
                                  status['connected_calls']?.toString() ?? '0',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Interested',
                                  status['interested_count']?.toString() ?? '0',
                                  Icons.star,
                                  Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          
                          // Current break indicator
                          if (actualStatus == 'break' && status['current_break_duration'] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.coffee, color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'On break for ${_formatDuration(status['current_break_duration'])}',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (status['current_break_type'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Type: ${status['current_break_type']}',
                                              style: TextStyle(
                                                color: Colors.orange.shade600,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // No break indicator
                          if (actualStatus != 'break' && actualStatus != 'offline' && 
                              (status['total_break_seconds_today'] == null || status['total_break_seconds_today'] == 0))
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No breaks taken today',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
