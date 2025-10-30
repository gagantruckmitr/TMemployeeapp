import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/smart_calling_service.dart';

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

  const _CallHistoryList({
    required this.history,
    required this.scrollController,
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
        );
      },
    );
  }
}

class _CallHistoryCard extends StatelessWidget {
  final CallHistoryEntry entry;

  const _CallHistoryCard({
    super.key,
    required this.entry,
  });

  Color _getStatusColor() {
    switch (entry.status) {
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
    switch (entry.status) {
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

    return GestureDetector(
      onTap: () {
        // Navigate to driver detail page
        context.push(
          '/dashboard/driver-detail/${entry.driverId}/${Uri.encodeComponent(entry.driverName)}',
        );
      },
      child: Container(
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
                        entry.driverName,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        entry.phoneNumber,
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
                    entry.status.name.toUpperCase(),
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
                      _formatDateTime(entry.callTime, entry.timeAgo),
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
                      _formatDuration(entry.duration, entry.durationFormatted),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Feedback Section
                if (entry.feedback != null && entry.feedback!.isNotEmpty) ...[
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
                                entry.feedback!,
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
                if (entry.remarks != null && entry.remarks!.isNotEmpty) ...[
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
                                entry.remarks!,
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
              ],
            ),
          ),
        ],
      ),
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
  });
}
