import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../widgets/gradient_background.dart';

class PerformanceAnalyticsPage extends StatefulWidget {
  final VoidCallback? onNavigateBack;
  
  const PerformanceAnalyticsPage({super.key, this.onNavigateBack});

  @override
  State<PerformanceAnalyticsPage> createState() =>
      _PerformanceAnalyticsPageState();
}

class _PerformanceAnalyticsPageState extends State<PerformanceAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  Map<String, dynamic> analyticsData = {};
  List<Map<String, dynamic>> callHistory = [];
  Map<String, dynamic> performanceMetrics = {};
  List<Map<String, dynamic>> weeklyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getTelecallerAnalytics(
        period: _selectedPeriod,
      );

      if (response['success'] == true) {
        setState(() {
          analyticsData = response['data'] ?? {};

          // Get call history from recent_calls
          callHistory = List<Map<String, dynamic>>.from(
            analyticsData['recent_calls'] ?? [],
          );

          // Get performance metrics
          performanceMetrics = analyticsData['performance_metrics'] ?? {};

          // Get weekly/trend data
          weeklyData = List<Map<String, dynamic>>.from(
            analyticsData['call_trends'] ?? [],
          );

          _isLoading = false;
        });
      } else {
        // API returned success: false, use empty data
        setState(() {
          analyticsData = _getEmptyAnalyticsData();
          callHistory = [];
          performanceMetrics = {};
          weeklyData = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Analytics Error: $e');
      // On error, show empty data instead of staying in loading state
      setState(() {
        analyticsData = _getEmptyAnalyticsData();
        callHistory = [];
        performanceMetrics = {};
        weeklyData = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load analytics. Showing empty data.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getEmptyAnalyticsData() {
    return {
      'overview': {
        'total_calls': 0,
        'connected_calls': 0,
        'success_rate': 0,
        'interested_count': 0,
      },
      'recent_calls': [],
      'performance_metrics': {},
      'call_trends': [],
      'trends': [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildPeriodSelector(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildCallsTab(),
                          _buildGoalsTab(),
                          _buildTrendsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              // Try callback first, then fallback to context.go
              if (widget.onNavigateBack != null) {
                widget.onNavigateBack!();
              } else {
                context.go('/dashboard');
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Performance Analytics',
                  style: AppTheme.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your progress & insights',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _loadAnalyticsData,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('Today', 'today'),
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('Year', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadAnalyticsData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Calls'),
          Tab(text: 'Goals'),
          Tab(text: 'Trends'),
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
          Text(
            'Loading analytics...',
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = analyticsData['overview'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildOverviewCards(overview),
          const SizedBox(height: 20),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> overview) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Calls',
                '${overview['total_calls'] ?? 0}',
                Icons.phone,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Connected',
                '${overview['connected_calls'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Success Rate',
                '${overview['success_rate'] ?? 0}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Interested',
                '${overview['interested_count'] ?? 0}',
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final conversionRate = performanceMetrics['conversion_rate'] ?? {};
    final successRate = performanceMetrics['success_rate'] ?? {};
    final followUpRate = performanceMetrics['follow_up_rate'] ?? {};
    final avgCallTime = performanceMetrics['avg_call_time'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Conversion',
                '${conversionRate['value'] ?? 0}%',
                '${(conversionRate['change'] ?? 0) >= 0 ? '+' : ''}${conversionRate['change'] ?? 0}%',
                (conversionRate['change'] ?? 0) >= 0,
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '${successRate['value'] ?? 0}%',
                '${(successRate['change'] ?? 0) >= 0 ? '+' : ''}${successRate['change'] ?? 0}%',
                (successRate['change'] ?? 0) >= 0,
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Follow-ups',
                '${followUpRate['value'] ?? 0}%',
                '${(followUpRate['change'] ?? 0) >= 0 ? '+' : ''}${followUpRate['change'] ?? 0}%',
                (followUpRate['change'] ?? 0) >= 0,
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Call Time',
                avgCallTime['formatted'] ?? '0:00',
                '${(avgCallTime['change'] ?? 0) >= 0 ? '+' : ''}${avgCallTime['change'] ?? 0}%',
                (avgCallTime['change'] ?? 0) >= 0,
                Icons.timer,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    bool positive,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (positive ? Colors.green : Colors.red).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: AppTheme.bodySmall.copyWith(
                    color: positive
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Call History',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (callHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_disabled,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No call history available',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...callHistory.map((call) => _buildCallHistoryItem(call)),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(Map<String, dynamic> call) {
    final status = call['call_status'] ?? 'pending';
    final driverName = call['driver_name'] ?? 'Unknown Driver';
    final duration = call['duration_formatted'] ?? '0:00';
    final timeAgo = call['time_ago'] ?? '';

    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _formatStatus(status),
              style: AppTheme.bodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'connected':
        return Colors.green;
      case 'callback':
      case 'callback_later':
        return Colors.orange;
      case 'not_interested':
        return Colors.red;
      case 'not_reachable':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'connected':
        return Icons.check_circle;
      case 'callback':
      case 'callback_later':
        return Icons.schedule;
      case 'not_interested':
        return Icons.cancel;
      case 'not_reachable':
        return Icons.phone_disabled;
      default:
        return Icons.pending;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'connected':
        return 'CONNECTED';
      case 'callback':
        return 'CALLBACK';
      case 'callback_later':
        return 'CALL LATER';
      case 'not_interested':
        return 'NOT INTERESTED';
      case 'not_reachable':
        return 'NOT REACHABLE';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildGoalsTab() {
    final dailyCallsData = performanceMetrics['daily_calls'] ?? {};
    final conversionData = performanceMetrics['conversion_rate'] ?? {};
    final followUpData = performanceMetrics['follow_up_rate'] ?? {};

    final goals = [
      {
        'title': 'Daily Calls',
        'current': dailyCallsData['current'] ?? 0,
        'target': dailyCallsData['target'] ?? 50,
        'unit': 'calls',
      },
      {
        'title': 'Conversion Rate',
        'current': conversionData['value'] ?? 0,
        'target': conversionData['target'] ?? 30,
        'unit': '%',
      },
      {
        'title': 'Follow-ups',
        'current': followUpData['value'] ?? 0,
        'target': followUpData['target'] ?? 95,
        'unit': '%',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals Progress',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ...goals.map((goal) => _buildGoalItem(goal)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    final current = goal['current'] is int ? goal['current'] : 0;
    final target = goal['target'] is int ? goal['target'] : 1;
    final progress = target > 0 ? current / target : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal['title'],
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$current/$target ${goal['unit']}',
                style: AppTheme.bodySmall.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.8
                  ? Colors.green
                  : progress >= 0.5
                  ? Colors.orange
                  : Colors.red,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trends = analyticsData['trends'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (trends.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No trends data available',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...trends.map(
                (trend) => _buildTrendItem(
                  trend['text'] ?? '',
                  _getTrendIcon(trend['type'] ?? 'stable'),
                  _getTrendColor(trend['type'] ?? 'stable'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTrendIcon(String type) {
    switch (type) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String type) {
    switch (type) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildTrendItem(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
