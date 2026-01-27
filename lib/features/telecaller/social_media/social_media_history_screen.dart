import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/social_media_feedback_service.dart';
import '../../../core/services/social_media_ivr_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../models/social_media_lead_model.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/tab_page_header.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../../../widgets/audio_player_widget.dart';
import '../../../widgets/error_handler.dart';

class SocialMediaHistoryScreen extends StatefulWidget {
  const SocialMediaHistoryScreen({super.key});

  @override
  State<SocialMediaHistoryScreen> createState() =>
      _SocialMediaHistoryScreenState();
}

class _SocialMediaHistoryScreenState extends State<SocialMediaHistoryScreen> {
  final SocialMediaFeedbackService _service =
      SocialMediaFeedbackService.instance;
  final DateFormat _dateFormat = DateFormat('d MMM yyyy • h:mm a');

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.fetchCallHistory();
      if (!mounted) return;
      setState(() {
        _history = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final results = await _service.fetchCallHistory();
      if (!mounted) return;
      setState(() {
        _history = results;
        _isRefreshing = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _error = error.toString();
      });
      ErrorHandler.showError(context, error, onRetry: _refresh);
    }
  }

  void _copyNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Number copied'),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _onCallPressed(Map<String, dynamic> call) async {
    // Convert call history data to SocialMediaLead for compatibility
    final lead = _convertCallToLead(call);
    await _startCall(lead, call);
  }

  SocialMediaLead _convertCallToLead(Map<String, dynamic> call) {
    final name = call['driver_name']?.toString() ?? 'Unknown';
    final mobile = call['user_number']?.toString() ?? '';
    final notesRaw = call['notes']?.toString() ?? '';
    final createdAt = call['created_at']?.toString() ?? DateTime.now().toIso8601String();

    // Extract source and role from notes field
    String source = 'Social Media';
    String role = 'driver';
    if (notesRaw.isNotEmpty) {
      final parts = notesRaw.split('|');
      for (var part in parts) {
        if (part.contains('Source:')) {
          source = part.replaceAll('Source:', '').trim();
        }
        if (part.contains('Role:')) {
          role = part.replaceAll('Role:', '').trim();
        }
      }
    }

    return SocialMediaLead(
      id: int.tryParse(call['id']?.toString() ?? '0') ?? 0,
      assignedId: int.tryParse(call['assigned_id']?.toString() ?? '0') ?? 0,
      name: name,
      mobile: mobile,
      source: source,
      remarks: call['remarks']?.toString(),
      chatDateTime: DateTime.tryParse(createdAt) ?? DateTime.now(),
      role: role,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  Future<void> _startCall(SocialMediaLead lead, Map<String, dynamic> originalCall) async {
    try {
      final contact = _mapLeadToDriverContact(lead);

      if (!mounted) return;

      final callType = await showDialog<String>(
        context: context,
        builder: (context) => CallTypeSelectionDialog(driverName: lead.name),
      );

      if (callType == null || !mounted) return;

      if (callType == 'manual') {
        await _handleManualCall(lead, contact, originalCall);
      } else if (callType == 'easygo_ivr') {
        await _handleIVRCall(lead, contact, originalCall);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    }
  }

  Future<void> _handleManualCall(
    SocialMediaLead lead,
    DriverContact contact,
    Map<String, dynamic> originalCall,
  ) async {
    try {
      final cleanNumber = lead.mobile.replaceAll(RegExp(r'[^\d]'), '');

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${lead.name}...'),
          backgroundColor: const Color(0xFF34C759),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );

      await FlutterPhoneDirectCaller.callNumber(cleanNumber);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showManualCallFeedbackModal(contact, lead, originalCall);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $error'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    }
  }

  void _showManualCallFeedbackModal(
    DriverContact contact,
    SocialMediaLead lead,
    Map<String, dynamic> originalCall,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        contact: contact,
        allowDismiss: true,
        onFeedbackSubmitted: (feedback) async {
          Navigator.of(context).pop();
          await _handleManualFeedbackSubmitted(contact, lead, feedback, originalCall);
        },
      ),
    );
  }

  Future<void> _handleManualFeedbackSubmitted(
    DriverContact contact,
    SocialMediaLead lead,
    CallFeedback feedback,
    Map<String, dynamic> originalCall,
  ) async {
    if (!mounted) return;

    final result = await SocialMediaFeedbackService.instance.submitFeedback(
      lead: lead,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      // Refresh history to show updated call
      _loadHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback saved for ${contact.name}'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save feedback: ${result['message']}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }

  Future<void> _handleIVRCall(
    SocialMediaLead lead,
    DriverContact contact,
    Map<String, dynamic> originalCall,
  ) async {
    if (!mounted) return;

    // Get current user (telecaller) information
    final currentUser = RealAuthService.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please login again.'),
          backgroundColor: Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
      return;
    }

    // Get telecaller phone number
    final telecallerPhone = currentUser.mobile;
    if (telecallerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your phone number is not available. Please update your profile.',
          ),
          backgroundColor: Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
      return;
    }

    // Show initial loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 Initiating Social Media IVR call...'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );

    try {
      // Initiate call using Social Media IVR API
      final result = await SocialMediaIVRService.initiateCall(
        assignedId: int.tryParse(currentUser.id) ?? 0,
        leadId: lead.id,
        name: lead.name,
        mobile: lead.mobile,
        source: lead.source,
        role: lead.role,
        leadRemarks: lead.remarks ?? '',
        exten: telecallerPhone,
        number: lead.mobile,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final callId = result['call_id'];
        print(
          '✅ Social Media IVR call initiated successfully. Call ID: $callId',
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calling ${lead.name}... Call ID: $callId'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );

        // Show IVR call waiting overlay
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (overlayContext) => PopScope(
              canPop: false,
              child: IVRCallWaitingOverlay(
                driverName: lead.name,
                referenceId: callId.toString(),
                onCallEnded: () {
                  // Add a delay to ensure the pop animation completes before showing modal
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      _showFeedbackModalWithCallId(
                        contact,
                        lead,
                        callId?.toString(),
                        originalCall,
                      );
                    }
                  });
                }, 
              ),
            ),
          ),
        );
      } else {
        final error = result['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initiate call: $error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }

  void _showFeedbackModalWithCallId(
    DriverContact contact,
    SocialMediaLead lead,
    String? callLogId,
    Map<String, dynamic> originalCall,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        contact: contact,
        allowDismiss: true,
        onFeedbackSubmitted: (feedback) async {
          Navigator.of(context).pop();
          await _handleIVRFeedbackSubmitted(contact, lead, feedback, callLogId, originalCall);
        },
      ),
    );
  }

  Future<void> _handleIVRFeedbackSubmitted(
    DriverContact contact,
    SocialMediaLead lead,
    CallFeedback feedback,
    String? callLogId,
    Map<String, dynamic> originalCall,
  ) async {
    if (!mounted) return;

    print('🔵 [Social Media History Feedback] Starting submission...');
    print('   Lead ID: ${lead.id}');
    print('   Lead Name: ${lead.name}');
    print('   Call Log ID: $callLogId');
    print('   Feedback Status: ${feedback.status}');
    print('   Feedback Remarks: ${feedback.remarks}');

    // Build feedback string based on status
    String feedbackString = '';
    String statusString = '';

    switch (feedback.status) {
      case CallStatus.connected:
        statusString = 'connected';
        feedbackString = feedback.connectedFeedback?.displayName ?? 'Connected';
        break;
      case CallStatus.callBack:
        statusString = 'not_connected';
        feedbackString = feedback.callBackReason?.displayName ?? 'Call Back';
        break;
      case CallStatus.callBackLater:
        statusString = 'callback_later';
        feedbackString =
            feedback.callBackTime?.displayName ?? 'Call Back Later';
        break;
      case CallStatus.notInterested:
        statusString = 'not_interested';
        feedbackString = 'not interested';
        break;
      case CallStatus.notReachable:
        statusString = 'not_reachable';
        feedbackString = 'not reachable';
        break;
      case CallStatus.invalid:
        statusString = 'invalid';
        feedbackString = 'invalid number';
        break;
      case CallStatus.pending:
        statusString = 'pending';
        feedbackString = 'pending';
        break;
    }

    print('🔵 [Social Media History Feedback] Mapped values:');
    print('   Status String: "$statusString"');
    print('   Feedback String: "$feedbackString"');
    print('   Remarks: "${feedback.remarks ?? ''}"');

    // If we have a callLogId, update via Social Media IVR API
    if (callLogId != null && callLogId.isNotEmpty) {
      final callId = int.tryParse(callLogId);
      if (callId != null) {
        print(
          '🔵 [Social Media History] Updating call feedback via social-media-ivr-call-update API',
        );
        print('   Call ID: $callId');
        print('   Status: "$statusString"');
        print('   Feedback: "$feedbackString"');
        print('   Remarks: "${feedback.remarks ?? ''}"');

        final result = await SocialMediaIVRService.updateCall(
          callId: callId,
          callStatus: statusString,
          callFeedbacks: feedbackString,
          callRemarks: feedback.remarks ?? '',
        );

        print('🔵 [Social Media History] Update API Result: $result');

        if (!mounted) return;

        HapticFeedback.lightImpact();

        if (result['success'] == true) {
          print('✅ [Social Media History] Feedback saved successfully');

          // Refresh history to show updated call
          _loadHistory();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Feedback saved for ${contact.name}'),
              backgroundColor: const Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        } else {
          print('❌ [Social Media History] Feedback save failed: ${result['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save feedback: ${result['error'] ?? 'Unknown error'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: const Color(0xFFFF3B30),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
        return;
      }
    }

    // Fallback to old API if no callLogId
    print(
      '⚠️ [Social Media History] No callLogId, falling back to social_media_feedback_api',
    );
    final result = await SocialMediaFeedbackService.instance.submitFeedback(
      lead: lead,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      // Refresh history to show updated call
      _loadHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback saved for ${contact.name}'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save feedback: ${result['message']}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }

  DriverContact _mapLeadToDriverContact(SocialMediaLead lead) {
    return DriverContact(
      id: lead.id.toString(),
      tmid: 'SM${lead.id.toString().padLeft(6, '0')}',
      name: lead.name,
      company: lead.source,
      phoneNumber: lead.mobile,
      state: '',
      subscriptionStatus: SubscriptionStatus.inactive,
      status: CallStatus.pending,
      lastFeedback: null,
      lastCallTime: lead.chatDateTime,
      remarks: lead.remarks,
      paymentInfo: PaymentInfo.none(),
      registrationDate: lead.createdAt,
      profileCompletion: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _isLoading
        ? 'Loading call history...'
        : _error != null
        ? 'Tap refresh to try again.'
        : _history.isEmpty
        ? 'No call history yet.'
        : '${_history.length} calls made';

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Social Media Call History',
          style: AppTheme.headingMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          TelecallerTabHeader(
            icon: Icons.history,
            iconColor: AppTheme.accentPurple,
            title: 'Call History',
            subtitle: subtitle,
            trailing: TelecallerHeaderActionButton(
              isLoading: _isRefreshing,
              onPressed: _refresh,
              icon: Icons.refresh_rounded,
              color: AppTheme.accentPurple,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingView()
                : _error != null
                ? _ErrorView(message: _error!, onRetry: _loadHistory)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppTheme.accentPurple,
                    child: _history.isEmpty
                        ? const _EmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final call = _history[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < _history.length - 1 ? 16 : 0,
                                ),
                                child: _CallHistoryCard(
                                  call: call,
                                  dateFormat: _dateFormat,
                                  onCall: () => _onCallPressed(call),
                                  onCopyNumber: _copyNumber,
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryCard extends StatelessWidget {
  const _CallHistoryCard({
    required this.call,
    required this.dateFormat,
    required this.onCall,
    required this.onCopyNumber,
  });

  final Map<String, dynamic> call;
  final DateFormat dateFormat;
  final VoidCallback onCall;
  final ValueChanged<String> onCopyNumber;

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final lastFour = phone.substring(phone.length - 4);
    return '******$lastFour';
  }

  Color _sourceColor() {
    final source = call['source']?.toString().toLowerCase() ?? '';
    switch (source) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return AppTheme.accentPurple;
    }
  }

  IconData _sourceIcon() {
    final source = call['source']?.toString().toLowerCase() ?? '';
    switch (source) {
      case 'facebook':
        return Icons.facebook;
      case 'whatsapp':
        return Icons.chat;
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.tag;
      default:
        return Icons.public;
    }
  }

  Color _feedbackColor() {
    final feedback = call['feedback']?.toString().toLowerCase() ?? '';
    if (feedback.contains('interested') || feedback.contains('connected')) {
      return AppTheme.success;
    } else if (feedback.contains('not interested') ||
        feedback.contains('rejected')) {
      return AppTheme.error;
    } else if (feedback.contains('callback') || feedback.contains('later')) {
      return AppTheme.warning;
    }
    return AppTheme.gray;
  }

  @override
  Widget build(BuildContext context) {
    final name = call['driver_name']?.toString() ?? 'Unknown';
    final mobile = call['user_number']?.toString() ?? 
                   call['mobile']?.toString() ?? 
                   call['phone']?.toString() ?? 
                   call['driver_mobile']?.toString() ?? '';
    final notesRaw = call['notes']?.toString() ?? '';
    final feedback = call['feedback']?.toString() ?? 'No feedback';
    final remarks = call['remarks']?.toString() ?? '';
    final tcFor = call['tc_for']?.toString() ?? '';
    final createdAt = call['created_at']?.toString() ?? '';

    // Debug: Print available fields to understand data structure
    print('🔍 [Social Media History Card] Available fields: ${call.keys.toList()}');
    print('🔍 [Social Media History Card] Mobile fields: user_number="${call['user_number']}", mobile="${call['mobile']}", phone="${call['phone']}", driver_mobile="${call['driver_mobile']}"');
    print('🔍 [Social Media History Card] Final mobile: "$mobile"');

    // Extract source and role from notes field
    String source = 'Social Media';
    String role = '';
    if (notesRaw.isNotEmpty) {
      final parts = notesRaw.split('|');
      for (var part in parts) {
        if (part.contains('Source:')) {
          source = part.replaceAll('Source:', '').trim();
        }
        if (part.contains('Role:')) {
          role = part.replaceAll('Role:', '').trim();
        }
      }
    }

    DateTime? callDate;
    try {
      callDate = DateTime.parse(createdAt);
    } catch (e) {
      callDate = null;
    }

    final sourceColor = _sourceColor();
    final feedbackColor = _feedbackColor();
    final maskedPhone = _maskPhone(mobile);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: sourceColor.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (mobile.isNotEmpty)
                        GestureDetector(
                          onTap: () => onCopyNumber(mobile),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                maskedPhone,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.gray,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Color(0xFFC7C7CC),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'No phone number',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.gray,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only show call button if mobile number exists
                    if (mobile.isNotEmpty && mobile.length >= 10) ...[
                      // Call Button - Make it more prominent
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onCall();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34C759).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sourceColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_sourceIcon(), size: 12, color: sourceColor),
                          const SizedBox(width: 4),
                          Text(
                            source,
                            style: AppTheme.bodySmall.copyWith(
                              color: sourceColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feedbackColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.feedback_outlined, size: 16, color: feedbackColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback,
                      style: AppTheme.bodyLarge.copyWith(
                        color: feedbackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined, size: 16, color: AppTheme.gray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remarks,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (call['manual_call_recording_url']?.toString().isNotEmpty ==
                true) ...[
              AudioPlayerWidget(
                recordingUrl: call['manual_call_recording_url'].toString(),
                label: 'Social Media Call Recording',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (callDate != null)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppTheme.gray),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(callDate),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: role.toLowerCase() == 'driver'
                          ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                          : AppTheme.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: role.toLowerCase() == 'driver'
                            ? AppTheme.primaryBlue
                            : AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (tcFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: AppTheme.gray),
                  const SizedBox(width: 4),
                  Text(
                    'TC For: $tcFor',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.gray,
                      fontStyle: FontStyle.italic,
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
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppTheme.accentPurple),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('Failed to load history', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.gray),
            const SizedBox(height: 16),
            Text('No call history yet', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Your social media call history will appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
}
