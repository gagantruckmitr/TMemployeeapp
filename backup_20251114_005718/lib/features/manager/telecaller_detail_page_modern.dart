import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../models/manager_models.dart';
import '../../core/services/manager_service.dart';

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

  // Modern teal green color scheme
  static const Color _tealPrimary = Color(0xFF14B8A6);
  static const Color _tealAccent = Color(0xFF2DD4BF);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final details = await _managerService.getTelecallerDetails(widget.telecallerId);
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
        if (mounted) setState(() => _assignments = assignments);
      } catch (e) {
        debugPrint('Assignments error: $e');
      }

      try {
        final performance = await _managerService.getTelecallerPerformance(widget.telecallerId);
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
      backgroundColor: _background,
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
    final assignmentsCount = _details!.assignments.isNotEmpty
        ? _details!.assignments.length
        : (_assignments?['assignments']?.length ?? 0);
    final summary = _callDetails?['summary'] ?? {};

    return CustomScrollView(
      slivers: [
        _buildModernAppBar(telecaller),
        SliverToBoxAdapter(child: _buildQuickStatsCard(telecaller, stats, assignmentsCount, summary)),
        SliverToBoxAdapter(child: _buildTabBar()),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(telecaller, stats, summary, assignmentsCount),
              _buildPerformanceTab(stats),
              _buildAssignmentsTab(),
              _buildCallsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernAppBar(TelecallerInfo telecaller) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _tealPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_tealPrimary, _tealAccent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
              child: Column(
                children: [
                  Hero(
                    tag: 'telecaller_${telecaller.id}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          telecaller.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _tealPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    telecaller.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _white,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        telecaller.mobile,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _white),
          onPressed: () => _loadAllData(),
          tooltip: 'Refresh',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: _white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            if (value == 'call') {
              Clipboard.setData(ClipboardData(text: telecaller.mobile));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mobile number copied!')),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'call',
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Copy Number'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatsCard(
    TelecallerInfo telecaller,
    TodayStats stats,
    int assignmentsCount,
    Map<String, dynamic> summary,
  ) {
    final totalCalled = int.tryParse(summary['unique_drivers']?.toString() ?? '0') ?? 0;
    final remaining = assignmentsCount > totalCalled ? assignmentsCount - totalCalled : 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _tealPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusBadge(telecaller.currentStatus),
              const Spacer(),
              if (telecaller.loginTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _tealPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: _tealPrimary),
                      const SizedBox(width: 6),
                      Text(
                        _calculateSessionDuration(telecaller.loginTime),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tealPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatBox('Assigned', assignmentsCount.toString(), Icons.assignment_outlined, const Color(0xFF3B82F6))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Called', totalCalled.toString(), Icons.phone_outlined, const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Remaining', remaining.toString(), Icons.pending_outlined, const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox('Connected', stats.connected.toString(), Icons.check_circle_outline, const Color(0xFF8B5CF6))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Interested', stats.interested.toString(), Icons.star_outline, const Color(0xFFFBBF24))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox('Conv. Rate', '${stats.conversionRate.toStringAsFixed(1)}%', Icons.trending_up, _tealPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
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
            style: const TextStyle(
              fontSize: 10,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TelecallerStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TelecallerStatus.online:
        color = const Color(0xFF10B981);
        text = 'Online';
        icon = Icons.circle;
        break;
      case TelecallerStatus.onCall:
        color = const Color(0xFF3B82F6);
        text = 'On Call';
        icon = Icons.phone_in_talk_rounded;
        break;
      case TelecallerStatus.break_:
        color = const Color(0xFFF59E0B);
        text = 'Break';
        icon = Icons.coffee_rounded;
        break;
      case TelecallerStatus.busy:
        color = const Color(0xFFFBBF24);
        text = 'Busy';
        icon = Icons.work_outline;
        break;
      default:
        color = const Color(0xFF6B7280);
        text = 'Offline';
        icon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateSessionDuration(DateTime? loginTime) {
    if (loginTime == null) return 'N/A';
    final duration = DateTime.now().difference(loginTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _tealPrimary,
        unselectedLabelColor: _textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: _tealPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Overview'),
          Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'Performance'),
          Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: 'Assignments'),
          Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Calls'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    TelecallerInfo telecaller,
    TodayStats stats,
    Map<String, dynamic> summary,
    int assignmentsCount,
  ) {
    final totalCalled = int.tryParse(summary['unique_drivers']?.toString() ?? '0') ?? 0;
    final remaining = assignmentsCount > totalCalled ? assignmentsCount - totalCalled : 0;
    final progress = assignmentsCount > 0 ? (totalCalled / assignmentsCount) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Lead Progress'),
          const SizedBox(height: 12),
          _buildProgressCard(assignmentsCount, totalCalled, remaining, progress),
          const SizedBox(height: 20),
          _buildSectionTitle('Call Breakdown'),
          const SizedBox(height: 12),
          _buildCallBreakdownCard(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('Profile Information'),
          const SizedBox(height: 12),
          _buildProfileCard(telecaller),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildProgressCard(int total, int called, int remaining, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat('Total', total.toString(), Icons.people_outline),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildProgressStat('Called', called.toString(), Icons.phone_forwarded_rounded),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildProgressStat('Pending', remaining.toString(), Icons.pending_actions_rounded),
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

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildCallBreakdownCard(TodayStats stats) {
    final total = stats.totalCalls;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBreakdownRow('Connected', stats.connected, total, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          _buildBreakdownRow('Interested', stats.interested, total, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _buildBreakdownRow('Not Interested', stats.notInterested, total, const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          _buildBreakdownRow('Callbacks', stats.callbacks, total, const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int value, int total, Color color) {
    final percent = total > 0 ? (value / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
            ),
            Text(
              '$value (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(TelecallerInfo telecaller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.badge_outlined, 'ID', '#${telecaller.id}'),
          if (telecaller.email != null) _buildInfoRow(Icons.email_outlined, 'Email', telecaller.email!),
          if (telecaller.loginTime != null)
            _buildInfoRow(Icons.login_rounded, 'Login Time', DateFormat('hh:mm a').format(telecaller.loginTime!)),
          if (telecaller.lastActivity != null)
            _buildInfoRow(Icons.access_time_rounded, 'Last Activity', _formatTimeAgo(telecaller.lastActivity!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _tealPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM dd, hh:mm a').format(dateTime);
  }

  Widget _buildPerformanceTab(TodayStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance Metrics'),
          const SizedBox(height: 12),
          _buildMetricsGrid(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('Call Distribution'),
          const SizedBox(height: 12),
          _buildPerformanceChart(stats),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(TodayStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard('Connection Rate', '${stats.connectionRate.toStringAsFixed(1)}%', Icons.link_rounded, const Color(0xFF3B82F6)),
        _buildMetricCard('Conversion Rate', '${stats.conversionRate.toStringAsFixed(1)}%', Icons.trending_up_rounded, const Color(0xFF10B981)),
        _buildMetricCard('Total Duration', _formatDuration(stats.totalDuration), Icons.timer_outlined, const Color(0xFF8B5CF6)),
        _buildMetricCard('Avg Duration', stats.totalCalls > 0 ? '${(stats.totalDuration / stats.totalCalls).round()}s' : '0s', Icons.access_time_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
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

  Widget _buildPerformanceChart(TodayStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Connected', stats.connected, const Color(0xFF10B981)),
                _buildBar('Interested', stats.interested, const Color(0xFFF59E0B)),
                _buildBar('Not Int.', stats.notInterested, const Color(0xFFEF4444)),
                _buildBar('Callbacks', stats.callbacks, const Color(0xFF3B82F6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color) {
    final maxValue = _details?.todayStats.totalCalls ?? 1;
    final height = maxValue > 0 ? (value / maxValue * 120).clamp(10.0, 120.0) : 10.0;

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
          width: 50,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab() {
    List<dynamic> assignments = [];

    if (_details?.assignments.isNotEmpty ?? false) {
      assignments = _details!.assignments
          .map((a) => {
                'driver_id': a.driverId,
                'driver_name': a.driverName,
                'driver_mobile': a.driverMobile,
                'assigned_at': a.assignedAt.toIso8601String(),
                'status': a.status,
                'priority': a.priority,
              })
          .toList();
    } else if (_assignments != null) {
      assignments = _assignments!['assignments'] as List? ?? [];
    }

    if (assignments.isEmpty && _details == null) {
      return const Center(child: CircularProgressIndicator(color: _tealPrimary));
    }

    if (assignments.isEmpty) {
      return _buildEmptyState('No assignments yet', Icons.assignment_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: assignments.length,
      itemBuilder: (context, index) => _buildAssignmentCard(assignments[index]),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final driverName = assignment['driver_name'] ?? 'Unknown';
    final mobile = assignment['driver_mobile'] ?? assignment['mobile'] ?? '';
    final assignedAt = assignment['assigned_at'] != null ? DateTime.parse(assignment['assigned_at']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _tealPrimary,
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
                    color: _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  mobile,
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (assignedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned ${_formatTimeAgo(assignedAt)}',
                    style: const TextStyle(fontSize: 11, color: _textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    if (_callDetails == null) {
      return const Center(child: CircularProgressIndicator(color: _tealPrimary));
    }

    final calls = _callDetails!['calls'] as List? ?? [];

    if (calls.isEmpty) {
      return _buildEmptyState('No calls yet', Icons.phone_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: calls.length,
      itemBuilder: (context, index) => _buildCallCard(calls[index]),
    );
  }

  Widget _buildCallCard(Map<String, dynamic> call) {
    final driverName = call['driver_name'] ?? 'Unknown';
    final mobile = call['driver_mobile'] ?? call['mobile'] ?? '';
    final callTime = call['call_time'] != null ? DateTime.parse(call['call_time']) : null;
    final duration = call['call_duration'] ?? call['duration'] ?? 0;
    final feedback = call['feedback'] ?? '';
    final callStatus = call['call_status'] ?? '';

    Color statusColor = const Color(0xFF6B7280);
    if (callStatus == 'connected') statusColor = const Color(0xFF10B981);
    if (callStatus == 'interested') statusColor = const Color(0xFFF59E0B);
    if (callStatus == 'not_interested') statusColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
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
                child: Icon(Icons.phone_rounded, color: statusColor, size: 18),
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
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mobile,
                      style: const TextStyle(fontSize: 13, color: _textSecondary),
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
                      style: const TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback,
                      style: const TextStyle(fontSize: 13, color: _textSecondary),
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: _tealPrimary.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _tealPrimary, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Loading telecaller details...',
            style: TextStyle(fontSize: 16, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(fontSize: 14, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealPrimary,
                foregroundColor: _white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
