import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/leave_models.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/api_service.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending';

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
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.getAllLeaveRequests(
        managerId: currentUser.id.toString(),
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

  Future<void> _handleLeaveAction(
    LeaveRequest request,
    String action,
  ) async {
    final remarksController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'approved' ? 'Approve' : 'Reject'} Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.telecallerName} - ${request.leaveType}',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('dd MMM').format(request.startDate)} - ${DateFormat('dd MMM').format(request.endDate)} (${request.totalDays} days)',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Add your comments...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved' ? AppTheme.success : AppTheme.error,
            ),
            child: Text(action == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final currentUser = RealAuthService.instance.currentUser;
        if (currentUser == null) return;

        final success = await ApiService.updateLeaveStatus(
          leaveId: request.id,
          status: action,
          managerId: currentUser.id,
          managerRemarks: remarksController.text.trim(),
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Leave request ${action}!'),
                backgroundColor: AppTheme.success,
              ),
            );
            _loadLeaveRequests();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update leave request'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
        decoration: BoxDecoration(
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
    final pendingCount = _leaveRequests.where((r) => r.status == 'pending').length;
    
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
                  'Leave Approvals',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$pendingCount pending requests',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.warning),
                ),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pendingCount',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
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
            _buildFilterChip(
              'Pending',
              'pending',
              _leaveRequests.where((r) => r.status == 'pending').length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip('All', 'all', _leaveRequests.length),
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
    return Center(
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
            Icons.check_circle_outline,
            size: 64,
            color: AppTheme.gray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No leave requests',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.gray),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'pending'
                ? 'All caught up!'
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
    final isPending = request.status == 'pending';
    
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    request.telecallerName[0].toUpperCase(),
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.telecallerName,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt),
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_available,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      request.leaveType,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Dates Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateInfo(
                        'From',
                        DateFormat('dd MMM yyyy').format(request.startDate),
                        Icons.calendar_today,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.gray.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildDateInfo(
                        'To',
                        DateFormat('dd MMM yyyy').format(request.endDate),
                        Icons.event,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.gray.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildDateInfo(
                        'Duration',
                        '${request.totalDays} days',
                        Icons.access_time,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
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
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 16,
                            color: AppTheme.gray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reason:',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.gray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                              'Your Remarks:',
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
                
                // Action Buttons (only for pending requests)
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleLeaveAction(request, 'rejected'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleLeaveAction(request, 'approved'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
