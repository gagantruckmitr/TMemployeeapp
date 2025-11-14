import 'dart:math' as math;

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
import 'screens/pending_calls_screen.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onOpenDrawer;
  final Function(NavigationSection section, {String? filter})?
  onNavigateToSection;

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

    // Loading dashboard data

    try {
      // Load stats from telecaller service
      final stats = await TelecallerService.instance.getDashboardStats();
      print('📊 Dashboard Stats Loaded: $stats');

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
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
        // Error occurred while loading stats

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
    final newVisibility = offset < 100;
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

  // Calculate dynamic max Y value for chart
  double _getMaxYValue() {
    final totalCalls = (_dashboardStats['total_calls'] ?? 0).toDouble();
    final connectedCalls = (_dashboardStats['connected_calls'] ?? 0).toDouble();
    final callbacks = (_dashboardStats['callbacks_scheduled'] ?? 0).toDouble();

    final maxValue = [totalCalls, connectedCalls, callbacks].reduce(math.max);

    if (maxValue <= 0) {
      return 0;
    }

    // Add 20% padding to the max value and round up to nearest 10
    final paddedMax = maxValue * 1.2;
    return ((paddedMax / 10).ceil() * 10).toDouble();
  }

  double _getYAxisInterval(double maxY) {
    if (maxY <= 0) return 1;
    final interval = maxY / 5;
    return interval <= 0 ? 1 : interval;
  }

  bool _hasPerformanceData() {
    final totalCalls = _dashboardStats['total_calls'] ?? 0;
    final connectedCalls = _dashboardStats['connected_calls'] ?? 0;
    final callbacksScheduled = _dashboardStats['callbacks_scheduled'] ?? 0;

    return totalCalls > 0 || connectedCalls > 0 || callbacksScheduled > 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return GestureDetector(
      onTap: () => ActivityTrackerService.instance.recordActivity(),
      onPanUpdate: (_) => ActivityTrackerService.instance.recordActivity(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: null, // Explicitly no AppBar to prevent conflicts
        body: Column(
          children: [
            // FIXED HEADER - This will NEVER scroll
            Material(
              elevation: 4,
              color: Colors.transparent,
              shadowColor: Colors.black.withOpacity(0.1),
              child: _buildFixedHeader(),
            ),

            // SCROLLABLE CONTENT - Only this part scrolls
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppTheme.primaryBlue,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      _buildSearchBar(),

                      const SizedBox(height: 20),

                      // KPI Cards in horizontal scroll
                      _buildKPICardsSection(),

                      const SizedBox(height: 24),

                      // Smart Calling Card
                      _buildSmartCallingCard(),

                      const SizedBox(height: 20),

                      // Call History Section
                      _buildCallHistorySection(),

                      const SizedBox(height: 20),

                      // Performance Section
                      _buildPerformanceSection(),

                      const SizedBox(height: 20),

                      // Follow-ups Section
                      _buildFollowupsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        // Add minimal shadow to ensure it appears above scrollable content
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top navigation bar with menu, title, and profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Menu button - flat design, no shadow
                  Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white, // Flat white background
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.menu_rounded,
                            color: Colors.grey.shade700,
                            size: 22,
                          ),
                          onPressed: widget.onOpenDrawer,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                  // Expanded center section for "Home" title
                  Expanded(
                    child: Center(
                      child: Text(
                        'Home',
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.grey.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                    ),
                  ),

                  // Right side icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification bell - flat design
                      Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white, // Flat white background
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.grey.shade700,
                                    size: 20,
                                  ),
                                ),
                                // Red notification dot
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms)
                          .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(width: 12),

                      // Profile avatar
                      GestureDetector(
                            onTap: _navigateToProfile,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(
                                  20,
                                ), // Circular avatar
                              ),
                              child: Center(
                                child: Text(
                                  _getUserName().isNotEmpty
                                      ? _getUserName()[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                    ],
                  ),
                ],
              ),
            ),

            // Greeting section - left aligned below menu button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                8,
                16,
                16,
              ), // Left padding for alignment below menu
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildGreetingSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
              'Hi ${_getUserName()}!',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.primaryColor, // Blue color as requested
                fontSize: 26, // Increased font size for wider look
                fontWeight: FontWeight.w800, // Made it bolder
                letterSpacing:
                    -0.3, // Slightly reduced letter spacing for better width
                height: 1.1,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 4),

        Text(
              _getGreeting(),
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.grey.shade600, // Grey color as requested
                fontSize: 14, // Smaller font size
                fontWeight: FontWeight.w500,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 400.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
          onTap: _navigateToSearch,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Search here...',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 800.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildKPICardsSection() {
    final kpiData = _getDynamicKPIData();

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children:
              kpiData.map((kpi) {
                final index = kpiData.indexOf(kpi);
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 8,
                    right: index == kpiData.length - 1 ? 0 : 8,
                  ),
                  child: SizedBox(
                    width: 100, // Reduced width to prevent overflow
                    child: _buildKPICard(kpi),
                  ),
                );
              }).toList(),
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

  Widget _buildKPICard(KPIData kpi) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _showKPIDetails(kpi);
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon at top
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: Color(kpi.color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kpi.icon,
                      style: const TextStyle(fontSize: 16), // Reduced size
                    ),
                  ),

                  const Spacer(),

                  // Bold number
                  Text(
                    kpi.value,
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.black,
                      fontSize: 20, // Reduced size
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 2), // Reduced spacing
                  // Small title below number
                  Text(
                    kpi.title,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.gray,
                      fontSize: 9, // Reduced size
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartCallingCard() {
    return RepaintBoundary(
      child: Container(
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
    );
  }

  Widget _buildCallHistorySection() {
    return Material(
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
              color: Colors.indigo.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                  color: Colors.indigo.withOpacity(0.1),
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
              child: Container(
                height: 200,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                child:
                    _hasPerformanceData()
                        ? _buildPerformanceChart()
                        : _buildNoPerformanceState(),
              ),
            ),
            const SizedBox(height: 20),
            if (_hasPerformanceData())
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

  Widget _buildPerformanceChart() {
    final maxY = _getMaxYValue();
    final yAxisInterval = _getYAxisInterval(maxY);

    final effectiveMaxY = maxY == 0 ? 1.0 : maxY;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: effectiveMaxY,
        minY: 0,
        groupsSpace: 20,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.primaryBlue.withOpacity(0.9),
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
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yAxisInterval,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.gray.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                    ),
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
                toY: (_dashboardStats['total_calls'] ?? 0).toDouble(),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.8),
                    AppTheme.primaryBlue,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
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
                toY: (_dashboardStats['connected_calls'] ?? 0).toDouble(),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.8),
                    AppTheme.accentPurple,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
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
                toY: (_dashboardStats['callbacks_scheduled'] ?? 0).toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
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
          horizontalInterval: yAxisInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.gray.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoPerformanceState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.inbox_outlined,
              color: AppTheme.primaryBlue.withOpacity(0.9),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No welcome calls yet',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Once you start calling, your performance stats will appear here.',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
            textAlign: TextAlign.center,
          ),
        ],
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
                    // Navigate to pending calls screen to show all follow-ups
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingCallsScreen(),
                      ),
                    );
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
                    margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Reduced from 16
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18, // Reduced from 20
                        ),
                        const SizedBox(width: 6), // Reduced from 8
                        Text(
                          'Complete',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11, // Reduced from 12
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple,
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Reduced from 16
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
                            fontSize: 11, // Reduced from 12
                          ),
                        ),
                        const SizedBox(width: 6), // Reduced from 8
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 18, // Reduced from 20
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
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: const BoxConstraints(
                      minHeight: 75, // Minimum height to prevent overflow
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(followup.status).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Reduced from 16
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
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Reduced from 16
                        onTap: () => _initiateCall(followup),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ), // Reduced padding
                          child: Row(
                            children: [
                              // Left side - Icon
                              Container(
                                padding: const EdgeInsets.all(
                                  6,
                                ), // Reduced from 8
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    followup.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ), // Reduced from 10
                                ),
                                child: Icon(
                                  Icons.business_center_rounded,
                                  color: _getStatusColor(followup.status),
                                  size: 14, // Reduced from 16
                                ),
                              ),
                              const SizedBox(width: 10), // Reduced from 12
                              // Middle - Company info (expanded to take available space)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      followup.companyName,
                                      style: AppTheme.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13, // Reduced from 14
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1), // Reduced from 2
                                    Text(
                                      followup.contactPerson,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.gray,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11, // Reduced from 12
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2), // Reduced from 3
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 10, // Reduced from 12
                                          color: AppTheme.gray.withOpacity(0.7),
                                        ),
                                        const SizedBox(
                                          width: 3,
                                        ), // Reduced from 4
                                        Flexible(
                                          child: Text(
                                            _formatFollowupTime(
                                              followup.followUpDate!,
                                            ),
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.gray.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 10, // Reduced from 11
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
                              // Right side - Status badge (top) and Call button (bottom)
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Status badge - top right corner
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(followup.status),
                                      borderRadius: BorderRadius.circular(8),
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
                                  // Call button - bottom right
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentPurple.withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.phone_rounded,
                                      color: AppTheme.accentPurple,
                                      size: 18,
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
      MaterialPageRoute(builder: (context) => const SearchUsersScreen()),
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

      print(
        '📊 Navigating to: $targetSection (index=${targetSection.index}), filter=$filter',
      );

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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
