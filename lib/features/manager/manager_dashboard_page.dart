import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../models/manager_models.dart';
import '../../core/services/manager_service.dart';
import '../../core/services/real_auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/overview_cards.dart';
import 'widgets/telecaller_list_view.dart';
import 'widgets/real_time_monitor.dart';
import 'widgets/performance_charts.dart';
import 'widgets/leaderboard_widget.dart';
import 'widgets/call_activity_widget.dart';
import 'widgets/assignments_widget.dart';

class ManagerDashboardPage extends StatefulWidget {
  final int managerId;
  final String managerName;

  const ManagerDashboardPage({
    Key? key,
    required this.managerId,
    required this.managerName,
  }) : super(key: key);

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> with SingleTickerProviderStateMixin {
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
  Map<String, dynamic> _realTimeStatus = {};

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

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('🔵 Loading manager dashboard data for manager ID: ${widget.managerId}');
      
      // Load manager details from admins table (optional - don't fail if this errors)
      try {
        final managerDetails = await _managerService.getManagerDetails(widget.managerId);
        print('✅ Manager details loaded: ${managerDetails['manager']}');
        if (mounted) {
          setState(() {
            _managerDetails = managerDetails;
          });
        }
      } catch (e) {
        print('⚠️ Could not load manager details (non-critical): $e');
      }
      
      final overviewData = await _managerService.getOverview(widget.managerId);
      print('✅ Overview data loaded: ${overviewData['overview']}');
      
      final telecallers = await _managerService.getTelecallers();
      print('✅ Telecallers loaded: ${telecallers.length} telecallers');
      
      final realTimeStatus = await _managerService.getRealTimeStatus();
      print('✅ Real-time status loaded');

      if (mounted) {
        setState(() {
          _overview = overviewData['overview'];
          _todayStats = overviewData['today'];
          _weekTrend = overviewData['weekTrend'];
          _topPerformers = overviewData['topPerformers'];
          _telecallers = telecallers;
          _realTimeStatus = realTimeStatus;
          _isLoading = false;
        });
        print('✅ Manager dashboard state updated successfully');
        print('📊 Manager: ${_managerDetails?['manager']?['name'] ?? widget.managerName}');
        print('📊 Overview: Total Telecallers=${_overview?.totalTelecallers}, Calls Today=${_overview?.totalCallsToday}');
      }
    } catch (e) {
      print('❌ Error loading manager dashboard: $e');
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
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Logout'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
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
      ),
    );
  }

  Widget _buildHeader() {
    final managerName = _managerDetails?['manager']?['name'] ?? widget.managerName;
    final managerEmail = _managerDetails?['manager']?['email'] ?? '';
    final teamStats = _managerDetails?['teamStats'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manager Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Welcome, $managerName',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (managerEmail.isNotEmpty)
                      Text(
                        managerEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _loadData(),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Refresh',
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.account_circle,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                tooltip: 'Profile',
                onSelected: (value) async {
                  if (value == 'logout') {
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (managerEmail.isNotEmpty)
                          Text(
                            managerEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        Divider(),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  _showManagerProfile();
                },
                icon: Icon(
                  Icons.account_circle,
                  color: AppTheme.textSecondary,
                ),
                tooltip: 'Profile',
              ),
            ],
          ),
          if (teamStats != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat('Team', '${teamStats['total_telecallers'] ?? 0}', Icons.people),
                  _buildQuickStat('Online', '${teamStats['online_telecallers'] ?? 0}', Icons.online_prediction),
                  _buildQuickStat('Calls Today', '${teamStats['total_calls_today'] ?? 0}', Icons.phone),
                  _buildQuickStat('Conversions', '${teamStats['conversions_today'] ?? 0}', Icons.check_circle),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
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
        title: Row(
          children: [
            Icon(Icons.account_circle, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Manager Profile'),
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
              _buildProfileRow('Member Since', manager['created_at']?.toString().split(' ')[0] ?? 'N/A'),
              const SizedBox(height: 16),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (recentActivity.isEmpty)
                Text('No recent activity', style: TextStyle(color: AppTheme.textSecondary))
              else
                ...recentActivity.take(5).map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity['description'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard_outlined),
            text: 'Overview',
          ),
          Tab(
            icon: Icon(Icons.timeline),
            text: 'Activity',
          ),
          Tab(
            icon: Icon(Icons.people_outline),
            text: 'Telecallers',
          ),
          Tab(
            icon: Icon(Icons.monitor_heart_outlined),
            text: 'Live Monitor',
          ),
          Tab(
            icon: Icon(Icons.leaderboard_outlined),
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

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 400,
              child: CallActivityWidget(managerId: widget.managerId),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400,
              child: AssignmentsWidget(managerId: widget.managerId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null || _todayStats == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverviewCards(
              overview: _overview!,
              todayStats: _todayStats!,
            ),
            const SizedBox(height: 24),
            PerformanceCharts(
              weekTrend: _weekTrend,
              todayStats: _todayStats!,
            ),
            const SizedBox(height: 24),
            _buildTopPerformersSection(),
          ],
        ),
      ),
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
    return RealTimeMonitor(
      realTimeStatus: _realTimeStatus,
      onRefresh: _loadData,
    );
  }

  Widget _buildLeaderboardTab() {
    return LeaderboardWidget(
      managerId: widget.managerId,
    );
  }

  Widget _buildTopPerformersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[700], size: 28),
              const SizedBox(width: 12),
              Text(
                'Top Performers Today',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_topPerformers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No performance data yet',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ..._topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final performer = entry.value;
              return _buildPerformerCard(performer, index + 1);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPerformerCard(TopPerformer performer, int rank) {
    final rankColors = [
      Colors.amber[700]!,
      Colors.grey[400]!,
      Colors.brown[400]!,
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rankColor.withOpacity(0.1),
            rankColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: rankColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  ),
                ),
                Text(
                  performer.mobile,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${performer.conversions} conversions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
              Text(
                '${performer.callsMade} calls',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
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
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(color: AppTheme.textSecondary),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
