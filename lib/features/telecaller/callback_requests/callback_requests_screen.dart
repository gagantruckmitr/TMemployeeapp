import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/callback_requests_service.dart';
import '../../../models/database_models.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/tab_page_header.dart';
import '../widgets/profile_completion_avatar.dart';

class CallbackRequestsScreen extends StatefulWidget {
  const CallbackRequestsScreen({super.key});

  @override
  State<CallbackRequestsScreen> createState() => _CallbackRequestsScreenState();
}

class _CallbackRequestsScreenState extends State<CallbackRequestsScreen>
    with AutomaticKeepAliveClientMixin {
  final CallbackRequestsService _service = CallbackRequestsService.instance;
  final DateFormat _timeFormat = DateFormat('d MMM • h:mm a');

  List<CallbackRequest> _requests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.fetchCallbackRequests();
      if (!mounted) return;
      setState(() {
        _requests = results;
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
      final results = await _service.fetchCallbackRequests();
      if (!mounted) return;
      setState(() {
        _requests = results;
        _isRefreshing = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _error = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to refresh: $error',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $phoneNumber'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCallPressed(CallbackRequest request) async {
    await _callDriver(request);
  }

  Future<void> _callDriver(CallbackRequest request) async {
    final cleanNumber = request.mobileNumber.replaceAll(RegExp(r'[^\d+]'), '');
    bool callPlaced = false;
    String message = 'Calling $cleanNumber';
    Color snackColor = AppTheme.primaryBlue;

    try {
      HapticFeedback.mediumImpact();
      final result = await FlutterPhoneDirectCaller.callNumber(cleanNumber);
      callPlaced = result ?? false;
      if (!callPlaced) {
        message = 'Unable to initiate call. Please try again.';
        snackColor = AppTheme.error;
      }
    } catch (error) {
      message = 'Unable to start call: $error';
      snackColor = AppTheme.error;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: snackColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    _showCallFeedbackModal(request);
  }

  void _showCallFeedbackModal(CallbackRequest request) {
    final contact = _mapRequestToDriverContact(request);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CallFeedbackModal(
            contact: contact,
            allowDismiss: true,
            onFeedbackSubmitted: (feedback) {
              Navigator.of(context).pop();
              _handleFeedbackSubmitted(contact, feedback);
            },
          ),
    );
  }

  DriverContact _mapRequestToDriverContact(CallbackRequest request) {
    final hasSubscription =
        request.subscribeDate != null &&
        request.subscribeDate!.trim().isNotEmpty &&
        request.subscribeDate!.trim().toLowerCase() != 'n/a' &&
        request.subscribeDate!.trim().toLowerCase() != 'not yet';

    final profileCompletion =
        request.profileCompletion != null
            ? ProfileCompletion.fromPercentageString(request.profileCompletion!)
            : null;

    return DriverContact(
      id: request.id.toString(),
      tmid: request.uniqueId ?? 'TM000000',
      name: request.userName,
      company: request.contactReason,
      phoneNumber: request.mobileNumber,
      state: '',
      subscriptionStatus:
          hasSubscription
              ? SubscriptionStatus.active
              : SubscriptionStatus.inactive,
      status: _mapCallbackStatus(request.status),
      lastFeedback: null,
      lastCallTime: request.requestDateTime,
      remarks: request.notes,
      paymentInfo: PaymentInfo.none(),
      registrationDate: request.createdAt,
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

  void _handleFeedbackSubmitted(DriverContact contact, CallFeedback feedback) {
    if (!mounted) return;

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved feedback for ${contact.name}'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final subtitle =
        _isLoading
            ? 'Fetching latest callback requests...'
            : _error != null
            ? 'Tap refresh to try again.'
            : _requests.isEmpty
            ? 'All caught up with callbacks.'
            : '${_requests.length} pending callback requests';

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: Column(
        children: [
          TelecallerTabHeader(
            icon: Icons.call_missed_outgoing,
            iconColor: AppTheme.primaryBlue,
            title: 'Callback Requests',
            subtitle: subtitle,
            trailing: TelecallerHeaderActionButton(
              isLoading: _isRefreshing,
              onPressed: _refresh,
              icon: Icons.refresh_rounded,
              color: AppTheme.primaryBlue,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child:
                  _isLoading
                      ? const _LoadingView()
                      : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadRequests)
                      : RefreshIndicator(
                        onRefresh: _refresh,
                        color: AppTheme.primaryBlue,
                        child:
                            _requests.isEmpty
                                ? const _EmptyView()
                                : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    24,
                                    20,
                                    24,
                                  ),
                                  itemBuilder: (context, index) {
                                    final request = _requests[index];
                                    return _CallbackRequestCard(
                                      request: request,
                                      formattedTime: _timeFormat.format(
                                        request.requestDateTime,
                                      ),
                                      onCall: () => _onCallPressed(request),
                                      onCopyNumber: _copyNumber,
                                    );
                                  },
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 16),
                                  itemCount: _requests.length,
                                ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallbackRequestCard extends StatelessWidget {
  const _CallbackRequestCard({
    required this.request,
    required this.formattedTime,
    required this.onCall,
    required this.onCopyNumber,
  });

  final CallbackRequest request;
  final String formattedTime;
  final VoidCallback onCall;
  final ValueChanged<String> onCopyNumber;

  Color _statusColor() {
    switch (request.status) {
      case CallbackStatus.resolved:
      case CallbackStatus.contacted:
      case CallbackStatus.interested:
        return AppTheme.success;
      case CallbackStatus.pending:
      case CallbackStatus.callback:
        return AppTheme.warning;
      case CallbackStatus.notInterested:
        return AppTheme.error;
      default:
        return AppTheme.gray;
    }
  }

  int _profilePercentage() {
    final raw = request.profileCompletion;
    if (raw == null) return 0;
    final digits = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
    return digits != null ? digits.clamp(0, 100) : 0;
  }

  String _subscriptionLabel() {
    final value = request.subscribeDate?.trim();
    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == 'n/a' ||
        value.toLowerCase() == 'not yet') {
      return 'Not yet';
    }
    return value;
  }

  bool _hasSubscription() {
    final label = _subscriptionLabel().toLowerCase();
    return label != 'not yet';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileCompletionAvatar(
                  name: request.userName,
                  completionPercentage: _profilePercentage(),
                  onTap: () {},
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 16,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              request.uniqueId ?? 'TM ID unavailable',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    request.status.value,
                    style: AppTheme.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.lightPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.message_outlined,
                      color: AppTheme.primaryBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason',
                          style: AppTheme.bodyMedium.copyWith(
                            fontSize: 12,
                            letterSpacing: 0.2,
                            color: AppTheme.gray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.contactReason,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.gray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.appType.value.toUpperCase(),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onCopyNumber(request.mobileNumber),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Number'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.insert_chart_outlined,
                  label: 'Profile',
                  value: '${_profilePercentage()}%',
                ),
                _InfoChip(
                  icon: Icons.event_available_outlined,
                  label: 'Subscribed',
                  value: _hasSubscription() ? _subscriptionLabel() : 'Not yet',
                  isLast: true,
                ),
              ],
            ),
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
    return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(45),
              ),
              child: Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load requests',
              style: AppTheme.headingMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: EdgeInsets.only(right: isLast ? 0 : 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
