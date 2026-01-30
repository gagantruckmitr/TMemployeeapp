import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/today_leads_service.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../../../core/services/easygo_ivr_service.dart';
import '../../../core/services/call_feedback_guard_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/transporter_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../widgets/manual_call_helper.dart';
import '../../../widgets/error_handler.dart';

class FreshLeadsScreen extends StatefulWidget {
  const FreshLeadsScreen({super.key});

  @override
  State<FreshLeadsScreen> createState() => _FreshLeadsScreenState();
}

class _FreshLeadsScreenState extends State<FreshLeadsScreen> {
  List<TodayLead> _leads = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  bool _isCallInProgress = false;
  TodayLead? _currentCallingLead;
  int _remainingFreshLeads = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize pending feedback check for call button visibility
    CallFeedbackGuardService.instance.getPendingCalls();
    _loadLeads(); // Load from cache first
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLeads();
    }
  }

  Future<void> _loadMoreLeads() async {
    if (_isLoadingMore || !TodayLeadsService.instance.hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final leads = await TodayLeadsService.instance.loadMoreLeads();
      if (mounted) {
        setState(() {
          _leads = leads;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Load leads - uses cache by default, API only on first load or refresh
  Future<void> _loadLeads({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get leads (from cache or API based on forceRefresh)
      final leads = await TodayLeadsService.instance.getTodayLeads(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _leads = leads;
          // Use totalRemainingFromApi for KPI display (total uncalled leads from API)
          // This shows the accurate count even with pagination
          _remainingFreshLeads =
              TodayLeadsService.instance.totalRemainingFromApi > 0
              ? TodayLeadsService.instance.totalRemainingFromApi
              : TodayLeadsService.instance.remainingFreshLeads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(
          context,
          e,
          onRetry: () => _loadLeads(forceRefresh: true),
        );
      }
    }
  }

  /// Pull-to-refresh - always fetch fresh data from API
  Future<void> _refreshLeads() async {
    await _loadLeads(forceRefresh: true);
  }

  List<TodayLead> get _filteredLeads {
    if (_searchQuery.isEmpty) return _leads;
    return _leads.where((lead) {
      final query = _searchQuery.toLowerCase();
      return lead.name.toLowerCase().contains(query) ||
          lead.nameEng.toLowerCase().contains(query) ||
          lead.mobile.contains(query) ||
          lead.uniqueId.toLowerCase().contains(query);
    }).toList();
  }

  // Convert TodayLead to DriverContact for use with DriverContactCard
  DriverContact _convertToDriverContact(TodayLead lead) {
    // Convert UTC to IST (UTC+5:30)
    DateTime? registrationDate;
    if (lead.createdAt.isNotEmpty) {
      final utcDate = DateTime.tryParse(lead.createdAt);
      if (utcDate != null) {
        // Convert to IST by adding 5 hours and 30 minutes
        registrationDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      }
    }

    // Use driverCompletion from TodayLead (comes from API)
    // This value is enriched by TodayLeadsService from profile_completion_api.php
    final completionPercentage = lead.driverCompletion;
    debugPrint(
      '🎯 Fresh Leads - Converting lead ${lead.id} (${lead.name}): profile completion = $completionPercentage%',
    );

    return DriverContact(
      id: lead.id.toString(),
      tmid: lead.uniqueId,
      name: lead.nameEng,
      company: lead.role == 'driver' ? 'Driver' : 'Transporter',
      phoneNumber: lead.mobile,
      state: lead.states ?? '0',
      subscriptionStatus: SubscriptionStatus.inactive,
      status: CallStatus.pending,
      role: lead.role,
      registrationDate: registrationDate,
      profileCompletion: ProfileCompletion(
        percentage: completionPercentage,
        documentStatus: {},
      ),
      assignedTelecaller: lead.assignedAdmin?.name,
    );
  }

  Future<void> _handleCall(TodayLead lead) async {
    if (_isCallInProgress) return;

    // Check for pending feedback before allowing call
    final hasPending = await CallFeedbackGuardService.instance
        .hasLastCallPendingFeedback();
    if (hasPending && mounted) {
      CallFeedbackGuardService.showPendingFeedbackToast(context);
      return;
    }

    setState(() {
      _isCallInProgress = true;
      _currentCallingLead = lead;
    });

    try {
      // Get current user ID
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ User not logged in. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isCallInProgress = false;
            _currentCallingLead = null;
          });
        }
        return;
      }

      final callerId = int.tryParse(currentUser.id) ?? 1;
      final contact = _convertToDriverContact(lead);

      debugPrint(
        '🔵 Fresh Leads - Starting call - Caller ID: $callerId, Contact: ${contact.name} (${contact.phoneNumber})',
      );

      // Show call type selection dialog
      if (mounted) {
        final callType = await showDialog<String>(
          context: context,
          builder: (context) =>
              CallTypeSelectionDialog(driverName: contact.name),
        );

        if (callType == null) {
          setState(() {
            _isCallInProgress = false;
            _currentCallingLead = null;
          });
          return;
        }

        // Log call hit
        print('🔵 Fresh Leads: Logging call hit for ${contact.name}');
        final logResult = await CallHitService.instance.logCallHit(
          contactId: contact.id,
          contactName: contact.name,
          contactType: lead.role,
          callType: callType,
          sourceScreen: 'fresh_leads',
          phoneNumber: contact.phoneNumber,
        );
        print('🔵 Fresh Leads: Log result: $logResult');

        if (callType == 'manual') {
          await _handleManualCall(contact, callerId, lead);
          return;
        }

        if (callType == 'easygo_ivr') {
          await _handleEasyGoIVR(contact, callerId, lead);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, onRetry: () => _handleCall(lead));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingLead = null;
        });
      }
    }
  }

  Future<void> _handleEasyGoIVR(
    DriverContact contact,
    int callerId,
    TodayLead lead,
  ) async {
    try {
      final cleanMobile = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final telecallerPhone = currentUser.mobile.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating EasyGo IVR call...'),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanMobile,
        callerId: callerId.toString(),
        contactId: contact.id,
        tmid: contact.tmid,
        contactType: lead.role,
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId =
              result['reference_id'] ??
              result['data']?['call_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ EasyGo IVR call initiated!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
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
                    // IVR overlay already pops itself, just show feedback modal
                    _showFeedbackModal(
                      contact,
                      lead,
                      referenceId: referenceId,
                      callDuration: 0,
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingLead = null;
        });
      }
    }
  }

  Future<void> _handleManualCall(
    DriverContact contact,
    int callerId,
    TodayLead lead,
  ) async {
    try {
      // Determine process based on role
      final process = lead.role == 'driver' 
          ? 'Driver Onboarding' 
          : 'Transporter Onboarding';

      // Use the new manual call helper
      await ManualCallHelper.initiateManualCall(
        context: context,
        contact: contact,
        process: process,
        showRecordingUpload: true, // Show recording upload for fresh leads
        onFeedbackSubmitted: (feedback) async {
          // Handle feedback submission using existing method
          await _updateContactStatus(contact, lead, feedback);
        },
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingLead = null;
        });
      }
    }
  }

  void _showFeedbackModal(
    DriverContact contact,
    TodayLead lead, {
    String? referenceId,
    int? callDuration,
  }) {
    // Show appropriate feedback modal based on role
    if (lead.role == 'transporter') {
      // Convert to TransporterContact for transporter feedback
      final transporterContact = TransporterContact(
        id: contact.id,
        tmid: contact.tmid,
        name: contact.name,
        company: contact.company,
        phoneNumber: contact.phoneNumber,
        state: contact.state,
        subscriptionStatus: contact.subscriptionStatus,
        status: contact.status,
        lastFeedback: contact.lastFeedback,
        lastCallTime: contact.lastCallTime,
        remarks: contact.remarks,
        paymentInfo: contact.paymentInfo,
        registrationDate: contact.registrationDate,
        profileCompletion: contact.profileCompletion,
        profilePicture: contact.profilePicture,
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => PopScope(
          canPop: false,
          child: TransporterFeedbackModal(
            contact: transporterContact,
            referenceId: referenceId,
            callDuration: callDuration,
            onFeedbackSubmitted: (feedback) {
              _updateContactStatus(
                contact,
                lead,
                feedback,
                referenceId: referenceId,
                callDuration: callDuration,
              );
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      // Driver feedback
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false, // Prevent dismissing by tapping outside
        enableDrag: false, // Prevent dragging to dismiss
        builder: (modalContext) => PopScope(
          canPop: false, // Prevent back button dismissal
          child: CallFeedbackModal(
            contact: contact,
            referenceId: referenceId,
            callDuration: callDuration,
            allowDismiss: false, // Hide close button
            onFeedbackSubmitted: (feedback) async {
              debugPrint('🔵 [FreshLeads] Feedback modal callback triggered');
              debugPrint('🔵 [FreshLeads] Feedback status: ${feedback.status}');
              debugPrint('🔵 [FreshLeads] Reference ID: $referenceId');

              try {
                // Save feedback to database using Laravel API
                final success = await _updateContactStatus(
                  contact,
                  lead,
                  feedback,
                  referenceId: referenceId,
                  callDuration: callDuration,
                );

                debugPrint('🔵 [FreshLeads] Feedback update result: $success');

                // Close modal only after everything is done
                if (modalContext.mounted) {
                  debugPrint('🔵 [FreshLeads] Closing modal...');
                  Navigator.of(modalContext).pop();
                }

                // Show success/error message
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Feedback saved for ${contact.name}'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '❌ Failed to save feedback for ${contact.name}',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                debugPrint(
                  '❌ [FreshLeads] Exception during feedback update: $e',
                );
                debugPrint('❌ [FreshLeads] Stack trace: $stackTrace');

                // Close modal on error
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
  }

  Future<bool> _updateContactStatus(
    DriverContact contact,
    TodayLead lead,
    CallFeedback feedback, {
    String? referenceId,
    int? callDuration,
  }) async {
    debugPrint('🔵 [FreshLeads] _updateContactStatus called');
    debugPrint('🔵 [FreshLeads] Contact: ${contact.name} (${contact.id})');
    debugPrint('🔵 [FreshLeads] Role: ${lead.role}');
    debugPrint('🔵 [FreshLeads] Status: ${feedback.status}');
    debugPrint('🔵 [FreshLeads] Reference ID (call_history_id): $referenceId');

    String feedbackText = '';

    if (lead.role == 'transporter') {
      switch (feedback.status) {
        case CallStatus.connected:
          feedbackText =
              feedback.transporterConnectedFeedback?.displayName ?? 'Connected';
          break;
        case CallStatus.callBack:
          feedbackText = feedback.callBackReason?.displayName ?? 'Call Back';
          break;
        default:
          feedbackText = 'Unknown';
          break;
      }
    } else {
      switch (feedback.status) {
        case CallStatus.connected:
          feedbackText = feedback.connectedFeedback?.displayName ?? 'Connected';
          break;
        case CallStatus.callBack:
          feedbackText = feedback.callBackReason?.displayName ?? 'Call Back';
          break;
        case CallStatus.callBackLater:
          feedbackText =
              feedback.callBackTime?.displayName ?? 'Call Back Later';
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
    }

    debugPrint('🔵 [FreshLeads] Feedback text: $feedbackText');
    debugPrint('🔵 [FreshLeads] Remarks: ${feedback.remarks}');

    try {
      bool success = false;

      // Map status to string for API (matching call_history_screen.dart logic)
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

      // Use Laravel API directly: ${ApiConfig.laravelApiBase}/ivr-call-update
      // referenceId is the call_history_id from the IVR call
      if (referenceId != null && referenceId.isNotEmpty) {
        final callId = int.tryParse(referenceId);

        if (callId != null) {
          debugPrint(
            '🔵 [FreshLeads] Using EasyGoIVRService.updateCall with call_id: $callId',
          );
          debugPrint('🔵 [FreshLeads] Status: $statusString');
          debugPrint('🔵 [FreshLeads] Feedback: $feedbackText');

          // Use EasyGoIVRService directly (same as call_history_screen.dart)
          final result = await EasyGoIVRService.updateCall(
            callId: callId,
            status: statusString,
            feedback: feedbackText,
            remarks: feedback.remarks,
          );

          success = result['success'] == true;
          debugPrint(
            '🔵 [FreshLeads] EasyGoIVRService.updateCall result: $result',
          );
          debugPrint('🔵 [FreshLeads] Success: $success');
        } else {
          debugPrint('⚠️ [FreshLeads] Invalid call_id format: $referenceId');
        }
      } else {
        debugPrint('🔵 [FreshLeads] No reference ID provided');
      }

      // If no referenceId or update failed, create a new call log first
      if (!success) {
        debugPrint(
          '🔄 [FreshLeads] Creating new call log via Laravel IVR API for ${contact.name}',
        );

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
            final contactType = lead.role;
            final process = contactType == 'transporter'
                ? 'Transporter Onboarding'
                : 'Driver Onboarding';

            // Create a call log using EasyGoIVRService directly
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
                  debugPrint(
                    '🔵 [FreshLeads] Created call log with ID: $callIdInt, now updating feedback...',
                  );

                  // Now update the feedback using EasyGoIVRService
                  final updateResult = await EasyGoIVRService.updateCall(
                    callId: callIdInt,
                    status: statusString,
                    feedback: feedbackText,
                    remarks: feedback.remarks,
                  );
                  success = updateResult['success'] == true;
                  debugPrint(
                    '🔵 [FreshLeads] Feedback update result: $success',
                  );
                }
              }
            } else {
              debugPrint(
                '⚠️ [FreshLeads] Failed to create call log: ${result['error']}',
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ [FreshLeads] Error creating call log: $e');
        }
      }

      // Mark lead as processed and remove from cache
      if (success && mounted) {
        // Remove from cache and mark as processed in TodayLeadsService
        // This ensures the lead won't appear again even after refresh
        TodayLeadsService.instance.removeLeadFromCache(lead.id);
        debugPrint(
          '✅ [FreshLeads] Marked lead ${lead.id} as processed in TodayLeadsService',
        );

        // Clear pending feedback cache since feedback was submitted
        CallFeedbackGuardService.instance.clearCache();

        // Update local list without API call
        setState(() {
          _leads.removeWhere((l) => l.id == lead.id);
          // Update remaining count from service
          _remainingFreshLeads =
              TodayLeadsService.instance.totalRemainingFromApi > 0
              ? TodayLeadsService.instance.totalRemainingFromApi
              : TodayLeadsService.instance.remainingFreshLeads;
        });
        HapticFeedback.lightImpact();
      }

      debugPrint('🔵 [FreshLeads] Final success status: $success');
      return success;
    } catch (e, stackTrace) {
      debugPrint('❌ [FreshLeads] Error saving feedback: $e');
      debugPrint('❌ [FreshLeads] Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Fresh Leads',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, or ID...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Stats header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_filteredLeads.length} Lead${_filteredLeads.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_callback,
                        color: AppTheme.primaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Remaining: $_remainingFreshLeads',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leads list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLeads.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshLeads,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _filteredLeads.length +
                          (_isLoadingMore ||
                                  TodayLeadsService.instance.hasMorePages
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom
                        if (index == _filteredLeads.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: _isLoadingMore
                                  ? const CircularProgressIndicator()
                                  : TodayLeadsService.instance.hasMorePages
                                  ? TextButton(
                                      onPressed: _loadMoreLeads,
                                      child: const Text('Load More'),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }

                        final lead = _filteredLeads[index];
                        final contact = _convertToDriverContact(lead);
                        final isCallInProgress =
                            _isCallInProgress &&
                            _currentCallingLead?.id == lead.id;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _filteredLeads.length - 1 ? 12 : 0,
                          ),
                          child: DriverContactCard(
                            contact: contact,
                            onCallPressed: () => _handleCall(lead),
                            isCallInProgress: isCallInProgress,
                            showPhoneNumber: true,
                            showAssignedTo: false,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No fresh leads' : 'No leads found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Fresh leads will appear here'
                : 'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
