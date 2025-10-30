import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../core/config/api_config.dart';
import '../widgets/live_status_tab.dart';

class TeamTrackingScreen extends StatefulWidget {
  const TeamTrackingScreen({super.key});

  @override
  State<TeamTrackingScreen> createState() => _TeamTrackingScreenState();
}

class _TeamTrackingScreenState extends State<TeamTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> _statuses = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _todayBreaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
    // Refresh other tabs every 10 seconds (Live tab has its own 1-second refresh)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadLeaveRequests();
      _loadTodayBreaks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStatuses(),
      _loadLeaveRequests(),
      _loadTodayBreaks(),
    ]);
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
            _statuses = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading statuses: $e');
    }
  }

  Future<void> _loadLeaveRequests() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/enhanced_leave_management_api.php?action=get_pending_approvals',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _leaveRequests = List<Map<String, dynamic>>.from(
              data['data'] ?? [],
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading leave requests: $e');
    }
  }

  Future<void> _loadTodayBreaks() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/enhanced_leave_management_api.php?action=get_all_breaks_today',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _todayBreaks = List<Map<String, dynamic>>.from(data['data'] ?? []);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading breaks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Team Tracking',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Live Status'),
            Tab(text: 'Leave Requests'),
            Tab(text: 'Break History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveStatusTab(),
                _buildLeaveRequestsTab(),
                _buildBreakHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildLiveStatusTab() {
    return LiveStatusTab(
      statuses: _statuses,
      onRefresh: _loadStatuses,
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelecallerCard(Map<String, dynamic> status) {
    final statusType = status['current_status'] ?? 'offline';
    final isInactive =
        status['is_inactive'] == true || status['is_inactive'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(statusType).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (status['telecaller_name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(statusType),
                    ),
                  ),
                ),
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
                            color: _getStatusColor(
                              statusType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _getStatusColor(statusType),
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
          const SizedBox(height: 12),
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
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaveRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_leaveRequests.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No pending leave requests'),
              ),
            )
          else
            ..._leaveRequests.map((leave) => _buildLeaveCard(leave)),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leave['telecaller_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (leave['leave_type'] ?? '')
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '${leave['start_date']} to ${leave['end_date']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Text(
                '(${leave['total_days']} days)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            leave['reason'] ?? '',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveLeave(leave['id']),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectLeave(leave['id']),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_todayBreaks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No breaks today'),
              ),
            )
          else
            ..._todayBreaks.map((breakItem) => _buildBreakCard(breakItem)),
        ],
      ),
    );
  }

  Widget _buildBreakCard(Map<String, dynamic> breakItem) {
    final breakType = breakItem['break_type'] ?? 'personal_break';
    final isActive = breakItem['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _getBreakColor(breakType).withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getBreakColor(breakType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getBreakIcon(breakType),
              color: _getBreakColor(breakType),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breakItem['telecaller_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBreakLabel(breakType),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                breakItem['duration_formatted'] ?? '--:--:--',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? _getBreakColor(breakType)
                      : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? _getBreakColor(breakType).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'COMPLETED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _getBreakColor(breakType) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveLeave(int leaveId) async {
    // TODO: Implement approve leave API call
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Leave approved')));
    _loadAllData();
  }

  Future<void> _rejectLeave(int leaveId) async {
    // TODO: Implement reject leave API call
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Leave rejected')));
    _loadAllData();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'break':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getBreakColor(String breakType) {
    switch (breakType) {
      case 'tea_break':
        return const Color(0xFFFFA726);
      case 'lunch_break':
        return const Color(0xFF66BB6A);
      case 'prayer_break':
        return const Color(0xFF42A5F5);
      case 'personal_break':
        return const Color(0xFFAB47BC);
      default:
        return Colors.grey;
    }
  }

  IconData _getBreakIcon(String breakType) {
    switch (breakType) {
      case 'tea_break':
        return Icons.local_cafe_rounded;
      case 'lunch_break':
        return Icons.restaurant_rounded;
      case 'prayer_break':
        return Icons.mosque_rounded;
      case 'personal_break':
        return Icons.person_rounded;
      default:
        return Icons.pause_circle_rounded;
    }
  }

  String _getBreakLabel(String breakType) {
    switch (breakType) {
      case 'tea_break':
        return 'Tea Break';
      case 'lunch_break':
        return 'Lunch Break';
      case 'prayer_break':
        return 'Prayer Break';
      case 'personal_break':
        return 'Personal Break';
      default:
        return 'Break';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime == 'null') return '--:--';
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '--:--';
    }
  }
}
