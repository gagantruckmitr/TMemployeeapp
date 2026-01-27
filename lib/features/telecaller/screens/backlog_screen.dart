import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../../../core/services/easygo_ivr_service.dart';
import '../../../core/services/backlog_cache_service.dart';
import '../../../core/services/call_feedback_guard_service.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../widgets/call_feedback_modal.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../widgets/error_handler.dart';

class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen>
    with AutomaticKeepAliveClientMixin {
  List<DriverContact>? _backlogLeads;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _processedLeadIds = {};
  final _cacheService = BacklogCacheService.instance;
  String? _callingLeadId; // Track which lead is currently being called

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize pending feedback check for call button visibility
    CallFeedbackGuardService.instance.getPendingCalls();
    _loadBacklogLeadsWithCache();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load leads from cache first, then API if needed
  Future<void> _loadBacklogLeadsWithCache() async {
    if (!mounted) return;

    final currentUser = RealAuthService.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _backlogLeads = [];
        _isLoading = false;
      });
      return;
    }

    final callerId = int.tryParse(currentUser.id) ?? 1;

    // Check memory cache first
    if (_cacheService.hasCachedData(callerId)) {
      final cachedLeads = _cacheService.getCachedLeads(callerId);
      if (cachedLeads != null && cachedLeads.isNotEmpty) {
        debugPrint('📦 Loading ${cachedLeads.length} leads from memory cache');
        setState(() {
          _backlogLeads = cachedLeads
              .where((lead) => !_processedLeadIds.contains(lead.id))
              .toList();
          _isLoading = false;
        });
        return;
      }
    }

    // Try loading from local storage
    final storedLeads = await _cacheService.loadFromStorage(callerId);
    if (storedLeads != null && storedLeads.isNotEmpty) {
      debugPrint('💾 Loading ${storedLeads.length} leads from local storage');
      setState(() {
        _backlogLeads = storedLeads
            .where((lead) => !_processedLeadIds.contains(lead.id))
            .toList();
        _isLoading = false;
      });
      return;
    }

    // No cache, fetch from API
    await _fetchFromApi(callerId);
  }

  /// Fetch fresh data from API
  Future<void> _fetchFromApi(int callerId) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final token = await RealAuthService.instance.getAuthToken();
      debugPrint('🌐 Fetching backlog from API for caller $callerId');

      final url =
          'https://development.truckmitr.com/api/telehead/withoutCallHistory?admin_id=$callerId';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data['success'] == true && data['data'] is List) {
          final List<dynamic> leadsData = data['data'];

          final leads = leadsData.map((leadJson) {
            return DriverContact.fromBacklogJson(leadJson);
          }).toList();

          // Sort by registration date - newest first
          leads.sort((a, b) {
            final dateA = a.registrationDate ?? DateTime(2000);
            final dateB = b.registrationDate ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          // Cache the data
          await _cacheService.cacheLeads(leads, callerId);
          debugPrint('✅ Cached ${leads.length} leads');

          if (mounted) {
            setState(() {
              _backlogLeads = leads
                  .where((lead) => !_processedLeadIds.contains(lead.id))
                  .toList();
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching backlog: $e');

      if (mounted) {
        setState(() {
          _backlogLeads ??= [];
          _isLoading = false;
        });
      }
    }
  }

  /// Pull-to-refresh - always fetch fresh data from API
  Future<void> _refreshData() async {
    final currentUser = RealAuthService.instance.currentUser;
    if (currentUser == null) return;

    final callerId = int.tryParse(currentUser.id) ?? 1;
    await _fetchFromApi(callerId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _backlogLeads == null || _backlogLeads!.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _backlogLeads!.length,
                        itemBuilder: (context, index) {
                          final lead = _backlogLeads![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DriverContactCard(
                              contact: lead,
                              onCallPressed: () => _initiateCall(lead),
                              isCallInProgress: _callingLeadId == lead.id,
                              callbackHistory: lead.callbackHistory,
                              callbackRequestsCount:
                                  lead.callbackRequestsCount ?? 0,
                              showPhoneNumber: false,
                              showAssignedTo: false,
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

  Widget _buildHeader() {
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
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.hourglass_bottom_rounded,
              color: Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backlog',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leads with callback scheduled',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_backlogLeads != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_backlogLeads!.length}',
                style: AppTheme.titleMedium.copyWith(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
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
            'No Backlog',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No leads with callback scheduled',
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

    // Prevent multiple calls at once
    if (_callingLeadId != null) return;

    // Check for pending feedback before allowing call
    final hasPending = await CallFeedbackGuardService.instance
        .hasLastCallPendingFeedback();
    if (hasPending && mounted) {
      CallFeedbackGuardService.showPendingFeedbackToast(context);
      return;
    }

    // Set loading state
    setState(() {
      _callingLeadId = lead.id;
    });

    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() => _callingLeadId = null);
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

      if (mounted) {
        final callType = await showDialog<String>(
          context: context,
          builder: (context) => CallTypeSelectionDialog(driverName: lead.name),
        );

        if (callType == null) {
          // User cancelled the dialog
          setState(() => _callingLeadId = null);
          return;
        }

        await CallHitService.instance.logCallHit(
          contactId: lead.id,
          contactName: lead.name,
          contactType: lead.role ?? 'driver',
          callType: callType,
          sourceScreen: 'backlog',
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
        setState(() => _callingLeadId = null);
        ErrorHandler.showError(context, e, onRetry: () => _initiateCall(lead));
      }
    }
  }

  Future<void> _handleManualCall(DriverContact lead, int callerId) async {
    try {
      final cleanMobile = lead.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final contactType = lead.role ?? 'driver';
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        setState(() => _callingLeadId = null);
        return;
      }

      final telecallerPhone = currentUser.mobile.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final process = contactType == 'transporter'
          ? 'Transporter Onboarding'
          : 'Driver Onboarding';

      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanMobile,
        callerId: callerId.toString(),
        contactId: lead.id,
        tmid: lead.tmid,
        contactType: contactType,
        process: process,
        driverName: lead.name,
      );

      // Clear loading state before showing feedback modal
      if (mounted) {
        setState(() => _callingLeadId = null);
      }

      if (mounted) {
        if (result['success'] == true) {
          final referenceId =
              result['call_id']?.toString() ??
              result['reference_id']?.toString() ??
              result['data']?['call_history_id']?.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${lead.name}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          await FlutterPhoneDirectCaller.callNumber(cleanMobile);
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            _showFeedbackModal(lead, referenceId: referenceId);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${lead.name}... (untracked)'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );

          await FlutterPhoneDirectCaller.callNumber(cleanMobile);
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            _showFeedbackModal(lead, referenceId: null);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _callingLeadId = null);
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _handleIVRCall(DriverContact lead, int callerId) async {
    try {
      final cleanMobile = lead.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        setState(() => _callingLeadId = null);
        return;
      }

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

      final contactType = lead.role ?? 'driver';
      final process = contactType == 'transporter'
          ? 'Transporter Onboarding'
          : 'Driver Onboarding';

      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanMobile,
        callerId: callerId.toString(),
        contactId: lead.id,
        tmid: lead.tmid,
        contactType: contactType,
        process: process,
        driverName: lead.name,
      );

      // Clear loading state
      if (mounted) {
        setState(() => _callingLeadId = null);
      }

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
        setState(() => _callingLeadId = null);
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
      builder: (modalContext) => PopScope(
        canPop: false,
        child: CallFeedbackModal(
          contact: lead,
          referenceId: referenceId,
          allowDismiss: false,
          onFeedbackSubmitted: (feedback) async {
            try {
              final success = await _updateContactStatus(
                lead,
                feedback,
                referenceId: referenceId,
              );

              if (modalContext.mounted) {
                Navigator.of(modalContext).pop();
              }

              if (success && mounted) {
                HapticFeedback.lightImpact();
                setState(() {
                  _processedLeadIds.add(lead.id);
                  _backlogLeads?.removeWhere((c) => c.id == lead.id);
                });
                // Also remove from cache
                _cacheService.removeLeadFromCache(lead.id);
                // Clear pending feedback cache since feedback was submitted
                CallFeedbackGuardService.instance.clearCache();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Feedback saved for ${lead.name}'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Failed to save feedback for ${lead.name}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              if (modalContext.mounted) {
                Navigator.of(modalContext).pop();
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<bool> _updateContactStatus(
    DriverContact contact,
    CallFeedback feedback, {
    String? referenceId,
  }) async {
    String feedbackText = '';

    switch (feedback.status) {
      case CallStatus.connected:
        feedbackText = feedback.connectedFeedback?.displayName ?? 'Connected';
        break;
      case CallStatus.callBack:
        feedbackText = feedback.callBackReason?.displayName ?? 'Call Back';
        break;
      case CallStatus.callBackLater:
        feedbackText = feedback.callBackTime?.displayName ?? 'Call Back Later';
        break;
      case CallStatus.notReachable:
        feedbackText = 'Not Reachable';
        break;
      case CallStatus.notInterested:
        feedbackText = 'Not Interested';
        break;
      case CallStatus.invalid:
        feedbackText = 'Invalid Number';
        break;
      case CallStatus.pending:
        feedbackText = 'Pending';
        break;
    }

    try {
      bool success = false;

      String statusString = 'not_connected';
      switch (feedback.status) {
        case CallStatus.connected:
          statusString = 'connected';
          break;
        case CallStatus.callBack:
          statusString = 'not_connected';
          break;
        case CallStatus.callBackLater:
          statusString = 'callback_later';
          break;
        case CallStatus.notReachable:
          statusString = 'not_connected';
          break;
        case CallStatus.notInterested:
          statusString = 'connected';
          break;
        case CallStatus.invalid:
          statusString = 'not_connected';
          break;
        case CallStatus.pending:
          statusString = 'not_connected';
          break;
      }

      if (referenceId != null && referenceId.isNotEmpty) {
        final callId = int.tryParse(referenceId);

        if (callId != null) {
          final result = await EasyGoIVRService.updateCall(
            callId: callId,
            status: statusString,
            feedback: feedbackText,
            remarks: feedback.remarks,
          );

          success = result['success'] == true;
        }
      }

      if (!success) {
        try {
          final currentUser = RealAuthService.instance.currentUser;
          if (currentUser != null) {
            final callerId = int.tryParse(currentUser.id) ?? 1;
            final telecallerPhone = currentUser.mobile.replaceAll(
              RegExp(r'[^\d]'),
              '',
            );
            final cleanMobile = contact.phoneNumber.replaceAll(
              RegExp(r'[^\d]'),
              '',
            );
            final contactType = contact.role ?? 'driver';
            final process = contactType == 'transporter'
                ? 'Transporter Onboarding'
                : 'Driver Onboarding';

            final result = await EasyGoIVRService.initiateCall(
              exten: telecallerPhone,
              number: cleanMobile,
              callerId: callerId.toString(),
              contactId: contact.id,
              tmid: contact.tmid,
              process: process,
              driverName: contact.name,
            );

            if (result['success'] == true) {
              final newCallId = result['call_id'] ?? result['reference_id'];
              if (newCallId != null) {
                final callIdInt = int.tryParse(newCallId.toString());
                if (callIdInt != null) {
                  final updateResult = await EasyGoIVRService.updateCall(
                    callId: callIdInt,
                    status: statusString,
                    feedback: feedbackText,
                    remarks: feedback.remarks,
                  );
                  success = updateResult['success'] == true;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error creating call log: $e');
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error saving feedback: $e');
      return false;
    }
  }
}
