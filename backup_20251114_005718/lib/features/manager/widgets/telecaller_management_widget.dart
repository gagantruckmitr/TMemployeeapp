import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TelecallerManagementWidget extends StatefulWidget {
  final int managerId;
  
  const TelecallerManagementWidget({
    super.key,
    required this.managerId,
  });

  @override
  State<TelecallerManagementWidget> createState() => _TelecallerManagementWidgetState();
}

class _TelecallerManagementWidgetState extends State<TelecallerManagementWidget> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<dynamic> _telecallerStatus = [];
  List<dynamic> _leaveRequests = [];
  List<dynamic> _activeBreaks = [];
  Map<String, int> _statusSummary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadTelecallerStatus(),
        _loadLeaveRequests(),
        _loadActiveBreaks(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _loadTelecallerStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/simple_leave_management_api.php').replace(
        queryParameters: {'action': 'get_all_telecaller_status'},
      );
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _telecallerStatus = data['data'] ?? [];
            _statusSummary = Map<String, int>.from(data['summary'] ?? {});
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadLeaveRequests() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/simple_leave_management_api.php').replace(
        queryParameters: {
          'action': 'get_all_leave_requests',
          'status': 'all',
        },
      );
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _leaveRequests = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadActiveBreaks() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/simple_leave_management_api.php').replace(
        queryParameters: {'action': 'get_active_breaks'},
      );
      
      final response = await http.get(uri).timeout(ApiConfig.timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _activeBreaks = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatusSummary(),
        const SizedBox(height: 20),
        _buildTabBar(),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTelecallerStatusTab(),
                    _buildLeaveRequestsTab(),
                    _buildActiveBreaksTab(),
                  ],
                ),
        ),
      ],
    );
  }


  Widget _buildStatusSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Telecaller Status Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Online', _statusSummary['online'] ?? 0, const Color(0xFF4CAF50))),
              Expanded(child: _buildSummaryItem('On Call', _statusSummary['on_call'] ?? 0, const Color(0xFF2196F3))),
              Expanded(child: _buildSummaryItem('Break', _statusSummary['break'] ?? 0, const Color(0xFFFFC107))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('On Leave', _statusSummary['on_leave'] ?? 0, const Color(0xFFFF5722))),
              Expanded(child: _buildSummaryItem('Offline', _statusSummary['offline'] ?? 0, Colors.grey)),
              Expanded(child: _buildSummaryItem('Total', _statusSummary['total'] ?? 0, Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 8),
                const Text('Status'),
                if (_telecallerStatus.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _telecallerStatus.length.toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_available, size: 18),
                const SizedBox(width: 8),
                const Text('Leaves'),
                if (_leaveRequests.where((l) => l['status'] == 'pending').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _leaveRequests.where((l) => l['status'] == 'pending').length.toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pause_circle, size: 18),
                const SizedBox(width: 8),
                const Text('Breaks'),
                if (_activeBreaks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _activeBreaks.length.toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelecallerStatusTab() {
    if (_telecallerStatus.isEmpty) {
      return const Center(
        child: Text('No telecaller status data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTelecallerStatus,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _telecallerStatus.length,
        itemBuilder: (context, index) {
          final telecaller = _telecallerStatus[index];
          return _buildTelecallerStatusCard(telecaller);
        },
      ),
    );
  }

  Widget _buildTelecallerStatusCard(Map<String, dynamic> telecaller) {
    final status = telecaller['status'] ?? 'offline';
    final name = telecaller['name'] ?? 'Unknown';
    final lastUpdate = telecaller['last_update'] ?? '';
    final currentCallDuration = telecaller['current_call_duration'] ?? '';
    final breakDuration = telecaller['break_duration'] ?? '';

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'online':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.circle;
        break;
      case 'on_call':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.phone_in_talk;
        break;
      case 'break':
        statusColor = const Color(0xFFFFC107);
        statusIcon = Icons.pause_circle;
        break;
      case 'on_leave':
        statusColor = const Color(0xFFFF5722);
        statusIcon = Icons.event_busy;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lastUpdate.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Last update: $lastUpdate',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            if (currentCallDuration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Call duration: $currentCallDuration',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ],
              ),
            ],
            if (breakDuration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.pause, size: 14, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Break duration: $breakDuration',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestsTab() {
    if (_leaveRequests.isEmpty) {
      return const Center(
        child: Text('No leave requests'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaveRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaveRequests.length,
        itemBuilder: (context, index) {
          final leave = _leaveRequests[index];
          return _buildLeaveRequestCard(leave);
        },
      ),
    );
  }

  Widget _buildLeaveRequestCard(Map<String, dynamic> leave) {
    final name = leave['telecaller_name'] ?? 'Unknown';
    final leaveType = leave['leave_type'] ?? '';
    final startDate = leave['start_date'] ?? '';
    final endDate = leave['end_date'] ?? '';
    final reason = leave['reason'] ?? '';
    final status = leave['status'] ?? 'pending';
    final leaveId = leave['id'];

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'rejected':
        statusColor = const Color(0xFFFF5722);
        break;
      default:
        statusColor = const Color(0xFFFFC107);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leaveType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$startDate to $endDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: $reason',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleLeaveAction(leaveId, 'reject'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleLeaveAction(leaveId, 'approve'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBreaksTab() {
    if (_activeBreaks.isEmpty) {
      return const Center(
        child: Text('No active breaks'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveBreaks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeBreaks.length,
        itemBuilder: (context, index) {
          final breakData = _activeBreaks[index];
          return _buildActiveBreakCard(breakData);
        },
      ),
    );
  }

  Widget _buildActiveBreakCard(Map<String, dynamic> breakData) {
    final name = breakData['telecaller_name'] ?? 'Unknown';
    final breakType = breakData['break_type'] ?? '';
    final startTime = breakData['start_time'] ?? '';
    final duration = breakData['duration'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pause_circle, color: Color(0xFFFFC107), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    breakType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Started: $startTime',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Duration: $duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLeaveAction(int leaveId, String action) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/simple_leave_management_api.php?action=${action}_leave');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'leave_id': leaveId,
          'approved_by': widget.managerId,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Leave request ${action}d successfully'),
                backgroundColor: action == 'approve' 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFFF5722),
              ),
            );
          }
          await _loadLeaveRequests();
        } else {
          throw Exception(data['error'] ?? 'Failed to $action leave request');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
    }
