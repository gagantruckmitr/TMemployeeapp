import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/smart_calling_service.dart';

class DriverFullDetailPage extends StatefulWidget {
  final String driverId;
  final String? driverName;

  const DriverFullDetailPage({
    super.key,
    required this.driverId,
    this.driverName,
  });

  @override
  State<DriverFullDetailPage> createState() => _DriverFullDetailPageState();
}

class _DriverFullDetailPageState extends State<DriverFullDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProfileCompletion? _profileData;
  List<CallHistoryEntry> _callHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDriverData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    setState(() => _isLoading = true);

    try {
      // Load profile and call history in parallel
      final results = await Future.wait([
        ApiService.getProfileCompletionDetails(widget.driverId),
        SmartCallingService.instance.getCallHistory(
          status: null, // Get all statuses for this driver
        ),
      ]);

      if (mounted) {
        setState(() {
          _profileData = results[0] as ProfileCompletion?;
          final historyData = results[1] as List<dynamic>;
          // Filter call history for this specific driver
          _callHistory = historyData
              .where((item) => item['driver_id'].toString() == widget.driverId)
              .map((item) {
                return CallHistoryEntry(
                  id: item['id'].toString(),
                  driverId: item['driver_id'].toString(),
                  driverName: item['driver_name'] ?? 'Unknown',
                  phoneNumber: item['phone_number'] ?? '',
                  status: _parseCallStatus(item['status']),
                  callTime: DateTime.parse(item['call_time']),
                  duration: item['duration'] != null
                      ? int.tryParse(item['duration'].toString())
                      : null,
                  durationFormatted: item['duration_formatted'],
                  timeAgo: item['time_ago'],
                  feedback: item['feedback'],
                  remarks: item['remarks'],
                  recordingUrl: item['recording_url'],
                );
              })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  CallStatus _parseCallStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'connected':
        return CallStatus.connected;
      case 'callback':
        return CallStatus.callBack;
      case 'callback_later':
        return CallStatus.callBackLater;
      case 'not_reachable':
        return CallStatus.notReachable;
      case 'not_interested':
        return CallStatus.notInterested;
      case 'invalid':
        return CallStatus.invalid;
      default:
        return CallStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [_buildSliverAppBar(innerBoxIsScrolled)];
              },
              body: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildProfileTab(), _buildCallHistoryTab()],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    final percentage = _profileData?.percentage ?? 0;
    final progressColor = _getProgressColor(percentage);

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                progressColor.withValues(alpha: 0.1),
                progressColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar with progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: progressColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (widget.driverName ?? 'D')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.driverName ?? 'Driver',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        percentage >= 80
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: progressColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$percentage% Complete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.indigo,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.person_outline),
            text: 'Profile (${_getCompletedCount()}/${_getTotalCount()})',
          ),
          Tab(
            icon: const Icon(Icons.history),
            text: 'Calls (${_callHistory.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final documents = _getDriverDocuments();
    final completedDocs = documents.where((doc) => doc.isPresent).toList();
    final missingDocs = documents.where((doc) => !doc.isPresent).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (completedDocs.isNotEmpty) ...[
          _buildSectionHeader(
            'Completed Documents',
            completedDocs.length,
            Colors.green,
            Icons.check_circle,
          ),
          const SizedBox(height: 12),
          ...completedDocs.map((doc) => _buildDocumentCard(doc)),
        ],
        if (missingDocs.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Missing Documents',
            missingDocs.length,
            Colors.red,
            Icons.error_outline,
          ),
          const SizedBox(height: 12),
          ...missingDocs.map((doc) => _buildDocumentCard(doc)),
        ],
        const SizedBox(height: 16), // Bottom padding
      ],
    );
  }

  Widget _buildCallHistoryTab() {
    if (_callHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_disabled, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Call History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No calls have been made to this driver yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _callHistory.length,
      itemBuilder: (context, index) {
        return _buildCallHistoryCard(_callHistory[index]);
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentItem doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: doc.isPresent
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: doc.isPresent
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              doc.isPresent ? Icons.check_circle : Icons.cancel,
              color: doc.isPresent ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.value ?? 'Not provided',
                  style: TextStyle(
                    fontSize: 13,
                    color: doc.isPresent
                        ? Colors.grey.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryCard(CallHistoryEntry entry) {
    final statusColor = _getStatusColor(entry.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(entry.status),
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.timeAgo ?? _formatDateTime(entry.callTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.duration != null && entry.duration! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.durationFormatted ??
                              _formatDuration(entry.duration),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feedback
                if (entry.feedback != null && entry.feedback!.isNotEmpty) ...[
                  _buildInfoRow(
                    Icons.feedback_outlined,
                    'Feedback',
                    entry.feedback!,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                ],

                // Remarks
                if (entry.remarks != null && entry.remarks!.isNotEmpty) ...[
                  _buildInfoRow(
                    Icons.note_outlined,
                    'Remarks',
                    entry.remarks!,
                    Colors.amber,
                  ),
                  const SizedBox(height: 12),
                ],

                // Recording
                if (entry.recordingUrl != null &&
                    entry.recordingUrl!.isNotEmpty) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _playRecording(entry.recordingUrl!),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              color: Colors.purple.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Play Call Recording',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.purple.shade700,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF4CAF50);
    if (percentage >= 50) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Color _getStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return Colors.green;
      case CallStatus.callBack:
        return Colors.orange;
      case CallStatus.callBackLater:
        return Colors.blue;
      case CallStatus.notReachable:
        return Colors.red;
      case CallStatus.notInterested:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return Icons.check_circle;
      case CallStatus.callBack:
        return Icons.refresh;
      case CallStatus.callBackLater:
        return Icons.schedule;
      case CallStatus.notReachable:
        return Icons.phone_disabled;
      case CallStatus.notInterested:
        return Icons.cancel;
      default:
        return Icons.phone;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM dd, h:mm a').format(dateTime);
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playRecording(String url) {
    // TODO: Implement audio player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing recording: $url'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  int _getCompletedCount() {
    return _getDriverDocuments().where((doc) => doc.isPresent).length;
  }

  int _getTotalCount() {
    return _getDriverDocuments().length;
  }

  List<DocumentItem> _getDriverDocuments() {
    final docs = _profileData?.documentStatus ?? {};
    final values = _profileData?.documentValues ?? {};

    return [
      DocumentItem('Name', 'name', docs['name'] ?? false, values['name']),
      DocumentItem('Email', 'email', docs['email'] ?? false, values['email']),
      DocumentItem('City', 'city', docs['city'] ?? false, values['city']),
      DocumentItem('Gender', 'sex', docs['sex'] ?? false, values['sex']),
      DocumentItem(
        'Vehicle Type',
        'vehicle_type',
        docs['vehicle_type'] ?? false,
        values['vehicle_type'],
      ),
      DocumentItem(
        'Father Name',
        'father_name',
        docs['father_name'] ?? false,
        values['father_name'],
      ),
      DocumentItem(
        'Profile Photo',
        'images',
        docs['images'] ?? false,
        values['images'],
      ),
      DocumentItem(
        'Address',
        'address',
        docs['address'] ?? false,
        values['address'],
      ),
      DocumentItem('Date of Birth', 'dob', docs['dob'] ?? false, values['dob']),
      DocumentItem(
        'License Type',
        'type_of_license',
        docs['type_of_license'] ?? false,
        values['type_of_license'],
      ),
      DocumentItem(
        'Driving Experience',
        'driving_experience',
        docs['driving_experience'] ?? false,
        values['driving_experience'],
      ),
      DocumentItem(
        'Education',
        'highest_education',
        docs['highest_education'] ?? false,
        values['highest_education'],
      ),
      DocumentItem(
        'License Number',
        'license_number',
        docs['license_number'] ?? false,
        values['license_number'],
      ),
      DocumentItem(
        'License Expiry',
        'expiry_date_of_license',
        docs['expiry_date_of_license'] ?? false,
        values['expiry_date_of_license'],
      ),
      DocumentItem(
        'Expected Income',
        'expected_monthly_income',
        docs['expected_monthly_income'] ?? false,
        values['expected_monthly_income'],
      ),
      DocumentItem(
        'Current Income',
        'current_monthly_income',
        docs['current_monthly_income'] ?? false,
        values['current_monthly_income'],
      ),
      DocumentItem(
        'Marital Status',
        'marital_status',
        docs['marital_status'] ?? false,
        values['marital_status'],
      ),
      DocumentItem(
        'Preferred Location',
        'preferred_location',
        docs['preferred_location'] ?? false,
        values['preferred_location'],
      ),
      DocumentItem(
        'Aadhar Number',
        'aadhar_number',
        docs['aadhar_number'] ?? false,
        values['aadhar_number'],
      ),
      DocumentItem(
        'Aadhar Photo',
        'aadhar_photo',
        docs['aadhar_photo'] ?? false,
        values['aadhar_photo'],
      ),
      DocumentItem(
        'Driving License',
        'driving_license',
        docs['driving_license'] ?? false,
        values['driving_license'],
      ),
      DocumentItem(
        'Previous Employer',
        'previous_employer',
        docs['previous_employer'] ?? false,
        values['previous_employer'],
      ),
      DocumentItem(
        'Job Placement',
        'job_placement',
        docs['job_placement'] ?? false,
        values['job_placement'],
      ),
    ];
  }
}

class DocumentItem {
  final String displayName;
  final String fieldName;
  final bool isPresent;
  final String? value;

  DocumentItem(this.displayName, this.fieldName, this.isPresent, this.value);
}

class CallHistoryEntry {
  final String id;
  final String driverId;
  final String driverName;
  final String phoneNumber;
  final CallStatus status;
  final DateTime callTime;
  final int? duration;
  final String? durationFormatted;
  final String? timeAgo;
  final String? feedback;
  final String? remarks;
  final String? recordingUrl;

  CallHistoryEntry({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.phoneNumber,
    required this.status,
    required this.callTime,
    this.duration,
    this.durationFormatted,
    this.timeAgo,
    this.feedback,
    this.remarks,
    this.recordingUrl,
  });
}
