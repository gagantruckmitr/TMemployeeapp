import '../../../core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../core/services/smart_calling_service.dart';
import '../../core/services/call_feedback_guard_service.dart';
import '../../core/services/match_making_feedback_guard_service.dart';
import '../../models/call_history_model.dart';
import '../../models/phase2_user_model.dart';
import '../../widgets/audio_player_widget.dart';
import 'widgets/call_feedback_modal.dart';
import '../telecaller/widgets/ivr_call_waiting_overlay.dart';
import '../telecaller/widgets/easygo_ivr_call_helper.dart';
import 'package:intl/intl.dart';
import '../main_container.dart' as main;

class CallHistoryScreen extends StatefulWidget {
  final String? initialPeriod;
  final String? initialFeedbackFilter;
  final bool showHeader;

  const CallHistoryScreen({
    super.key,
    this.initialPeriod,
    this.initialFeedbackFilter,
    this.showHeader = true,
  });

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<CallHistoryLog> _callLogs = [];
  Map<String, List<CallHistoryLog>> _groupedCallLogs = {};
  Map<String, bool> _expandedDrivers = {};
  bool _isLoading = true;
  String _selectedPeriod = 'all';
  String? _selectedFeedback;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Phase2User? _currentUser;

  final ScrollController _scrollController = ScrollController();
  bool _showFilters = true;
  double _lastScrollOffset = 0;

  // Pagination
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 100; // Increased page size to load more records

  final List<String> _periods = ['today', 'yesterday', 'week', 'month', 'all'];
  final List<String> _feedbackTypes = [
    'All',
    'Connected',
    'Not Connected',
    'Callback Later',
  ];

  // Check if embedded in hub (no header/tabs needed)
  bool get _isEmbedded => widget.initialPeriod != null;

  @override
  void initState() {
    super.initState();

    // Initialize from widget parameters if provided
    if (widget.initialPeriod != null) {
      _selectedPeriod = widget.initialPeriod!;
    }

    if (widget.initialFeedbackFilter != null) {
      _selectedFeedback = widget.initialFeedbackFilter;
    }

    // Determine initial tab index based on _selectedPeriod
    int initialIndex = _periods.indexOf(_selectedPeriod);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = _periods[_tabController.index];
        });
        _resetAndLoadData();
      }
    });

    _scrollController.addListener(_onScroll);
    _loadCurrentUser();
    _loadData();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // Show filters when scrolling down or at top, hide when scrolling up
    if (delta > 5 && _showFilters && currentOffset > 50) {
      setState(() => _showFilters = false);
    } else if (delta < -5 && !_showFilters) {
      setState(() => _showFilters = true);
    } else if (currentOffset <= 0 && !_showFilters) {
      setState(() => _showFilters = true);
    }

    _lastScrollOffset = currentOffset;

    // Infinite scroll
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await Phase2AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  void didUpdateWidget(CallHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If period changed from hub, reload data
    if (widget.initialPeriod != oldWidget.initialPeriod &&
        widget.initialPeriod != null) {
      setState(() {
        _selectedPeriod = widget.initialPeriod!;
      });
      _resetAndLoadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _groupCallLogsByDriver() {
    _groupedCallLogs.clear();
    for (var log in _callLogs) {
      final key = log.contactId; // Group by driver TMID
      if (!_groupedCallLogs.containsKey(key)) {
        _groupedCallLogs[key] = [];
      }
      _groupedCallLogs[key]!.add(log);
    }

    // Sort each group by date (most recent first)
    _groupedCallLogs.forEach((key, logs) {
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _resetAndLoadData() async {
    setState(() {
      _callLogs = [];
      _groupedCallLogs = {};
      _currentOffset = 0;
      _hasMore = true;
      _isLoading = true;
    });
    await _loadData();
  }

  Future<void> _loadMoreData() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });
    await _loadData(isLoadMore: true);
  }

  Future<void> _loadData({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await Phase2ApiService.fetchCallHistory(
        period: _selectedPeriod,
        feedbackFilter: _selectedFeedback == 'All' ? null : _selectedFeedback,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        limit: _pageSize,
        offset: _currentOffset,
      );

      final logs = (result['logs'] as List)
          .map((json) => CallHistoryLog.fromJson(json))
          .toList();

      setState(() {
        if (isLoadMore) {
          _callLogs.addAll(logs);
        } else {
          _callLogs = logs;
        }

        _groupCallLogsByDriver();

        if (logs.length < _pageSize) {
          _hasMore = false;
        } else {
          _currentOffset += _pageSize;
        }

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isEmbedded
          ? const Color(0xFFF2F2F7)
          : AppColors.background,
      body: Column(
        children: [
          // Only show header when not embedded in hub
          if (!_isEmbedded) _buildHeader(),
          // Only show period tabs when not embedded in hub
          if (!_isEmbedded) _buildPeriodTabs(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showFilters ? null : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showFilters ? 1.0 : 0.0,
              child: _buildFilters(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _groupedCallLogs.isEmpty
                ? _buildEmptyState()
                : _buildGroupedCallList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.darkGray,
                  size: 18,
                ),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const main.MainContainer(),
                      ),
                    );
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Drivers',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_groupedCallLogs.length} drivers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _resetAndLoadData,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Yesterday'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
            Tab(text: 'All'),
          ],
        ),
      ),
    );
  }

  // Helper to get short filter label for display
  String _getFilterLabel(String type) {
    switch (type) {
      case 'Not Connected':
        return 'Not Connected';
      case 'Callback Later':
        return 'Callback';
      default:
        return type;
    }
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Apple-style search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7), // iOS search bar background
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _resetAndLoadData();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
              onSubmitted: (_) => _resetAndLoadData(),
            ),
          ),
          const SizedBox(height: 12),
          // Apple-style filter pills
          Row(
            children: _feedbackTypes.map((type) {
              final isSelected =
                  _selectedFeedback == type ||
                  (type == 'All' && _selectedFeedback == null);

              // Define colors based on type
              Color bgColor;
              Color textColor;
              if (isSelected) {
                bgColor = const Color(0xFF1C1C1E);
                textColor = Colors.white;
              } else {
                bgColor = const Color(0xFFF2F2F7);
                textColor = const Color(0xFF1C1C1E);
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFeedback = type == 'All' ? null : type;
                    });
                    _resetAndLoadData();
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type != _feedbackTypes.last ? 6 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getFilterLabel(type),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedCallList() {
    final driverKeys = _groupedCallLogs.keys.toList();

    // Sort driver keys by the latest call date (most recent first)
    driverKeys.sort((a, b) {
      final aLatest = _groupedCallLogs[a]!.first.createdAt;
      final bLatest = _groupedCallLogs[b]!.first.createdAt;
      return bLatest.compareTo(aLatest);
    });

    return RefreshIndicator(
      onRefresh: _resetAndLoadData,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: driverKeys.length,
        itemBuilder: (context, index) {
          final driverKey = driverKeys[index];
          final driverLogs = _groupedCallLogs[driverKey]!;
          final isExpanded = _expandedDrivers[driverKey] ?? false;

          return Column(
            children: [
              _buildDriverCard(driverKey, driverLogs, isExpanded),
              if (index == driverKeys.length - 1 && _isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(
    String driverKey,
    List<CallHistoryLog> logs,
    bool isExpanded,
  ) {
    final latestLog = logs.first;
    final callCount = logs.length;

    // Calculate jobs count and feedback counts for expanded view
    final jobs = <String>{};
    final feedbackCounts = <String, int>{};
    for (var log in logs) {
      if (log.jobId.isNotEmpty) {
        jobs.add(log.jobId);
      }
      if (log.feedback.isNotEmpty) {
        feedbackCounts[log.feedback] = (feedbackCounts[log.feedback] ?? 0) + 1;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: () {
              setState(() {
                _expandedDrivers[driverKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with call count badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.grey.shade600,
                          size: 26,
                        ),
                      ),
                      if (callCount > 1)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '$callCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Driver info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestLog.contactName.isEmpty
                              ? 'Unknown Driver'
                              : latestLog.contactName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // TMID badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                latestLog.contactId,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time
                            Flexible(
                              child: Text(
                                _formatDateTime(latestLog.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Jobs count - subtle display
                        if (jobs.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${jobs.length} job${jobs.length > 1 ? 's' : ''} applied',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Call button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: Color(0xFF34C759),
                            size: 20,
                          ),
                          onPressed: () => _makeCall(latestLog),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expand arrow
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Latest feedback card - Apple style
          if (latestLog.feedback.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getFeedbackColor(latestLog.feedback).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getFeedbackColor(
                        latestLog.feedback,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFeedbackIcon(latestLog.feedback),
                      size: 18,
                      color: _getFeedbackColor(latestLog.feedback),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Feedback',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestLog.feedback,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getFeedbackColor(latestLog.feedback),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getFeedbackColor(latestLog.feedback),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      latestLog.matchStatus.isNotEmpty
                          ? latestLog.matchStatus
                          : _getStatusLabel(latestLog.feedback),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Job ID
            if (latestLog.jobId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      latestLog.jobId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(latestLog.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Feedback counts preview (when collapsed and has multiple)
          if (!isExpanded && feedbackCounts.length > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: feedbackCounts.entries.take(4).map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getFeedbackColor(entry.key).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.key} (${entry.value})',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getFeedbackColor(entry.key),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Expanded call history
          if (isExpanded) ...[
            Container(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Call History ($callCount calls)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...logs.map((log) => _buildCompactCallItem(log)).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to get status label from feedback
  String _getStatusLabel(String feedback) {
    final lowerFeedback = feedback.toLowerCase();
    // IMPORTANT: Check Not Connected FIRST to avoid false matches
    if (lowerFeedback.contains('ringing') ||
        lowerFeedback.contains('busy') ||
        lowerFeedback.contains('switched off') ||
        lowerFeedback.contains('not reachable') ||
        lowerFeedback.contains("didn't pick") ||
        lowerFeedback.contains("no answer") ||
        lowerFeedback.contains('not answered') ||
        lowerFeedback.contains('unreachable') ||
        lowerFeedback.contains('not available') ||
        lowerFeedback.contains('disconnected')) {
      return 'Not Connected';
    }

    // Callback Later
    if (lowerFeedback.contains('call back') ||
        lowerFeedback.contains('callback') ||
        lowerFeedback.contains('later') ||
        lowerFeedback.contains('tomorrow') ||
        lowerFeedback.contains('evening') ||
        lowerFeedback.contains('morning') ||
        lowerFeedback.contains('busy right now') ||
        lowerFeedback.contains('will confirm') ||
        lowerFeedback.contains('after 2 days')) {
      return 'Callback';
    }

    // Connected
    if (lowerFeedback.contains('interview') ||
        lowerFeedback.contains('selected') ||
        lowerFeedback.contains('interested') ||
        lowerFeedback.contains('done') ||
        lowerFeedback.contains('match making') ||
        lowerFeedback.contains('confirmed')) {
      return 'Connected';
    }

    return 'Pending';
  }

  Widget _buildCompactCallItem(CallHistoryLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _getFeedbackIcon(log.feedback),
                      size: 14,
                      color: _getFeedbackColor(log.feedback),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log.feedback.isEmpty ? 'No feedback' : log.feedback,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: log.feedback.isEmpty
                              ? Colors.grey.shade500
                              : AppColors.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDateTime(log.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (log.matchStatus.isNotEmpty || log.jobId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (log.matchStatus.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchStatusColor(
                        log.matchStatus,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.matchStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getMatchStatusColor(log.matchStatus),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (log.jobId.isNotEmpty)
                  Text(
                    log.jobId,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
          if (log.remark.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              log.remark,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (log.callRecording.isNotEmpty) ...[
            const SizedBox(height: 8),
            AudioPlayerWidget(recordingUrl: log.callRecording),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditFeedbackModal(log),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Old _buildCallCard method removed - now using _buildDriverCard with grouped calls

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No call history found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call logs will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showCallDetail(CallHistoryLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.1), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _getFeedbackColor(
                          log.feedback,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getFeedbackIcon(log.feedback),
                        color: _getFeedbackColor(log.feedback),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Call Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.contactName.isEmpty
                                ? 'Unknown Contact'
                                : log.contactName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Contact Information', [
                      _buildDetailRow('Name', log.contactName),
                      _buildDetailRow('Type', log.contactType),
                      _buildDetailRow('ID', log.contactId),
                      if (log.callerName.isNotEmpty)
                        _buildDetailRow('Called By', log.callerName),
                    ]),

                    const SizedBox(height: 20),

                    _buildDetailSection('Call Feedback', [
                      _buildDetailRow('Feedback', log.feedback),
                      if (log.matchStatus.isNotEmpty)
                        _buildDetailRow('Match Status', log.matchStatus),
                      if (log.remark.isNotEmpty)
                        _buildDetailRow('Remark', log.remark),
                    ]),

                    if (log.jobId.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Job Information', [
                        _buildDetailRow('Job ID', log.jobId),
                      ]),
                    ],

                    const SizedBox(height: 20),

                    _buildDetailSection('Timestamps', [
                      _buildDetailRow(
                        'Called At',
                        _formatDateTime(log.createdAt),
                      ),
                      _buildDetailRow(
                        'Updated At',
                        _formatDateTime(log.updatedAt),
                      ),
                    ]),

                    // Call Recording
                    if (log.callRecording.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      AudioPlayerWidget(recordingUrl: log.callRecording),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _makeCall(log);
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditFeedbackModal(log);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Store matchId for feedback submission
  String? _currentMatchId;

  // Make a phone call using EasyGo IVR with Laravel Job Matching API
  Future<void> _makeCall(CallHistoryLog log) async {
    try {
      // Debug log the mobile numbers
      print(
        '📱 [DEBUG _makeCall] driverMobile: "${log.driverMobile}", transporterMobile: "${log.transporterMobile}", contactMobile: "${log.contactMobile}"',
      );

      // Check if phone number is available
      if (log.contactMobile.isEmpty) {
        // Show informational dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Phone Number Not Available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To call ${log.contactName}, please find them in:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoStep('1', 'Smart Calling section'),
                const SizedBox(height: 8),
                _buildInfoStep('2', 'Jobs section'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contact ID: ${log.contactId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate back and let user go to smart calling from dashboard
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Get current user info for IVR call
      final currentUser = await Phase2AuthService.getCurrentUser();
      final currentUserId = currentUser?.id ?? 0;

      print(
        '🚀 [IVR DEBUG] CallHistoryScreen: Initiating IVR call for ${log.contactName}...',
      );
      print('🔵 Current User ID for assignedTo: $currentUserId');
      print('🔵 Driver TMID: ${log.uniqueIdDriver}');
      print('🔵 Driver User ID: ${log.userIdDriver}');
      print('🔵 Transporter TMID: ${log.uniqueIdTransporter}');
      print('🔵 Transporter User ID: ${log.userIdTransporter}');
      print('🔵 Job ID: ${log.jobId}');

      // Use EasyGo IVR with job matching API for driver calls
      // API: ${ApiConfig.laravelApiBase}/ivr-call-jobMatching
      await EasyGoIVRCallHelper.initiateCall(
        context: context,
        clientName: log.contactName,
        clientPhone: log.contactMobile,
        clientId: log.contactId,
        tmid: log.uniqueIdDriver.isNotEmpty
            ? log.uniqueIdDriver
            : log.contactId,
        contactType: 'driver',
        callSource:
            'job_applicants', // Use job_applicants to trigger job matching API
        onCallCompleted: (matchId) {
          print('🔵 Call completed with matchId: $matchId');
          _currentMatchId = matchId;
          _showCallFeedbackModal(log, matchId: matchId);
        },
        // Additional data for IVR call API (ivr-call-jobMatching)
        transporterTmid: log.uniqueIdTransporter.isNotEmpty
            ? log.uniqueIdTransporter
            : 'N/A',
        transporterName: log.transporterName.isNotEmpty
            ? log.transporterName
            : 'Unknown Transporter',
        transporterUserId: log.userIdTransporter,
        driverUserId: log.userIdDriver,
        jobId: log.jobId.isNotEmpty ? log.jobId : 'N/A',
        assignedTo: currentUserId,
      );
      return;
    } catch (e) {
      // Close any open dialogs
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  // Show feedback modal for new call
  void _showFeedbackModalForLog(CallHistoryLog log) {
    // Reload data and show edit feedback modal
    _loadData();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showEditFeedbackModal(log);
      }
    });
  }

  // Show edit feedback modal with role-based options
  void _showEditFeedbackModal(CallHistoryLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCallFeedbackModal(
        log: log,
        onUpdate: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _handleManualCall(
    CallHistoryLog log,
    String phoneNumber,
    int callerId,
    String contactId,
  ) async {
    try {
      final cleanMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Log manual call
      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: contactId,
      );

      if (result['success'] == true) {
        final driverMobileRaw = result['data']?['driver_mobile_raw'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Calling ${log.contactName}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Make direct call
        await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);

        // Show feedback modal immediately
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          _showCallFeedbackModal(log);
        }
      } else {
        final errorMsg = result['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log call: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleIVRCall(
    CallHistoryLog log,
    String phoneNumber,
    int callerId,
    String contactId,
  ) async {
    try {
      final cleanMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating IVR call...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Initiate IVR call
      final result = await SmartCallingService.instance.initiateClick2CallIVR(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: contactId,
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId = result['data']?['reference_id'];

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ IVR call initiated! Both phones will ring.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Show IVR waiting overlay
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: log.contactName,
                  referenceId: referenceId,
                  onCallEnded: () {
                    Navigator.of(context).pop();
                    _showCallFeedbackModal(log);
                  },
                ),
              ),
            ),
          );
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate IVR call: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Unused method removed: _showFeedbackModalForLog

  void _showCallFeedbackModal(
    CallHistoryLog log, {
    int? newCallId,
    String? matchId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent dismissal by tapping outside
      enableDrag: false, // Prevent dismissal by dragging down
      builder: (context) => CallFeedbackModal(
        userType: 'driver',
        userName: log.contactName,
        userTmid: log.uniqueIdDriver.isNotEmpty
            ? log.uniqueIdDriver
            : log.contactId,
        transporterTmid: log.uniqueIdTransporter.isNotEmpty
            ? log.uniqueIdTransporter
            : null,
        jobId: log.jobId.isNotEmpty ? log.jobId : null,
        showRecordingUpload: false, // Hide manual call upload
        onSubmit: (feedback, matchStatus, notes) async {
          try {
            final callerId = _currentUser?.id ?? 0;

            // Debug: Print the data being sent
            print('=== FEEDBACK SUBMISSION DEBUG ===');
            print('Caller ID: $callerId');
            print('Driver TMID: ${log.uniqueIdDriver}');
            print('Driver Name: ${log.driverName}');
            print('Transporter TMID: ${log.uniqueIdTransporter}');
            print('Transporter Name: ${log.transporterName}');
            print('Job ID: ${log.jobId}');
            print('Match ID: $matchId');
            print('Current Match ID: $_currentMatchId');
            print('Feedback: $feedback');
            print('Match Status: $matchStatus');
            print('================================');

            // Use matchId from parameter or stored _currentMatchId
            final effectiveMatchId = matchId ?? _currentMatchId;

            // If matchId is available, use the job matching feedback API
            // API: ${ApiConfig.laravelApiBase}/ivr-call-update-jobMatching
            if (effectiveMatchId != null && effectiveMatchId.isNotEmpty) {
              print('🔵 Using IVR Job Matching Feedback API');
              print(
                '🔵 API: ${ApiConfig.laravelApiBase}/ivr-call-update-jobMatching',
              );

              // Extract call_status from feedback string
              String callStatus = 'not_connected'; // default

              // Check for category prefix in feedback
              // IMPORTANT: Check "Not Connected" BEFORE "Connected" because "not connected" contains "connected"
              if (feedback.startsWith('Not Connected:') ||
                  feedback.toLowerCase().contains('not connected:')) {
                callStatus = 'not_connected';
              } else if (feedback.startsWith('Call Back Later:') ||
                  feedback.toLowerCase().contains('call back later:')) {
                callStatus = 'callback_later';
              } else if (feedback.startsWith('Connected:') ||
                  feedback.toLowerCase().contains('connected:')) {
                callStatus = 'connected';
              } else {
                // Fallback: check if feedback matches known options
                final connectedOptions = [
                  'Driver Interested',
                  'Driver Not Interested',
                  'Driver Already Booked / Busy',
                  'Driver Does Not Work on That Route',
                  'Driver Rate Mismatch',
                  'Vehicle Not Available',
                  'Vehicle Type Not Matching',
                  'Driver Wants More Details',
                  'Driver Wants to Speak to Transporter',
                  'Driver Wants Call Back Later',
                  'Driver Requested Callback on WhatsApp',
                ];
                final notConnectedOptions = [
                  'Ringing – No Answer',
                  'Switched Off',
                  'Not Reachable',
                  'Call Disconnected',
                  'Number Busy',
                  'Wrong Number',
                  'Third Person Received – Asked to Call Later',
                ];
                final callBackOptions = [
                  'Busy Right Now',
                  'Call Tomorrow Morning',
                  'Call in Evening',
                  'Call After 2 Days',
                ];

                if (connectedOptions.any(
                  (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
                )) {
                  callStatus = 'connected';
                } else if (notConnectedOptions.any(
                  (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
                )) {
                  callStatus = 'not_connected';
                } else if (callBackOptions.any(
                  (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
                )) {
                  callStatus = 'callback_later';
                }
              }

              // Extract just the option name (e.g., "Interview Done" from "Connected: Interview Done")
              String callFeedback = feedback;
              if (feedback.contains(':')) {
                callFeedback = feedback.split(':').last.trim();
              }

              print('🔵 Match ID: $effectiveMatchId');
              print('🔵 Extracted call_status: $callStatus');
              print('🔵 Extracted call_feedback: $callFeedback');
              print('🔵 Call Remarks: $notes');

              await Phase2ApiService.updateIVRCallJobMatchingFeedback(
                matchId: effectiveMatchId,
                callStatus: callStatus,
                callFeedback: callFeedback,
                callRemarks: notes,
                matchStatus: matchStatus,
              );
            } else if (newCallId != null) {
              // Update using Live API for new calls
              await SmartCallingService.instance.updateEasyGoCallFeedback(
                callId: newCallId,
                status: matchStatus, // e.g. 'connected'
                feedback: feedback, // e.g. 'Interested'
                remarks: notes,
              );
            } else {
              // Legacy update for existing history logs
              await Phase2ApiService.saveCallFeedback(
                callerId: callerId,
                transporterTmid: log.uniqueIdTransporter.isNotEmpty
                    ? log.uniqueIdTransporter
                    : null,
                driverTmid: log.uniqueIdDriver.isNotEmpty
                    ? log.uniqueIdDriver
                    : null,
                driverName: log.driverName,
                transporterName: log.transporterName,
                feedback: feedback,
                matchStatus: matchStatus,
                notes: notes,
                jobId: log.jobId.isNotEmpty ? log.jobId : null,
              );
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call feedback saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // Clear pending feedback cache
              CallFeedbackGuardService.instance.clearCache();
              MatchMakingFeedbackGuardService.instance.clearCache();
              // Clear stored matchId
              _currentMatchId = null;
              _loadData();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving feedback: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Color _getFeedbackColor(String feedback) {
    final lowerFeedback = feedback.toLowerCase();

    // Not Connected - RED
    if (lowerFeedback.contains('ringing') ||
        lowerFeedback.contains('busy') ||
        lowerFeedback.contains('switched off') ||
        lowerFeedback.contains('not reachable') ||
        lowerFeedback.contains("didn't pick") ||
        lowerFeedback.contains("no answer") ||
        lowerFeedback.contains('not answered') ||
        lowerFeedback.contains('unreachable') ||
        lowerFeedback.contains('not available') ||
        lowerFeedback.contains('disconnected') ||
        lowerFeedback.contains('not selected')) {
      return const Color(0xFFFF3B30); // iOS Red
    }

    // Callback Later - YELLOW/AMBER
    if (lowerFeedback.contains('call back') ||
        lowerFeedback.contains('callback') ||
        lowerFeedback.contains('later') ||
        lowerFeedback.contains('tomorrow') ||
        lowerFeedback.contains('evening') ||
        lowerFeedback.contains('morning') ||
        lowerFeedback.contains('busy right now') ||
        lowerFeedback.contains('will confirm') ||
        lowerFeedback.contains('after 2 days')) {
      return const Color(0xFFFF9500); // iOS Orange/Amber
    }

    // Connected - GREEN
    if (lowerFeedback.contains('interview') ||
        lowerFeedback.contains('selected') ||
        lowerFeedback.contains('interested') ||
        lowerFeedback.contains('done') ||
        lowerFeedback.contains('match making') ||
        lowerFeedback.contains('confirmed')) {
      return const Color(0xFF34C759); // iOS Green
    }

    // Default - Grey
    return Colors.grey.shade600;
  }

  Color _getMatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return Colors.green.shade600;
      case 'not connected':
        return Colors.red.shade600;
      case 'callback later':
        return Colors.orange.shade600;
      case 'selected':
        return Colors.green.shade600;
      case 'not selected':
        return Colors.red.shade600;
      case 'pending':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getFeedbackIcon(String feedback) {
    switch (feedback.toLowerCase()) {
      case 'interview done':
      case 'match making done':
        return Icons.check_circle;
      case 'not selected':
        return Icons.cancel;
      case 'switched off':
      case 'not reachable':
        return Icons.phone_disabled;
      case 'will confirm later':
        return Icons.schedule;
      default:
        return Icons.phone;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();

    // Compare calendar dates, not time differences
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

    if (dateOnly == todayOnly) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateOnly == yesterdayOnly) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }
}

// Edit Call Feedback Modal with Recording Upload Support
class _EditCallFeedbackModal extends StatefulWidget {
  final CallHistoryLog log;
  final VoidCallback onUpdate;

  const _EditCallFeedbackModal({required this.log, required this.onUpdate});

  @override
  State<_EditCallFeedbackModal> createState() => _EditCallFeedbackModalState();
}

class _EditCallFeedbackModalState extends State<_EditCallFeedbackModal> {
  late String? _selectedFeedback;
  late String? _selectedMatchStatus;
  late TextEditingController _notesController;
  File? _selectedRecordingFile;
  String? _selectedRecordingName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedFeedback = widget.log.feedback.isNotEmpty
        ? widget.log.feedback
        : null;
    _selectedMatchStatus = widget.log.matchStatus.isNotEmpty
        ? widget.log.matchStatus
        : null;
    _notesController = TextEditingController(text: widget.log.remark);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRecording() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
          'flac',
          'wma',
          'amr',
          'opus',
          '3gp',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedRecordingFile = File(result.files.single.path!);
          _selectedRecordingName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (_selectedFeedback == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload recording if selected
      String? recordingUrl;
      if (_selectedRecordingFile != null) {
        try {
          final uploadResult = await Phase2ApiService.uploadCallRecording(
            filePath: _selectedRecordingFile!.path,
            jobId: widget.log.jobId,
            callerId: widget.log.callerId,
            driverTmid: widget.log.contactType == 'Driver'
                ? widget.log.contactId
                : null,
            transporterTmid: widget.log.contactType == 'Transporter'
                ? widget.log.contactId
                : null,
          );
          if (uploadResult['success'] == true) {
            recordingUrl = uploadResult['recording_url'];
          }
        } catch (e) {
          print('Error uploading recording: $e');
          // Continue without recording if upload fails
        }
      }

      // 2. Create NEW feedback entry (Insert instead of Update)
      await Phase2ApiService.saveCallFeedback(
        callerId: widget.log.callerId,
        driverTmid: widget.log.contactType == 'Driver'
            ? widget.log.contactId
            : null,
        transporterTmid: widget.log.contactType == 'Transporter'
            ? widget.log.contactId
            : null,
        driverName: widget.log.contactType == 'Driver'
            ? widget.log.contactName
            : null,
        transporterName: widget.log.contactType == 'Transporter'
            ? widget.log.contactName
            : null,
        feedback: _selectedFeedback!,
        matchStatus: _selectedMatchStatus,
        notes: _notesController.text,
        jobId: widget.log.jobId,
        callRecording: recordingUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New feedback submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Feedback',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        '${widget.log.contactName} • ${widget.log.contactId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Connected',
                    Icons.check_circle_outline,
                    Colors.green,
                    [
                      'Interview Done',
                      'Not Selected',
                      'Not Interested',
                      'Interview Fixed',
                      'Ready for Interview',
                      'Will Confirm Later',
                      'Match Making Done',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    '2. Not Connected',
                    Icons.phone_disabled_outlined,
                    Colors.orange,
                    [
                      'Ringing',
                      'Call Busy',
                      'Switched Off',
                      'Not Reachable',
                      'Disconnected',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    '3. Call Back Later',
                    Icons.schedule_outlined,
                    Colors.blue,
                    [
                      'Busy Right Now',
                      'Call Tomorrow Morning',
                      'Call in Evening',
                      'Call After 2 Days',
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '4. Match Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMatchStatusChip('Selected'),
                      _buildMatchStatusChip('Not Selected'),
                      _buildMatchStatusChip('Pending'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '5. Additional Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter any remarks or follow-up details...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.log.jobId.isNotEmpty) ...[
                    const Text(
                      '6. Call Recording (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          if (_selectedRecordingName != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.audiotrack,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedRecordingName!,
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedRecordingFile = null;
                                      _selectedRecordingName = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recording will be uploaded when you update feedback',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: _pickRecording,
                              icon: const Icon(Icons.attach_file, size: 18),
                              label: const Text('Select Recording File'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.log.callRecording.isNotEmpty
                                  ? 'Replace existing recording or leave empty to keep current'
                                  : 'Select audio file from your device storage',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedFeedback != null && !_isSubmitting
                          ? _submitUpdate
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedRecordingFile != null
                                  ? 'Submit Feedback & Upload Recording'
                                  : 'Submit New Feedback',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((option) => _buildFeedbackChip(option, color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFeedbackChip(String label, Color color) {
    final isSelected = _selectedFeedback == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedback = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchStatusChip(String label) {
    final isSelected = _selectedMatchStatus == label;
    final color = label == 'Selected'
        ? Colors.green
        : label == 'Not Selected'
        ? Colors.red
        : Colors.orange;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMatchStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
