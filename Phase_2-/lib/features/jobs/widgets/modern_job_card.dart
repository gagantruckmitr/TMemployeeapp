import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/phase2_api_service.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../models/job_model.dart';
import '../../../widgets/profile_completion_avatar.dart';
import '../job_applicants_screen.dart';
import 'job_brief_feedback_modal.dart';
import 'show_transporter_call_feedback.dart';
import '../../telecaller/widgets/call_type_selection_dialog.dart';
import '../../telecaller/widgets/ivr_call_waiting_overlay.dart';

class ModernJobCard extends StatefulWidget {
  final JobModel job;
  final bool isSearchResult;

  const ModernJobCard(
      {super.key, required this.job, this.isSearchResult = false});

  @override
  State<ModernJobCard> createState() => _ModernJobCardState();
}

class _ModernJobCardState extends State<ModernJobCard> {
  bool _isAssignedToMe = false;

  @override
  void initState() {
    super.initState();
    _checkAssignment();
  }

  Future<void> _checkAssignment() async {
    final user = await Phase2AuthService.getCurrentUser();
    if (user != null && mounted) {
      // Debug logging
      print('=== ASSIGNMENT CHECK ===');
      print('Job ID: ${widget.job.jobId}');
      print('Job assignedTo: ${widget.job.assignedTo}');
      print('Job assignedToName: ${widget.job.assignedToName}');
      print('Current User ID: ${user.id}');
      print(
          'Match: ${widget.job.assignedTo != null && widget.job.assignedTo.toString() == user.id.toString()}');

      setState(() {
        // Check if this job is assigned to the current user
        _isAssignedToMe = widget.job.assignedTo != null &&
            widget.job.assignedTo.toString() == user.id.toString();
      });
    }
  }

  String? _getProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty || imagePath.toLowerCase() == 'null') {
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
    return 'https://truckmitr.com/public/$cleanPath';
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

    // Check if user can make calls on this job
    if (!_isAssignedToMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'This job is assigned to ${widget.job.assignedToName ?? "another telecaller"}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show call type selection dialog
    final callType = await showDialog<String>(
      context: context,
      builder: (context) => CallTypeSelectionDialog(
        driverName: widget.job.transporterName,
      ),
    );

    if (callType == null) return;

    // Get current user for caller ID
    final user = await Phase2AuthService.getCurrentUser();
    final callerId = user?.id ?? 0;

    if (callType == 'manual') {
      // Manual call - just open phone dialer
      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
    } else if (callType == 'click2call') {
      // IVR call
      await _handleIVRCall(phone, callerId);
    }
  }

  Future<void> _handleIVRCall(String phone, int callerId) async {
    try {
      // Clean phone number
      final cleanMobile = phone.replaceAll(RegExp(r'[^\d]'), '');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📞 Initiating IVR call...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Initiate IVR call
      final result = await SmartCallingService.instance.initiateClick2CallIVR(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: widget.job.transporterTmid,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ IVR call initiated! Both phones will ring.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Show IVR waiting overlay
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => IVRCallWaitingOverlay(
              driverName: widget.job.transporterName,
              onCallEnded: () {
                Navigator.pop(context);
                // Show call feedback after IVR call
                _showTransporterCallFeedbackAfterIVR();
              },
            ),
          );
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate IVR call: $errorMsg'),
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

  Future<void> _showTransporterCallFeedbackAfterIVR() async {
    await showTransporterCallFeedback(
      context: context,
      transporterTmid: widget.job.transporterTmid,
      transporterName: widget.job.transporterName,
      jobId: widget.job.jobId,
      onSubmit: (callStatus, notes, recordingFile) async {
        Navigator.pop(context);

        if (callStatus == 'Connected: Details Received') {
          showJobBriefFeedbackModal(
            context: context,
            job: widget.job,
            onSubmit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job brief saved with call status: $callStatus'),
                ),
              );
            },
          );
        } else {
          try {
            await Phase2ApiService.saveJobBrief(
              uniqueId: widget.job.transporterTmid,
              jobId: widget.job.jobId,
              callStatusFeedback: callStatus,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Call status saved: $callStatus'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.job.isExpiredByDeadline
            ? const Color(0xFFFEF2F2)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.job.isExpiredByDeadline
                ? const Color(0xFFEF4444)
                : Colors.grey.shade200,
            width: widget.job.isExpiredByDeadline ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: widget.job.isExpiredByDeadline
                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
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
            profileImageUrl: _getProfileImageUrl(widget.job.transporterProfilePhoto),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.job.transporterTmid.isNotEmpty
                      ? widget.job.transporterTmid
                      : 'No TMID',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Show expired badge first and more prominently
              if (widget.job.isExpiredByDeadline) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      : const Color(0xFFF59E0B)),
              const SizedBox(height: 4),
              _buildStatusBadge(
                  'Status',
                  widget.job.isActive ? 'Active' : 'Inactive',
                  widget.job.isActive
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF6B7280)),
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
                      color: AppColors.primary),
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
                          color: AppColors.darkGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show assignment badge for all jobs
                    if (widget.job.assignedTo != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
        _buildInfoRow('Posted', _formatDate(widget.job.createdAt), 'Deadline',
            _formatDate(widget.job.applicationDeadline)),
        const SizedBox(height: 8),
        _buildInfoRow(
            'City',
            widget.job.transporterCity.isNotEmpty
                ? widget.job.transporterCity
                : 'N/A',
            'State',
            widget.job.transporterState.isNotEmpty
                ? widget.job.transporterState
                : 'N/A'),
        const SizedBox(height: 8),
        _buildSingleInfo(
            'Route',
            widget.job.jobLocation.isNotEmpty
                ? widget.job.jobLocation
                : 'Not specified'),
        const SizedBox(height: 8),
        _buildInfoRow(
            'Vehicle',
            widget.job.vehicleType.isNotEmpty ? widget.job.vehicleType : 'N/A',
            'License',
            widget.job.typeOfLicense.isNotEmpty
                ? widget.job.typeOfLicense
                : 'N/A'),
        const SizedBox(height: 8),
        _buildInfoRow(
            'Salary',
            widget.job.salaryRange.isNotEmpty ? widget.job.salaryRange : 'N/A',
            'Experience',
            widget.job.requiredExperience.isNotEmpty
                ? widget.job.requiredExperience
                : 'N/A'),
        const SizedBox(height: 8),
        _buildSingleInfo('Posted At', _getTimeAgoString()),
        const SizedBox(height: 8),
        _buildSingleInfo(
            'Drivers Required', '${widget.job.numberOfDriverRequired}'),
      ],
    );
  }

  Widget _buildInfoRow(
      String label1, String value1, String label2, String value2) {
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
                color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color),
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
                        jobId: widget.job.jobId, jobTitle: widget.job.jobTitle),
                  ),
                );
              }
            },
            icon: const Icon(Icons.people_outline, size: 16),
            label: Text('${widget.job.applicantsCount} Applicants',
                style: const TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
                        content:
                            Text('This job is assigned to another telecaller'),
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
              child: const Icon(Icons.visibility_outlined,
                  color: Colors.white, size: 18),
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
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Job Details',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray)),
                        Text(widget.job.jobId,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.softGray)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
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
                    const Text('Transporter Information',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray)),
                    const SizedBox(height: 12),
                    _buildDetailItem('Name', widget.job.transporterName),
                    _buildDetailItem(
                        'TMID',
                        widget.job.transporterTmid.isNotEmpty
                            ? widget.job.transporterTmid
                            : 'N/A'),
                    _buildDetailItem(
                        'Phone', _maskPhone(widget.job.transporterPhone)),
                    _buildDetailItem(
                        'City',
                        widget.job.transporterCity.isNotEmpty
                            ? widget.job.transporterCity
                            : 'N/A'),
                    _buildDetailItem(
                        'State',
                        widget.job.transporterState.isNotEmpty
                            ? widget.job.transporterState
                            : 'N/A'),
                    _buildDetailItem('Profile Completion',
                        '${widget.job.transporterProfileCompletion}%'),
                    const SizedBox(height: 24),
                    const Text('Job Information',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray)),
                    const SizedBox(height: 12),
                    _buildDetailItem('Job Title', widget.job.jobTitle),
                    _buildDetailItem('Job ID', widget.job.jobId),
                    _buildDetailItem(
                        'Posted Date', _formatDate(widget.job.createdAt)),
                    _buildDetailItem('Deadline',
                        _formatDate(widget.job.applicationDeadline)),
                    _buildDetailItem(
                        'Salary Range',
                        widget.job.salaryRange.isNotEmpty
                            ? widget.job.salaryRange
                            : 'Not specified'),
                    _buildDetailItem(
                        'Route/Location',
                        widget.job.jobLocation.isNotEmpty
                            ? widget.job.jobLocation
                            : 'Not specified'),
                    _buildDetailItem(
                        'Vehicle Type',
                        widget.job.vehicleType.isNotEmpty
                            ? widget.job.vehicleType
                            : 'Not specified'),
                    _buildDetailItem(
                        'Required Experience',
                        widget.job.requiredExperience.isNotEmpty
                            ? widget.job.requiredExperience
                            : 'Not specified'),
                    _buildDetailItem(
                        'License Type',
                        widget.job.typeOfLicense.isNotEmpty
                            ? widget.job.typeOfLicense
                            : 'Not specified'),
                    _buildDetailItem('Posted At', _getTimeAgoString()),
                    _buildDetailItem('Drivers Required',
                        widget.job.numberOfDriverRequired.toString()),
                    _buildDetailItem(
                        'Applicants', widget.job.applicantsCount.toString()),
                    if (widget.job.jobDescription.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Job Description',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGray)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(widget.job.jobDescription,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.darkGray,
                                height: 1.5)),
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
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.softGray,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
