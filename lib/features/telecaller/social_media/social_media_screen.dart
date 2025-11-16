import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/social_media_service.dart';
import '../../../core/services/social_media_feedback_service.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../../../models/social_media_lead_model.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
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
        builder: (context) => CallTypeSelectionDialog(
          driverName: lead.name,
        ),
      );

      if (callType == null || !mounted) return;

      if (callType == 'manual') {
        await _handleManualCall(lead, contact);
      } else if (callType == 'click2call') {
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

  Future<void> _handleManualCall(SocialMediaLead lead, DriverContact contact) async {
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

  Future<void> _handleIVRCall(SocialMediaLead lead, DriverContact contact) async {
    if (!mounted) return;

    try {
      // Get current user ID
      final callerId = await Phase2AuthService.getUserId();
      if (callerId == 0) {
        throw Exception('User not logged in');
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Initiate IVR call
      final result = await SmartCallingService.instance.initiateClick2CallIVR(
        driverMobile: lead.mobile,
        callerId: callerId,
        driverId: contact.id,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final referenceId = result['reference_id'] as String?;
        
        // Show IVR waiting overlay
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => IVRCallWaitingOverlay(
            driverName: lead.name,
            referenceId: referenceId,
            onCallEnded: () {
              Navigator.pop(context);
            },
          ),
        );

        // Show feedback modal after call ends
        if (!mounted) return;
        _showFeedbackModal(contact);
      } else {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to initiate IVR call',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate IVR call: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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

  Future<void> _handleFeedbackSubmitted(DriverContact contact, CallFeedback feedback) async {
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

    final subtitle =
        _isLoading
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
              child:
                  _isLoading
                      ? const _LoadingView()
                      : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadLeads)
                      : RefreshIndicator(
                        onRefresh: _refresh,
                        color: AppTheme.accentPurple,
                        child:
                            _leads.isEmpty
                                ? const _EmptyView()
                                : ListView.separated(
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
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 16),
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

class _SocialMediaLeadCard extends StatelessWidget {
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

  String _extractLatestFeedback(String remarks) {
    // Extract only the latest feedback from remarks
    if (remarks.contains('[Feedback:')) {
      final feedbackEntries = remarks.split('\n').where((line) => line.contains('[Feedback:')).toList();
      if (feedbackEntries.isNotEmpty) {
        final latestFeedback = feedbackEntries.last;
        // Remove the [Feedback: ] wrapper
        return latestFeedback.replaceAll('[Feedback:', '').replaceAll(']', '').trim();
      }
    }
    return remarks;
  }

  Color _sourceColor() {
    switch (lead.source.toLowerCase()) {
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
    switch (lead.source.toLowerCase()) {
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: sourceColor.withOpacity(0.12),
                  child: Text(
                    lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 16,
                            color: AppTheme.gray,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lead.mobile,
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w500,
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
                    color: sourceColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sourceIcon(), size: 14, color: sourceColor),
                      const SizedBox(width: 4),
                      Text(
                        lead.source,
                        style: AppTheme.bodyMedium.copyWith(
                          color: sourceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lead.remarks != null && lead.remarks!.isNotEmpty) ...[
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
                        color: AppTheme.accentPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.message_outlined,
                        color: AppTheme.accentPurple,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message',
                            style: AppTheme.bodyMedium.copyWith(
                              fontSize: 12,
                              letterSpacing: 0.2,
                              color: AppTheme.gray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _extractLatestFeedback(lead.remarks ?? ''),
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
            ],
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lead.isDriver ? AppTheme.primaryBlue.withOpacity(0.12) : AppTheme.accentOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lead.isDriver ? Icons.person : Icons.business,
                        size: 14,
                        color: lead.isDriver ? AppTheme.primaryBlue : AppTheme.accentOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.role.toUpperCase(),
                        style: AppTheme.bodyMedium.copyWith(
                          color: lead.isDriver ? AppTheme.primaryBlue : AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                      backgroundColor: AppTheme.accentPurple,
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
                    onPressed: () => onCopyNumber(lead.mobile),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Number'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppTheme.accentPurple.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
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
    return Center(child: CircularProgressIndicator(color: AppTheme.accentPurple));
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
              child: Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 38,
              ),
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
