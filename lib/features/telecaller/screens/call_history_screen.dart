import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/pending_feedback_service.dart';
import '../widgets/call_feedback_modal.dart';

class CallHistoryScreen extends StatefulWidget {
  final String? initialFilter;
  
  const CallHistoryScreen({super.key, this.initialFilter});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<CallHistoryEntry>? _callHistory;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _filterStatus = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _filterStatus = widget.initialFilter!;
    }
    _loadCallHistory();
  }

  @override
  void didUpdateWidget(CallHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filter if it changed
    if (widget.initialFilter != oldWidget.initialFilter && widget.initialFilter != null) {
      setState(() {
        _filterStatus = widget.initialFilter!;
      });
      _loadCallHistory();
    }
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

  Future<void> _loadCallHistory() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final historyData = await SmartCallingService.instance.getCallHistory(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );

      // Convert dynamic list to CallHistoryEntry list
      final history = historyData.map((item) {
        return CallHistoryEntry(
          id: item['id'].toString(),
          driverId: item['driver_id'].toString(),
          driverName: item['driver_name'] ?? 'Unknown',
          phoneNumber: item['phone_number'] ?? '',
          status: _parseCallStatus(item['status']),
          callTime: DateTime.parse(item['call_time']),
          duration: item['duration'] != null ? int.tryParse(item['duration'].toString()) : null,
          durationFormatted: item['duration_formatted'],
          timeAgo: item['time_ago'],
          feedback: item['feedback'],
          remarks: item['remarks'],
          recordingUrl: item['recording_url'],
          manualCallRecordingUrl: item['manual_call_recording_url'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _callHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _callHistory = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final historyData = await SmartCallingService.instance.getCallHistory(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );

      // Convert dynamic list to CallHistoryEntry list
      final history = historyData.map((item) {
        return CallHistoryEntry(
          id: item['id'].toString(),
          driverId: item['driver_id'].toString(),
          driverName: item['driver_name'] ?? 'Unknown',
          phoneNumber: item['phone_number'] ?? '',
          status: _parseCallStatus(item['status']),
          callTime: DateTime.parse(item['call_time']),
          duration: item['duration'] != null ? int.tryParse(item['duration'].toString()) : null,
          durationFormatted: item['duration_formatted'],
          timeAgo: item['time_ago'],
          feedback: item['feedback'],
          remarks: item['remarks'],
          recordingUrl: item['recording_url'],
          manualCallRecordingUrl: item['manual_call_recording_url'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _callHistory = history;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  CallStatus _parseCallStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'connected':
        return CallStatus.connected;
      case 'callback':
        return CallStatus.callBack;
      case 'callback_later':
        return CallStatus.callBackLater;
      case 'not_reachable':
        return CallStatus.notReachable;
      case 'not_interested':
        return CallStatus.notInterested;
      case 'invalid':
        return CallStatus.invalid;
      default:
        return CallStatus.pending;
    }
  }

  void _onFilterChanged(String status) {
    if (_filterStatus != status) {
      setState(() {
        _filterStatus = status;
      });
      _loadCallHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _CallHistoryHeader(
            totalCalls: _callHistory?.length ?? 0,
            onRefresh: _refreshData,
            isRefreshing: _isRefreshing,
          ),
          _FilterChips(
            selectedFilter: _filterStatus,
            onFilterChanged: _onFilterChanged,
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: (_callHistory?.isEmpty ?? true)
                        ? const _EmptyStateWidget()
                        : _CallHistoryList(
                            history: _callHistory!,
                            scrollController: _scrollController,
                            onUpdate: _refreshData,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryHeader extends StatelessWidget {
  final int totalCalls;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const _CallHistoryHeader({
    required this.totalCalls,
    required this.onRefresh,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
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
      child: Column(
        children: [
          // Back button row
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                color: Colors.grey.shade700,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                color: Colors.indigo,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.withValues(alpha: 0.2),
                      Colors.purple.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call History',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$totalCalls total calls logged',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'All', 'value': 'all', 'icon': Icons.all_inclusive},
      {'label': 'Connected', 'value': 'connected', 'icon': Icons.check_circle},
      {'label': 'Callback', 'value': 'callback', 'icon': Icons.refresh},
      {
        'label': 'Not Reachable',
        'value': 'not_reachable',
        'icon': Icons.phone_disabled
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  if (selected) {
                    HapticFeedback.lightImpact();
                    onFilterChanged(filter['value'] as String);
                  }
                },
                selectedColor: Colors.indigo,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CallHistoryList extends StatelessWidget {
  final List<CallHistoryEntry> history;
  final ScrollController scrollController;
  final VoidCallback? onUpdate;

  const _CallHistoryList({
    required this.history,
    required this.scrollController,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _CallHistoryCard(
          key: ValueKey(entry.id),
          entry: entry,
          onUpdate: onUpdate,
        );
      },
    );
  }
}

class _CallHistoryCard extends StatefulWidget {
  final CallHistoryEntry entry;
  final VoidCallback? onUpdate;

  const _CallHistoryCard({
    super.key,
    required this.entry,
    this.onUpdate,
  });

  @override
  State<_CallHistoryCard> createState() => _CallHistoryCardState();
}

class _CallHistoryCardState extends State<_CallHistoryCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayRecording() async {
    final recordingUrl = widget.entry.anyRecordingUrl;
    if (recordingUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        await _audioPlayer.play(UrlSource(recordingUrl));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.entry.status) {
      case CallStatus.connected:
        return Colors.green;
      case CallStatus.callBack:
        return Colors.orange;
      case CallStatus.callBackLater:
        return Colors.blue;
      case CallStatus.notReachable:
        return Colors.red;
      case CallStatus.notInterested:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.entry.status) {
      case CallStatus.connected:
        return Icons.check_circle;
      case CallStatus.callBack:
        return Icons.refresh;
      case CallStatus.callBackLater:
        return Icons.schedule;
      case CallStatus.notReachable:
        return Icons.phone_disabled;
      case CallStatus.notInterested:
        return Icons.cancel;
      default:
        return Icons.phone;
    }
  }

  Future<void> _makeCall() async {
    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
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

      final callerId = int.tryParse(currentUser.id) ?? 1;
      final cleanPhone = widget.entry.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Log manual call
      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanPhone,
        callerId: callerId,
        driverId: widget.entry.driverId,
      );

      if (result['success'] == true && mounted) {
        final referenceId = result['data']?['reference_id'];
        final driverMobileRaw = result['data']?['driver_mobile_raw'];

        // Save pending feedback
        await PendingFeedbackService.instance.savePendingFeedback(
          referenceId: referenceId,
          driverId: widget.entry.driverId,
          driverName: widget.entry.driverName,
          driverPhone: widget.entry.phoneNumber,
          driverCompany: 'Unknown',
          callerId: callerId,
        );

        // Make the call
        await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
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

  void _showUpdateFeedbackModal() {
    final contact = DriverContact(
      id: widget.entry.driverId,
      tmid: 'TM${widget.entry.driverId}',
      name: widget.entry.driverName,
      phoneNumber: widget.entry.phoneNumber,
      company: 'Unknown',
      state: 'Unknown',
      subscriptionStatus: SubscriptionStatus.inactive,
      status: widget.entry.status,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Allow dismissing by tapping outside
      enableDrag: true, // Allow dragging to dismiss
      builder: (context) => CallFeedbackModal(
        contact: contact,
        referenceId: widget.entry.id,
        callDuration: widget.entry.duration,
        allowDismiss: true, // Allow close button in call history
        onFeedbackSubmitted: (feedback) async {
          await _updateFeedback(feedback);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _updateFeedback(CallFeedback feedback) async {
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
      // Upload recording if provided
      if (feedback.recordingFile != null) {
        final user = RealAuthService.instance.currentUser;
        final uploadResult = await SmartCallingService.instance.uploadCallRecording(
          recordingFile: feedback.recordingFile,
          tmid: widget.entry.driverId, // Using driver ID as TMID
          callerId: user?.id ?? '1',
          callLogId: widget.entry.id,
        );
        
        if (!uploadResult['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Recording upload failed: ${uploadResult['error']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      final success = await SmartCallingService.instance.updateCallHistoryFeedback(
        callLogId: widget.entry.id,
        status: feedback.status,
        feedback: feedbackText,
        remarks: feedback.remarks,
      );

      if (success && mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Feedback updated for ${widget.entry.driverName}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Notify parent to refresh
        if (widget.onUpdate != null) {
          widget.onUpdate!();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update feedback'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime, String? timeAgo) {
    // Use API-provided time_ago if available, otherwise calculate
    if (timeAgo != null && timeAgo.isNotEmpty && timeAgo != 'Unknown') {
      return timeAgo;
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM dd, h:mm a').format(dateTime);
    }
  }

  String _formatDuration(int? seconds, String? durationFormatted) {
    // Use API-provided duration_formatted if available
    if (durationFormatted != null && durationFormatted.isNotEmpty && durationFormatted != '0:00') {
      return durationFormatted;
    }
    
    if (seconds == null || seconds == 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.driverName,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.entry.phoneNumber,
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.entry.status.name.toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and Duration
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(widget.entry.callTime, widget.entry.timeAgo),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(widget.entry.duration, widget.entry.durationFormatted),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Feedback Section
                if (widget.entry.feedback != null && widget.entry.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.entry.feedback!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Remarks Section
                if (widget.entry.remarks != null && widget.entry.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remarks',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.entry.remarks!,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _makeCall,
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showUpdateFeedbackModal,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Update'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (widget.entry.hasRecording) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _isLoading ? null : _togglePlayRecording,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                size: 32,
                              ),
                        color: Colors.purple,
                        tooltip: _isPlaying ? 'Pause Recording' : 'Play Recording',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.purple.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 60,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Call History',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call logs will appear here\nonce you start making calls',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.grey.shade500,
            ),
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
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// Call History Entry Model
class CallHistoryEntry {
  final String id;
  final String driverId;
  final String driverName;
  final String phoneNumber;
  final CallStatus status;
  final DateTime callTime;
  final int? duration;
  final String? durationFormatted;
  final String? timeAgo;
  final String? feedback;
  final String? remarks;
  final String? recordingUrl;
  final String? manualCallRecordingUrl;

  CallHistoryEntry({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.phoneNumber,
    required this.status,
    required this.callTime,
    this.duration,
    this.durationFormatted,
    this.timeAgo,
    this.feedback,
    this.remarks,
    this.recordingUrl,
    this.manualCallRecordingUrl,
  });
  
  // Helper to get any available recording URL
  String? get anyRecordingUrl => manualCallRecordingUrl ?? recordingUrl;
  bool get hasRecording => anyRecordingUrl != null && anyRecordingUrl!.isNotEmpty;
}
