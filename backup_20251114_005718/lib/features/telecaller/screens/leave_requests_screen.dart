import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/leave_models.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/api_service.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) return;

      final response = await ApiService.getLeaveRequests(
        telecallerId: currentUser.id,
      );

      if (mounted) {
        setState(() {
          _leaveRequests = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leave requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<LeaveRequest> get _filteredRequests {
    if (_selectedFilter == 'all') {
      return _leaveRequests;
    }
    return _leaveRequests.where((req) => req.status == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterChips(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaveList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Leave Requests',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_leaveRequests.length} total requests',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadLeaveRequests,
            icon: const Icon(Icons.refresh),
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', _leaveRequests.length),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Pending',
              'pending',
              _leaveRequests.where((r) => r.status == 'pending').length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Approved',
              'approved',
              _leaveRequests.where((r) => r.status == 'approved').length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Rejected',
              'rejected',
              _leaveRequests.where((r) => r.status == 'rejected').length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      backgroundColor: AppTheme.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.gray,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.gray.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppTheme.gray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No leave requests found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.gray),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Apply for leave from your profile'
                : 'No $_selectedFilter requests',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.gray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList() {
    return RefreshIndicator(
      onRefresh: _loadLeaveRequests,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final request = _filteredRequests[index];
          return _buildLeaveCard(request);
        },
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequest request) {
    final statusColor = _getStatusColor(request.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${request.statusIcon} ${request.status.toUpperCase()}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy').format(request.createdAt),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leave Type
                Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.leaveType,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.calendar_today,
                        'From',
                        DateFormat('dd MMM').format(request.startDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.event,
                        'To',
                        DateFormat('dd MMM').format(request.endDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.access_time,
                        'Days',
                        '${request.totalDays}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Reason
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason:',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.reason,
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                
                // Manager Remarks (if any)
                if (request.managerRemarks != null && request.managerRemarks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.comment,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Manager Remarks:',
                              style: AppTheme.bodySmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.managerRemarks!,
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.gray),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
