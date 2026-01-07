import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';

import '../../../core/services/social_media_service.dart';
import '../../../core/services/social_media_feedback_service.dart';
import '../../../core/services/social_media_ivr_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../models/social_media_lead_model.dart';
import '../../../models/smart_calling_models.dart';
import '../../../widgets/access_denied_screen.dart';
import '../../../widgets/audio_player_widget.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final SocialMediaService _service = SocialMediaService.instance;

  late TabController _tabController;

  List<SocialMediaLead> _leads = [];
  List<Map<String, dynamic>> _history = [];

  bool _isLoadingLeads = true;
  bool _isLoadingHistory = true;
  bool _isRefreshing = false;

  String? _leadsError;
  String? _historyError;

  bool _hasAccess = false;
  bool _checkingAccess = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAccess();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    setState(() => _checkingAccess = true);

    try {
      setState(() {
        _hasAccess = true;
        _checkingAccess = false;
      });
      _loadLeads();
    } catch (e) {
      setState(() {
        _hasAccess = true;
        _checkingAccess = false;
      });
      _loadLeads();
    }
  }

  Future<void> _loadLeads() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLeads = true;
      _leadsError = null;
    });

    try {
      final results = await _service.fetchSocialMediaLeads();
      if (!mounted) return;

      results.sort((a, b) => b.chatDateTime.compareTo(a.chatDateTime));

      setState(() {
        _leads = results;
        _isLoadingLeads = false;
      });
    } catch (error) {
      if (!mounted) return;

      final errorMessage = error.toString();
      if (errorMessage.contains('Access denied') ||
          errorMessage.contains('403')) {
        setState(() {
          _hasAccess = false;
          _isLoadingLeads = false;
          _leadsError = null;
        });
      } else {
        setState(() {
          _leadsError = errorMessage;
          _isLoadingLeads = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      final assignedId = int.tryParse(currentUser.id) ?? 0;

      final result = await SocialMediaIVRService.fetchCallHistory(
        assignedId: assignedId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final List<dynamic> historyList = data['data']['data'] ?? [];

        setState(() {
          _history = List<Map<String, dynamic>>.from(historyList);
          _isLoadingHistory = false;
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to load history');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _historyError = error.toString();
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      if (_tabController.index == 0) {
        await _loadLeads();
      } else {
        await _loadHistory();
      }
    } catch (e) {
      // Errors handled in individual load methods
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
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

  Future<void> _onCallPressed(SocialMediaLead lead) async {
    await _startCall(lead);
  }

  Future<void> _startCall(SocialMediaLead lead) async {
    try {
      final contact = _mapLeadToDriverContact(lead);

      if (!mounted) return;

      final callType = await showDialog<String>(
        context: context,
        builder: (context) => CallTypeSelectionDialog(driverName: lead.name),
      );

      if (callType == null || !mounted) return;

      if (callType == 'manual') {
        await _handleManualCall(lead, contact);
      } else if (callType == 'easygo_ivr') {
        await _handleIVRCall(lead, contact);
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
        _showManualCallFeedbackModal(contact, lead);
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
          await _handleManualFeedbackSubmitted(contact, lead, feedback);
        },
      ),
    );
  }

  Future<void> _handleManualFeedbackSubmitted(
    DriverContact contact,
    SocialMediaLead lead,
    CallFeedback feedback,
  ) async {
    if (!mounted) return;

    final result = await SocialMediaFeedbackService.instance.submitFeedback(
      lead: lead,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      setState(() {
        _leads.removeWhere((l) => l.id == lead.id);
      });

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
          await _handleIVRFeedbackSubmitted(contact, lead, feedback, callLogId);
        },
      ),
    );
  }

  Future<void> _handleIVRFeedbackSubmitted(
    DriverContact contact,
    SocialMediaLead lead,
    CallFeedback feedback,
    String? callLogId,
  ) async {
    if (!mounted) return;

    print('🔵 [Social Media Feedback] Starting submission...');
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

    print('🔵 [Social Media Feedback] Mapped values:');
    print('   Status String: "$statusString"');
    print('   Feedback String: "$feedbackString"');
    print('   Remarks: "${feedback.remarks ?? ''}"');

    // If we have a callLogId, update via Social Media IVR API
    if (callLogId != null && callLogId.isNotEmpty) {
      final callId = int.tryParse(callLogId);
      if (callId != null) {
        print(
          '🔵 [Social Media] Updating call feedback via social-media-ivr-call-update API',
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

        print('🔵 [Social Media] Update API Result: $result');

        if (!mounted) return;

        HapticFeedback.lightImpact();

        if (result['success'] == true) {
          print('✅ [Social Media] Feedback saved successfully');

          // Remove lead from list
          setState(() {
            _leads.removeWhere((l) => l.id == lead.id);
          });

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
          print('❌ [Social Media] Feedback save failed: ${result['error']}');
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
      '⚠️ [Social Media] No callLogId, falling back to social_media_feedback_api',
    );
    final result = await SocialMediaFeedbackService.instance.submitFeedback(
      lead: lead,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      setState(() {
        _leads.removeWhere((l) => l.id == lead.id);
      });

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
    super.build(context);

    if (_checkingAccess) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF007AFF),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!_hasAccess) {
      return AccessDeniedScreen(
        title: 'Leads',
        message:
            'Unable to load leads.\n\nPlease contact your administrator if you believe you should have access.',
        icon: Icons.people_outline,
        onContactAdmin: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please contact your administrator for assistance'),
              backgroundColor: Color(0xFF007AFF),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppleHeader(),
            _buildSegmentedControl(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLeadsTab(), _buildHistoryTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleHeader() {
    final count = _tabController.index == 0 ? _leads.length : _history.length;
    final isLoading = _tabController.index == 0
        ? _isLoadingLeads
        : _isLoadingHistory;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leads',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? 'Loading...'
                      : '$count ${_tabController.index == 0 ? 'leads' : 'calls'}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isRefreshing ? null : _refresh,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: _isRefreshing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF007AFF),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF007AFF),
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSegmentButton(0, 'New Leads'),
          _buildSegmentButton(1, 'History'),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _tabController.animateTo(index);
          });
          if (index == 1 && _history.isEmpty && !_isLoadingHistory) {
            _loadHistory();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF000000)
                  : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadsTab() {
    if (_isLoadingLeads) {
      return const _AppleLoadingView();
    }

    if (_leadsError != null) {
      return _AppleErrorView(message: _leadsError!, onRetry: _loadLeads);
    }

    if (_leads.isEmpty) {
      return const _AppleEmptyView(
        icon: Icons.check_circle_outline_rounded,
        title: 'All Caught Up!',
        message: 'You\'ve processed all leads.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeads,
      color: const Color(0xFF007AFF),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _leads.length,
        itemBuilder: (context, index) {
          final lead = _leads[index];
          return _AppleLeadCard(
            lead: lead,
            onCall: () => _onCallPressed(lead),
            onCopyNumber: _copyNumber,
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const _AppleLoadingView();
    }

    if (_historyError != null) {
      return _AppleErrorView(message: _historyError!, onRetry: _loadHistory);
    }

    if (_history.isEmpty) {
      return const _AppleEmptyView(
        icon: Icons.history_rounded,
        title: 'No History Yet',
        message: 'Your call history will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF007AFF),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final call = _history[index];
          return _AppleHistoryCard(call: call, onCopyNumber: _copyNumber);
        },
      ),
    );
  }
}

// Apple-style Lead Card - Clean white design with call icon top-right, date bottom-right, reason bottom-left
class _AppleLeadCard extends StatelessWidget {
  const _AppleLeadCard({
    required this.lead,
    required this.onCall,
    required this.onCopyNumber,
  });

  final SocialMediaLead lead;
  final VoidCallback onCall;
  final ValueChanged<String> onCopyNumber;

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final lastFour = phone.substring(phone.length - 4);
    return '******$lastFour';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('h:mm a');
    final time = timeFormat.format(dateTime);

    if (dateToCheck == today) {
      return 'Today, $time';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    } else {
      final dateFormat = DateFormat('d MMM yyyy');
      return '${dateFormat.format(dateTime)}, $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskPhone(lead.mobile);
    final formattedDate = _formatDateTime(lead.chatDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name/Phone + Call Button (top-right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: lead.name.isNotEmpty
                        ? Text(
                            lead.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF3C3C43),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFF8E8E93),
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => onCopyNumber(lead.mobile),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              maskedPhone,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8E8E93),
                                letterSpacing: 0.5,
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
                      ),
                    ],
                  ),
                ),

                // Call Button (circular, top-right)
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
                          color: const Color(0xFF34C759).withOpacity(0.3),
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
              ],
            ),

            const SizedBox(height: 12),

            // Tags Row
            Row(
              children: [
                _buildTag(lead.source, isPrimary: true),
                const SizedBox(width: 8),
                _buildTag(lead.role, isPrimary: false),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Row: Reason (left) + Date (right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Reason/Remarks (bottom-left)
                Expanded(
                  child: lead.remarks != null && lead.remarks!.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lead.remarks!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF3C3C43),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Date (bottom-right)
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0xFF007AFF).withOpacity(0.1)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isPrimary ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
        ),
      ),
    );
  }
}

// Apple-style History Card
class _AppleHistoryCard extends StatelessWidget {
  const _AppleHistoryCard({required this.call, required this.onCopyNumber});

  final Map<String, dynamic> call;
  final ValueChanged<String> onCopyNumber;

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final lastFour = phone.substring(phone.length - 4);
    return '******$lastFour';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('h:mm a');
    final time = timeFormat.format(dateTime);

    if (dateToCheck == today) {
      return 'Today, $time';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    } else {
      final dateFormat = DateFormat('d MMM yyyy');
      return '${dateFormat.format(dateTime)}, $time';
    }
  }

  Color _getFeedbackColor(String feedback) {
    final lower = feedback.toLowerCase();
    if (lower.contains('interested') || lower.contains('connected')) {
      return const Color(0xFF34C759);
    } else if (lower.contains('not interested') || lower.contains('rejected')) {
      return const Color(0xFFFF3B30);
    } else if (lower.contains('callback') || lower.contains('later')) {
      return const Color(0xFFFF9500);
    }
    return const Color(0xFF8E8E93);
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('connected') && !lower.contains('not')) {
      return const Color(0xFF34C759); // Green
    } else if (lower.contains('not') || lower.contains('failed')) {
      return const Color(0xFFFF3B30); // Red
    } else if (lower.contains('back')) {
      return const Color(0xFFFF9500); // Yellow/Orange
    } else if (lower.contains('ringing')) {
      return const Color(0xFF007AFF); // Blue
    }
    return const Color(0xFF8E8E93); // Gray
  }

  @override
  Widget build(BuildContext context) {
    // New API Fields Mapping
    final name = call['name']?.toString() ?? 'Unknown';
    final mobile = call['mobile']?.toString() ?? '';
    final feedback =
        call['call_feedbacks']?.toString() ??
        call['feedback']?.toString() ?? // Fallback
        'No feedback';
    final remarks =
        call['call_remarks']?.toString() ??
        call['remarks']?.toString() ??
        ''; // Fallback
    final createdAt = call['created_at']?.toString() ?? '';
    final source = call['source']?.toString() ?? 'Social Media';
    final role = call['role']?.toString() ?? '';
    final status = call['call_status']?.toString() ?? '';

    DateTime? callDate;
    try {
      callDate = DateTime.parse(createdAt);
    } catch (e) {
      callDate = null;
    }

    final feedbackColor = _getFeedbackColor(feedback);
    final statusColor = _getStatusColor(status);
    final maskedMobile = _maskPhone(mobile);
    final formattedDate = callDate != null ? _formatDateTime(callDate) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name/Phone
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: name.isNotEmpty
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF3C3C43),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFF8E8E93),
                            size: 24,
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => onCopyNumber(mobile),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              maskedMobile,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8E8E93),
                                letterSpacing: 0.5,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: feedbackColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: feedbackColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    source,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
              ],
            ),

            // Remarks if exists
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  remarks,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3C3C43),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Audio Player if exists
            if (call['manual_call_recording_url']?.toString().isNotEmpty ==
                true) ...[
              const SizedBox(height: 12),
              AudioPlayerWidget(
                recordingUrl: call['manual_call_recording_url'].toString(),
                label: 'Call Recording',
              ),
            ],

            // Date at bottom-right
            if (formattedDate.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Apple-style Loading View
class _AppleLoadingView extends StatelessWidget {
  const _AppleLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF007AFF),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Apple-style Error View
class _AppleErrorView extends StatelessWidget {
  const _AppleErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to Load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Apple-style Empty View
class _AppleEmptyView extends StatelessWidget {
  const _AppleEmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF007AFF)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
