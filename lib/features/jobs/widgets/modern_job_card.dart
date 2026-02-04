import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter/services.dart';

import '../../../core/config/api_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../../../models/job_model.dart';
import '../../../widgets/profile_completion_avatar.dart';
import '../job_applicants_screen.dart';
import 'job_brief_feedback_modal.dart';
import 'job_call_status_selection_modal.dart';
import '../../telecaller/widgets/call_type_selection_dialog.dart';
import '../../telecaller/widgets/easygo_ivr_call_helper.dart';
import '../../../core/services/manual_call_service.dart';
import '../../../core/services/phase2_api_service.dart';

class ModernJobCard extends StatefulWidget {
  final JobModel job;
  final bool isSearchResult;
  final int? currentUserId;

  const ModernJobCard({
    super.key,
    required this.job,
    this.isSearchResult = false,
    this.currentUserId,
  });

  @override
  State<ModernJobCard> createState() => _ModernJobCardState();
}

class _ModernJobCardState extends State<ModernJobCard> {
  int? _localUserId;

  bool get _isAssignedToMe {
    final userId = widget.currentUserId ?? _localUserId;

    // Debug prints
    print(
      'Card Check: Job=${widget.job.jobId}, AssignedTo=${widget.job.assignedTo}, CurrentUser=$userId',
    );

    if (userId == null || widget.job.assignedTo == null) {
      return false;
    }
    return widget.job.assignedTo.toString() == userId.toString();
  }

  @override
  void initState() {
    super.initState();
    if (widget.currentUserId == null) {
      _fetchUserLocally();
    }
  }

  Future<void> _fetchUserLocally() async {
    final user = await Phase2AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _localUserId = user.id;
      });
    }
  }

  String? _getProfileImageUrl(String? imagePath) {
    if (imagePath == null ||
        imagePath.isEmpty ||
        imagePath.toLowerCase() == 'null') {
      return null;
    }

    // If it's already a full URL
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // If it's a relative path, prepend the correct base URL
    String cleanPath = imagePath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    return '${ApiConfig.publicUrl}/$cleanPath';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty || phone.length < 4) return '••••••••••';
    return '${phone.substring(0, 2)}••••••${phone.substring(phone.length - 2)}';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date;
    }
  }

  String _getTimeAgoString() {
    if (widget.job.createdAt.isEmpty) return 'N/A';

    try {
      final createdDate = DateTime.parse(widget.job.createdAt);

      // Format time as HH:MM AM/PM
      final hour = createdDate.hour;
      final minute = createdDate.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final formattedMinute = minute.toString().padLeft(2, '0');

      return '$displayHour:$formattedMinute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;

    if (!_isAssignedToMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This job is assigned to ${widget.job.assignedToName ?? "another telecaller"}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // First show call type selection dialog
      final callType = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) =>
            CallTypeSelectionDialog(driverName: widget.job.transporterName),
      );

      if (callType == null) return;

      if (callType == 'manual') {
        await _handleManualCall(phone);
      } else if (callType == 'easygo_ivr') {
        // Get current user ID for assignedTo
        final currentUser = await Phase2AuthService.getCurrentUser();
        final currentUserId = currentUser?.id ?? 0;

        // Parse transporter ID - it should be numeric
        final transporterUserId = int.tryParse(widget.job.transporterId) ?? 0;

        await EasyGoIVRCallHelper.initiateCall(
          context: context,
          clientName: widget.job.transporterName,
          clientPhone: phone,
          clientId: transporterUserId.toString(),
          tmid: widget.job.transporterTmid,
          contactType: 'transporter',
          callSource: 'job_posting',
          onCallCompleted: (jobBriefId) {
            // After call ends, show call status selection modal
            _showCallStatusModalAfterCall(jobBriefId);
          },
          jobId: widget.job.jobId,
          assignedTo: currentUserId,
          jobBriefTransporterUserId: transporterUserId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleManualCall(String phone) async {
    final user = await Phase2AuthService.getCurrentUser();
    final callerId = user?.id ?? 0;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    print('🔵 Initiating Manual Job Brief Call...');

    // Use the new service method
    final result = await ManualCallService.initiateJobBriefCall(
      uniqueId: widget.job.transporterTmid,
      userId: callerId.toString(),
      assignedTo: (widget.job.assignedTo ?? 0).toString(),
      jobId: widget.job.jobId,
      exten: user?.mobile ?? '',
      number: cleanPhone,
    );

    if (result['success'] == true) {
      // Extract the ID from the response (can be in 'id' or 'data.id' or 'data.match_id' or 'data.job_brief_id')
      final dynamic rawId =
          result['id'] ??
          result['data']?['id'] ??
          result['data']?['match_id'] ??
          result['data']?['job_brief_id'];
      final callId = rawId?.toString();

      print('✅ Call initiated. ID: $callId');

      await FlutterPhoneDirectCaller.callNumber(cleanPhone);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _showCallStatusModalAfterCall(callId, isManualCall: true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to initiate call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show call status selection modal after call ends
  Future<void> _showCallStatusModalAfterCall(
    String? jobBriefId, {
    bool isManualCall = false,
  }) async {
    if (!mounted) return;

    print(
      '🔵 _showCallStatusModalAfterCall called with jobBriefId: $jobBriefId, isManualCall: $isManualCall',
    );

    // Show modal and get result via callback
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => PopScope(
        canPop: false,
        child: JobCallStatusSelectionModal(
          transporterName: widget.job.transporterName,
          onStatusSelected:
              (
                String status,
                String? feedback,
                String? remarks,
                bool shouldCloseJob,
                File? recordingFile,
              ) async {
                print(
                  '🔵 onStatusSelected: status=$status, feedback=$feedback, remarks=$remarks, closeJob=$shouldCloseJob',
                );

                // Close the modal first
                Navigator.of(modalContext).pop();

                // Small delay to ensure modal animation completes
                await Future.delayed(const Duration(milliseconds: 100));

                if (!mounted) return;

                // Handle the selection based on feedback type
                if (status == 'Connected' &&
                    feedback == 'Transporter Confirmed Job Details') {
                  print('🔵 Opening Job Brief modal');
                  // Open Job Brief modal
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      showJobBriefFeedbackModal(
                        context: context,
                        job: widget.job,
                        jobBriefId: jobBriefId,
                        hideCallStatusFields: true,
                        preSelectedCallStatus: 'connected',
                        preSelectedCallFeedback:
                            'Transporter Confirmed Job Details',
                        preSelectedRemarks: remarks,
                        isManualCall: isManualCall,
                        onSubmit: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Job brief feedback saved successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    }
                  });
                } else {
                  // For other feedbacks, update via API
                  print('🔵 Submitting feedback via API: $status - $feedback');
                  await _updateJobBriefCallStatus(
                    jobBriefId: jobBriefId,
                    status: status,
                    feedback: feedback!,
                    remarks: remarks,
                    closeJob: shouldCloseJob,
                    isManualCall: isManualCall,
                    recordingFile: recordingFile,
                  );
                }
              },
        ),
      ),
    );
  }

  Future<void> _updateJobBriefCallStatus({
    String? jobBriefId,
    required String status,
    required String feedback,
    String? remarks,
    bool closeJob = false,
    bool isManualCall = false,
    File? recordingFile,
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        print('✗ No user found');
        return;
      }

      // Map status to API format (for both IVR and Manual)
      String apiCallStatus;
      if (status == 'Connected') {
        apiCallStatus = 'connected';
      } else if (status == 'Not Connected') {
        apiCallStatus = 'not_connected';
      } else if (status == 'Call Back Later') {
        apiCallStatus = 'callback_later';
      } else {
        apiCallStatus = status.toLowerCase().replaceAll(' ', '_');
      }

      // If NOT manual call (i.e. IVR call), use the Phase2ApiService
      if (!isManualCall) {
        // Legacy/IVR flow
        await Phase2ApiService.updateIVRCallJobBriefFeedback(
          jobBriefId: jobBriefId ?? '',
          name: widget.job.transporterName,
          jobLocation: widget.job.jobLocation,
          route: widget.job.jobLocation,
          vehicleType: widget.job.vehicleType,
          licenseType: widget.job.typeOfLicense,
          experience: widget.job.requiredExperience,
          salaryFixed: widget.job.salaryRange,
          salaryVariable: '0',
          esiPf: 'no',
          foodAllowance: '0', // API expects string usually for this endpoint?
          tripIncentive: '0',
          rehneKiSuvidha: 'no',
          mileage: 'N/A',
          fastTagRoadKharcha: '0',
          closedJob: closeJob ? '1' : '0',
          callStatus: apiCallStatus,
          callFeedback: feedback,
          callRemarks: remarks,
          requiredDrivers: widget.job.numberOfDriverRequired.toString(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                closeJob
                    ? 'Job closed successfully'
                    : 'Feedback saved successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Manual Call Flow (New)
      int callId = 0;
      if (jobBriefId != null) {
        callId = int.tryParse(jobBriefId) ?? 0;
      }

      final result = await ManualCallService.updateJobBriefCall(
        id: callId,
        name: widget.job.transporterName,
        jobLocation: widget.job.jobLocation,
        route: widget.job.jobLocation,
        vehicleType: widget.job.vehicleType,
        licenseType: widget.job.typeOfLicense,
        experience: widget.job.requiredExperience,
        salaryFixed: widget.job.salaryRange,
        salaryVariable: '0',
        esiPf: 'no',
        foodAllowance: 0,
        tripIncentive: 0,
        rehneKiSuvidha: 'no',
        mileage: 'N/A',
        fastTagRoadKharcha: 0,
        closedJob: closeJob ? 1 : 0,
        callStatus: apiCallStatus,
        callFeedback: feedback,
        callRemarks: remarks,
        requiredDrivers: widget.job.numberOfDriverRequired.toString(),
        callRecording: recordingFile,
      );

      if (mounted) {
        if (result['success'] == true || result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                closeJob
                    ? 'Job closed successfully'
                    : 'Feedback saved successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save feedback: ${result['error'] ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('✗ Error updating call status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.job.isClosed
            ? Colors.grey.shade50
            : (widget.job.isExpiredByDeadline
                  ? const Color(0xFFFEF2F2)
                  : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.job.isClosed
              ? Colors.grey.shade300
              : (widget.job.isExpiredByDeadline
                    ? const Color(0xFFEF4444)
                    : Colors.grey.shade200),
          width: (widget.job.isExpiredByDeadline || widget.job.isClosed)
              ? 2
              : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.job.isClosed
                ? Colors.black.withValues(alpha: 0.05)
                : (widget.job.isExpiredByDeadline
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.04)),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProfileCompletionAvatar(
            name: widget.job.transporterName,
            userId: int.tryParse(widget.job.transporterId) ?? 0,
            userType: 'transporter',
            completionPercentage: widget.job.transporterProfileCompletion,
            profileImageUrl: _getProfileImageUrl(
              widget.job.transporterProfilePhoto,
            ),
            gender: widget.job.transporterGender,
            size: 70,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.transporterName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: widget.job.transporterTmid.isNotEmpty
                      ? () {
                          Clipboard.setData(
                            ClipboardData(text: widget.job.transporterTmid),
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
                        widget.job.transporterTmid.isNotEmpty
                            ? widget.job.transporterTmid
                            : 'No TMID',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (widget.job.transporterTmid.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 12, color: Colors.grey.shade600),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Show Closed badge
              if (widget.job.isClosed) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'CLOSED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Show expired badge first and more prominently
              if (widget.job.isExpiredByDeadline) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              _buildStatusBadge(
                'Approval',
                widget.job.isApproved ? 'Approved' : 'Pending',
                widget.job.isApproved
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(
                'Status',
                widget.job.isActive ? 'Active' : 'Inactive',
                widget.job.isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF6B7280),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.job.jobId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.jobTitle.isNotEmpty
                          ? widget.job.jobTitle
                          : 'Driver Required',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show assignment badge for all jobs
                    if (widget.job.assignedTo != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _isAssignedToMe
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isAssignedToMe
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Text(
                          _isAssignedToMe
                              ? 'Assigned to You'
                              : 'Assigned to ${widget.job.assignedToName ?? "another telecaller"}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _isAssignedToMe
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoGrid(),
          const SizedBox(height: 14),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        _buildInfoRow(
          'Posted',
          _formatDate(widget.job.createdAt),
          'Deadline',
          _formatDate(widget.job.applicationDeadline),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'City',
          widget.job.transporterCity.isNotEmpty
              ? widget.job.transporterCity
              : 'N/A',
          'State',
          widget.job.transporterState.isNotEmpty
              ? widget.job.transporterState
              : 'N/A',
        ),
        const SizedBox(height: 8),
        _buildSingleInfo(
          'Route',
          widget.job.jobLocation.isNotEmpty
              ? widget.job.jobLocation
              : 'Not specified',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Vehicle',
          widget.job.vehicleType.isNotEmpty ? widget.job.vehicleType : 'N/A',
          'License',
          widget.job.typeOfLicense.isNotEmpty
              ? widget.job.typeOfLicense
              : 'N/A',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Salary',
          widget.job.salaryRange.isNotEmpty ? widget.job.salaryRange : 'N/A',
          'Experience',
          widget.job.requiredExperience.isNotEmpty
              ? widget.job.requiredExperience
              : 'N/A',
        ),
        const SizedBox(height: 8),
        _buildSingleInfo('Posted At', _getTimeAgoString()),
        const SizedBox(height: 8),
        _buildSingleInfo(
          'Drivers Required',
          '${widget.job.numberOfDriverRequired}',
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildInfoItem(label1, value1)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoItem(label2, value2)),
      ],
    );
  }

  Widget _buildSingleInfo(String label, String value) {
    return _buildInfoItem(label, value);
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              if (widget.job.applicantsCount > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobApplicantsScreen(
                      jobId: widget.job.jobId,
                      jobTitle: widget.job.jobTitle,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.people_outline, size: 16),
            label: Text(
              '${widget.job.applicantsCount} Applicants',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _isAssignedToMe ? Colors.green : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _isAssignedToMe
                ? () async {
                    // Make the phone call (will show IVR or manual call dialog)
                    await _makePhoneCall(widget.job.transporterPhone);
                  }
                : () {
                    // Show message for non-assigned jobs
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This job is assigned to another telecaller',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.call, color: Colors.white, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _showJobDetails(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.visibility_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showJobDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Job Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                        Text(
                          widget.job.jobId,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.softGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transporter Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailItem('Name', widget.job.transporterName),
                    _buildDetailItem(
                      'TMID',
                      widget.job.transporterTmid.isNotEmpty
                          ? widget.job.transporterTmid
                          : 'N/A',
                    ),
                    _buildDetailItem(
                      'Phone',
                      _maskPhone(widget.job.transporterPhone),
                    ),
                    _buildDetailItem(
                      'City',
                      widget.job.transporterCity.isNotEmpty
                          ? widget.job.transporterCity
                          : 'N/A',
                    ),
                    _buildDetailItem(
                      'State',
                      widget.job.transporterState.isNotEmpty
                          ? widget.job.transporterState
                          : 'N/A',
                    ),
                    _buildDetailItem(
                      'Profile Completion',
                      '${widget.job.transporterProfileCompletion}%',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Job Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailItem('Job Title', widget.job.jobTitle),
                    _buildDetailItem('Job ID', widget.job.jobId),
                    _buildDetailItem(
                      'Posted Date',
                      _formatDate(widget.job.createdAt),
                    ),
                    _buildDetailItem(
                      'Deadline',
                      _formatDate(widget.job.applicationDeadline),
                    ),
                    _buildDetailItem(
                      'Salary Range',
                      widget.job.salaryRange.isNotEmpty
                          ? widget.job.salaryRange
                          : 'Not specified',
                    ),
                    _buildDetailItem(
                      'Route/Location',
                      widget.job.jobLocation.isNotEmpty
                          ? widget.job.jobLocation
                          : 'Not specified',
                    ),
                    _buildDetailItem(
                      'Vehicle Type',
                      widget.job.vehicleType.isNotEmpty
                          ? widget.job.vehicleType
                          : 'Not specified',
                    ),
                    _buildDetailItem(
                      'Required Experience',
                      widget.job.requiredExperience.isNotEmpty
                          ? widget.job.requiredExperience
                          : 'Not specified',
                    ),
                    _buildDetailItem(
                      'License Type',
                      widget.job.typeOfLicense.isNotEmpty
                          ? widget.job.typeOfLicense
                          : 'Not specified',
                    ),
                    _buildDetailItem('Posted At', _getTimeAgoString()),
                    _buildDetailItem(
                      'Drivers Required',
                      widget.job.numberOfDriverRequired.toString(),
                    ),
                    _buildDetailItem(
                      'Applicants',
                      widget.job.applicantsCount.toString(),
                    ),
                    if (widget.job.jobDescription.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Job Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.job.jobDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGray,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.softGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
