import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../core/config/api_config.dart';

class LiveTelecallerStatusWidget extends StatefulWidget {
  const LiveTelecallerStatusWidget({super.key});

  @override
  State<LiveTelecallerStatusWidget> createState() =>
      _LiveTelecallerStatusWidgetState();
}

class _LiveTelecallerStatusWidgetState
    extends State<LiveTelecallerStatusWidget> {
  List<Map<String, dynamic>> _statuses = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadStatuses();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/live_status_api.php?action=get_all_status',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _statuses = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading statuses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildStatusGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    final online = _statuses.where((s) => s['current_status'] == 'online').length;
    final onBreak = _statuses.where((s) => s['current_status'] == 'break').length;
    final offline = _statuses.where((s) => s['current_status'] == 'offline').length;

    return Row(
      children: [
        _buildStatusBadge('Online', online, Colors.green),
        const SizedBox(width: 12),
        _buildStatusBadge('On Break', onBreak, Colors.orange),
        const SizedBox(width: 12),
        _buildStatusBadge('Offline', offline, Colors.grey),
      ],
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statuses.length,
      itemBuilder: (context, index) {
        return _buildStatusCard(_statuses[index]);
      },
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> status) {
    final statusType = status['current_status'] ?? 'offline';
    final isInactive = status['is_inactive'] == true || status['is_inactive'] == 1;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (statusType) {
      case 'online':
        statusColor = isInactive ? Colors.orange : Colors.green;
        statusIcon = isInactive ? Icons.warning_rounded : Icons.check_circle_rounded;
        break;
      case 'break':
        statusColor = Colors.orange;
        statusIcon = Icons.coffee_rounded;
        break;
      case 'on_call':
        statusColor = Colors.blue;
        statusIcon = Icons.phone_in_talk_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInactive ? Colors.orange.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
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
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
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
                            statusType.toUpperCase().replaceAll('_', ' '),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.login_rounded,
                  'Login',
                  _formatTime(status['login_time']),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.timer_rounded,
                  'Online',
                  status['online_duration'] ?? '00:00:00',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.coffee_rounded,
                  'Break',
                  status['total_break_duration'] ?? '00:00:00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.phone_rounded,
                  'Calls',
                  '${status['today_calls'] ?? 0}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.check_circle_rounded,
                  'Connected',
                  '${status['today_connected'] ?? 0}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time_rounded,
                  'Last Activity',
                  status['inactive_duration'] ?? '00:00:00',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '--:--';
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
