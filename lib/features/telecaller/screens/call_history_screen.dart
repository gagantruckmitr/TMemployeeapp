import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../models/phase2_user_model.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../../../core/services/pending_feedback_service.dart';
import '../../../core/services/call_hit_service.dart';
import '../../../core/utils/phone_masking_utils.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/call_type_selection_dialog.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../widgets/easygo_ivr_call_helper.dart';

class CallHistoryScreen extends StatefulWidget {
  final String? initialFilter;

  const CallHistoryScreen({super.key, this.initialFilter});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<CallHistoryEntry>? _callHistory;
  int _totalRecords = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _filterStatus = 'all';
  String _filterFeedback = 'all';
  String _filterRemarks = 'all';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != null) {
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
    _searchController.dispose();
    _debounce?.cancel();
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
        feedback: _filterFeedback == 'all' ? null : _filterFeedback,
        remarks: _filterRemarks == 'all' ? null : _filterRemarks,
        search: _searchController.text,
        limit: 1000, // Increased limit as requested
      );

      final List<dynamic> historyList = historyData['data'] ?? [];
      final int total = historyData['total'] ?? 0;

      // Convert dynamic list to CallHistoryEntry list
      final history = historyList.map((item) {
        return CallHistoryEntry(
          id: item['id'].toString(),
          driverId: item['driver_id'].toString(),
          tmid: item['tmid'] ?? '',
          driverName: item['driver_name'] ?? '',
          phoneNumber: item['phone_number'] ?? '',
          status: _parseCallStatus(item['status']),
          callTime: DateTime.parse(item['call_time']),
          duration: item['duration'] != null
              ? int.tryParse(item['duration'].toString())
              : null,
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
          _totalRecords = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _callHistory = [];
          _totalRecords = 0;
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
        feedback: _filterFeedback == 'all' ? null : _filterFeedback,
        remarks: _filterRemarks == 'all' ? null : _filterRemarks,
        search: _searchController.text,
        limit: 1000, // Increased limit as requested
      );

      final List<dynamic> historyList = historyData['data'] ?? [];
      final int total = historyData['total'] ?? 0;

      // Convert dynamic list to CallHistoryEntry list
      final history = historyList.map((item) {
        return CallHistoryEntry(
          id: item['id'].toString(),
          driverId: item['driver_id'].toString(),
          tmid: item['tmid'] ?? '',
          driverName: item['driver_name'] ?? '',
          phoneNumber: item['phone_number'] ?? '',
          status: _parseCallStatus(item['status']),
          callTime: DateTime.parse(item['call_time']),
          duration: item['duration'] != null
              ? int.tryParse(item['duration'].toString())
              : null,
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
          _totalRecords = total;
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => _FilterBottomSheet(
        initialFeedback: _filterFeedback,
        initialRemarks: _filterRemarks,
        onFeedbackChanged: (feedback) {
          setState(() {
            _filterFeedback = feedback;
          });
        },
        onRemarksChanged: (remarks) {
          setState(() {
            _filterRemarks = remarks;
          });
        },
        onApply: () {
          Navigator.pop(context);
          _loadCallHistory();
        },
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadCallHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _CallHistoryHeader(
            totalCalls: _totalRecords,
            onRefresh: _refreshData,
            isRefreshing: _isRefreshing,
            onFilterTap: _showFilterBottomSheet,
          ),
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
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
  final VoidCallback onFilterTap;

  const _CallHistoryHeader({
    required this.totalCalls,
    required this.onRefresh,
    required this.isRefreshing,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 4, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Colors.indigo, size: 20),
          const SizedBox(width: 8),
          Text(
            'Call History',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onFilterTap,
            icon: const Icon(Icons.filter_list, size: 20),
            color: Colors.indigo,
            tooltip: 'Filter',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            color: Colors.indigo,
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or number...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String initialFeedback;
  final String initialRemarks;
  final Function(String) onFeedbackChanged;
  final Function(String) onRemarksChanged;
  final VoidCallback onApply;

  const _FilterBottomSheet({
    required this.initialFeedback,
    required this.initialRemarks,
    required this.onFeedbackChanged,
    required this.onRemarksChanged,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String selectedFeedback;
  late String selectedRemarks;

  @override
  void initState() {
    super.initState();
    selectedFeedback = widget.initialFeedback;
    selectedRemarks = widget.initialRemarks;
  }

  @override
  Widget build(BuildContext context) {
    final feedbackOptions = [
      {'label': 'All Feedbacks', 'value': 'all', 'icon': Icons.all_inclusive},
      {'label': 'Ringing', 'value': 'Ringing', 'icon': Icons.phone_in_talk},
      {'label': 'Call Busy', 'value': 'Call Busy', 'icon': Icons.phone_locked},
      {'label': 'Not Interested', 'value': 'Not Interested', 'icon': Icons.cancel},
      {'label': 'Switch Off', 'value': 'Switch Off', 'icon': Icons.phone_disabled},
      {'label': 'Wrong Number', 'value': 'Wrong Number', 'icon': Icons.error_outline},
      {'label': 'Call Back Later', 'value': 'Call Back Later', 'icon': Icons.schedule},
      {'label': 'Interested', 'value': 'Interested', 'icon': Icons.thumb_up},
      {'label': 'Already Registered', 'value': 'Already Registered', 'icon': Icons.check_circle},
      {'label': 'Will Register Later', 'value': 'Will Register Later', 'icon': Icons.pending},
      {'label': 'Not Reachable', 'value': 'Not Reachable', 'icon': Icons.phone_missed},
      {'label': 'Agree for Subscription Today', 'value': 'Agree for Subscription Today', 'icon': Icons.check_circle_outline},
      {'label': 'Payment Pending', 'value': 'Payment Pending', 'icon': Icons.payment},
      {'label': 'Document Pending', 'value': 'Document Pending', 'icon': Icons.description},
      {'label': 'Follow Up Required', 'value': 'Follow Up Required', 'icon': Icons.follow_the_signs},
      {'label': 'Language Barrier', 'value': 'Language Barrier', 'icon': Icons.language},
      {'label': 'Call Disconnected', 'value': 'Call Disconnected', 'icon': Icons.call_end},
    ];

    final remarkOptions = [
      {'label': 'All Remarks', 'value': 'all', 'icon': Icons.all_inclusive},
      {'label': 'Has Remarks', 'value': 'has_remarks', 'icon': Icons.note},
      {'label': 'No Remarks', 'value': 'no_remarks', 'icon': Icons.note_outlined},
    ];

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.indigo, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Call History',
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Feedback Filter Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Feedback',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: feedbackOptions.map((option) {
                      final isSelected = selectedFeedback == option['value'];
                      return ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            selectedFeedback = option['value'] as String;
                          });
                          widget.onFeedbackChanged(option['value'] as String);
                        },
                        icon: Icon(
                          option['icon'] as IconData,
                          size: 16,
                        ),
                        label: Text(
                          option['label'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.indigo
                              : Colors.grey.shade100,
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.indigo
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Remarks Filter Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Remarks',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: remarkOptions.map((option) {
                      final isSelected = selectedRemarks == option['value'];
                      return ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            selectedRemarks = option['value'] as String;
                          });
                          widget.onRemarksChanged(option['value'] as String);
                        },
                        icon: Icon(
                          option['icon'] as IconData,
                          size: 16,
                        ),
                        label: Text(
                          option['label'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.green
                              : Colors.grey.shade100,
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        'icon': Icons.phone_disabled,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
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
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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

  const _CallHistoryCard({super.key, required this.entry, this.onUpdate});

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
      // Check both auth services for user
      final currentUser = RealAuthService.instance.currentUser;
      Phase2User? phase2User = await Phase2AuthService.getCurrentUser();

      // If RealAuthService has user but Phase2AuthService doesn't, create Phase2User from RealAuth data
      if (currentUser != null && phase2User == null) {
        print('🔄 Syncing user from RealAuthService to Phase2AuthService');
        // Create a Phase2User object from RealAuthService data
        phase2User = Phase2User(
          id: int.tryParse(currentUser.id) ?? 0,
          name: currentUser.name,
          mobile: currentUser.mobile,
          email: currentUser.email,
          role: currentUser.role,
          tcFor: '', // Not available in RealAuthService
          createdAt: DateTime.now().toIso8601String(),
        );
      }

      if (currentUser == null && phase2User == null) {
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

      // Show call type selection dialog
      final callType = await showDialog<String>(
        context: context,
        builder: (context) =>
            CallTypeSelectionDialog(driverName: widget.entry.driverName),
      );

      if (callType == null) return;

      // Log call hit
      await CallHitService.instance.logCallHit(
        contactId: widget.entry.driverId,
        contactName: widget.entry.driverName,
        contactType: 'driver',
        callType: callType,
        sourceScreen: 'telecaller_call_history',
        phoneNumber: widget.entry.phoneNumber,
      );

      // Use appropriate user ID based on which auth service has the user
      final callerId = currentUser != null
          ? (int.tryParse(currentUser.id) ?? 1)
          : (phase2User?.id ?? 1);
      final cleanPhone = widget.entry.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (callType == 'manual') {
        // For manual calls, phone number might be hidden for privacy
        // The manual_call_api will fetch the actual number from database
        final result = await SmartCallingService.instance.initiateManualCall(
          driverMobile: cleanPhone.isEmpty ? widget.entry.driverId : cleanPhone,
          callerId: callerId,
          driverId: widget.entry.driverId,
        );

        if (result['success'] == true && mounted) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];
          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _showUpdateFeedbackModal();
        }
      } else if (callType == 'easygo_ivr') {
        // For IVR calls, if phone number is empty, fetch it from database first
        String phoneToUse = widget.entry.phoneNumber;

        if (cleanPhone.isEmpty) {
          // Fetch phone number from database using the same API as manual calls
          final result = await SmartCallingService.instance.initiateManualCall(
            driverMobile: widget.entry.driverId,
            callerId: callerId,
            driverId: widget.entry.driverId,
          );

          if (result['success'] == true) {
            phoneToUse = result['data']?['driver_mobile_raw'] ?? '';
          }
        }

        await EasyGoIVRCallHelper.initiateCall(
          context: context,
          clientName: widget.entry.driverName,
          clientPhone: phoneToUse,
          clientId: widget.entry.driverId,
          contactType: 'driver',
          callSource: null, // Regular telecaller call, not from job screens
          onCallEnded: () {
            if (mounted) _showUpdateFeedbackModal();
          },
        );
      }
    } catch (e) {
      print('❌ CALL HISTORY: Exception in _makeCall: $e');
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
      company: '',
      state: '',
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
        final uploadResult = await SmartCallingService.instance
            .uploadCallRecording(
              recordingFile: feedback.recordingFile,
              tmid: widget.entry.driverId, // Using driver ID as TMID
              callerId: user?.id ?? '1',
              callLogId: widget.entry.id,
            );

        if (!uploadResult['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Recording upload failed: ${uploadResult['error']}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      final success = await SmartCallingService.instance
          .updateCallHistoryFeedback(
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

        // Add delay to ensure database has committed the changes
        await Future.delayed(const Duration(milliseconds: 800));

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
    // Always show exact date and time
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM dd, yyyy h:mm a').format(dateTime);
    }
  }

  String _formatDuration(int? seconds, String? durationFormatted) {
    // Use API-provided duration_formatted if available
    if (durationFormatted != null &&
        durationFormatted.isNotEmpty &&
        durationFormatted != '0:00') {
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
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
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
                  child: Icon(_getStatusIcon(), color: statusColor, size: 20),
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
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.tmid.isNotEmpty 
                            ? widget.entry.tmid 
                            : 'TMID: ${widget.entry.driverId}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.indigo.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PhoneMaskingUtils.maskPhoneNumber(
                          widget.entry.phoneNumber,
                        ),
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                      _formatDateTime(
                        widget.entry.callTime,
                        widget.entry.timeAgo,
                      ),
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
                      _formatDuration(
                        widget.entry.duration,
                        widget.entry.durationFormatted,
                      ),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Feedback Section
                if (widget.entry.feedback != null &&
                    widget.entry.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
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

                // Remarks Section - Always show
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (widget.entry.remarks != null &&
                            widget.entry.remarks!.isNotEmpty)
                        ? Colors.amber.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (widget.entry.remarks != null &&
                              widget.entry.remarks!.isNotEmpty)
                          ? Colors.amber.shade200
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: (widget.entry.remarks != null &&
                                widget.entry.remarks!.isNotEmpty)
                            ? Colors.amber.shade700
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remarks',
                              style: AppTheme.bodySmall.copyWith(
                                color: (widget.entry.remarks != null &&
                                        widget.entry.remarks!.isNotEmpty)
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (widget.entry.remarks != null &&
                                      widget.entry.remarks!.isNotEmpty)
                                  ? widget.entry.remarks!
                                  : 'No remarks added',
                              style: AppTheme.bodyMedium.copyWith(
                                color: (widget.entry.remarks != null &&
                                        widget.entry.remarks!.isNotEmpty)
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade400,
                                fontSize: 13,
                                fontStyle: (widget.entry.remarks == null ||
                                        widget.entry.remarks!.isEmpty)
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                size: 32,
                              ),
                        color: Colors.purple,
                        tooltip: _isPlaying
                            ? 'Pause Recording'
                            : 'Play Recording',
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

// Call History Entry Model
class CallHistoryEntry {
  final String id;
  final String driverId;
  final String tmid;
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
    required this.tmid,
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
  bool get hasRecording =>
      anyRecordingUrl != null && anyRecordingUrl!.isNotEmpty;
}
