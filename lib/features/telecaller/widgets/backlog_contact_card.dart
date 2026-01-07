import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tmemployeeapp/models/smart_calling_models.dart';
import '../../../core/utils/state_code_mapper.dart';
import '../../../core/services/call_feedback_guard_service.dart';
import 'profile_completion_avatar.dart';
import 'package:tmemployeeapp/features/telecaller/screens/profile_completion_details_page.dart';

/// Backlog Contact Card - Exact replica of DriverContactCard for backlog leads
/// Shows full details of leads with callback_later status
class BacklogContactCard extends StatefulWidget {
  final DriverContact contact;
  final VoidCallback onCallPressed;
  final bool isCallInProgress;
  final VoidCallback? onTap;
  final bool showPhoneNumber;
  final bool showAssignedTo;
  final String? reason;
  final String? subscriptionDateText;
  final List<dynamic>? callbackHistory;
  final int? callbackRequestsCount;
  final bool hideCallButtonOnPendingFeedback;

  const BacklogContactCard({
    super.key,
    required this.contact,
    required this.onCallPressed,
    this.isCallInProgress = false,
    this.onTap,
    this.showPhoneNumber = false,
    this.showAssignedTo = true,
    this.reason,
    this.subscriptionDateText,
    this.callbackHistory,
    this.callbackRequestsCount,
    this.hideCallButtonOnPendingFeedback = true,
  });

  @override
  State<BacklogContactCard> createState() => _BacklogContactCardState();
}

class _BacklogContactCardState extends State<BacklogContactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  String _formatRegistrationDate() {
    final date = widget.contact.registrationDate ?? DateTime.now();
    return DateFormat('dd-MMM-yy hh:mma').format(date);
  }

  String _formatSubscriptionDate() {
    if (widget.subscriptionDateText != null) {
      return widget.subscriptionDateText!;
    }
    final paymentInfo = widget.contact.paymentInfo;
    if (paymentInfo == null) {
      return 'N/A';
    }
    // Use updated_at from payments array (as requested) - this is the subscription date
    if (paymentInfo.updatedAt != null) {
      return DateFormat('dd-MMM-yy hh:mma').format(paymentInfo.updatedAt!);
    }
    // Fallback to startAt (subscription start date)
    if (paymentInfo.startAt != null) {
      return DateFormat('dd-MMM-yy hh:mma').format(paymentInfo.startAt!);
    }
    // Fallback to paymentDate if available
    if (paymentInfo.paymentDate != null) {
      return DateFormat('dd-MMM-yy hh:mma').format(paymentInfo.paymentDate!);
    }
    return 'N/A';
  }

  /// Calculate profile completion percentage - EXACT COPY from ProfileCompletionDetailsPage.build()
  int _calculateProfileCompletionPercentage() {
    // Calculate completion based on the displayed documents list ONLY
    // This ensures count matches the list shown to user
    final documents = _getDriverDocuments();
    final totalDocs = documents.length;
    
    // Count completed docs by checking actual values, not just API status
    // This handles special cases like mobile (from contact) and state (from TMID)
    final completion = widget.contact.profileCompletion;
    final values = completion?.documentValues ?? {};
    
    int completedDocs = 0;
    for (var doc in documents) {
      var value = values[doc.fieldName];
      
      // Special handling for mobile - fallback to contact phone
      if (doc.fieldName == 'mobile' && (value == null || value.isEmpty)) {
        value = widget.contact.phoneNumber;
      }
      
      // Special handling for state - extract from TMID
      if (doc.fieldName == 'state' && (value == null || value.isEmpty)) {
        value = StateCodeMapper.getStateName(widget.contact.tmid);
      }
      
      // Check if value is valid
      if (_isValidValue(value)) {
        completedDocs++;
      }
    }

    // Recalculate percentage from visible docs
    // This ensures displayed percentage matches the displayed fraction (X/Y Records)
    final percentage = totalDocs > 0
        ? ((completedDocs / totalDocs) * 100).round()
        : 0;

    return percentage;
  }

  /// EXACT COPY from ProfileCompletionDetailsPage._getDriverDocuments()
  List<_DocumentItem> _getDriverDocuments() {
    final completion = widget.contact.profileCompletion;
    final docs = completion?.documentStatus ?? {};
    final values = completion?.documentValues ?? {};

    // Use the flag passed from the calling page, or check document keys as fallback
    final allKeys = docs.keys.map((k) => k.toLowerCase()).toList();
    final isTransporterFromKeys =
        allKeys.contains('transport_name') ||
        allKeys.contains('pan_number') ||
        allKeys.contains('fleet_size') ||
        allKeys.contains('gst_certificate');

    final isTransporter = widget.contact.role == 'transporter' || isTransporterFromKeys;

    if (isTransporter) {
      // Return transporter-specific fields
      return [
        _DocumentItem('Name', 'name', docs['name'] ?? false, values['name']),
        _DocumentItem('Email', 'email', docs['email'] ?? false, values['email']),
        _DocumentItem('Mobile', 'mobile', docs['mobile'] ?? false, values['mobile']),
        _DocumentItem('Transport Name', 'transport_name', docs['transport_name'] ?? false, values['transport_name']),
        _DocumentItem('Year of Establishment', 'year_of_establishment', docs['year_of_establishment'] ?? false, values['year_of_establishment']),
        _DocumentItem('Fleet Size', 'fleet_size', docs['fleet_size'] ?? false, values['fleet_size']),
        _DocumentItem('Operational Segment', 'operational_segment', docs['operational_segment'] ?? false, values['operational_segment']),
        _DocumentItem('Average KM', 'average_km', docs['average_km'] ?? false, values['average_km']),
        _DocumentItem('City', 'city', docs['city'] ?? false, values['city']),
        _DocumentItem('State', 'state', docs['state'] ?? false, values['state']),
        _DocumentItem('Profile Photo', 'images', docs['images'] ?? false, values['images']),
        _DocumentItem('Address', 'address', docs['address'] ?? false, values['address']),
        _DocumentItem('PAN Number', 'pan_number', docs['pan_number'] ?? false, values['pan_number']),
        _DocumentItem('PAN Image', 'pan_image', docs['pan_image'] ?? false, values['pan_image']),
        _DocumentItem('GST Certificate', 'gst_certificate', docs['gst_certificate'] ?? false, values['gst_certificate']),
      ];
    }

    // Return driver-specific fields (23 records total)
    return [
      _DocumentItem('Basic Information', 'name', docs['name'] ?? false, values['name']),
      _DocumentItem('Email', 'email', docs['email'] ?? false, values['email']),
      _DocumentItem('Mobile', 'mobile', docs['mobile'] ?? false, values['mobile']),
      _DocumentItem('State', 'state', docs['state'] ?? false, values['state']),
      _DocumentItem('Vehicle Type', 'vehicle_type', docs['vehicle_type'] ?? false, values['vehicle_type']),
      _DocumentItem('Father Name', 'father_name', docs['father_name'] ?? false, values['father_name']),
      _DocumentItem('Profile Photo', 'images', docs['images'] ?? false, values['images']),
      _DocumentItem('Address', 'address', docs['address'] ?? false, values['address']),
      _DocumentItem('Date of Birth', 'dob', docs['dob'] ?? false, values['dob']),
      _DocumentItem('License Type', 'type_of_license', docs['type_of_license'] ?? false, values['type_of_license']),
      _DocumentItem('Driving Experience (Yrs)', 'driving_experience', docs['driving_experience'] ?? false, values['driving_experience']),
      _DocumentItem('Education', 'highest_education', docs['highest_education'] ?? false, values['highest_education']),
      _DocumentItem('License Number', 'license_number', docs['license_number'] ?? false, values['license_number']),
      _DocumentItem('License Expiry', 'expiry_date_of_license', docs['expiry_date_of_license'] ?? false, values['expiry_date_of_license']),
      _DocumentItem('Expected Income', 'expected_monthly_income', docs['expected_monthly_income'] ?? false, values['expected_monthly_income']),
      _DocumentItem('Current Income', 'current_monthly_income', docs['current_monthly_income'] ?? false, values['current_monthly_income']),
      _DocumentItem('Marital Status', 'marital_status', docs['marital_status'] ?? false, values['marital_status']),
      _DocumentItem('Preferred Location', 'preferred_location', docs['preferred_location'] ?? false, values['preferred_location']),
      _DocumentItem('Aadhar Number', 'aadhar_number', docs['aadhar_number'] ?? false, values['aadhar_number']),
      _DocumentItem('Aadhar Photo', 'aadhar_photo', docs['aadhar_photo'] ?? false, values['aadhar_photo']),
      _DocumentItem('Driving License', 'driving_license', docs['driving_license'] ?? false, values['driving_license']),
      _DocumentItem('Previous Employer', 'previous_employer', docs['previous_employer'] ?? false, values['previous_employer']),
      _DocumentItem('Job Placement', 'job_placement', docs['job_placement'] ?? false, values['job_placement']),
    ];
  }

  /// EXACT COPY from ProfileCompletionDetailsPage._isValidValue()
  bool _isValidValue(dynamic value) {
    if (value == null) return false;

    final String stringValue = value.toString().trim();

    if (stringValue.isEmpty) return false;
    if (stringValue.toLowerCase() == 'null') return false;
    if (stringValue.toLowerCase() == 'n/a') return false;

    return true;
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCallButton() {
    return GestureDetector(
      onTap: widget.isCallInProgress
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onCallPressed();
            },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: widget.isCallInProgress
              ? Colors.grey.shade300
              : const Color(0xFF2196F3),
          shape: BoxShape.circle,
          boxShadow: widget.isCallInProgress
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.isCallInProgress
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : const Icon(
                Icons.phone,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar, Name/TMID, Call Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with profile completion and role badge
                      Column(
                        children: [
                          ProfileCompletionAvatar(
                            name: widget.contact.name,
                            completionPercentage: _calculateProfileCompletionPercentage(),
                            imageUrl: widget.contact.profilePicture,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProfileCompletionDetailsPage(
                                        contact: widget.contact,
                                        isTransporter:
                                            widget.contact.role ==
                                            'transporter',
                                      ),
                                ),
                              );
                            },
                            size: 60,
                          ),
                          const SizedBox(height: 6),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (widget.contact.role == 'driver')
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (widget.contact.role == 'driver')
                                    ? Colors.blue.shade300
                                    : Colors.orange.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              (widget.contact.role ?? 'driver').toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: (widget.contact.role == 'driver')
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Name and TMID
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onLongPress: () {
                                  Clipboard.setData(
                                    ClipboardData(text: widget.contact.name),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Name copied: ${widget.contact.name}',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  HapticFeedback.mediumImpact();
                                },
                                child: Text(
                                  widget.contact.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: widget.contact.tmid),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'TMID copied: ${widget.contact.tmid}',
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.contact.tmid,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.copy,
                                        size: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Call Button - Hidden when pending feedback
                      if (widget.hideCallButtonOnPendingFeedback)
                        ValueListenableBuilder<bool>(
                          valueListenable: CallFeedbackGuardService.instance.hasPendingFeedbackNotifier,
                          builder: (context, hasPendingFeedback, child) {
                            if (hasPendingFeedback) {
                              // Show disabled/hidden state when feedback is pending
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  CallFeedbackGuardService.showPendingFeedbackToast(context);
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.phone_disabled,
                                    color: Colors.grey.shade500,
                                    size: 24,
                                  ),
                                ),
                              );
                            }
                            return _buildCallButton();
                          },
                        )
                      else
                        _buildCallButton(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Registration Date and Subscription Date Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          'Registration Date',
                          _formatRegistrationDate(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoRow(
                          'Subscription Date',
                          _formatSubscriptionDate(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // State and License Type Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          'State',
                          StateCodeMapper.getStateName(widget.contact.tmid),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoRow(
                          widget.contact.role == 'transporter'
                              ? 'Fleet Size'
                              : 'License Type',
                          widget.contact.role == 'transporter'
                              ? (widget.contact.fleetSize ?? 'N/A')
                              : (widget.contact.licenseType ?? 'N/A'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Assigned To and Last Feedback (only show if there's a value)
                  if (widget.showAssignedTo &&
                      widget.contact.assignedTelecaller != null &&
                      widget.contact.assignedTelecaller!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            children: [
                              TextSpan(
                                text: 'Assigned to: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextSpan(
                                text: widget.contact.assignedTelecaller!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.contact.lastFeedback != null &&
                            widget.contact.lastFeedback!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.feedback_outlined,
                                  size: 14,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Last Feedback',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.contact.lastFeedback!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade900,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (widget.contact.remarks != null &&
                            widget.contact.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 14,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Remarks',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.contact.remarks!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade900,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper class for document items - EXACT COPY from ProfileCompletionDetailsPage
class _DocumentItem {
  final String displayName;
  final String fieldName;
  final bool isPresent;
  final String? value;

  _DocumentItem(this.displayName, this.fieldName, this.isPresent, this.value);
}
