import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../models/manager_models.dart';
import '../../core/services/manager_service.dart';
import '../../core/theme/app_theme.dart';

class TelecallerDetailPageModern extends StatefulWidget {
  final int telecallerId;
  final int managerId;

  const TelecallerDetailPageModern({
    super.key,
    required this.telecallerId,
    required this.managerId,
  });

  @override
  State<TelecallerDetailPageModern> createState() =>
      _TelecallerDetailPageModernState();
}

class _TelecallerDetailPageModernState extends State<TelecallerDetailPageModern>
    with SingleTickerProviderStateMixin {
  final ManagerService _managerService = ManagerService();
  late TabController _tabController;
  Timer? _refreshTimer;

  bool _isLoading = true;
  TelecallerDetails? _details;
  Map<String, dynamic>? _callDetails;
  Map<String, dynamic>? _assignments;
  Map<String, dynamic>? _performance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _loadAllData(silent: true);
    });
  }

  Future<void> _loadAllData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final details = await _managerService.getTelecallerDetails(
        widget.telecallerId,
      );
      if (mounted) setState(() => _details = details);

      try {
        final callDetails = await _managerService.getTelecallerCallDetails(
          telecallerId: widget.telecallerId,
        );
        if (mounted) setState(() => _callDetails = callDetails);
      } catch (e) {
        debugPrint('Call details error: $e');
      }

      try {
        final assignments = await _managerService.getDriverAssignments(
          telecallerId: widget.telecallerId,
        );
        debugPrint('📋 Assignments response: $assignments');
        debugPrint('📋 Assignments count: ${assignments['assignments']?.length ?? 0}');
        if (mounted) setState(() => _assignments = assignments);
      } catch (e) {
        debugPrint('❌ Assignments error: $e');
      }

      try {
        final performance = await _managerService.getTelecallerPerformance(
          widget.telecallerId,
        );
        if (mounted) setState(() => _performance = performance);
      } catch (e) {
        debugPrint('Performance error: $e');
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading && _details == null
          ? _buildLoadingState()
          : _error != null && _details == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final telecaller = _details!.telecaller;
    final stats = _details!.todayStats;
    // Use assignments from details first (from getTelecallerDetails API), then from separate API call
    final assignmentsCount = _details!.assignments.length > 0 
        ? _details!.assignments.length 
        : (_assignments?['assignments']?.length ?? 0);
    final summary = _callDetails?['summary'] ?? {};
    
    debugPrint('📊 Build Content - Assignments from details: ${_details!.assignments.length}, from API: ${_assignments?['assignments']?.length ?? 0}');

    return CustomScrollView(
      slivers: [
        _buildAppBar(telecaller),
        SliverToBoxAdapter(child: _buildProfileSection(telecaller)),
        SliverToBoxAdapter(
          child: _buildQuickStats(telecaller, stats, assignmentsCount, summary),
        ),
        SliverToBoxAdapter(child: _buildTabBar()),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(telecaller, stats, summary),
              _buildPerformanceTab(stats, summary),
              _buildAssignmentsTab(),
              _buildCallsTab(),
              _buildAnalyticsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(TelecallerInfo telecaller) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.accentColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'telecaller_${telecaller.id}',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        telecaller.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  telecaller.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      telecaller.mobile,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatusBadge(telecaller.currentStatus),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _loadAllData(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showMoreOptions(telecaller),
          tooltip: 'More options',
        ),
      ],
    );
  }

  void _showMoreOptions(TelecallerInfo telecaller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Telecaller'),
              onTap: () {
                Navigator.pop(context);
                _makeCall(telecaller.mobile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _sendMessage(telecaller.mobile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('Send Email'),
              onTap: () {
                Navigator.pop(context);
                if (telecaller.email != null) {
                  _sendEmail(telecaller.email!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.purple),
              title: const Text('Copy Mobile Number'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: telecaller.mobile));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mobile number copied!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _makeCall(String mobile) {
    // Implement call functionality
  }

  void _sendMessage(String mobile) {
    // Implement SMS functionality
  }

  void _sendEmail(String email) {
    // Implement email functionality
  }

  Widget _buildProfileSection(TelecallerInfo telecaller) {
    final loginTime = telecaller.loginTime;
    final lastActivity = telecaller.lastActivity;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge, 'ID', '#${telecaller.id}'),
          if (telecaller.email != null)
            _buildInfoRow(Icons.email, 'Email', telecaller.email!),
          if (loginTime != null)
            _buildInfoRow(
              Icons.login,
              'Login Time',
              DateFormat('hh:mm a').format(loginTime),
            ),
          if (lastActivity != null)
            _buildInfoRow(
              Icons.access_time,
              'Last Activity',
              _formatTimeAgo(lastActivity),
            ),
          _buildInfoRow(
            Icons.timer,
            'Session Duration',
            _calculateSessionDuration(loginTime),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM dd, hh:mm a').format(dateTime);
  }

  String _calculateSessionDuration(DateTime? loginTime) {
    if (loginTime == null) return 'N/A';
    final duration = DateTime.now().difference(loginTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildStatusBadge(TelecallerStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TelecallerStatus.online:
        color = Colors.green;
        text = 'Online';
        icon = Icons.circle;
        break;
      case TelecallerStatus.onCall:
        color = Colors.blue;
        text = 'On Call';
        icon = Icons.phone_in_talk;
        break;
      case TelecallerStatus.break_:
        color = Colors.orange;
        text = 'Break';
        icon = Icons.coffee;
        break;
      case TelecallerStatus.busy:
        color = Colors.amber;
        text = 'Busy';
        icon = Icons.work;
        break;
      default:
        color = Colors.grey;
        text = 'Offline';
        icon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    TelecallerInfo telecaller,
    TodayStats stats,
    int assignmentsCount,
    Map<String, dynamic> summary,
  ) {
    debugPrint('📊 Quick Stats - Received assignmentsCount: $assignmentsCount');
    final totalCalled =
        int.tryParse(summary['unique_drivers']?.toString() ?? '0') ?? 0;
    final remaining = assignmentsCount > totalCalled
        ? assignmentsCount - totalCalled
        : 0;
    final avgDuration = stats.totalCalls > 0
        ? (stats.totalDuration / stats.totalCalls).round()
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.accentColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatItem(
                  Icons.assignment_outlined,
                  'Assigned',
                  assignmentsCount.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.phone_outlined,
                  'Called',
                  totalCalled.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.pending_outlined,
                  'Remaining',
                  remaining.toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.check_circle_outline,
                  'Connected',
                  stats.connected.toString(),
                  Colors.purple,
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatItem(
                  Icons.star_outline,
                  'Interested',
                  stats.interested.toString(),
                  Colors.amber,
                ),
                _buildStatItem(
                  Icons.trending_up,
                  'Conv. Rate',
                  '${stats.conversionRate.toStringAsFixed(1)}%',
                  Colors.teal,
                ),
                _buildStatItem(
                  Icons.timer_outlined,
                  'Avg Duration',
                  '${avgDuration}s',
                  Colors.indigo,
                ),
                _buildStatItem(
                  Icons.access_time,
                  'Total Time',
                  _formatDuration(stats.totalDuration),
                  Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${seconds}s';
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Overview'),
          Tab(icon: Icon(Icons.analytics, size: 18), text: 'Performance'),
          Tab(icon: Icon(Icons.assignment, size: 18), text: 'Assignments'),
          Tab(icon: Icon(Icons.history, size: 18), text: 'Calls'),
          Tab(icon: Icon(Icons.insights, size: 18), text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    TelecallerInfo telecaller,
    TodayStats stats,
    Map<String, dynamic> summary,
  ) {
    // Use assignments from details first (from getTelecallerDetails API), then from separate API call
    final assignmentsCount = _details?.assignments.length ?? _assignments?['assignments']?.length ?? 0;
    final totalCalled =
        int.tryParse(summary['unique_drivers']?.toString() ?? '0') ?? 0;
    final remaining = assignmentsCount > totalCalled
        ? assignmentsCount - totalCalled
        : 0;
    
    debugPrint('📊 Overview Tab - Assignments: $assignmentsCount, Called: $totalCalled, Remaining: $remaining');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Lead Assignment Summary'),
          const SizedBox(height: 12),
          _buildLeadSummaryCard(assignmentsCount, totalCalled, remaining),
          const SizedBox(height: 20),
          _buildSectionTitle('Today\'s Summary'),
          const SizedBox(height: 12),
          _buildSummaryCard(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('Call Breakdown'),
          const SizedBox(height: 12),
          _buildCallBreakdownCard(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('Performance Metrics'),
          const SizedBox(height: 12),
          _buildMetricsGrid(stats),
        ],
      ),
    );
  }

  Widget _buildLeadSummaryCard(int total, int called, int remaining) {
    final progress = total > 0 ? (called / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLeadStatItem('Total Leads', total.toString(), Icons.people),
              Container(width: 1, height: 50, color: Colors.white30),
              _buildLeadStatItem(
                'Called',
                called.toString(),
                Icons.phone_forwarded,
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              _buildLeadStatItem(
                'Remaining',
                remaining.toString(),
                Icons.pending_actions,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSummaryCard(TodayStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Calls', stats.totalCalls.toString()),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildSummaryItem('Connected', stats.connected.toString()),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildSummaryItem('Interested', stats.interested.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Conversion Rate: ${stats.conversionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildCallBreakdownCard(TodayStats stats) {
    final total = stats.totalCalls;
    final connectedPercent = total > 0
        ? (stats.connected / total * 100).toDouble()
        : 0.0;
    final interestedPercent = total > 0
        ? (stats.interested / total * 100).toDouble()
        : 0.0;
    final notInterestedPercent = total > 0
        ? (stats.notInterested / total * 100).toDouble()
        : 0.0;
    final callbacksPercent = total > 0
        ? (stats.callbacks / total * 100).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            'Connected',
            stats.connected,
            connectedPercent,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            'Interested',
            stats.interested,
            interestedPercent,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            'Not Interested',
            stats.notInterested,
            notInterestedPercent,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            'Callbacks',
            stats.callbacks,
            callbacksPercent,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    int value,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '$value (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(TodayStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Connection Rate',
          '${stats.connectionRate.toStringAsFixed(1)}%',
          Icons.link,
          Colors.blue,
        ),
        _buildMetricCard(
          'Conversion Rate',
          '${stats.conversionRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildMetricCard(
          'Total Duration',
          _formatDuration(stats.totalDuration),
          Icons.timer,
          Colors.purple,
        ),
        _buildMetricCard(
          'Avg Duration',
          stats.totalCalls > 0
              ? '${(stats.totalDuration / stats.totalCalls).round()}s'
              : '0s',
          Icons.access_time,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(TodayStats stats, Map<String, dynamic> summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance Overview'),
          const SizedBox(height: 12),
          _buildPerformanceChart(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('Key Metrics'),
          const SizedBox(height: 12),
          _buildMetricsGrid(stats),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(TodayStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Call Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Connected', stats.connected, Colors.green),
                _buildBar('Interested', stats.interested, Colors.orange),
                _buildBar('Not Int.', stats.notInterested, Colors.red),
                _buildBar('Callbacks', stats.callbacks, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color) {
    final maxValue = _details?.todayStats.totalCalls ?? 1;
    final height = maxValue > 0 ? (value / maxValue * 150) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAssignmentsTab() {
    // Try to get assignments from details first, then from separate API call
    List<dynamic> assignments = [];
    
    if (_details?.assignments != null && _details!.assignments.isNotEmpty) {
      // Convert DriverAssignment objects to maps for display
      assignments = _details!.assignments.map((a) => {
        'driver_id': a.driverId,
        'driver_name': a.driverName,
        'driver_mobile': a.driverMobile,
        'assigned_at': a.assignedAt.toIso8601String(),
        'status': a.status,
        'priority': a.priority,
        'total_calls': 0,
        'connected_calls': 0,
        'interested_calls': 0,
      }).toList();
    } else if (_assignments != null) {
      assignments = _assignments!['assignments'] as List? ?? [];
    }
    
    debugPrint('📋 Assignments Tab - Count: ${assignments.length}');
    
    if (assignments.isEmpty && _details == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (assignments.isEmpty) {
      return _buildEmptyState('No assignments yet', Icons.assignment_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final driverName = assignment['driver_name'] ?? 'Unknown';
    final mobile = assignment['driver_mobile'] ?? assignment['mobile'] ?? '';
    final assignedAt = assignment['assigned_at'] != null
        ? DateTime.parse(assignment['assigned_at'])
        : null;
    final totalCalls =
        int.tryParse(assignment['total_calls']?.toString() ?? '0') ?? 0;
    final connectedCalls =
        int.tryParse(assignment['connected_calls']?.toString() ?? '0') ?? 0;
    final interestedCalls =
        int.tryParse(assignment['interested_calls']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mobile,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (assignedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned ${_formatTimeAgo(assignedAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (totalCalls > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCallStat('Calls', totalCalls, Icons.phone, Colors.blue),
                  _buildCallStat(
                    'Connected',
                    connectedCalls,
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildCallStat(
                    'Interested',
                    interestedCalls,
                    Icons.star,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCallsTab() {
    if (_callDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final calls = _callDetails!['calls'] as List? ?? [];

    if (calls.isEmpty) {
      return _buildEmptyState('No calls yet', Icons.phone_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return _buildCallCard(call);
      },
    );
  }

  Widget _buildCallCard(Map<String, dynamic> call) {
    final driverName = call['driver_name'] ?? 'Unknown';
    final mobile = call['driver_mobile'] ?? call['mobile'] ?? '';
    final callTime = call['call_time'] != null
        ? DateTime.parse(call['call_time'])
        : null;
    final duration = call['call_duration'] ?? call['duration'] ?? 0;
    final feedback = call['feedback'] ?? 'No feedback';
    final callStatus = call['call_status'] ?? '';

    Color statusColor = Colors.grey;
    if (callStatus == 'connected') statusColor = Colors.green;
    if (callStatus == 'interested') statusColor = Colors.orange;
    if (callStatus == 'not_interested') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mobile,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (callTime != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('hh:mm a').format(callTime),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (feedback.isNotEmpty && feedback != 'No feedback') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_performance == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance Trends'),
          const SizedBox(height: 12),
          _buildTrendCard(
            'Daily Average',
            '${_performance!['daily_avg'] ?? 0} calls',
          ),
          const SizedBox(height: 12),
          _buildTrendCard(
            'Weekly Total',
            '${_performance!['weekly_total'] ?? 0} calls',
          ),
          const SizedBox(height: 12),
          _buildTrendCard(
            'Monthly Total',
            '${_performance!['monthly_total'] ?? 0} calls',
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Insights'),
          const SizedBox(height: 12),
          _buildInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final stats = _details?.todayStats;
    if (stats == null) return const SizedBox();

    final insights = <String>[];

    if (stats.conversionRate > 20) {
      insights.add('🎯 Excellent conversion rate!');
    }
    if (stats.totalCalls > 50) {
      insights.add('🔥 High call volume today!');
    }
    if (stats.connectionRate > 70) {
      insights.add('📞 Great connection rate!');
    }
    if (insights.isEmpty) {
      insights.add('Keep up the good work!');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: insights
            .map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  insight,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading telecaller details...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
