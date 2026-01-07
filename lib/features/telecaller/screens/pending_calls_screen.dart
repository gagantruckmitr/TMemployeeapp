import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../widgets/call_feedback_modal.dart';
import '../../../widgets/error_handler.dart';

class PendingCallsScreen extends StatefulWidget {
  const PendingCallsScreen({super.key});

  @override
  State<PendingCallsScreen> createState() => _PendingCallsScreenState();
}

class _PendingCallsScreenState extends State<PendingCallsScreen>
    with AutomaticKeepAliveClientMixin {
  List<DriverContact>? _pendingLeads;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPendingLeads();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingLeads() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final leads = await SmartCallingService.instance.getDrivers(
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _pendingLeads = leads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingLeads = [];
          _isLoading = false;
        });
        ErrorHandler.showError(context, e, onRetry: _loadPendingLeads);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadPendingLeads();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Calls',
                              style: AppTheme.headingMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leads not yet called',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pendingLeads != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_pendingLeads!.length}',
                            style: AppTheme.titleMedium.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingLeads == null || _pendingLeads!.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingLeads!.length,
                        itemBuilder: (context, index) {
                          final lead = _pendingLeads![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DriverContactCard(
                              contact: lead,
                              onCallPressed: () => _initiateCall(lead),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Pending Calls',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All assigned leads have been called',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateCall(DriverContact lead) async {
    HapticFeedback.lightImpact();

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
          builder: (context) => CallTypeSelectionDialog(driverName: lead.name),
        );

        if (callType == null) return;

        // Log call hit
        await CallHitService.instance.logCallHit(
          contactId: lead.id,
          contactName: lead.name,
          contactType: 'driver',
          callType: callType,
          sourceScreen: 'pending_calls',
          phoneNumber: lead.phoneNumber,
        );

        if (callType == 'manual') {
          await _handleManualCall(lead, callerId);
        } else if (callType == 'easygo_ivr' || callType == 'click2call') {
          await _handleIVRCall(lead, callerId);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, onRetry: () => _initiateCall(lead));
      }
    }
  }

  Future<void> _handleManualCall(DriverContact lead, int callerId) async {
    try {
      final cleanMobile = lead.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: lead.id,
      );

      if (mounted) {
        if (result['success'] == true) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];
          final referenceId = result['data']?['reference_id'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${lead.name}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            _showFeedbackModal(lead, referenceId: referenceId);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _handleIVRCall(DriverContact lead, int callerId) async {
    try {
      final cleanMobile = lead.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
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
        contactId: lead.id,
        tmid: lead.tmid,
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
                  driverName: lead.name,
                  referenceId: referenceId,
                  onCallEnded: () {
                    Navigator.of(context).pop();
                    _showFeedbackModal(lead, referenceId: referenceId);
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
        ErrorHandler.showError(context, e);
      }
    }
  }

  void _showFeedbackModal(DriverContact lead, {String? referenceId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PopScope(
        canPop: false,
        child: CallFeedbackModal(
          contact: lead,
          referenceId: referenceId,
          onFeedbackSubmitted: (feedback) async {
            // Remove lead from list after feedback
            setState(() {
              _pendingLeads?.removeWhere((c) => c.id == lead.id);
            });
            Navigator.of(context).pop();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Call completed for ${lead.name}'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }
}
