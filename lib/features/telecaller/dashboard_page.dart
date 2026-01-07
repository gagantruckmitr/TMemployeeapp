import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';
import '../../core/config/api_config.dart';
import '../../models/dummy_models.dart';
import '../../models/smart_calling_models.dart';
import '../../routes/app_router.dart';
import 'widgets/call_type_selection_dialog.dart';
import 'widgets/ivr_call_waiting_overlay.dart';
import '../../core/services/real_auth_service.dart';
import '../../core/services/telecaller_service.dart';
import '../../core/services/activity_tracker_service.dart';
import '../../core/services/smart_calling_service.dart';
import 'screens/search_users_screen.dart';

import 'performance_analytics_page.dart';
import '../../core/services/subscription_service.dart';
import 'subscriptions/subscriptions_screen.dart';
import '../../core/services/today_leads_service.dart';
import 'screens/fresh_leads_screen.dart';
import 'screens/backlog_screen.dart';
import 'screens/profile_completion_screen.dart';

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
  int _totalSubscriptions = 0;
  double _totalRevenue = 0.0;
  String _selectedPeriod = 'today'; // today, week, month, all
  List<TodayLead> _todayLeads = [];
  bool _isLoadingLeads = false;
  bool _isLoadingKPIs = true; // For skeleton loading
  int _realBacklogCount = 0;

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

    // Set loading state for skeleton
    setState(() {
      _isLoadingKPIs = true;
    });

    try {
      // Load stats from telecaller service with period filter
      final stats = await TelecallerService.instance.getDashboardStats(
        period: _selectedPeriod,
      );
      print('📊 Dashboard Stats Loaded ($_selectedPeriod): $stats');

      // Load subscription stats
      final subscriptionStats = await SubscriptionService.instance
          .getSubscriptionStats();
      print(
        '💳 Subscription Stats Loaded: ${subscriptionStats?.totalSubscriptions ?? 0}',
      );
      print('💰 Total Revenue: ₹${subscriptionStats?.totalRevenue ?? 0}');

      // Load today's leads (await to ensure leads are loaded before UI update)
      await _loadTodayLeads();

      // Load real backlog count
      await _loadBacklogCount();

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          // Always show TODAY's subscriptions in the KPI card
          _totalSubscriptions = subscriptionStats?.todaySubscriptions ?? 0;
          _totalRevenue = subscriptionStats?.todayRevenue ?? 0.0;
          _isLoadingKPIs = false; // Done loading
        });
        print('✅ Dashboard UI Updated with stats');
        print('💳 Today Subscriptions: $_totalSubscriptions');
        print('💰 Today Revenue: ₹$_totalRevenue');

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
        setState(() {
          _isLoadingKPIs = false; // Stop loading on error
        });
        // Get user-friendly error message
        String errorMessage = 'Unable to load dashboard';
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('socket') ||
            errorString.contains('failed host lookup') ||
            errorString.contains('network')) {
          errorMessage = 'No internet connection';
        } else if (errorString.contains('timeout')) {
          errorMessage = 'Connection timeout';
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$errorMessage. Please check your connection and try again.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
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

  Future<void> _loadTodayLeads() async {
    if (!mounted) return;

    _isLoadingLeads = true;

    try {
      final leads = await TodayLeadsService.instance.getTodayLeads();
      print('📋 Today Leads Loaded: ${leads.length} leads');

      if (mounted) {
        _todayLeads = leads;
        _isLoadingLeads = false;
      }
    } catch (e) {
      print('❌ Error loading today leads: $e');
      if (mounted) {
        _isLoadingLeads = false;
      }
    }
  }

  Future<void> _loadBacklogCount() async {
    if (!mounted) return;

    try {
      final currentUser = RealAuthService.instance.currentUser;
      final token = await RealAuthService.instance.getAuthToken();

      if (currentUser == null || token == null) {
        print('❌ Cannot load backlog: User not logged in or no token');
        return;
      }

      final callerId = int.tryParse(currentUser.id) ?? 1;

      // Use Laravel API - same as backlog_screen.dart
      final url =
          'https://truckmitr.com/api/telehead/withoutCallHistory?admin_id=$callerId';

      print('🔍 Loading backlog count from Laravel API: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Laravel API returns: {"success": true, "total": 477, "data": [...]}
        if (data is Map && data['success'] == true) {
          final backlogCount = data['total'] ?? 0;
          print('✅ Backlog count from Laravel API: $backlogCount');

          if (mounted) {
            setState(() {
              _realBacklogCount = backlogCount;
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error loading backlog count: $e');
      // Don't show error to user, just use 0 as fallback
      if (mounted) {
        setState(() {
          _realBacklogCount = 0;
        });
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

  // Build profile avatar with photo or initials
  Widget _buildProfileAvatar() {
    final user = RealAuthService.instance.currentUser;
    final photoUrl = user?.photoUrl;
    final userName = _getUserName();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        placeholder: (context, url) => Container(
          color: AppTheme.primaryColor,
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.primaryColor,
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.primaryColor,
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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

                      // Today's Workflow Heading
                      Center(
                        child: Text(
                          "Today's Workflow",
                          style: AppTheme.headingMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // KPI Cards in horizontal scroll
                      _buildKPICardsSection(),

                      const SizedBox(height: 24),

                      // Smart Calling Card
                      _buildSmartCallingCard(),

                      const SizedBox(height: 16),

                      // Profile Completion Card
                      _buildProfileCompletionCard(),

                      const SizedBox(height: 20),

                      // Call History Section
                      _buildCallHistorySection(),

                      const SizedBox(height: 20),

                      // Call Analytics Section
                      _buildCallAnalyticsSection(),

                      const SizedBox(height: 20),

                      // // Performance Section
                      // _buildPerformanceSection(),
                      const SizedBox(height: 20),

                      // Follow-ups Section
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Slim top navigation bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Menu button
                  Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Colors.white),
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

                  const SizedBox(width: 12),

                  // User name and greeting stacked
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hi ${_getUserName()}!',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                        const SizedBox(height: 2),
                        Text(
                          _getGreeting(),
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      ],
                    ),
                  ),

                  // Right side icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification bell
                      Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Stack(
                              children: [
                                const Center(child: Text('')),
                                const SizedBox(height: 4),
                                const Center(
                                  child: Text(
                                    'V. 06',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms)
                          .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(width: 8),

                      // Profile avatar with photo
                      GestureDetector(
                            onTap: _navigateToProfile,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: _buildProfileAvatar(),
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

            // Period filter chips
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
            //   child: _buildPeriodFilter(),
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _buildPeriodFilter() {
  //   final periods = [
  //     {'value': 'today', 'label': 'Today'},
  //     {'value': 'week', 'label': 'Week'},
  //     {'value': 'month', 'label': 'Month'},
  //     {'value': 'all', 'label': 'All'},
  //   ];

  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: periods.map((period) {
  //         final isSelected = _selectedPeriod == period['value'];
  //         return Padding(
  //           padding: const EdgeInsets.only(right: 6),
  //           child: Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               onTap: () {
  //                 HapticFeedback.lightImpact();
  //                 setState(() {
  //                   _selectedPeriod = period['value']!;
  //                 });
  //                 _loadDashboardData();
  //               },
  //               borderRadius: BorderRadius.circular(16),
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //                 decoration: BoxDecoration(
  //                   color: isSelected ? AppTheme.primaryBlue : Colors.white,
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(
  //                     color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
  //                     width: 1.5,
  //                   ),
  //                   boxShadow: isSelected ? [
  //                     BoxShadow(
  //                       color: AppTheme.primaryBlue.withOpacity(0.2),
  //                       blurRadius: 8,
  //                       offset: const Offset(0, 2),
  //                     ),
  //                   ] : [],
  //                 ),
  //                 child: Text(
  //                   period['label']!,
  //                   style: AppTheme.bodyMedium.copyWith(
  //                     color: isSelected ? Colors.white : Colors.grey.shade700,
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

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
    // Show skeleton loading while data is being fetched
    if (_isLoadingKPIs) {
      return _buildKPISkeletonSection();
    }

    final kpiData = _getDynamicKPIData();

    return Column(
      children: [
        // First row - 3 KPIs (Total, Connected, Not Connected)
        Row(
          children: [
            Expanded(child: _buildKPICard(kpiData[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildKPICard(kpiData[1])),
            const SizedBox(width: 8),
            Expanded(child: _buildKPICard(kpiData[2])),
          ],
        ),
        const SizedBox(height: 8),
        // Second row - 2 KPIs (Callbacks, Pending)
        Row(
          children: [
            Expanded(child: _buildKPICard(kpiData[3])),
            const SizedBox(width: 8),
            Expanded(child: _buildKPICard(kpiData[4])),
          ],
        ),
        const SizedBox(height: 12),
        // Subscription KPI (full width for better visibility)
        _buildSubscriptionKPICard(),
      ],
    );
  }

  Widget _buildKPISkeletonSection() {
    return Column(
      children: [
        // First row - 3 skeleton KPIs
        Row(
          children: [
            Expanded(child: _buildKPISkeletonCard()),
            const SizedBox(width: 8),
            Expanded(child: _buildKPISkeletonCard()),
            const SizedBox(width: 8),
            Expanded(child: _buildKPISkeletonCard()),
          ],
        ),
        const SizedBox(height: 8),
        // Second row - 2 skeleton KPIs
        Row(
          children: [
            Expanded(child: _buildKPISkeletonCard()),
            const SizedBox(width: 8),
            Expanded(child: _buildKPISkeletonCard()),
          ],
        ),
        const SizedBox(height: 12),
        // Subscription skeleton
        _buildSubscriptionSkeletonCard(),
      ],
    );
  }

  Widget _buildKPISkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon skeleton
          Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.grey.shade100),
          const SizedBox(height: 4),
          // Number skeleton
          Container(
                width: 40,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1200.ms,
                color: Colors.grey.shade100,
                delay: 100.ms,
              ),
          const SizedBox(height: 4),
          // Title skeleton
          Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1200.ms,
                color: Colors.grey.shade100,
                delay: 200.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSkeletonCard() {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Left icon skeleton
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              // Middle content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Right content skeleton
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.grey.shade100);
  }

  List<KPIData> _getDynamicKPIData() {
    // Use remaining fresh leads count (uncalled leads) for Fresh Leads KPI
    final remainingFreshLeads = TodayLeadsService.instance.remainingFreshLeads;
    final connectedCalls = _dashboardStats['connected_calls'] ?? 0;
    final notConnectedCalls =
        _dashboardStats['not_connected_calls'] ?? 0; // From API
    final callbacksScheduled = _dashboardStats['callbacks_scheduled'] ?? 0;
    // Use real backlog count from backlog API instead of pending_calls
    final backlogCount = _realBacklogCount;

    return [
      KPIData(
        title: 'Fresh Leads',
        value: remainingFreshLeads.toString(),
        icon: '📞',
        color: 0xFF4F46E5,
      ),
      KPIData(
        title: 'Connected Calls',
        value: connectedCalls.toString(),
        icon: '✅',
        color: 0xFF10B981,
      ),
      KPIData(
        title: 'Not Connected',
        value: notConnectedCalls.toString(),
        icon: '❌',
        color: 0xFFEF4444,
      ),
      KPIData(
        title: 'Callbacks',
        value: callbacksScheduled.toString(),
        icon: '🔔',
        color: 0xFFF59E0B,
      ),
      KPIData(
        title: 'Backlog',
        value: backlogCount.toString(),
        icon: '⏳',
        color: 0xFF8B5CF6,
      ),
    ];
  }

  Widget _buildKPICard(KPIData kpi) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.lightImpact();
            _showKPIDetails(kpi);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Color(kpi.color).withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon at top
                Text(kpi.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                // Bold number
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    kpi.value,
                    style: AppTheme.headingMedium.copyWith(
                      color: Color(kpi.color),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Small title below number
                Text(
                  kpi.title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionKPICard() {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to subscriptions screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.95),
                  const Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side - Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('💳', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                // Middle - Subscription info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Subscriptions',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _totalSubscriptions.toString(),
                            style: AppTheme.headingLarge.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Today',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side - Today's Revenue
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Today's Revenue",
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_formatRevenue(_totalRevenue)}',
                      style: AppTheme.headingMedium.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRevenue(double revenue) {
    // Show exact amount with comma separators
    final amount = revenue.toStringAsFixed(0);
    // Add comma separators for thousands
    return amount.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildSmartCallingCard() {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome Calling',
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                  const SizedBox(height: 4),
                  Text(
                        'Start IVR call for your next best lead',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideX(begin: -0.2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right side - Compact call button
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _startSmartCalling();
              },
              child:
                  Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.08, 1.08),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildProfileCompletionCard() {
    // Simple card that navigates to profile completion screen with sample contact cards
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _navigateToProfileCompletion();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_search_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profile Completion',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View driver/transporter profile fields',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.1);
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

  Widget _buildCallAnalyticsSection() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToCallAnalytics,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.accentPurple.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call Analytics',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track performance & view detailed insights',
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

  void _navigateToCallAnalytics() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerformanceAnalyticsPage(
          onNavigateBack: () => Navigator.pop(context),
        ),
      ),
    );
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
                child: _hasPerformanceData()
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

  // --- Helper Methods ---

  void _navigateToProfile() {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
    } else {
      // Fallback to GoRouter if callback is not available
      context.go(AppRouter.profile);
    }
  }

  void _navigateToProfileCompletion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileCompletionScreen()),
    );
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
    print('📊 KPI Tapped: ${kpi.title}');

    // Handle Fresh Leads KPI separately
    if (kpi.title.toLowerCase() == 'fresh leads') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FreshLeadsScreen()),
      );
      return;
    }

    // Handle Backlog KPI separately - navigate to backlog screen
    if (kpi.title.toLowerCase() == 'backlog') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BacklogScreen()),
      );
      return;
    }

    // Navigate to appropriate screen based on KPI
    if (widget.onNavigateToSection != null) {
      NavigationSection? targetSection;
      String? filter;

      switch (kpi.title.toLowerCase()) {
        case 'total':
          targetSection = NavigationSection.callHistory;
          filter = 'all';
          break;
        case 'connected':
        case 'connected calls':
          targetSection = NavigationSection.callHistory;
          filter = 'connected';
          break;
        case 'not connected':
          // Use 'callback' filter value which maps to "Not Connected" in Call History
          targetSection = NavigationSection.callHistory;
          filter = 'callback';
          break;
        case 'callbacks':
          // Use 'callback_later' filter value which maps to "Call Back" in Call History
          targetSection = NavigationSection.callHistory;
          filter = 'callback_later';
          break;
        case 'pending':
          // Navigate to pending calls screen
          targetSection = NavigationSection.pendingCalls;
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

  // void _navigateToModernDashboard() {
  //   HapticFeedback.lightImpact();
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const ModernDashboardPage(),
  //     ),
  //   );
  // }

  Future<void> _initiateCall(Lead lead) async {
    try {
      // Show call type selection dialog
      final callType = await showDialog<String>(
        context: context,
        builder: (context) =>
            CallTypeSelectionDialog(driverName: lead.contactPerson),
      );

      if (callType == null) return;

      // Get current user
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ User not logged in. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final callerId = int.tryParse(currentUser.id) ?? 1;

      // For demo purposes, using a placeholder phone number
      // In production, you should fetch the actual phone number from the lead data
      final phoneNumber = lead.phoneNumber ?? '';

      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available for this contact'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (callType == 'manual') {
        await _handleManualCall(lead, phoneNumber, callerId);
      } else if (callType == 'easygo_ivr') {
        await _handleIVRCall(lead, phoneNumber, callerId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initiating call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleManualCall(
    Lead lead,
    String phoneNumber,
    int callerId,
  ) async {
    try {
      final cleanMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Log manual call
      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: lead.id.toString(),
      );

      if (result['success'] == true) {
        final driverMobileRaw = result['data']?['driver_mobile_raw'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Calling ${lead.contactPerson}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Make direct call
        await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Call completed with ${lead.contactPerson}'),
              backgroundColor: Colors.green,
            ),
          );
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
    Lead lead,
    String phoneNumber,
    int callerId,
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
        driverId: lead.id.toString(),
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
                  driverName: lead.contactPerson,
                  referenceId: referenceId,
                  onCallEnded: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Call completed with ${lead.contactPerson}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
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
