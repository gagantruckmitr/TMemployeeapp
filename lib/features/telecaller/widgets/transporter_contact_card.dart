import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/utils/state_code_mapper.dart';
import '../../../core/services/call_feedback_guard_service.dart';
import 'profile_completion_avatar.dart';
import '../screens/profile_completion_details_page.dart';

class TransporterContactCard extends StatefulWidget {
  final TransporterContact contact;
  final VoidCallback onCallPressed;
  final bool isCallInProgress;
  final VoidCallback? onTap;
  final bool hideCallButtonOnPendingFeedback;

  const TransporterContactCard({
    super.key,
    required this.contact,
    required this.onCallPressed,
    this.isCallInProgress = false,
    this.onTap,
    this.hideCallButtonOnPendingFeedback = true,
  });

  @override
  State<TransporterContactCard> createState() => _TransporterContactCardState();
}

class _TransporterContactCardState extends State<TransporterContactCard> {

  String _formatRegistrationDate() {
    final date = widget.contact.registrationDate ?? DateTime.now();
    return DateFormat('dd MMM yyyy').format(date);
  }

  bool _hasSubscription() {
    return widget.contact.subscriptionStatus == SubscriptionStatus.active ||
        widget.contact.paymentInfo?.paymentStatus == PaymentStatus.success;
  }

  String _getSubscriptionText() {
    final paymentInfo = widget.contact.paymentInfo;

    if (paymentInfo != null && paymentInfo.subscriptionType != null) {
      return paymentInfo.subscriptionType!;
    }

    if (_hasSubscription()) {
      return 'Active';
    }

    return 'No Subscription';
  }

  Color _getSubscriptionColor() {
    final paymentInfo = widget.contact.paymentInfo;

    if (paymentInfo?.paymentStatus == PaymentStatus.success) {
      return const Color(0xFF4CAF50);
    } else if (paymentInfo?.paymentStatus == PaymentStatus.pending) {
      return const Color(0xFFFFC107);
    } else if (paymentInfo?.paymentStatus == PaymentStatus.failed) {
      return const Color(0xFFF44336);
    }

    return Colors.grey.shade600;
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

    // Transporter-specific fields (15 fields)
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

  /// EXACT COPY from ProfileCompletionDetailsPage._isValidValue()
  bool _isValidValue(dynamic value) {
    if (value == null) return false;

    final String stringValue = value.toString().trim();

    if (stringValue.isEmpty) return false;
    if (stringValue.toLowerCase() == 'null') return false;
    if (stringValue.toLowerCase() == 'n/a') return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                children: [
                  // Top Row: Avatar, Name, Call Button
                  Row(
                    children: [
                      // Avatar with profile completion
                      ProfileCompletionAvatar(
                        name: widget.contact.name,
                        completionPercentage: _calculateProfileCompletionPercentage(),
                        imageUrl: widget.contact.profilePicture,
                        size: 54,
                        onTap: () async {
                          print('🔵 Transporter avatar tapped: ${widget.contact.name}');
                          print('🔵 Transporter ID: ${widget.contact.id}');
                          print('🔵 Transporter TMID: ${widget.contact.tmid}');
                          
                          try {
                            HapticFeedback.lightImpact();
                            
                            // Convert TransporterContact to DriverContact for profile page
                            final driverContact = DriverContact(
                              id: widget.contact.id,
                              tmid: widget.contact.tmid,
                              name: widget.contact.name,
                              company: widget.contact.company,
                              phoneNumber: widget.contact.phoneNumber,
                              state: widget.contact.state,
                              subscriptionStatus: widget.contact.subscriptionStatus,
                              status: widget.contact.status,
                              lastFeedback: widget.contact.lastFeedback,
                              lastCallTime: widget.contact.lastCallTime,
                              remarks: widget.contact.remarks,
                              paymentInfo: widget.contact.paymentInfo,
                              registrationDate: widget.contact.registrationDate,
                              profileCompletion: widget.contact.profileCompletion,
                              profilePicture: widget.contact.profilePicture,
                            );
                            
                            print('🔵 About to navigate to profile page...');
                            
                            if (!context.mounted) {
                              print('❌ Context not mounted!');
                              return;
                            }
                            
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileCompletionDetailsPage(
                                  contact: driverContact,
                                  isTransporter: true,
                                ),
                              ),
                            );
                            
                            print('✅ Navigation completed');
                          } catch (e, stackTrace) {
                            print('❌ Navigation error: $e');
                            print('❌ Stack trace: $stackTrace');
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error opening profile: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 14),

                      // Name (Long press to copy)
                      Expanded(
                        child: GestureDetector(
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
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(8),
                              ),
                            );
                            HapticFeedback.mediumImpact();
                          },
                          child: Text(
                            widget.contact.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.phone_disabled,
                                    color: Colors.grey.shade500,
                                    size: 22,
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

                  const SizedBox(height: 14),

                  // Divider
                  Container(height: 1, color: Colors.grey.shade200),

                  const SizedBox(height: 14),

                  // Bottom Grid: Details in 2x2 layout
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.calendar_today_outlined,
                          'Registration',
                          _formatRegistrationDate(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.location_on_outlined,
                          'State',
                          StateCodeMapper.getStateName(widget.contact.tmid),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _buildSubscriptionItem()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.badge_outlined,
                          'TMID',
                          widget.contact.tmid,
                        ),
                      ),
                    ],
                  ),

                  // Show feedback if available
                  if (widget.contact.lastFeedback != null &&
                      widget.contact.lastFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildFeedbackSection(),
                  ],

                  // Show remarks if available
                  if (widget.contact.remarks != null &&
                      widget.contact.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildRemarksSection(),
                  ],
                ],
              ),
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
        width: 48,
        height: 48,
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : const Icon(
                Icons.phone,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied: $value'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
        HapticFeedback.mediumImpact();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.copy, size: 12, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem() {
    final subscriptionText = _getSubscriptionText();
    final subscriptionColor = _getSubscriptionColor();
    final hasSubscription = _hasSubscription();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasSubscription
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 14,
              color: subscriptionColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: subscriptionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: subscriptionColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            subscriptionText,
            style: TextStyle(
              fontSize: 11,
              color: subscriptionColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.feedback_outlined, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Feedback',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.contact.lastFeedback!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
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

  Widget _buildRemarksSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.note_outlined, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.contact.remarks!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
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
}

/// Helper class for document items - EXACT COPY from ProfileCompletionDetailsPage
class _DocumentItem {
  final String displayName;
  final String fieldName;
  final bool isPresent;
  final String? value;

  _DocumentItem(this.displayName, this.fieldName, this.isPresent, this.value);
}
