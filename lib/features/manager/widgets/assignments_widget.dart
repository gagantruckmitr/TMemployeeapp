import 'package:flutter/material.dart';
import '../../../core/services/manager_service.dart';
import '../../../core/theme/app_theme.dart';

class AssignmentsWidget extends StatefulWidget {
  final int managerId;

  const AssignmentsWidget({
    super.key,
    required this.managerId,
  });

  @override
  State<AssignmentsWidget> createState() => _AssignmentsWidgetState();
}

class _AssignmentsWidgetState extends State<AssignmentsWidget> {
  final ManagerService _managerService = ManagerService();
  List<dynamic> _assignments = [];
  bool _isLoading = true;
  int? _selectedTelecaller;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);

    try {
      final data = await _managerService.getDriverAssignments(
        telecallerId: _selectedTelecaller,
      );
      if (mounted) {
        setState(() {
          _assignments = data['assignments'] as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assignments.isEmpty
                    ? _buildEmptyState()
                    : _buildAssignmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment, color: Colors.purple, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lead Assignments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Driver assignments to telecallers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final telecallerName = assignment['telecaller_name'] ?? 'Unknown';
    final driverName = assignment['driver_name'] ?? 'Unknown Driver';
    final driverMobile = assignment['driver_mobile'] ?? '';
    final driverState = assignment['driver_state'] ?? '';
    final driverCity = assignment['driver_city'] ?? '';
    final status = assignment['status'] ?? 'active';
    final priority = assignment['priority'] ?? 'medium';
    final totalCalls = assignment['total_calls'] ?? 0;
    final connectedCalls = assignment['connected_calls'] ?? 0;
    final interestedCalls = assignment['interested_calls'] ?? 0;

    Color priorityColor;
    switch (priority) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            priorityColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            telecallerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                driverMobile,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.location_city, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$driverCity, $driverState',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total Calls', totalCalls.toString(), Icons.phone_in_talk, Colors.blue),
                _buildStat('Connected', connectedCalls.toString(), Icons.check_circle, Colors.green),
                _buildStat('Interested', interestedCalls.toString(), Icons.star, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No assignments yet',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
