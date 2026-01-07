import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

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
  Map<String, dynamic> analyticsData = {};
  List<Map<String, dynamic>> callHistory = [];
  bool _isLoading = true;
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

          print('📊 Analytics Data Received: $analyticsData');
          print('📈 Overview Data: ${analyticsData['overview']}');

          // Get call history from recent_calls
          callHistory = List<Map<String, dynamic>>.from(
            analyticsData['recent_calls'] ?? [],
          );

          _isLoading = false;
        });
      } else {
        // API returned success: false, use empty data
        setState(() {
          analyticsData = _getEmptyAnalyticsData();
          callHistory = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Analytics Error: $e');
      // On error, show empty data instead of staying in loading state
      setState(() {
        analyticsData = _getEmptyAnalyticsData();
        callHistory = [];
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
      backgroundColor: Colors.white,
      body: SafeArea(
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
                      children: [_buildOverviewTab(), _buildCallsTab()],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () {
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
                  'Analytics',
                  style: AppTheme.headingMedium.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.black87,
              size: 24,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _buildPeriodButton('Today', 'today'),
            _buildPeriodButton('Yesterday', 'yesterday'),
            _buildPeriodButton('This Week', 'this_week'),
            _buildPeriodButton('This Month', 'this_month'),
            _buildPeriodButton('All', 'all'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = value);
        _loadAnalyticsData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? Colors.black : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Call Logs'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Updating Data',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fetching latest insights...',
              style: AppTheme.bodySmall.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = analyticsData['overview'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Summary',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildOverviewCards(overview),
          const SizedBox(height: 24),
          _buildSuccessRateCard(overview),
        ],
      ),
    );
  }

  Widget _buildSuccessRateCard(Map<String, dynamic> overview) {
    final successRate = overview['success_rate']?.toDouble() ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success Rate',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${successRate.toStringAsFixed(1)}%',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: successRate / 100,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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
                Icons.phone_rounded,
                const Color(0xFF007AFF), // iOS Blue
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Connected',
                '${overview['connected_calls'] ?? 0}',
                Icons.check_circle_rounded,
                const Color(0xFF34C759), // iOS Green
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'No Connection',
                '${overview['not_connected_calls'] ?? 0}',
                Icons.phone_missed_rounded,
                const Color(0xFFFF3B30), // iOS Red
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Callbacks',
                '${overview['callbacks_scheduled'] ?? 0}',
                Icons.timer_rounded,
                const Color(0xFFFF9500), // iOS Orange
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Recent Activity',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Expanded(
          child: callHistory.isEmpty
              ? _buildEmptyCallsState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: callHistory.length,
                  itemBuilder: (context, index) =>
                      _buildCallHistoryItem(callHistory[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyCallsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_disabled_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Calls',
            style: AppTheme.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Calls will appear here once they are made.',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(Map<String, dynamic> call) {
    final status = call['call_status'] ?? 'pending';
    final name = (call['driver_name'] ?? call['user_name'] ?? 'Unknown').trim();
    final duration = call['duration_formatted'] ?? '0:00';
    final timeAgo = call['time_ago'] ?? '';
    final mobile = call['mobile'] ?? '';

    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getStatusIcon(status), color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (mobile.isNotEmpty) ...[
                      Text(
                        mobile,
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      timeAgo,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                duration,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatStatus(status),
                style: AppTheme.bodySmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'connected':
        return const Color(0xFF34C759);
      case 'callback':
      case 'callback_later':
        return const Color(0xFFFF9500);
      case 'not_interested':
        return const Color(0xFFFF3B30);
      case 'not_reachable':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF007AFF);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'connected':
        return Icons.call_made_rounded;
      case 'callback':
      case 'callback_later':
        return Icons.history_rounded;
      case 'not_interested':
        return Icons.call_end_rounded;
      case 'not_reachable':
        return Icons.phone_disabled_rounded;
      default:
        return Icons.call_rounded;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'callback':
        return 'Callback';
      case 'callback_later':
        return 'Soon';
      case 'not_interested':
        return 'Declined';
      case 'not_reachable':
        return 'Missed';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
