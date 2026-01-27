import '../../../core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:convert';
import '../../app/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/driver_applicant_model.dart';
import '../../widgets/profile_completion_avatar.dart';
import '../calls/widgets/call_feedback_modal.dart';
import '../telecaller/widgets/call_type_selection_dialog.dart';
import '../telecaller/widgets/easygo_ivr_call_helper.dart';
import '../jobs/driver_detailed_info_screen.dart';
import '../../widgets/error_handler.dart';

class DriverBucketScreen extends StatefulWidget {
  const DriverBucketScreen({super.key});

  @override
  State<DriverBucketScreen> createState() => _DriverBucketScreenState();
}

class _DriverBucketScreenState extends State<DriverBucketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<DriverApplicant> _drivers = [];
  List<DriverApplicant> _filteredDrivers = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDrivers = _drivers;
      } else {
        _filteredDrivers = _drivers.where((driver) {
          return driver.name.toLowerCase().contains(query) ||
              driver.driverTmid.toLowerCase().contains(query) ||
              driver.city.toLowerCase().contains(query) ||
              driver.state.toLowerCase().contains(query) ||
              driver.vehicleType.toLowerCase().contains(query) ||
              driver.mobile.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final drivers = await Phase2ApiService.fetchDriverBuckets();
      setState(() {
        _drivers = drivers;
        _filteredDrivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initiateCall(DriverApplicant driver) async {
    if (driver.mobile.isEmpty) return;

    try {
      final callType = await showDialog<String>(
        context: context,
        builder: (context) => CallTypeSelectionDialog(driverName: driver.name),
      );

      if (callType == null) return;

      final callerId = await Phase2AuthService.getUserId();

      if (callType == 'manual') {
        await _handleManualCall(driver, callerId);
      } else if (callType == 'easygo_ivr') {
        await _handleIVRCall(driver, callerId);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _handleIVRCall(DriverApplicant driver, int callerId) async {
    // We need job details to make a proper Job Matching IVR call
    // The bucket driver has a jobId. We should fetch the job to get transporter details.

    // Show loading while preparing call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing call...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 1. Fetch Job Details if jobId matches
      // Since fetching all jobs might be heavy, we'll try to get job details.
      // However Phase2ApiService.fetchJobs() is the available method.
      // We can optimize this later if needed or add a specific getJob endpoint.
      // For now, let's try to fetch jobs and find the matching one.
      final jobs = await Phase2ApiService.fetchJobs();
      final job = jobs.firstWhere(
        (j) =>
            j.jobId == 'TMJB${driver.jobId.toString().padLeft(5, '0')}' ||
            j.jobId == driver.jobId.toString() ||
            j.jobId.endsWith(driver.jobId.toString()),
        orElse: () => jobs
            .first, // Fallback is risky, but better than crash. Ideally handle "not found".
      );

      // Check if we actually found the correct job
      bool jobFound = job.jobId.contains(driver.jobId.toString());

      if (!jobFound) {
        // Fallback to generic IVR if job details specific to this driver are not found
        // But user asked for "same how i call to job applicants" which implies job context.
        // If we can't find job, we might just proceed with generic IVR or warn user.
        print(
          "Warning: Job ID ${driver.jobId} not found in fetched jobs list.",
        );
      }

      final transporterTmid = job.transporterTmid;
      final transporterName = job.transporterName;
      final transporterUserId = int.tryParse(job.transporterId);
      final assignedTo = job.assignedTo ?? callerId;

      await EasyGoIVRCallHelper.initiateCall(
        context: context,
        clientName: driver.name,
        clientPhone: driver.mobile,
        clientId: driver.driverId.toString(),
        tmid: driver.driverTmid,
        contactType: 'driver',
        callSource: 'job_applicants', // Use same source to trigger match logic
        transporterTmid: transporterTmid,
        transporterName: transporterName,
        transporterUserId: transporterUserId,
        driverUserId: driver.driverId,
        jobId:
            'TMJB${driver.jobId.toString().padLeft(5, '0')}', // Ensure TMJB format if needed
        assignedTo: assignedTo,
        onCallCompleted: (matchId) =>
            _showCallFeedbackModalWithMatchId(driver, matchId),
      );
    } catch (e) {
      print('Error preparing IVR call: $e');
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _handleManualCall(DriverApplicant driver, int callerId) async {
    try {
      // First, fetch job details to get transporter info (same as IVR call)
      final jobs = await Phase2ApiService.fetchJobs();
      final job = jobs.firstWhere(
        (j) =>
            j.jobId == 'TMJB${driver.jobId.toString().padLeft(5, '0')}' ||
            j.jobId == driver.jobId.toString() ||
            j.jobId.endsWith(driver.jobId.toString()),
        orElse: () => jobs.first,
      );

      final transporterTmid = job.transporterTmid;
      final transporterName = job.transporterName;
      final transporterUserId = int.tryParse(job.transporterId) ?? 0;
      final assignedTo = job.assignedTo ?? callerId;
      final jobIdFormatted = 'TMJB${driver.jobId.toString().padLeft(5, '0')}';

      // Initiate call via Laravel API to get matchId
      final cleanMobile = driver.mobile.replaceAll(RegExp(r'[^\d]'), '');

      print('🔵 Initiating manual call via Laravel API');
      final result = await Phase2ApiService.initiateIVRCallJobMatching(
        uniqueIdTransporter: transporterTmid,
        uniqueIdDriver: driver.driverTmid,
        userIdTransporter: transporterUserId,
        userIdDriver: driver.driverId,
        assignedTo: assignedTo,
        jobId: jobIdFormatted,
        transporterName: transporterName,
        driverName: driver.name,
        exten: '1001', // Default extension for manual calls
        number: cleanMobile,
      );

      // Extract matchId from response
      String? matchId;
      if (result['data'] != null && result['data']['id'] != null) {
        matchId = result['data']['id'].toString();
      } else if (result['id'] != null) {
        matchId = result['id'].toString();
      }

      print('🔵 Manual call initiated, matchId: $matchId');

      // Make the actual phone call
      await FlutterPhoneDirectCaller.callNumber(cleanMobile);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (matchId != null && matchId.isNotEmpty) {
          _showCallFeedbackModalWithMatchId(driver, matchId);
        } else {
          print('⚠️ No matchId returned from API');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call initiated but feedback tracking unavailable'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in manual call: $e');
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _submitFeedbackWithMatchId(
    DriverApplicant driver,
    String feedback,
    String? matchStatus,
    String? notes,
    String matchId,
  ) async {
    try {
      // Parse the feedback to extract call_status and call_feedback
      // Format: "Connected: Driver Interested" or "Not Connected: Ringing – No Answer"
      String callStatus = 'connected';
      String callFeedback = feedback;

      if (feedback.contains(':')) {
        final parts = feedback.split(':');
        final statusPart = parts[0].trim().toLowerCase();
        callFeedback = parts.length > 1 ? parts[1].trim() : feedback;

        if (statusPart == 'connected') {
          callStatus = 'connected';
        } else if (statusPart == 'not connected') {
          callStatus = 'not_connected';
        } else if (statusPart == 'call back later') {
          callStatus = 'callback_later';
        }
      }

      print('🔵 Submitting bucket feedback with matchId: $matchId');
      print('🔵 Call Status: $callStatus');
      print('🔵 Call Feedback: $callFeedback');
      print('🔵 Match Status: $matchStatus');
      print('🔵 Notes: $notes');

      await Phase2ApiService.updateIVRCallJobMatchingFeedback(
        matchId: matchId,
        callStatus: callStatus,
        callFeedback: callFeedback,
        callRemarks: notes,
        matchStatus: matchStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list to show updated feedback
        _loadDrivers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCallFeedbackModalWithMatchId(
    DriverApplicant driver,
    String? matchId,
  ) {
    if (matchId == null || matchId.isEmpty) {
      print('⚠️ No matchId provided, cannot submit feedback');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No call record found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: 'driver',
        userName: driver.name,
        userTmid: driver.driverTmid,
        jobId: driver.jobIdString.isNotEmpty
            ? driver.jobIdString
            : driver.jobId.toString(),
        onSubmit: (feedback, matchStatus, notes) async {
          await _submitFeedbackWithMatchId(
            driver,
            feedback,
            matchStatus,
            notes,
            matchId,
          );
        },
      ),
    );
  }

  String? _getProfileImageUrl(String imagePath) {
    if (imagePath.isEmpty || imagePath.toLowerCase() == 'null') return null;
    try {
      final decoded = json.decode(imagePath);
      if (decoded is List && decoded.isNotEmpty) {
        imagePath = decoded[0].toString();
      }
    } catch (e) {
      // Not JSON
    }
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('/')) imagePath = imagePath.substring(1);
      return '${ApiConfig.publicUrl}/$imagePath';
    }
    return null;
  }

  // Visual Helpers
  Color _getMatchStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.white;
    switch (status.toLowerCase()) {
      case 'selected':
        return const Color(0xFFE8F5E9); // Light green
      case 'not selected':
      case 'not_selected':
        return const Color(0xFFFFEBEE); // Light red
      case 'pending':
        return const Color(0xFFFFF8E1); // Light amber
      default:
        return Colors.white;
    }
  }

  Color _getMatchStatusBorderColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey.shade200;
    switch (status.toLowerCase()) {
      case 'selected':
        return Colors.green.shade400;
      case 'not selected':
      case 'not_selected':
        return Colors.red.shade400;
      case 'pending':
        return Colors.amber.shade400;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getFeedbackColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.white;
    final lower = feedback.toLowerCase();
    if (lower.contains('interested') && !lower.contains('not interested')) {
      return const Color(0xFFE8F5E9);
    } else if (lower.contains('not interested') ||
        lower.contains('not reachable') ||
        lower.contains('switched off')) {
      return const Color(0xFFFFEBEE);
    } else if (lower.contains('callback') ||
        lower.contains('call back') ||
        lower.contains('busy')) {
      return const Color(0xFFFFF8E1);
    }
    return Colors.white;
  }

  Color _getFeedbackBorderColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.grey.shade200;
    final lower = feedback.toLowerCase();
    if (lower.contains('interested') && !lower.contains('not interested')) {
      return Colors.green.shade400;
    } else if (lower.contains('not interested') ||
        lower.contains('not reachable') ||
        lower.contains('switched off')) {
      return Colors.red.shade400;
    } else if (lower.contains('callback') ||
        lower.contains('call back') ||
        lower.contains('busy')) {
      return Colors.amber.shade400;
    }
    return Colors.grey.shade200;
  }

  String _formatCallStatus(String? status) {
    if (status == null || status.isEmpty) return 'N/A';
    switch (status.toLowerCase()) {
      case 'connected':
        return 'Connected';
      case 'not_connected':
        return 'Not Connected';
      case 'callback_later':
        return 'Callback Later';
      default:
        return status;
    }
  }

  String _formatMatchStatus(String? status) {
    if (status == null || status.isEmpty) return 'Pending';
    switch (status.toLowerCase()) {
      case 'selected':
        return 'Selected';
      case 'not_selected':
      case 'not selected':
        return 'Not Selected';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  IconData _getCallStatusIcon(String? status) {
    if (status == null || status.isEmpty) return Icons.phone_outlined;
    switch (status.toLowerCase()) {
      case 'connected':
        return Icons.check_circle_outline;
      case 'not_connected':
        return Icons.phone_disabled_outlined;
      case 'callback_later':
        return Icons.schedule_outlined;
      default:
        return Icons.phone_outlined;
    }
  }

  Color _getCallStatusIconColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'connected':
        return Colors.green;
      case 'not_connected':
        return Colors.red;
      case 'callback_later':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMatchStatusIcon(String? status) {
    if (status == null || status.isEmpty) return Icons.pending_outlined;
    switch (status.toLowerCase()) {
      case 'selected':
        return Icons.check_circle;
      case 'not_selected':
      case 'not selected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending_outlined;
      default:
        return Icons.pending_outlined;
    }
  }

  Color _getMatchStatusIconColor(String? status) {
    if (status == null || status.isEmpty) return Colors.amber;
    switch (status.toLowerCase()) {
      case 'selected':
        return Colors.green;
      case 'not_selected':
      case 'not selected':
        return Colors.red;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1F3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Driver Bucket',
          style: TextStyle(
            color: Color(0xFF1A1F3A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Available'),
            Tab(text: 'Assigned'),
            Tab(text: 'Inactive'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search drivers by name, TMID...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDriverList('all'),
                _buildDriverList('available'),
                _buildDriverList('assigned'),
                _buildDriverList('inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverList(String filter) {
    // Filter logic can be improved based on actual status
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error'));
    }

    if (_filteredDrivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Since we don't have explicit status mapping from API for tabs yet,
    // we show same list for 'all' and maybe empty for others, or just show list.
    // Assuming 'all' shows all.
    List<DriverApplicant> displayList = _filteredDrivers;
    // if (filter != 'all') {
    //   // displayList = displayList.where((d) => d.status == filter).toList();
    // }

    if (displayList.isEmpty) {
      return const Center(child: Text("No drivers in this category"));
    }

    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayList.length,
        itemBuilder: (context, index) => _buildDriverCard(displayList[index]),
      ),
    );
  }

  Widget _buildDriverCard(DriverApplicant driver) {
    // Replicate logic for match/feedback status coloring
    final hasFeedback =
        driver.callFeedback != null && driver.callFeedback!.isNotEmpty;
    final hasMatchStatus =
        driver.matchStatus != null && driver.matchStatus!.isNotEmpty;

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    int borderWidth = 1;

    if (hasMatchStatus) {
      cardColor = _getMatchStatusColor(driver.matchStatus);
      borderColor = _getMatchStatusBorderColor(driver.matchStatus);
      borderWidth = 2;
    } else if (hasFeedback) {
      cardColor = _getFeedbackColor(driver.callFeedback);
      borderColor = _getFeedbackBorderColor(driver.callFeedback);
      borderWidth = 2;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth.toDouble()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name/Loc/TMID, Call/Bucket Icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final imageUrl =
                        driver.profileImage != null &&
                            driver.profileImage!.isNotEmpty
                        ? _getProfileImageUrl(driver.profileImage!)
                        : null;
                    return ProfileCompletionAvatar(
                      name: driver.name,
                      userId: driver.driverId,
                      userType: 'driver',
                      size: 60, // Slightly larger
                      completionPercentage: driver.profileCompletion,
                      profileImageUrl: imageUrl,
                      gender: driver.gender,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driver.city.isNotEmpty && driver.state.isNotEmpty
                            ? '${driver.city}, ${driver.state}'
                            : driver.city.isNotEmpty
                            ? driver.city
                            : driver.state,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: driver.driverTmid.isNotEmpty
                            ? () {
                                Clipboard.setData(
                                  ClipboardData(text: driver.driverTmid),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('TMID copied to clipboard'),
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              driver.driverTmid.isNotEmpty
                                  ? driver.driverTmid
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (driver.driverTmid.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions - Only Call button (removed cart icon since already in bucket)
                Material(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _initiateCall(driver),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Job ID Badge
            if (driver.jobIdString.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      driver.jobIdString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Call Status & Feedback Section
            if (driver.callStatus != null && driver.callStatus!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCallStatusIconColor(
                    driver.callStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getCallStatusIconColor(
                      driver.callStatus,
                    ).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCallStatusIcon(driver.callStatus),
                          size: 16,
                          color: _getCallStatusIconColor(driver.callStatus),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Call: ${_formatCallStatus(driver.callStatus)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getCallStatusIconColor(driver.callStatus),
                          ),
                        ),
                      ],
                    ),
                    if (driver.callFeedback != null &&
                        driver.callFeedback!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Feedback: ${driver.callFeedback}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (driver.callRemarks != null &&
                        driver.callRemarks!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remarks: ${driver.callRemarks}',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Match Status Section
            if (driver.matchStatus != null &&
                driver.matchStatus!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getMatchStatusIconColor(
                    driver.matchStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getMatchStatusIconColor(
                      driver.matchStatus,
                    ).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMatchStatusIcon(driver.matchStatus),
                      size: 14,
                      color: _getMatchStatusIconColor(driver.matchStatus),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Match: ${_formatMatchStatus(driver.matchStatus)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getMatchStatusIconColor(driver.matchStatus),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            // Info Grid
            _buildDetailRow(
              'Vehicle:',
              driver.vehicleType.isNotEmpty ? driver.vehicleType : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Experience:',
              driver.drivingExperience.isNotEmpty
                  ? driver.drivingExperience
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'License:',
              driver.licenseType.isNotEmpty ? driver.licenseType : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Applied:',
              driver.appliedAt.isNotEmpty ? driver.appliedAt : 'N/A',
            ), // Need formatting?
            const SizedBox(height: 8),
            _buildDetailRow(
              'Time:',
              '',
            ), // Time separate? Or part of appliedAt. Leaving visual placeholder or parsing Logic
            // In image "5:50 PM". Assuming appliedAt has time. If null, show N/A.
            const SizedBox(height: 8),
            if (driver.matchMakerName != null &&
                driver.matchMakerName!.isNotEmpty) ...[
              _buildDetailRow('Added by:', driver.matchMakerName!),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Subscription:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                // Date logic could be complex, assuming subscription end date or valid till
                Text(
                  driver.subscriptionStartDate ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green, // Image shows green date
                  ),
                ),
                const Spacer(),
                if (driver.subscriptionAmount != null)
                  Text(
                    '₹${driver.subscriptionAmount}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom Action Buttons - Jobs and Reject only (removed Bucket since already in bucket)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    text: 'Jobs (${driver.totalJobsApplied})',
                    icon: Icons.work_outline,
                    color: Colors.blue.shade50,
                    textColor: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverDetailedInfoScreen(
                            driverId: driver.driverId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    text: 'Reject',
                    icon: Icons.cancel_outlined,
                    color: Colors.red.shade50,
                    textColor: Colors.red,
                    onTap: () {
                      // Reject logic
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
