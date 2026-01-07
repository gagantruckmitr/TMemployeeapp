import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/smart_calling_service.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_feedback_modal.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../../../widgets/error_handler.dart';

class CallBackLaterScreen extends StatefulWidget {
  const CallBackLaterScreen({super.key});

  @override
  State<CallBackLaterScreen> createState() => _CallBackLaterScreenState();
}

class _CallBackLaterScreenState extends State<CallBackLaterScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<DriverContact>? _callBackLaterContacts;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCallBackLaterContactsAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _loadCallBackLaterContactsAsync() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Force refresh to get latest data
      final contacts = await SmartCallingService.instance.getDriversByCategory(
        NavigationSection.callBackLater,
      );

      if (mounted) {
        setState(() {
          _callBackLaterContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _callBackLaterContacts = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Clear cache and fetch fresh data
      SmartCallingService.instance.clearCache();
      final contacts = await SmartCallingService.instance.getDriversByCategory(
        NavigationSection.callBackLater,
      );

      if (mounted) {
        setState(() {
          _callBackLaterContacts = contacts;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ErrorHandler.showError(context, e, onRetry: _refreshData);
      }
    }
  }

  void _onCallPressed(DriverContact contact) {
    HapticFeedback.mediumImpact();
    _initiateCall(contact);
  }

  Future<void> _initiateCall(DriverContact contact) async {
    try {
      // Get current user
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ User not logged in. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final callerId = int.tryParse(currentUser.id) ?? 1;

      // Show call type selection dialog
      if (mounted) {
        final callType = await showDialog<String>(
          context: context,
          builder: (context) =>
              CallTypeSelectionDialog(driverName: contact.name),
        );

        if (callType == null) return;

        // Log call hit
        await CallHitService.instance.logCallHit(
          contactId: contact.id,
          contactName: contact.name,
          contactType: 'driver',
          callType: callType,
          sourceScreen: 'call_back_later',
          phoneNumber: contact.phoneNumber,
        );

        if (callType == 'manual') {
          await _handleManualCall(contact, callerId);
        } else if (callType == 'easygo_ivr' || callType == 'click2call') {
          await _handleIVRCall(contact, callerId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleManualCall(DriverContact contact, int callerId) async {
    try {
      final cleanMobile = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: contact.id,
      );

      if (mounted) {
        if (result['success'] == true) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];
          final referenceId = result['data']?['reference_id'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${contact.name}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            _showCallFeedbackModal(contact, referenceId: referenceId);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleIVRCall(DriverContact contact, int callerId) async {
    try {
      final cleanMobile = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) return;

      final telecallerPhone = currentUser.mobile.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating IVR call...'),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanMobile,
        callerId: callerId.toString(),
        contactId: contact.id,
        tmid: contact.tmid,
        contactType: 'driver',
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId =
              result['reference_id'] ??
              result['data']?['call_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ IVR call initiated! Both phones will ring.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: contact.name,
                  referenceId: referenceId,
                  onCallEnded: () {
                    Navigator.of(context).pop();
                    _showCallFeedbackModal(contact, referenceId: referenceId);
                  },
                ),
              ),
            ),
          );
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate IVR call: $errorMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCallFeedbackModal(DriverContact contact, {String? referenceId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PopScope(
        canPop: false,
        child: CallFeedbackModal(
          contact: contact,
          referenceId: referenceId,
          onFeedbackSubmitted: (feedback) async {
            await _handleFeedbackSubmitted(
              contact,
              feedback,
              referenceId: referenceId,
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _handleFeedbackSubmitted(
    DriverContact contact,
    CallFeedback feedback, {
    String? referenceId,
  }) async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Saving feedback...'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Build complete feedback text with all details
    final feedbackText = _buildCompleteFeedbackText(feedback);

    // Update via API with complete feedback
    final success = await SmartCallingService.instance.updateCallStatus(
      driverId: contact.id,
      status: feedback.status,
      feedback: feedbackText,
      remarks: feedback.remarks,
    );

    // Update call history feedback if referenceId is present
    if (referenceId != null) {
      await SmartCallingService.instance.updateCallFeedback(
        referenceId: referenceId,
        callStatus: feedback.status.name,
        feedback: feedbackText,
        remarks: feedback.remarks,
        driverName: contact.name,
      );
    }

    if (success) {
      // Refresh the list to get updated data
      await _refreshData();

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Updated ${contact.name}\n$feedbackText')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to save feedback'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _buildCompleteFeedbackText(CallFeedback feedback) {
    final parts = <String>[];

    // Add status
    parts.add('Status: ${feedback.status.name}');

    // Add specific feedback based on status
    if (feedback.connectedFeedback != null) {
      parts.add('Feedback: ${feedback.connectedFeedback!.displayName}');
    } else if (feedback.callBackReason != null) {
      parts.add('Reason: ${feedback.callBackReason!.displayName}');
    } else if (feedback.callBackTime != null) {
      parts.add('Time: ${feedback.callBackTime!.displayName}');
    }

    // Add remarks if present
    if (feedback.remarks != null && feedback.remarks!.isNotEmpty) {
      parts.add('Notes: ${feedback.remarks}');
    }

    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _CallBackLaterHeader(
            contactCount: _callBackLaterContacts?.length ?? 0,
            onRefresh: _refreshData,
            isRefreshing: _isRefreshing,
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: (_callBackLaterContacts?.isEmpty ?? true)
                        ? const _EmptyStateWidget()
                        : _ContactsList(
                            contacts: _callBackLaterContacts!,
                            scrollController: _scrollController,
                            onCallPressed: _onCallPressed,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Optimized separate widgets
class _CallBackLaterHeader extends StatelessWidget {
  final int contactCount;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const _CallBackLaterHeader({
    required this.contactCount,
    required this.onRefresh,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.deepPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call Back Later',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$contactCount scheduled callbacks',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            color: Colors.purple,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _ContactsList extends StatelessWidget {
  final List<DriverContact> contacts;
  final ScrollController scrollController;
  final Function(DriverContact) onCallPressed;

  const _ContactsList({
    required this.contacts,
    required this.scrollController,
    required this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DriverContactCard(
            key: ValueKey(contact.id),
            contact: contact,
            onCallPressed: () => onCallPressed(contact),
          ),
        );
      },
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 60,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Scheduled Callbacks',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacts scheduled for later\ncallbacks will appear here',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
