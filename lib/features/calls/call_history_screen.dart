import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../core/services/smart_calling_service.dart';
import '../../models/call_history_model.dart';
import '../../models/phase2_user_model.dart';
import '../../widgets/audio_player_widget.dart';
import 'widgets/call_feedback_modal.dart';
import '../telecaller/widgets/call_type_selection_dialog.dart';
import '../telecaller/widgets/ivr_call_waiting_overlay.dart';
import '../telecaller/widgets/easygo_ivr_call_helper.dart';
import 'package:intl/intl.dart';
import '../main_container.dart' as main;

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

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
  static const int _pageSize = 20;

  final List<String> _periods = ['all', 'today', 'week', 'month'];
  final List<String> _feedbackTypes = [
    'All',
    'Interview Done',
    'Not Selected',
    'Switched Off',
    'Match Making Done',
    'Will Confirm Later',
    'Ringing',
    'Call Busy',
    'Busy Right Now',
    'Not Reachable',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildPeriodTabs(),
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
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _resetAndLoadData();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => _resetAndLoadData(),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _feedbackTypes.map((type) {
                final isSelected =
                    _selectedFeedback == type ||
                    (type == 'All' && _selectedFeedback == null);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(type, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeedback = type == 'All' ? null : type;
                      });
                      _resetAndLoadData();
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedCallList() {
    final driverKeys = _groupedCallLogs.keys.toList();

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

    // Calculate detailed statistics
    final feedbackCounts = <String, int>{};
    final jobs = <String>{};
    final matchStatuses = <String, int>{};
    int connectedCalls = 0;
    int notConnectedCalls = 0;
    int callbackCalls = 0;

    for (var log in logs) {
      if (log.feedback.isNotEmpty) {
        feedbackCounts[log.feedback] = (feedbackCounts[log.feedback] ?? 0) + 1;

        // Categorize feedback
        final feedback = log.feedback.toLowerCase();
        if (feedback.contains('interview') ||
            feedback.contains('selected') ||
            feedback.contains('interested') ||
            feedback.contains('match making')) {
          connectedCalls++;
        } else if (feedback.contains('ringing') ||
            feedback.contains('busy') ||
            feedback.contains('switched off') ||
            feedback.contains('not reachable')) {
          notConnectedCalls++;
        } else if (feedback.contains('call') ||
            feedback.contains('later') ||
            feedback.contains('tomorrow') ||
            feedback.contains('evening')) {
          callbackCalls++;
        }
      }
      if (log.jobId.isNotEmpty) {
        jobs.add(log.jobId);
      }
      if (log.matchStatus.isNotEmpty) {
        matchStatuses[log.matchStatus] =
            (matchStatuses[log.matchStatus] ?? 0) + 1;
      }
    }

    final successRate = callCount > 0
        ? (connectedCalls / callCount * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedDrivers[driverKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with call count badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.15),
                                  AppColors.primary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$callCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGray,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 10,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        latestLog.contactId,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    _formatDateTime(latestLog.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Enhanced stats row
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                // Success rate
                                _buildStatChip(
                                  icon: Icons.trending_up,
                                  label: '$successRate% success',
                                  color: successRate >= 50
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                // Jobs count
                                if (jobs.isNotEmpty)
                                  _buildStatChip(
                                    icon: Icons.work_outline,
                                    label:
                                        '${jobs.length} job${jobs.length > 1 ? 's' : ''}',
                                    color: Colors.blue,
                                  ),
                                // Connected calls
                                if (connectedCalls > 0)
                                  _buildStatChip(
                                    icon: Icons.check_circle_outline,
                                    label: '$connectedCalls connected',
                                    color: Colors.green,
                                  ),
                                // Not connected
                                if (notConnectedCalls > 0)
                                  _buildStatChip(
                                    icon: Icons.phone_disabled_outlined,
                                    label: '$notConnectedCalls missed',
                                    color: Colors.red,
                                  ),
                                // Callbacks
                                if (callbackCalls > 0)
                                  _buildStatChip(
                                    icon: Icons.schedule_outlined,
                                    label: '$callbackCalls callback',
                                    color: Colors.amber,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.phone,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              onPressed: () => _makeCall(latestLog),
                              tooltip: 'Call',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Latest feedback and match status with more details
                  if (latestLog.feedback.isNotEmpty ||
                      latestLog.matchStatus.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getFeedbackColor(
                              latestLog.feedback,
                            ).withOpacity(0.05),
                            _getFeedbackColor(
                              latestLog.feedback,
                            ).withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getFeedbackColor(
                            latestLog.feedback,
                          ).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _getFeedbackColor(
                                    latestLog.feedback,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getFeedbackIcon(latestLog.feedback),
                                  size: 14,
                                  color: _getFeedbackColor(latestLog.feedback),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Latest Feedback',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      latestLog.feedback,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _getFeedbackColor(
                                          latestLog.feedback,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (latestLog.matchStatus.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getMatchStatusColor(
                                      latestLog.matchStatus,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getMatchStatusColor(
                                          latestLog.matchStatus,
                                        ).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    latestLog.matchStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (latestLog.jobId.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 10,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  latestLog.jobId,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDateTime(latestLog.createdAt),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Feedback breakdown (if multiple feedbacks)
                  if (feedbackCounts.length > 1 && !isExpanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: feedbackCounts.entries.take(3).map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getFeedbackColor(
                              entry.key,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getFeedbackColor(
                                entry.key,
                              ).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${entry.key} (${entry.value})',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _getFeedbackColor(entry.key),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded call history
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
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
              TextButton.icon(
                onPressed: () => _confirmDelete(log),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
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

  // Make a phone call using EasyGo IVR
  Future<void> _makeCall(CallHistoryLog log) async {
    try {
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

      // Use EasyGo IVR for all calls
      await EasyGoIVRCallHelper.initiateCall(
        context: context,
        clientName: log.contactName,
        clientPhone: log.contactMobile,
        clientId: log.contactId,
        contactType: log.contactType.toLowerCase(),
        onCallEnded: () {
          // Show feedback modal after call
          _showFeedbackModalForLog(log);
        },
      );
      return;

      // OLD CODE - Keeping for reference but not used
      // Show call type selection dialog
      // final callType = await showDialog<String>(
      //   context: context,
      //   builder: (context) => CallTypeSelectionDialog(
      //     driverName: log.contactName,
      //   ),
      // );

      // if (callType == null) return;

      // // Get phone number from the call history log
      // final phoneNumber = log.contactMobile;

      // if (phoneNumber.isEmpty) {
      //   // Show informational dialog
      //   showDialog(
      //     context: context,
      //     builder: (context) => AlertDialog(
      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //       title: Row(
      //         children: [
      //           Icon(Icons.info_outline, color: AppTheme.primaryBlue),
      //           const SizedBox(width: 12),
      //           const Expanded(
      //             child: Text(
      //               'Phone Number Not Available',
      //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      //             ),
      //           ),
      //         ],
      //       ),
      //       content: Column(
      //         mainAxisSize: MainAxisSize.min,
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           Text(
      //             'To call ${log.contactName}, please find them in:',
      //             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      //           ),
      //           const SizedBox(height: 12),
      //           _buildInfoStep('1', 'Smart Calling section'),
      //           const SizedBox(height: 8),
      //           _buildInfoStep('2', 'Jobs section'),
      //           const SizedBox(height: 16),
      //           Container(
      //             padding: const EdgeInsets.all(12),
      //             decoration: BoxDecoration(
      //               color: Colors.blue.shade50,
      //               borderRadius: BorderRadius.circular(8),
      //               border: Border.all(color: Colors.blue.shade200),
      //             ),
      //             child: Row(
      //               children: [
      //                 Icon(Icons.security, size: 16, color: Colors.blue.shade700),
      //                 const SizedBox(width: 8),
      //                 Expanded(
      //                   child: Text(
      //                     'Contact ID: ${log.contactId}',
      //                     style: TextStyle(
      //                       fontSize: 11,
      //                       color: Colors.blue.shade700,
      //                       fontWeight: FontWeight.w600,
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ),
      //       actions: [
      //         TextButton(
      //           onPressed: () => Navigator.pop(context),
      //           child: const Text('Got it'),
      //         ),
      //         ElevatedButton(
      //           onPressed: () {
      //             Navigator.pop(context);
      //             // Navigate back and let user go to smart calling from dashboard
      //             Navigator.pop(context);
      //           },
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: AppTheme.primaryBlue,
      //           ),
      //           child: const Text('OK'),
      //         ),
      //       ],
      //     ),
      //   );
      //   return;
      // }

      // final callerId = _currentUser?.id ?? 0;
      // final contactId = log.contactId;

      // if (callType == 'manual') {
      //   await _handleManualCall(log, phoneNumber, callerId, contactId);
      // } else if (callType == 'easygo_ivr') {
      //   await _handleIVRCall(log, phoneNumber, callerId, contactId);
      // }
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
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCallFeedbackModal(CallHistoryLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: log.contactType.toLowerCase(),
        userName: log.contactName,
        userTmid: log.contactId,
        transporterTmid: log.uniqueIdTransporter.isNotEmpty
            ? log.uniqueIdTransporter
            : null,
        jobId: log.jobId.isNotEmpty ? log.jobId : null,
        onSubmit: (feedback, matchStatus, notes) async {
          try {
            await Phase2ApiService.saveCallFeedback(
              callerId: _currentUser?.id ?? 0,
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

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call feedback saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
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

  void _confirmDelete(CallHistoryLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call Log'),
        content: const Text('Are you sure you want to delete this call log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Phase2ApiService.deleteCallLog(log.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call log deleted')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getFeedbackColor(String feedback) {
    switch (feedback.toLowerCase()) {
      case 'interview done':
      case 'match making done':
        return Colors.green.shade600;
      case 'not selected':
        return Colors.red.shade600;
      case 'switched off':
      case 'not reachable':
      case 'disconnected':
        return Colors.orange.shade600;
      case 'will confirm later':
      case 'busy right now':
      case 'call tomorrow morning':
      case 'call in evening':
      case 'call after 2 days':
        return Colors.blue.shade600;
      case 'ringing':
      case 'call busy':
      case 'didn\'t pick':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getMatchStatusColor(String status) {
    switch (status.toLowerCase()) {
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
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
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
