import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../../../core/services/call_feedback_guard_service.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/easygo_ivr_call_helper.dart';
import 'search_users_screen.dart';
import '../../../widgets/draggable_floating_action_button.dart';
import '../../../widgets/error_handler.dart';

class CallBacksScreen extends StatefulWidget {
  const CallBacksScreen({super.key});

  @override
  State<CallBacksScreen> createState() => _CallBacksScreenState();
}

class _CallBacksScreenState extends State<CallBacksScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<DriverContact>? _callBackContacts;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCallBackContactsAsync();
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

  Future<void> _loadCallBackContactsAsync() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Force refresh to get latest data
      final contacts = await SmartCallingService.instance.getDriversByCategory(
        NavigationSection.callBacks,
      );

      if (mounted) {
        setState(() {
          _callBackContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _callBackContacts = [];
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
        NavigationSection.callBacks,
      );

      if (mounted) {
        setState(() {
          _callBackContacts = contacts;
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

  Future<void> _onCallPressed(DriverContact contact) async {
    HapticFeedback.mediumImpact();

    // Check for pending feedback before allowing call
    final hasPending = await CallFeedbackGuardService.instance
        .hasLastCallPendingFeedback();
    if (hasPending && mounted) {
      CallFeedbackGuardService.showPendingFeedbackToast(context);
      return;
    }

    // Show call type selection dialog
    final callType = await showDialog<String>(
      context: context,
      builder: (context) => CallTypeSelectionDialog(driverName: contact.name),
    );

    if (callType == null || !mounted) return;

    // Get current user
    final user = RealAuthService.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Log call hit
    await CallHitService.instance.logCallHit(
      contactId: contact.id,
      contactName: contact.name,
      contactType: 'driver',
      callType: callType,
      sourceScreen: 'call_backs',
      phoneNumber: contact.phoneNumber,
    );

    final callerId = int.tryParse(user.id) ?? 1;
    final cleanPhone = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    try {
      if (callType == 'manual') {
        // Manual call
        final result = await SmartCallingService.instance.initiateManualCall(
          driverMobile: cleanPhone.isEmpty ? contact.id : cleanPhone,
          callerId: callerId,
          driverId: contact.id,
          callSource: 'call_backs',
        );

        if (result['success'] == true && mounted) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];
          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _showCallFeedbackModal(contact);
        }
      } else if (callType == 'easygo_ivr') {
        // IVR call
        await EasyGoIVRCallHelper.initiateCall(
          context: context,
          clientName: contact.name,
          clientPhone: contact.phoneNumber,
          clientId: contact.id,
          tmid: contact.tmid,
          contactType: 'driver',
          callSource: 'call_backs',
          onCallEnded: () {
            if (mounted) {
              _showCallFeedbackModal(contact);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCallFeedbackModal(DriverContact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => CallFeedbackModal(
        contact: contact,
        allowDismiss: true,
        onFeedbackSubmitted: (feedback) async {
          await _handleFeedbackSubmitted(contact, feedback);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _handleFeedbackSubmitted(
    DriverContact contact,
    CallFeedback feedback,
  ) async {
    // Optimistically remove contact from list immediately for instant UI update
    if (mounted) {
      setState(() {
        _callBackContacts?.removeWhere((c) => c.id == contact.id);
      });
    }

    try {
      // Get feedback text
      final feedbackText = _getFeedbackText(feedback);

      // Simple approach: Just update the driver status in users table
      // The call_logs entry will be created/updated by the API
      final success = await SmartCallingService.instance.updateCallStatus(
        driverId: contact.id,
        status: feedback.status,
        feedback: feedbackText,
        remarks: feedback.remarks,
      );

      if (success && mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Updated ${contact.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh in background to sync with server
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _refreshData();
          }
        });
      } else if (mounted) {
        // If API call failed, add the contact back to the list
        setState(() {
          _callBackContacts?.add(contact);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update feedback'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // If error occurred, add the contact back to the list
      if (mounted) {
        setState(() {
          _callBackContacts?.add(contact);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getFeedbackText(CallFeedback feedback) {
    if (feedback.connectedFeedback != null) {
      return feedback.connectedFeedback!.displayName;
    } else if (feedback.callBackReason != null) {
      return feedback.callBackReason!.displayName;
    } else if (feedback.callBackTime != null) {
      return feedback.callBackTime!.displayName;
    }
    return feedback.status.name;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          Column(
            children: [
              _CallBacksHeader(
                contactCount: _callBackContacts?.length ?? 0,
                onRefresh: _refreshData,
                isRefreshing: _isRefreshing,
              ),
              Expanded(
                child: _isLoading
                    ? const _LoadingWidget()
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: (_callBackContacts?.isEmpty ?? true)
                            ? const _EmptyStateWidget()
                            : _ContactsList(
                                contacts: _callBackContacts!,
                                scrollController: _scrollController,
                                onCallPressed: _onCallPressed,
                              ),
                      ),
              ),
            ],
          ),
          DraggableFloatingActionButton(
            heroTag: 'callbacks_global_search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchUsersScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Optimized separate widgets
class _CallBacksHeader extends StatelessWidget {
  final int contactCount;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const _CallBacksHeader({
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
                  Colors.orange.withValues(alpha: 0.2),
                  Colors.deepOrange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.refresh_rounded,
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
                  'Call Backs',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$contactCount contacts need follow-up',
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
            color: Colors.orange,
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
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 60,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Call Backs',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacts requiring immediate\nfollow-up will appear here',
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
