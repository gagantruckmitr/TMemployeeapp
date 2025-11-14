import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../models/manager_models.dart';
import '../../core/services/manager_service.dart';
import '../../core/services/real_auth_service.dart';
import 'widgets/overview_cards.dart';
import 'widgets/telecaller_list_view.dart';
import 'widgets/performance_charts.dart';
import 'widgets/leaderboard_widget.dart';
import 'widgets/assignments_widget.dart';
import 'widgets/live_telecaller_status_widget.dart';
import 'screens/leave_approval_screen.dart';

class ManagerDashboardPage extends StatefulWidget {
  final int managerId;
  final String managerName;

  const ManagerDashboardPage({
    super.key,
    required this.managerId,
    required this.managerName,
  });

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage>
    with SingleTickerProviderStateMixin {
  final ManagerService _managerService = ManagerService();
  late TabController _tabController;
  Timer? _refreshTimer;

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _managerDetails;
  ManagerOverview? _overview;
  TodayStats? _todayStats;
  List<WeekTrend> _weekTrend = [];
  List<TopPerformer> _topPerformers = [];
  List<TelecallerInfo> _telecallers = [];

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
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
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
      if (mounted) {
        _loadData(silent: true);
      }
    });
  }

  void _navigateToLeaveApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LeaveApprovalScreen(),
      ),
    );
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Load manager details
      try {
        final managerDetails = await _managerService.getManagerDetails(
          widget.managerId,
        );
        if (mounted) {
          setState(() {
            _managerDetails = managerDetails;
          });
        }
      } catch (e) {
        debugPrint('Could not load manager details: $e');
      }

      final overviewData = await _managerService.getOverview(widget.managerId);
      final telecallers = await _managerService.getTelecallers();

      if (mounted) {
        setState(() {
          _overview = overviewData['overview'];
          _todayStats = overviewData['today'];
          _weekTrend = overviewData['weekTrend'];
          _topPerformers = overviewData['topPerformers'];
          _telecallers = telecallers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading manager dashboard: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: _white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await RealAuthService.instance.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            _buildModernTabBar(),
            Expanded(
              child: _isLoading && _overview == null
                  ? _buildLoadingState()
                  : _error != null && _overview == null
                  ? _buildErrorState()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final managerName =
        _managerDetails?['manager']?['name'] ?? widget.managerName;
    final managerEmail = _managerDetails?['manager']?['email'] ?? '';
    final teamStats = _managerDetails?['teamStats'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Teal gradient icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_tealPrimary, _tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _tealPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: _white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manager Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Welcome, $managerName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Leave Approval button
              Container(
                decoration: BoxDecoration(
                  color: _tealPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _navigateToLeaveApproval,
                  icon: const Icon(Icons.event_available),
                  color: _tealPrimary,
                  tooltip: 'Leave Approvals',
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: _tealPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _loadData(),
                  icon: const Icon(Icons.refresh_rounded, color: _tealPrimary),
                  tooltip: 'Refresh',
                ),
              ),
              const SizedBox(width: 8),
              // Profile menu
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _tealPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    color: _tealPrimary,
                    size: 24,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                offset: const Offset(0, 50),
                onSelected: (value) async {
                  if (value == 'profile') {
                    _showManagerProfile();
                  } else if (value == 'logout') {
                    await _handleLogout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          managerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textPrimary,
                          ),
                        ),
                        if (managerEmail.isNotEmpty)
                          Text(
                            managerEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        const Divider(height: 16),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: _tealPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (teamStats != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _tealPrimary.withValues(alpha: 0.08),
                    _tealAccent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _tealPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat(
                    'Team',
                    '${teamStats['total_telecallers'] ?? 0}',
                    Icons.people_outline,
                  ),
                  _buildDivider(),
                  _buildQuickStat(
                    'Online',
                    '${teamStats['online_telecallers'] ?? 0}',
                    Icons.online_prediction_outlined,
                  ),
                  _buildDivider(),
                  _buildQuickStat(
                    'Calls',
                    '${teamStats['total_calls_today'] ?? 0}',
                    Icons.phone_outlined,
                  ),
                  _buildDivider(),
                  _buildQuickStat(
                    'Conversions',
                    '${teamStats['conversions_today'] ?? 0}',
                    Icons.check_circle_outline,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: _tealPrimary.withValues(alpha: 0.2),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: _tealPrimary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showManagerProfile() {
    if (_managerDetails == null) return;

    final manager = _managerDetails!['manager'];
    final recentActivity = _managerDetails!['recentActivity'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _tealPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_circle,
                color: _tealPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Manager Profile', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileRow('Name', manager['name']),
              _buildProfileRow('Mobile', manager['mobile']),
              _buildProfileRow('Email', manager['email'] ?? 'N/A'),
              _buildProfileRow('Role', manager['role']),
              _buildProfileRow(
                'Member Since',
                manager['created_at']?.toString().split(' ')[0] ?? 'N/A',
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (recentActivity.isEmpty)
                const Text(
                  'No recent activity',
                  style: TextStyle(color: _textSecondary),
                )
              else
                ...recentActivity
                    .take(5)
                    .map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _tealPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activity['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _tealPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _tealPrimary,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _tealPrimary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Overview'),
          Tab(icon: Icon(Icons.timeline_outlined, size: 20), text: 'Activity'),
          Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Team'),
          Tab(icon: Icon(Icons.monitor_heart_outlined, size: 20), text: 'Live'),
          Tab(
            icon: Icon(Icons.leaderboard_outlined, size: 20),
            text: 'Leaderboard',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildActivityTab(),
        _buildTelecallersTab(),
        _buildLiveMonitorTab(),
        _buildLeaderboardTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null || _todayStats == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: _tealPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverviewCards(overview: _overview!, todayStats: _todayStats!),
            const SizedBox(height: 24),
            PerformanceCharts(weekTrend: _weekTrend, todayStats: _todayStats!),
            const SizedBox(height: 24),
            _buildTopPerformersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AssignmentsWidget(managerId: widget.managerId),
    );
  }

  Widget _buildTelecallersTab() {
    return TelecallerListView(
      telecallers: _telecallers,
      managerId: widget.managerId,
      onRefresh: _loadData,
    );
  }

  Widget _buildLiveMonitorTab() {
    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: _tealPrimary,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: LiveTelecallerStatusWidget(),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return LeaderboardWidget(managerId: widget.managerId);
  }

  Widget _buildTopPerformersSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _tealPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: _white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Performers Today',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_topPerformers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: _textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No performance data yet',
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final performer = entry.value;
              return _buildPerformerCard(performer, index + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildPerformerCard(TopPerformer performer, int rank) {
    final rankColors = [
      const Color(0xFFFBBF24), // Gold
      const Color(0xFF94A3B8), // Silver
      const Color(0xFFD97706), // Bronze
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : _tealPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rankColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rankColor, rankColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  performer.mobile,
                  style: const TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${performer.conversions}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${performer.callsMade} calls',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _tealPrimary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _tealPrimary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading dashboard...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealPrimary,
                foregroundColor: _white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
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
