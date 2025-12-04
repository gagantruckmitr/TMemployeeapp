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
import '../../../widgets/access_denied_screen.dart';
import '../../../widgets/audio_player_widget.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../widgets/tab_page_header.dart';
import '../widgets/easygo_ivr_call_helper.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final SocialMediaService _service = SocialMediaService.instance;
  final SocialMediaFeedbackService _feedbackService = SocialMediaFeedbackService.instance;
  final DateFormat _timeFormat = DateFormat('d MMM • h:mm a');
  final DateFormat _dateFormat = DateFormat('d MMM yyyy • h:mm a');

  late TabController _tabController;

  List<SocialMediaLead> _leads = [];
  List<Map<String, dynamic>> _history = [];
  
  bool _isLoadingLeads = true;
  bool _isLoadingHistory = true;
  bool _isRefreshing = false;
  
  String? _leadsError;
  String? _historyError;
  
  bool _hasAccess = false;
  bool _checkingAccess = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAccess();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    setState(() => _checkingAccess = true);
    
    try {
      // All telecallers have access to social media leads
      // Access is controlled by assigned_id in the API
      setState(() {
        _hasAccess = true;
        _checkingAccess = false;
      });
      
      _loadLeads();
    } catch (e) {
      // On error, still try to load - let API handle auth
      setState(() {
        _hasAccess = true;
        _checkingAccess = false;
      });
      _loadLeads();
    }
  }

  Future<void> _loadLeads() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLeads = true;
      _leadsError = null;
    });

    try {
      final results = await _service.fetchSocialMediaLeads();
      if (!mounted) return;
      setState(() {
        _leads = results;
        _isLoadingLeads = false;
      });
    } catch (error) {
      if (!mounted) return;
      
      // Check if it's an access denied error
      final errorMessage = error.toString();
      if (errorMessage.contains('Access denied') || errorMessage.contains('403')) {
        setState(() {
          _hasAccess = false;
          _isLoadingLeads = false;
          _leadsError = null;
        });
      } else {
        setState(() {
          _leadsError = errorMessage;
          _isLoadingLeads = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final results = await _feedbackService.fetchCallHistory();
      if (!mounted) return;
      setState(() {
        _history = results;
        _isLoadingHistory = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _historyError = error.toString();
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    try {
      if (_tabController.index == 0) {
        await _loadLeads();
      } else {
        await _loadHistory();
      }
    } catch (e) {
      // Errors handled in individual load methods
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
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
      } else if (callType == 'easygo_ivr') {
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

    await EasyGoIVRCallHelper.initiateCall(
      context: context,
      clientName: lead.name,
      clientPhone: lead.mobile,
      clientId: lead.id.toString(),
      contactType: lead.role.toLowerCase(),
      callSource: 'social_media',
      onCallEnded: () {
        if (mounted) {
          _showFeedbackModal(contact);
        }
      },
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

  Future<void> _handleFeedbackSubmitted(DriverContact contact, CallFeedback feedback) async {
    if (!mounted) return;

    // Find the original lead
    SocialMediaLead? lead;
    try {
      lead = _leads.firstWhere(
        (l) => l.mobile == contact.phoneNumber,
      );
    } catch (e) {
      // Lead not found in list - it may have been removed already
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Lead not found. It may have been already processed.'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Submit feedback to API
    final result = await SocialMediaFeedbackService.instance.submitFeedback(
      lead: lead,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      // Remove the lead from the list immediately
      final leadId = lead.id;
      setState(() {
        _leads.removeWhere((l) => l.id == leadId);
      });
      
      // Refresh history to show the new call
      _loadHistory();

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

    // Show loading while checking access
    if (_checkingAccess) {
      return Scaffold(
        backgroundColor: AppTheme.lightGray,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentPurple),
        ),
      );
    }

    // Show access denied screen if user doesn't have permission
    if (!_hasAccess) {
      return AccessDeniedScreen(
        title: 'Social Media Leads',
        message: 'Unable to load social media leads.\n\nPlease contact your administrator if you believe you should have access.',
        icon: Icons.people_outline,
        onContactAdmin: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please contact your administrator for assistance'),
              backgroundColor: AppTheme.accentPurple,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    }

    final subtitle = _tabController.index == 0
        ? (_isLoadingLeads
            ? 'Fetching latest social media leads...'
            : _leadsError != null
                ? 'Tap refresh to try again.'
                : _leads.isEmpty
                    ? 'No social media leads available.'
                    : '${_leads.length} social media leads')
        : (_isLoadingHistory
            ? 'Loading call history...'
            : _historyError != null
                ? 'Tap refresh to try again.'
                : _history.isEmpty
                    ? 'No call history yet.'
                    : '${_history.length} calls made');

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: Column(
        children: [
          TelecallerTabHeader(
            icon: Icons.people_outline,
            iconColor: AppTheme.accentPurple,
            title: 'Social Media Leads',
            subtitle: subtitle,
            trailing: TelecallerHeaderActionButton(
              isLoading: _isRefreshing,
              onPressed: _refresh,
              icon: Icons.refresh_rounded,
              color: AppTheme.accentPurple,
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.accentPurple,
              unselectedLabelColor: AppTheme.gray,
              indicatorColor: AppTheme.accentPurple,
              indicatorWeight: 3,
              onTap: (index) {
                setState(() {}); // Rebuild to update subtitle
                if (index == 1 && _history.isEmpty && !_isLoadingHistory) {
                  _loadHistory();
                }
              },
              tabs: const [
                Tab(text: 'New Leads'),
                Tab(text: 'Call History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Leads Tab
                _isLoadingLeads
                    ? const _LoadingView()
                    : _leadsError != null
                        ? _ErrorView(message: _leadsError!, onRetry: _loadLeads)
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadLeads();
                            },
                            color: AppTheme.accentPurple,
                            child: _leads.isEmpty
                                ? const _EmptyView(
                                    icon: Icons.people_outline,
                                    title: 'No social media leads',
                                    message: 'Great job! You have processed all available leads.',
                                  )
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
                
                // History Tab
                _isLoadingHistory
                    ? const _LoadingView()
                    : _historyError != null
                        ? _ErrorView(message: _historyError!, onRetry: _loadHistory)
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadHistory();
                            },
                            color: AppTheme.accentPurple,
                            child: _history.isEmpty
                                ? const _EmptyView(
                                    icon: Icons.history,
                                    title: 'No call history yet',
                                    message: 'Your social media call history will appear here.',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: _history.length,
                                    itemBuilder: (context, index) {
                                      final call = _history[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index < _history.length - 1 ? 16 : 0,
                                        ),
                                        child: _CallHistoryCard(
                                          call: call,
                                          dateFormat: _dateFormat,
                                        ),
                                      );
                                    },
                                  ),
                          ),
              ],
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
                    color: Colors.black.withOpacity(0.08),
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
                        backgroundColor: sourceColor.withOpacity(0.12),
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
                                color: AppTheme.accentPurple.withOpacity(0.3),
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
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.lead.remarks!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceItem(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _sourceIcon(),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.lead.source,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

class _CallHistoryCard extends StatelessWidget {
  const _CallHistoryCard({
    required this.call,
    required this.dateFormat,
  });

  final Map<String, dynamic> call;
  final DateFormat dateFormat;

  Color _sourceColor() {
    final source = call['source']?.toString().toLowerCase() ?? '';
    switch (source) {
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
    final source = call['source']?.toString().toLowerCase() ?? '';
    switch (source) {
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

  Color _feedbackColor() {
    final feedback = call['feedback']?.toString().toLowerCase() ?? '';
    if (feedback.contains('interested') || feedback.contains('connected')) {
      return AppTheme.success;
    } else if (feedback.contains('not interested') || feedback.contains('rejected')) {
      return AppTheme.error;
    } else if (feedback.contains('callback') || feedback.contains('later')) {
      return AppTheme.warning;
    }
    return AppTheme.gray;
  }

  @override
  Widget build(BuildContext context) {
    final name = call['driver_name']?.toString() ?? 'Unknown';
    final mobile = call['user_number']?.toString() ?? '';
    final notesRaw = call['notes']?.toString() ?? '';
    final feedback = call['feedback']?.toString() ?? 'No feedback';
    final remarks = call['remarks']?.toString() ?? '';
    final tcFor = call['tc_for']?.toString() ?? '';
    final createdAt = call['created_at']?.toString() ?? '';
    
    // Extract source and role from notes field
    String source = 'Social Media';
    String role = '';
    if (notesRaw.isNotEmpty) {
      final parts = notesRaw.split('|');
      for (var part in parts) {
        if (part.contains('Source:')) {
          source = part.replaceAll('Source:', '').trim();
        }
        if (part.contains('Role:')) {
          role = part.replaceAll('Role:', '').trim();
        }
      }
    }

    DateTime? callDate;
    try {
      callDate = DateTime.parse(createdAt);
    } catch (e) {
      callDate = null;
    }

    final sourceColor = _sourceColor();
    final feedbackColor = _feedbackColor();

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
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: sourceColor.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mobile,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sourceColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sourceIcon(), size: 12, color: sourceColor),
                      const SizedBox(width: 4),
                      Text(
                        source,
                        style: AppTheme.bodySmall.copyWith(
                          color: sourceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feedbackColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.feedback_outlined, size: 16, color: feedbackColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback,
                      style: AppTheme.bodyLarge.copyWith(
                        color: feedbackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined, size: 16, color: AppTheme.gray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remarks,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (call['manual_call_recording_url']?.toString().isNotEmpty == true) ...[
              AudioPlayerWidget(
                recordingUrl: call['manual_call_recording_url'].toString(),
                label: 'Social Media Call Recording',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (callDate != null)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppTheme.gray),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(callDate),
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
                      ),
                    ],
                  ),
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: role.toLowerCase() == 'driver'
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.accentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: role.toLowerCase() == 'driver'
                            ? AppTheme.primaryBlue
                            : AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (tcFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: AppTheme.gray),
                  const SizedBox(width: 4),
                  Text(
                    'TC For: $tcFor',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.gray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.gray),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
}