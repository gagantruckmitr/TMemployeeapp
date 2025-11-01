import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';
import '../../models/dummy_models.dart';
import '../../models/smart_calling_models.dart';
import '../../routes/app_router.dart';
import 'widgets/smart_call_button.dart';
import '../../core/services/real_auth_service.dart';
import '../../core/services/telecaller_service.dart';
import '../../core/services/activity_tracker_service.dart';
import 'screens/search_users_screen.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onOpenDrawer;
  final Function(NavigationSection section, {String? filter})? onNavigateToSection;

  const DashboardPage({
    super.key,
    this.onNavigateToProfile,
    this.onOpenDrawer,
    this.onNavigateToSection,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  late AnimationController _counterController;
  bool _isKPIVisible = true;

  // Dynamic data
  Map<String, int> _dashboardStats = {};
  bool _isLoadingStats = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _counterController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
    _loadDashboardData();

    // Start activity tracking
    ActivityTrackerService.instance.startTracking();

    // Start counter animation with delay to improve initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _counterController.forward();
      });
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() => _isLoadingStats = true);

    try {
      // Load stats from telecaller service
      final stats = await TelecallerService.instance.getDashboardStats();
      print('📊 Dashboard Stats Loaded: $stats');

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoadingStats = false;
        });
        print('✅ Dashboard UI Updated with stats');

        // Show message if no data
        if (stats['total_calls'] == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No calls logged yet today. Start making calls!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading dashboard stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadDashboardData,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newVisibility = offset < 120;
    if (_isKPIVisible != newVisibility) {
      setState(() {
        _isKPIVisible = newVisibility;
      });
    }
  }

  // Get real user name from auth service
  String _getUserName() {
    final user = RealAuthService.instance.currentUser;
    if (user != null) {
      // Return first name only
      final nameParts = user.name.split(' ');
      return nameParts.first;
    }
    return 'User';
  }

  // Calculate success rate
  String _getSuccessRate() {
    final total = _dashboardStats['total_calls'] ?? 0;
    final connected = _dashboardStats['connected_calls'] ?? 0;

    if (total == 0) return '0%';
    final rate = (connected / total * 100).toStringAsFixed(1);
    return '$rate%';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return GestureDetector(
      onTap: () => ActivityTrackerService.instance.recordActivity(),
      onPanUpdate: (_) => ActivityTrackerService.instance.recordActivity(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Main Content with pull-to-refresh
              RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppTheme.primaryBlue,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 1000,
                  slivers: [
                    // Custom App Bar
                    _buildStickyAppBar(),

                    // KPI Section as separate sliver for better performance
                    SliverToBoxAdapter(child: _buildKPISection()),

                    // Smart Calling Section
                  SliverToBoxAdapter(child: _buildSmartCallingSection()),

                  // Performance Section with Charts
                  SliverToBoxAdapter(child: _buildPerformanceSection()),

                  // Upcoming Follow-ups Section
                  SliverToBoxAdapter(child: _buildFollowupsSection()),

                  // Bottom padding for bottom navigation
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // Floating KPI Summary (when scrolled)
            if (!_isKPIVisible) _buildFloatingKPISummary(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStickyAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(76, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                  _getGreeting(),
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideX(begin: -0.3, end: 0),
                            const SizedBox(height: 4),
                            Text(
                                  'Hi ${_getUserName()} 👋',
                                  style: AppTheme.headingMedium.copyWith(
                                    color: Colors.grey.shade900,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                                .animate()
                                .fadeIn(duration: 600.ms, delay: 200.ms)
                                .slideX(begin: -0.3, end: 0),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildProfileSection(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notifications Button
        Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.grey.shade700,
                size: 20,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 400.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(width: 12),
        // Profile Avatar
        GestureDetector(
          onTap: _navigateToProfile,
          child:
              Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _navigateToSearch,
      child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Search leads, contacts...',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 600.ms, delay: 800.ms)
          .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildKPISection() {
    // Create dynamic KPI data from real stats
    final kpiData = _getDynamicKPIData();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 140,
        child: _isLoadingStats
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kpiData.length,
                cacheExtent: 500,
                addAutomaticKeepAlives: true,
                itemBuilder: (context, index) {
                  final kpi = kpiData[index];
                  return _buildOptimizedKPITile(kpi, index);
                },
              ),
      ),
    );
  }

  List<KPIData> _getDynamicKPIData() {
    final totalCalls = _dashboardStats['total_calls'] ?? 0;
    final connectedCalls = _dashboardStats['connected_calls'] ?? 0;
    final pendingCalls = _dashboardStats['pending_calls'] ?? 0;
    final freshLeads = _dashboardStats['fresh_leads'] ?? 0;
    final callbacksScheduled = _dashboardStats['callbacks_scheduled'] ?? 0;

    return [
      KPIData(
        title: 'Total Calls',
        value: totalCalls.toString(),
        icon: '📞',
        color: 0xFF4F46E5,
      ),
      KPIData(
        title: 'Connected',
        value: connectedCalls.toString(),
        icon: '✅',
        color: 0xFF10B981,
      ),
      KPIData(
        title: 'Pending Calls',
        value: pendingCalls.toString(),
        icon: '⏳',
        color: 0xFFF59E0B,
      ),
      KPIData(
        title: 'Fresh Leads',
        value: freshLeads.toString(),
        icon: '🆕',
        color: 0xFF8B5CF6,
      ),
      KPIData(
        title: 'Callbacks',
        value: callbacksScheduled.toString(),
        icon: '🔔',
        color: 0xFFEF4444,
      ),
    ];
  }

  Widget _buildOptimizedKPITile(KPIData kpi, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 60) / 2.2; // Responsive width

    return RepaintBoundary(
      // Isolate repaints for better performance
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            _showKPIDetails(kpi);
          },
          child: Container(
            width: tileWidth.clamp(140.0, 160.0),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(kpi.color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          kpi.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      Icon(
                        Icons.trending_up_rounded,
                        color: Color(kpi.color),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simplified counter without heavy animation
                      Text(
                        kpi.value,
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kpi.title,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.gray,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingKPISummary() {
    if (_isLoadingStats) return const SizedBox.shrink();
    final kpiData = _getDynamicKPIData();

    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: RepaintBoundary(
        child: AnimatedOpacity(
          opacity: !_isKPIVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: kpiData.map((kpi) {
                return Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kpi.value,
                        style: AppTheme.titleMedium.copyWith(
                          color: Color(kpi.color),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kpi.title.split(' ').first,
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: 10,
                          color: AppTheme.gray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartCallingSection() {
    return RepaintBoundary(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Smart Calling',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start automated IVR call sequence for your next best lead.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SmartCallButton(
                  onPressed: () {
                    _startSmartCalling();
                  },
                ),
              ],
            ),
          ),
          // Call History Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToCallHistory,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
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
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'View all your call logs with feedback',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCallHistory() {
    HapticFeedback.lightImpact();
    if (widget.onNavigateToSection != null) {
      widget.onNavigateToSection!(NavigationSection.callHistory);
    }
  }

  Widget _buildPerformanceSection() {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.black,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 3,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'This Week',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Optimized Bar Chart with RepaintBoundary
            RepaintBoundary(
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 50,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) =>
                            AppTheme.primaryBlue.withOpacity(0.9),
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          const labels = ['Calls', 'Leads', 'Follow-ups'];
                          return BarTooltipItem(
                            '${labels[group.x.toInt()]}\n${rod.toY.round()}',
                            AppTheme.bodyMedium.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Calls', 'Leads', 'F/Ups'];
                            if (value.toInt() < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[value.toInt()],
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.gray,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.gray.withOpacity(0.7),
                                fontWeight: FontWeight.w400,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: (_dashboardStats['total_calls'] ?? 35)
                                .toDouble(),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.8),
                                AppTheme.primaryBlue,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: (_dashboardStats['connected_calls'] ?? 28)
                                .toDouble(),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentPurple.withOpacity(0.8),
                                AppTheme.accentPurple,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: (_dashboardStats['callbacks_scheduled'] ?? 22)
                                .toDouble(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppTheme.gray.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Performance Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Success Rate',
                    _getSuccessRate(),
                    Icons.check_circle_rounded,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Calls',
                    (_dashboardStats['total_calls'] ?? 0).toString(),
                    Icons.phone,
                    AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Connected',
                    (_dashboardStats['connected_calls'] ?? 0).toString(),
                    Icons.check_circle,
                    AppTheme.accentPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.gray,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowupsSection() {
    final followups = DummyData.upcomingFollowUps;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Follow-ups',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 3,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full follow-ups list
                  },
                  child: Text(
                    'View All →',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...followups.take(3).map((followup) {
              return RepaintBoundary(
                key: Key('followup_${followup.id}'),
                child: Dismissible(
                  key: Key(followup.id),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Complete',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Reschedule',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      _markFollowupComplete(followup);
                    } else {
                      _rescheduleFollowup(followup);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(followup.status).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(
                          followup.status,
                        ).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _initiateCall(followup),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    followup.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.business_center_rounded,
                                  color: _getStatusColor(followup.status),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      followup.companyName,
                                      style: AppTheme.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      followup.contactPerson,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.gray,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: AppTheme.gray.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _formatFollowupTime(
                                              followup.followUpDate!,
                                            ),
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.gray.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(followup.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(followup.status),
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.phone_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 14,
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
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  void _navigateToProfile() {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
    } else {
      // Fallback to GoRouter if callback is not available
      context.go(AppRouter.profile);
    }
  }

  void _navigateToSearch() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchUsersScreen(),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.new_:
        return const Color(0xFF2196F3);
      case LeadStatus.contacted:
        return const Color(0xFFFF9800);
      case LeadStatus.interested:
        return const Color(0xFF4CAF50);
      case LeadStatus.quoted:
        return const Color(0xFF9C27B0);
      case LeadStatus.converted:
        return const Color(0xFF4CAF50);
      case LeadStatus.lost:
        return const Color(0xFFF44336);
    }
  }

  String _getStatusText(LeadStatus status) {
    switch (status) {
      case LeadStatus.new_:
        return 'NEW';
      case LeadStatus.contacted:
        return 'CONTACTED';
      case LeadStatus.interested:
        return 'INTERESTED';
      case LeadStatus.quoted:
        return 'QUOTED';
      case LeadStatus.converted:
        return 'CONVERTED';
      case LeadStatus.lost:
        return 'LOST';
    }
  }

  String _formatFollowupTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h Left'; // Added "Left"
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m Left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m Left';
    } else {
      return 'Due Now'; // Changed from 'Now'
    }
  }

  void _showKPIDetails(KPIData kpi) {
    // Navigate to appropriate screen based on KPI
    if (widget.onNavigateToSection != null) {
      NavigationSection? targetSection;
      String? filter;
      
      print('📊 KPI Tapped: ${kpi.title}');
      
      switch (kpi.title.toLowerCase()) {
        case 'total calls':
          targetSection = NavigationSection.callHistory;
          filter = 'all';
          break;
        case 'connected':
          targetSection = NavigationSection.callHistory;
          filter = 'connected';
          break;
        case 'pending calls':
          // Navigate to dedicated pending calls screen
          targetSection = NavigationSection.pendingCalls;
          break;
        case 'fresh leads':
          // Navigate to dedicated pending calls screen (same as pending)
          targetSection = NavigationSection.pendingCalls;
          break;
        case 'callbacks':
          targetSection = NavigationSection.callHistory;
          filter = 'callback';
          break;
        default:
          targetSection = NavigationSection.callHistory;
          filter = 'all';
      }
      
      print('📊 Navigating to: $targetSection (index=${targetSection.index}), filter=$filter');
      
      // Navigate with or without filter
      if (filter != null) {
        widget.onNavigateToSection!(targetSection, filter: filter);
      } else {
        widget.onNavigateToSection!(targetSection);
      }
      
      // Show a snackbar to indicate navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing ${kpi.title}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(kpi.color),
        ),
      );
    }
  }


  void _startSmartCalling() {
    context.push(AppRouter.smartCalling);
  }

  void _initiateCall(Lead lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.phone_in_talk_rounded,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Call ${lead.companyName}',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact: ${lead.contactPerson}',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Action: ${lead.notes}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.gray,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accentPurple.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: AppTheme.accentPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy Notice: IVR-controlled call. Phone number remains concealed.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentPurple.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
            child: Text(
              'Cancel',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.gray,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSmartCalling();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Start Call',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markFollowupComplete(Lead lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${lead.companyName} follow-up marked as complete!'),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppConstants.paddingLarge),
      ),
    );
  }

  void _rescheduleFollowup(Lead lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ ${lead.companyName} follow-up has been rescheduled.'),
        backgroundColor: AppTheme.accentOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppConstants.paddingLarge),
      ),
    );
  }
}
