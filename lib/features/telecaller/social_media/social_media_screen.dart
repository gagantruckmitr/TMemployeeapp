import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/social_media_service.dart';
import '../../../core/services/social_media_feedback_service.dart';
import '../../../models/social_media_lead_model.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/tab_page_header.dart';
import 'social_media_history_screen.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen>
    with AutomaticKeepAliveClientMixin {
  final SocialMediaService _service = SocialMediaService.instance;
  final DateFormat _timeFormat = DateFormat('d MMM • h:mm a');

  List<SocialMediaLead> _leads = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.fetchSocialMediaLeads();
      if (!mounted) return;
      setState(() {
        _leads = results;
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
      final results = await _service.fetchSocialMediaLeads();
      if (!mounted) return;
      setState(() {
        _leads = results;
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

  Future<void> _onCallPressed(SocialMediaLead lead) async {
    await _startCall(lead);
  }

  Future<void> _startCall(SocialMediaLead lead) async {
    try {
      final contact = _mapLeadToDriverContact(lead);

      // Show call type selection dialog
      if (!mounted) return;

      final callType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📞 Select Call Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how to call ${lead.name}:',
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.phone_forwarded,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('IVR Call'),
                subtitle: const Text('MyOperator progressive dialing'),
                onTap: () => Navigator.pop(context, 'ivr'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.phone, color: AppTheme.success),
                title: const Text('Manual Call'),
                subtitle: const Text('Direct phone dialer'),
                onTap: () => Navigator.pop(context, 'manual'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.success),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (callType == null || !mounted) return;

      if (callType == 'manual') {
        await _handleManualCall(lead, contact);
      } else {
        await _handleIVRCall(lead, contact);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
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
          content: Text('📱 Calling ${lead.name}...'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      await FlutterPhoneDirectCaller.callNumber(cleanNumber);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showFeedbackModal(contact);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $error'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleIVRCall(
    SocialMediaLead lead,
    DriverContact contact,
  ) async {
    if (!mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📞 Progressive Dialing'),
        content: Text(
          'MyOperator will call ${lead.name} first.\n\n'
          '1. ${lead.name}\'s phone will ring FIRST\n'
          '2. When they pick up, they hear IVR message\n'
          '3. YOUR phone will ring NEXT\n'
          '4. When you pick up - instant connection!\n'
          '5. Number remains hidden\n\n'
          'Ready to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Call'),
          ),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 IVR call feature coming soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showFeedbackModal(DriverContact contact) {
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

  Future<void> _handleFeedbackSubmitted(
    DriverContact contact,
    CallFeedback feedback,
  ) async {
    if (!mounted) return;

    // Find the original lead
    final lead = _leads.firstWhere(
      (l) => l.mobile == contact.phoneNumber,
      orElse: () => _leads.first,
    );

    // Submit feedback to API
    final result = await SocialMediaFeedbackService.instance.submitFeedback(
      lead: lead,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      // Remove the lead from the list immediately
      setState(() {
        _leads.removeWhere((l) => l.id == lead.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Feedback saved for ${contact.name}'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save feedback: ${result['message']}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final subtitle = _isLoading
        ? 'Fetching latest social media leads...'
        : _error != null
        ? 'Tap refresh to try again.'
        : _leads.isEmpty
        ? 'No social media leads available.'
        : '${_leads.length} social media leads';

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: Column(
        children: [
          TelecallerTabHeader(
            icon: Icons.people_outline,
            iconColor: AppTheme.accentPurple,
            title: 'Social Media Leads',
            subtitle: subtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TelecallerHeaderActionButton(
                  isLoading: false,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SocialMediaHistoryScreen(),
                      ),
                    );
                  },
                  icon: Icons.history,
                  color: AppTheme.accentPurple,
                ),
                const SizedBox(width: 8),
                TelecallerHeaderActionButton(
                  isLoading: _isRefreshing,
                  onPressed: _refresh,
                  icon: Icons.refresh_rounded,
                  color: AppTheme.accentPurple,
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: _isLoading
                  ? const _LoadingView()
                  : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadLeads)
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppTheme.accentPurple,
                      child: _leads.isEmpty
                          ? const _EmptyView()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                24,
                              ),
                              itemBuilder: (context, index) {
                                final lead = _leads[index];
                                return _SocialMediaLeadCard(
                                  lead: lead,
                                  formattedTime: _timeFormat.format(
                                    lead.chatDateTime,
                                  ),
                                  onCall: () => _onCallPressed(lead),
                                  onCopyNumber: _copyNumber,
                                );
                              },
                              itemCount: _leads.length,
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialMediaLeadCard extends StatefulWidget {
  const _SocialMediaLeadCard({
    required this.lead,
    required this.formattedTime,
    required this.onCall,
    required this.onCopyNumber,
  });

  final SocialMediaLead lead;
  final String formattedTime;
  final VoidCallback onCall;
  final ValueChanged<String> onCopyNumber;

  @override
  State<_SocialMediaLeadCard> createState() => _SocialMediaLeadCardState();
}

class _SocialMediaLeadCardState extends State<_SocialMediaLeadCard>
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

  String _extractLatestFeedback(String remarks) {
    // Extract only the latest feedback from remarks
    if (remarks.contains('[Feedback:')) {
      final feedbackEntries = remarks
          .split('\n')
          .where((line) => line.contains('[Feedback:'))
          .toList();
      if (feedbackEntries.isNotEmpty) {
        final latestFeedback = feedbackEntries.last;
        // Remove the [Feedback: ] wrapper
        return latestFeedback
            .replaceAll('[Feedback:', '')
            .replaceAll(']', '')
            .trim();
      }
    }
    return remarks;
  }

  Color _sourceColor() {
    switch (widget.lead.source.toLowerCase()) {
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
    switch (widget.lead.source.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final sourceColor = _sourceColor();

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
                      // Avatar
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: sourceColor.withValues(alpha: 0.12),
                        child: Text(
                          widget.lead.name.isNotEmpty
                              ? widget.lead.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: sourceColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name and Mobile
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.lead.name),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Name copied: ${widget.lead.name}',
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
                                widget.lead.name,
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
                                widget.lead.mobile,
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
                            color: AppTheme.accentPurple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPurple.withValues(
                                  alpha: 0.3,
                                ),
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
                          Icons.access_time,
                          'Received',
                          widget.formattedTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSourceItem(sourceColor)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          widget.lead.isDriver ? Icons.person : Icons.business,
                          'Role',
                          widget.lead.role.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.phone_android,
                          'Mobile',
                          widget.lead.mobile,
                        ),
                      ),
                    ],
                  ),

                  // Message Section
                  if (widget.lead.remarks != null &&
                      widget.lead.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMessageSection(),
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

  Widget _buildSourceItem(Color sourceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_sourceIcon(), size: 14, color: sourceColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Source',
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
            color: sourceColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sourceColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            widget.lead.source,
            style: TextStyle(
              fontSize: 11,
              color: sourceColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.message_outlined, size: 16, color: AppTheme.accentPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _extractLatestFeedback(widget.lead.remarks ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentPurple.withValues(alpha: 0.9),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(45),
              ),
              child: Icon(Icons.error_outline, color: AppTheme.error, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load leads',
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
                backgroundColor: AppTheme.accentPurple,
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
                color: AppTheme.accentPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(45),
              ),
              child: Icon(
                Icons.people_outline,
                color: AppTheme.accentPurple,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No leads yet',
              style: AppTheme.headingMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Social media leads will appear here when available.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
}