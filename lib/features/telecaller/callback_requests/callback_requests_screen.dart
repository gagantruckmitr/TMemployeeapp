import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/callback_requests_service.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/call_feedback_guard_service.dart';
import '../../../models/database_models.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/transporter_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/easygo_ivr_call_helper.dart';
import '../widgets/tab_page_header.dart';

import '../screens/search_users_screen.dart';
import '../../../widgets/draggable_floating_action_button.dart';
import '../widgets/driver_contact_card.dart';

class CallbackRequestsScreen extends StatefulWidget {
  const CallbackRequestsScreen({super.key});

  @override
  State<CallbackRequestsScreen> createState() => _CallbackRequestsScreenState();
}

class _CallbackRequestsScreenState extends State<CallbackRequestsScreen>
    with AutomaticKeepAliveClientMixin {
  final CallbackRequestsService _service = CallbackRequestsService.instance;

  List<CallbackRequest> _requests = [];
  List<CallbackRequest> _history = [];
  bool _isLoadingRequests = true;
  bool _isLoadingHistory = true;
  bool _isRefreshing = false;
  String? _requestsError;
  String? _historyError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize pending feedback check for call button visibility
    CallFeedbackGuardService.instance.getPendingCalls();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadRequests();
    _loadHistory();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRequests = true;
      _requestsError = null;
    });

    try {
      final results = await _service.fetchCallbackRequests();
      if (!mounted) return;
      setState(() {
        _requests = results;
        _isLoadingRequests = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error loading callback requests: $error');
      setState(() {
        _requestsError = 'Unable to load callback requests';
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final results = await _service.fetchCallbackHistory();
      if (!mounted) return;
      setState(() {
        _history = results;
        _isLoadingHistory = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error loading callback history: $error');
      setState(() {
        _historyError = 'Unable to load history';
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        _service.fetchCallbackRequests().then((r) {
          if (mounted) setState(() => _requests = r);
        }),
        _service.fetchCallbackHistory().then((h) {
          if (mounted) setState(() => _history = h);
        }),
      ]);
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _requestsError = null;
        _historyError = null;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error refreshing: $error');
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to refresh. Please try again.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onCallPressed(CallbackRequest request) async {
    await _callDriver(request);
  }

  Future<void> _callDriver(CallbackRequest request) async {
    try {
      // Check for pending feedback before allowing call
      final hasPending = await CallFeedbackGuardService.instance.hasLastCallPendingFeedback();
      if (hasPending && mounted) {
        CallFeedbackGuardService.showPendingFeedbackToast(context);
        return;
      }

      // Show call type selection dialog
      final callType = await showDialog<String>(
        context: context,
        builder: (context) =>
            CallTypeSelectionDialog(driverName: request.userName),
      );

      if (callType == null) return; // User cancelled

      // Get user info
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final callerId = user.id;
      final cleanNumber = request.mobileNumber.replaceAll(
        RegExp(r'[^\d+]'),
        '',
      );

      if (callType == 'manual') {
        // Manual call
        HapticFeedback.mediumImpact();

        final result = await SmartCallingService.instance.initiateManualCall(
          driverMobile: cleanNumber,
          callerId: int.tryParse(callerId) ?? 0,
          driverId: request.id.toString(),
          callSource: 'callback_requests',
        );

        if (result['success'] == true) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];
          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📱 Calling ${request.userName}...'),
                backgroundColor: AppTheme.primaryBlue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (callType == 'easygo_ivr') {
        // IVR call
        await EasyGoIVRCallHelper.initiateCall(
          context: context,
          clientName: request.userName,
          clientPhone: cleanNumber,
          clientId: request.id.toString(),
          tmid: request.uniqueId ?? 'TM${request.id}',
          contactType: 'driver',
          callSource: 'callback_requests',
          onCallEnded: () {
            if (mounted) {
              _showCallFeedbackModal(request);
            }
          },
        );
        return; // Don't show feedback modal yet, it will be shown after call ends
      }

      // Show feedback modal for manual calls
      if (mounted) {
        _showCallFeedbackModal(request);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to start call: $error'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCallFeedbackModal(CallbackRequest request) {
    // Check if user is driver or transporter
    final isTransporter = request.appType == AppType.transporter;

    if (isTransporter) {
      // Show transporter feedback modal
      final transporterContact = _mapRequestToTransporterContact(request);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => TransporterFeedbackModal(
          contact: transporterContact,
          onFeedbackSubmitted: (feedback) {
            Navigator.of(context).pop();
            _handleFeedbackSubmitted(request, feedback);
          },
        ),
      );
    } else {
      // Show driver feedback modal
      final driverContact = _mapRequestToDriverContact(request);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CallFeedbackModal(
          contact: driverContact,
          allowDismiss: true,
          onFeedbackSubmitted: (feedback) async {
            Navigator.of(context).pop();
            await _handleFeedbackSubmitted(request, feedback);
          },
        ),
      );
    }
  }

  DriverContact _mapRequestToDriverContact(CallbackRequest request) {
    final hasSubscription =
        request.subscribeDate != null &&
        request.subscribeDate!.trim().isNotEmpty &&
        request.subscribeDate!.trim().toLowerCase() != 'n/a' &&
        request.subscribeDate!.trim().toLowerCase() != 'not yet';

    final profileCompletion = request.profileCompletion != null
        ? ProfileCompletion.fromPercentageString(request.profileCompletion!)
        : null;

    debugPrint(
      '📊 Profile completion for ${request.userName}: ${request.profileCompletion} -> ${profileCompletion?.percentage}%',
    );

    // Parse training status
    TrainingInfo? trainingInfo;
    if (request.trainingStatus != null) {
      trainingInfo = TrainingInfo(
        isCompleted: request.trainingStatus!.toLowerCase() == 'completed',
        totalQuestions: 0,
        correctAnswers: 0,
        percentage: 0.0,
        rating: 0,
        rankingPercentage: 0.0,
        tier: 'N/A',
      );
    }

    // Parse applied jobs from API data
    final appliedJobs = (request.appliedJobs ?? [])
        .map((job) => AppliedJob.fromJson(job as Map<String, dynamic>))
        .toList();

    // Parse call history from API data
    final callHistory = (request.callHistory ?? [])
        .map((call) => CallHistoryEntry.fromJson(call as Map<String, dynamic>))
        .toList();

    return DriverContact(
      id: request.userId?.toString() ?? request.id.toString(),
      tmid: request.uniqueId ?? 'TM000000',
      name: request.userName,
      company: request.contactReason,
      phoneNumber: request.mobileNumber,
      state: '',
      subscriptionStatus: hasSubscription
          ? SubscriptionStatus.active
          : SubscriptionStatus.inactive,
      status: _mapCallbackStatus(request.status),
      lastFeedback: request.callFeedback,
      lastCallTime: request.lastCallTime ?? request.requestDateTime,
      remarks: request.callRemarks ?? request.notes,
      paymentInfo: PaymentInfo.none(),
      registrationDate: request.registrationDate ?? request.createdAt,
      profileCompletion: profileCompletion,
      role: request.appType.value,
      trainingInfo: trainingInfo,
      appliedJobs: appliedJobs,
      callHistory: callHistory,
      assignedTelecaller: request.assignedTelecaller,
    );
  }

  TransporterContact _mapRequestToTransporterContact(CallbackRequest request) {
    final hasSubscription =
        request.subscribeDate != null &&
        request.subscribeDate!.trim().isNotEmpty &&
        request.subscribeDate!.trim().toLowerCase() != 'n/a' &&
        request.subscribeDate!.trim().toLowerCase() != 'not yet';

    final profileCompletion = request.profileCompletion != null
        ? ProfileCompletion.fromPercentageString(request.profileCompletion!)
        : null;

    return TransporterContact(
      id: request.id.toString(),
      tmid: request.uniqueId ?? 'TM000000',
      name: request.userName,
      company: request.contactReason,
      phoneNumber: request.mobileNumber,
      state: '',
      subscriptionStatus: hasSubscription
          ? SubscriptionStatus.active
          : SubscriptionStatus.inactive,
      status: _mapCallbackStatus(request.status),
      lastFeedback: request.callFeedback,
      lastCallTime: request.lastCallTime ?? request.requestDateTime,
      remarks: request.callRemarks ?? request.notes,
      paymentInfo: PaymentInfo.none(),
      registrationDate: request.registrationDate ?? request.createdAt,
      profileCompletion: profileCompletion,
    );
  }

  CallStatus _mapCallbackStatus(CallbackStatus status) {
    switch (status) {
      case CallbackStatus.pending:
      case CallbackStatus.callback:
      case CallbackStatus.ringingCallBusy:
      case CallbackStatus.disconnected:
      case CallbackStatus.switchedOff:
      case CallbackStatus.futureProspects:
        return CallStatus.callBack;
      case CallbackStatus.contacted:
      case CallbackStatus.resolved:
      case CallbackStatus.interested:
        return CallStatus.connected;
      case CallbackStatus.notInterested:
        return CallStatus.notInterested;
    }
  }

  String _getSubscriptionLabel(CallbackRequest request) {
    final value = request.subscribeDate?.trim();
    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == 'n/a' ||
        value.toLowerCase() == 'not yet') {
      return 'Not yet';
    }

    try {
      // Handle potential different separators
      String cleaned = value.replaceAll('/', '-');
      final date = DateTime.tryParse(cleaned);
      if (date != null) {
        return DateFormat('dd-MMM-yyyy').format(date);
      }
    } catch (_) {}

    return value;
  }

  Future<void> _handleFeedbackSubmitted(
    CallbackRequest request,
    CallFeedback feedback,
  ) async {
    if (!mounted) return;

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved feedback for ${request.userName}'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Optimistic update: Move from requests to history immediately
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _requests.removeAt(index);

        // Get feedback text for optimistic update
        final feedbackText = _getFeedbackText(feedback);

        // Create updated request for history
        final updatedRequest = CallbackRequest(
          id: request.id,
          uniqueId: request.uniqueId,
          assignedTo: request.assignedTo,
          userName: request.userName,
          mobileNumber: request.mobileNumber,
          requestDateTime: request.requestDateTime,
          contactReason: request.contactReason,
          appType: request.appType,
          status: _mapFeedbackToCallbackStatus(feedback),
          notes: feedback.remarks ?? request.notes,
          createdAt: request.createdAt,
          updatedAt: DateTime.now(),
          profileCompletion: request.profileCompletion,
          subscribeDate: request.subscribeDate,
          profileImage: request.profileImage,
          callFeedback: feedbackText,
          callRemarks: feedback.remarks,
          lastCallTime: DateTime.now(),
          appliedJobsCount: request.appliedJobsCount,
          callHistoryCount: (request.callHistoryCount ?? 0) + 1,
          trainingStatus: request.trainingStatus,
          assignedTelecaller: request.assignedTelecaller,
          registrationDate: request.registrationDate,
          appliedJobs: request.appliedJobs,
          callHistory: request.callHistory,
          userId: request.userId,
        );

        _history.insert(0, updatedRequest);
      }
    });

    // Get feedback text for call_logs
    String feedbackText = _getFeedbackText(feedback);

    try {
      // Get current user
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 1. Save to call_logs table via API with correct user_id
      final actualUserId =
          request.userId ??
          request
              .id; // Use userId from users table, fallback to callback_request id
      await _saveToCallLogs(
        userId: actualUserId,
        callerId: int.parse(user.id),
        driverName: request.userName,
        userNumber: request.mobileNumber,
        status: _mapCallStatusToString(feedback.status),
        feedback: feedbackText,
        remarks: feedback.remarks,
        callSource: 'callback_requests',
        tmid: request.uniqueId,
      );

      // 2. Update callback_requests table status
      final status = _mapFeedbackToCallbackStatus(feedback);
      await _service.updateCallbackRequest(
        requestId: request.id,
        status: status.value,
        notes: feedback.remarks,
      );

      debugPrint('✅ Feedback saved to call_logs and callback_requests updated');
    } catch (e) {
      debugPrint('❌ Error saving feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Refresh lists to ensure data consistency with server
    _refresh();
  }

  String _getFeedbackText(CallFeedback feedback) {
    switch (feedback.status) {
      case CallStatus.connected:
        if (feedback.connectedFeedback != null) {
          return feedback.connectedFeedback!.displayName;
        }
        return 'Connected';
      case CallStatus.callBack:
        if (feedback.callBackReason != null) {
          return feedback.callBackReason!.displayName;
        }
        return 'Call Back';
      case CallStatus.callBackLater:
        if (feedback.callBackTime != null) {
          return feedback.callBackTime!.displayName;
        }
        return 'Call Back Later';
      case CallStatus.notReachable:
        return 'Not Reachable';
      case CallStatus.notInterested:
        return 'Not Interested';
      case CallStatus.invalid:
        return 'Invalid Number';
      case CallStatus.pending:
        return 'Pending';
    }
  }

  String _mapCallStatusToString(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return 'connected';
      case CallStatus.callBack:
        return 'callback';
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_reachable';
      case CallStatus.notInterested:
        return 'not_interested';
      case CallStatus.invalid:
        return 'invalid';
      case CallStatus.pending:
        return 'pending';
    }
  }

  Future<void> _saveToCallLogs({
    required int userId,
    required int callerId,
    required String driverName,
    required String userNumber,
    required String status,
    required String feedback,
    String? remarks,
    String? callSource,
    String? tmid,
  }) async {
    try {
      // Get current user for caller number
      final user = RealAuthService.instance.currentUser;
      final callerNumber = user?.mobile ?? '';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/call_logs_api.php?action=insert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'caller_id': callerId,
          'driver_name': driverName,
          'user_number': userNumber,
          'caller_number': callerNumber,
          'call_status': status,
          'feedback': feedback,
          'remarks': remarks,
          'notes': remarks,
          'call_source': callSource,
          'call_time': DateTime.now().toIso8601String(),
          'reference_id':
              'CALLBACK_${DateTime.now().millisecondsSinceEpoch}_${callerId}_$userId',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Call log saved successfully: ${data['id']}');
        } else {
          throw Exception(data['error'] ?? 'Failed to save call log');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error saving to call_logs: $e');
      rethrow;
    }
  }

  CallbackStatus _mapFeedbackToCallbackStatus(CallFeedback feedback) {
    switch (feedback.status) {
      case CallStatus.connected:
        if (feedback.connectedFeedback != null) {
          switch (feedback.connectedFeedback!) {
            case ConnectedFeedback.agreeForSubscription:
            case ConnectedFeedback.agreeForSubscriptionToday:
            case ConnectedFeedback.agreeForSubscriptionTomorrow:
            case ConnectedFeedback.alreadySubscribed:
            case ConnectedFeedback.readyForInterview:
              return CallbackStatus.interested;
            case ConnectedFeedback.neitherTransporterNorDriver:
            case ConnectedFeedback.transporterButRegisteredAsDriver:
            case ConnectedFeedback.driverCabBus:
            case ConnectedFeedback.noMoney:
            case ConnectedFeedback.notInterested:
            case ConnectedFeedback.misbehave:
            case ConnectedFeedback.wrongNumber:
              return CallbackStatus.notInterested;
            case ConnectedFeedback.willSubscribeLater:
            case ConnectedFeedback.willSubscribeWhenNeedJob:
            case ConnectedFeedback.wantsToThink:
            case ConnectedFeedback.thirdPersonReceivedAskedToCallLater:
              return CallbackStatus.futureProspects;
            case ConnectedFeedback.needsHelpInProfile:
            case ConnectedFeedback.doesntUnderstandApp:
            case ConnectedFeedback.languageBarrier:
            case ConnectedFeedback.wantsDemoVideo:
            case ConnectedFeedback.internetIssueLowSpeed:
            case ConnectedFeedback.appIssue:
            case ConnectedFeedback.needLoad:
            case ConnectedFeedback.needJobUrgently:
            case ConnectedFeedback.others:
              return CallbackStatus.contacted;
          }
        }
        return CallbackStatus.contacted;
      case CallStatus.callBack:
      case CallStatus.callBackLater:
        return CallbackStatus.callback;
      case CallStatus.notReachable:
        return CallbackStatus.switchedOff;
      case CallStatus.notInterested:
        return CallbackStatus.notInterested;
      case CallStatus.invalid:
        return CallbackStatus.disconnected;
      case CallStatus.pending:
        return CallbackStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final subtitle = _isLoadingRequests
        ? 'Fetching latest callback requests...'
        : _requestsError != null
        ? 'Tap refresh to try again.'
        : _requests.isEmpty
        ? 'All caught up with callbacks.'
        : '${_requests.length} pending callback requests';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.lightGray,
        body: Stack(
          children: [
            Column(
              children: [
                TelecallerTabHeader(
                  icon: Icons.call_missed_outgoing,
                  iconColor: AppTheme.primaryBlue,
                  title: 'App Callback',
                  subtitle: subtitle,
                  trailing: TelecallerHeaderActionButton(
                    isLoading: _isRefreshing,
                    onPressed: _refresh,
                    icon: Icons.refresh_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: AppTheme.primaryBlue,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Requests'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: TabBarView(
                      children: [
                        // Requests Tab
                        _buildRequestsList(),
                        // History Tab
                        _buildHistoryList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DraggableFloatingActionButton(
              heroTag: 'callback_requests_global_search',
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
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) return const _LoadingView();
    if (_requestsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _requestsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryBlue,
      child: _requests.isEmpty
          ? const _EmptyView()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              itemBuilder: (context, index) {
                final request = _requests[index];
                final contact = _mapRequestToDriverContact(request);
                final requestTime = DateFormat(
                  'dd-MMM-yyyy hh:mma',
                ).format(request.requestDateTime);

                return DriverContactCard(
                  contact: contact,
                  onCallPressed: () => _onCallPressed(request),
                  isCallInProgress: false,
                  showPhoneNumber: true,
                  reason: '${request.contactReason}\n\n $requestTime',
                  subscriptionDateText: _getSubscriptionLabel(request),
                  callbackHistory: request.callbackHistory,
                  callbackRequestsCount: request.callbackRequestsCount,
                );
              },
              itemCount: _requests.length,
            ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoadingHistory) return const _LoadingView();
    if (_historyError != null) return Center(child: Text(_historyError!));

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryBlue,
      child: _history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(45),
                      ),
                      child: Icon(
                        Icons.history_outlined,
                        color: AppTheme.primaryBlue,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No callback history yet',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed callback requests will appear here.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              itemBuilder: (context, index) {
                final request = _history[index];
                final contact = _mapRequestToDriverContact(request);
                final requestTime = DateFormat(
                  'dd-MMM hh:mma',
                ).format(request.requestDateTime);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DriverContactCard(
                    contact: contact,
                    onCallPressed: () => _onCallPressed(request),
                    isCallInProgress: false,
                    showPhoneNumber: true,
                    reason:
                        '${request.contactReason}\n\nRequested: $requestTime',
                    subscriptionDateText: _getSubscriptionLabel(request),
                  ),
                );
              },
              itemCount: _history.length,
            ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(45),
              ),
              child: Icon(
                Icons.celebration_outlined,
                color: AppTheme.primaryBlue,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All caught up!',
              style: AppTheme.headingMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no pending callback requests right now.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
}
