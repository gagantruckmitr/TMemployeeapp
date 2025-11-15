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
import '../../../widgets/coming_soon_screen.dart';
import 'callback_profile_details_screen.dart';

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
      debugPrint('Error loading callback requests: $error');
      setState(() {
        _error = 'Unable to load callback requests';
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
      debugPrint('Error refreshing callback requests: $error');
      setState(() {
        _isRefreshing = false;
        _error = 'Unable to refresh';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to refresh. Please try again.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      builder: (context) => CallFeedbackModal(
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

    final profileCompletion = request.profileCompletion != null
        ? ProfileCompletion.fromPercentageString(request.profileCompletion!)
        : null;

    return DriverContact(
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

    final subtitle = _isLoading
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
              child: _isLoading
                  ? const _LoadingView()
                  : _error != null
                  ? const CallbacksNotAvailable()
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppTheme.primaryBlue,
                      child: _requests.isEmpty
                          ? const _EmptyView()
                          : ListView.builder(
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

class _CallbackRequestCard extends StatefulWidget {
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

  @override
  State<_CallbackRequestCard> createState() => _CallbackRequestCardState();
}

class _CallbackRequestCardState extends State<_CallbackRequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  int _profilePercentage() {
    final raw = widget.request.profileCompletion;
    if (raw == null) return 0;
    final digits = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
    return digits != null ? digits.clamp(0, 100) : 0;
  }

  String _subscriptionLabel() {
    final value = widget.request.subscribeDate?.trim();
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
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
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
                        name: widget.request.userName,
                        completionPercentage: _profilePercentage(),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CallbackProfileDetailsScreen(
                                    request: widget.request,
                                  ),
                            ),
                          );
                        },
                        size: 54,
                        imageUrl: widget.request.profileImage,
                      ),
                      const SizedBox(width: 14),

                      // Name and TMID
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.request.userName),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Name copied: ${widget.request.userName}',
                                ),
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
                              Text(
                                widget.request.userName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.request.uniqueId ?? 'TM ID unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Call Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onCall();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2196F3,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
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
                          widget.formattedTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.badge_outlined,
                          'Role Type',
                          widget.request.appType.value.toUpperCase(),
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
                          Icons.message_outlined,
                          'Reason',
                          widget.request.contactReason.isNotEmpty
                              ? widget.request.contactReason
                              : 'N/A',
                        ),
                      ),
                    ],
                  ),

                  // Notes Section
                  if (widget.request.notes != null &&
                      widget.request.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildNotesSection(),
                  ],
                ],
              ),
            ),
          );
        },
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
    final subscriptionText = _subscriptionLabel();
    final hasSubscription = _hasSubscription();
    final subscriptionColor = hasSubscription
        ? const Color(0xFF4CAF50)
        : Colors.grey.shade600;

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

  Widget _buildNotesSection() {
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
                  'Notes',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.request.notes!,
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