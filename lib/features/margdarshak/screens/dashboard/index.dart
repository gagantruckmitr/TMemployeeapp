import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/margdarshak_auth_service.dart';
import '../../services/margdarshak_api_service.dart';
import '../../widgets/dashboard_stats_card.dart';
import '../../widgets/quick_action_card.dart';

import '../../widgets/duty_tracking_widget.dart';
import '../add_shop/index.dart';
import '../navigation/index.dart';
import '../../services/notification_service.dart';

class MargdarshakDashboardPage extends StatefulWidget {
  const MargdarshakDashboardPage({super.key});

  @override
  State<MargdarshakDashboardPage> createState() =>
      _MargdarshakDashboardPageState();
}

class _MargdarshakDashboardPageState extends State<MargdarshakDashboardPage> {
  final _authService = MargdarshakAuthService();
  final _apiService = MargdarshakApiService();

  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await MargdarshakNotificationService.instance.initialize();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 Dashboard: Starting to fetch data...');

      // Fetch real dashboard data from API
      final response = await _apiService.getDashboardStats();

      print('🔵 Dashboard: Response received');
      print('   Full Response: $response');
      print('   Status: ${response['status']}');
      print('   Message: ${response['message']}');
      print('   Has Data: ${response['data'] != null}');

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];
        print('✅ Dashboard: Data loaded successfully');
        print('   Territory: ${data['territory']}');
        print('   Shops: ${data['shops']}');
        print('   Drivers: ${data['drivers']}');
        print('   Earnings: ${data['earnings']}');

        // Extract specific values
        print('📊 Extracted Values:');
        print('   State Name: ${data['territory']?['state_name']}');
        print('   Districts Count: ${data['territory']?['districts_count']}');
        print('   Total Onboarded: ${data['shops']?['total_onboarded']}');
        print('   Dhaba Count: ${data['shops']?['dhaba_count']}');
        print('   Puncture Count: ${data['shops']?['puncture_count']}');
        print('   Drivers Total: ${data['drivers']?['total']}');
        print('   Drivers This Month: ${data['drivers']?['this_month']}');
        print('   Monthly Amount: ${data['earnings']?['monthly_amount']}');

        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });

        print('✅ Dashboard: State updated with new data');
        print('   _dashboardData: $_dashboardData');
      } else {
        throw Exception(
          response['message'] ?? 'Failed to fetch dashboard data',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Dashboard error: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');

      // Fallback to demo data if API fails
      setState(() {
        _dashboardData = {
          'territory': {
            'state_name': _authService.currentUser?.stateName ?? 'N/A',
            'districts_count': 0,
            'districts': [],
          },
          'shops': {
            'total_onboarded': 0,
            'dhaba_count': 0,
            'puncture_count': 0,
            'blocked_shops': 0,
          },
          'drivers': {'total': 0, 'today': 0, 'this_week': 0, 'this_month': 0},
          'earnings': {
            'total_amount': 0,
            'monthly_amount': 0,
            'pending_amount': 0,
          },
        };
        _errorMessage = 'API Error - Using offline mode';
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: $e'),
            backgroundColor: Colors.orange,
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
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    // Debug: Print build info
    print('🏗️ Dashboard build() called');
    print('   _isLoading: $_isLoading');
    print('   _dashboardData keys: ${_dashboardData.keys.toList()}');
    print('   Territory data: ${_dashboardData['territory']}');
    print('   Shops data: ${_dashboardData['shops']}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(
                        _dashboardData['territory']?['name'] ??
                            user?.name ??
                            'Margdarshak',
                        _dashboardData['territory']?['employee_id'] ??
                            user?.employeeId ??
                            'Field Agent',
                      ),

                      const SizedBox(height: 24),

                      // Error message if any
                      if (_errorMessage != null) _buildErrorBanner(),

                      // Duty Tracking
                      const DutyTrackingWidget(),

                      const SizedBox(height: 20),

                      // Territory Summary
                      _buildTerritoryCard(),

                      const SizedBox(height: 20),

                      // Stats Grid
                      _buildStatsGrid(),

                      const SizedBox(height: 20),

                      // Quick Actions
                      _buildQuickActions(),

                      const SizedBox(height: 20),

                      // Recent Activity
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String userName, String employeeId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  employeeId,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Show notifications
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildTerritoryCard() {
    final territory = _dashboardData['territory'] ?? {};

    return Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Color(0xFF1976D2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Territory',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D5F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'State',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          territory['state_name']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Districts',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${territory['districts_count'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatsGrid() {
    final shops = _dashboardData['shops'] ?? {};
    final drivers = _dashboardData['drivers'] ?? {};
    final earnings = _dashboardData['earnings'] ?? {};

    return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Shops Onboarded',
                    value: '${shops['total_onboarded'] ?? 0}',
                    subtitle: '${shops['blocked_shops'] ?? 0} blocked',
                    icon: Icons.store_rounded,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Drivers Added',
                    value: '${drivers['this_month'] ?? 0}',
                    subtitle: 'This month',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF7B1FA2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Earnings',
                    value: '₹${earnings['monthly_amount'] ?? 0}',
                    subtitle: 'this month',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF388E3C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Today\'s Drivers',
                    value: '${drivers['today'] ?? 0}',
                    subtitle: '${drivers['this_week'] ?? 0} this month',
                    icon: Icons.today_rounded,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickActions() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D5F),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    title: 'Add Partner',
                    icon: Icons.add_business_rounded,
                    color: const Color(0xFFFF6B35),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddShopScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    title: 'View Drivers',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF00B894),
                    onTap: () {
                      // Navigate to drivers tab in main navigation
                      _navigateToTab(3); // Drivers tab index
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    title: 'View Earnings',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFE17055),
                    onTap: () {
                      // Navigate to earnings tab in main navigation
                      _navigateToTab(4); // Earnings tab index
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    title: 'My Territory',
                    icon: Icons.map_outlined,
                    color: const Color(0xFF1976D2),
                    onTap: () {
                      // Navigate to territory tab in main navigation
                      _navigateToTab(1); // Territory tab index
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    title: 'My Shops',
                    icon: Icons.store_outlined,
                    color: const Color(0xFFE65100),
                    onTap: () {
                      // Navigate to shops tab in main navigation
                      _navigateToTab(2); // Shops tab index
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()), // Empty space for symmetry
              ],
            ),
            const SizedBox(height: 12),
            // Row(
            //   children: [
            //     Expanded(
            //       child: QuickActionCard(
            //         title: 'Tele Activity',
            //         icon: Icons.phone_outlined,
            //         color: const Color(0xFF9C27B0),
            //         onTap: () {
            //           // Navigate to drivers with tele filter
            //           _navigateToDriversWithFilter('contacted');
            //         },
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: QuickActionCard(
            //         title: 'Subscriptions',
            //         icon: Icons.card_membership_outlined,
            //         color: const Color(0xFF795548),
            //         onTap: () {
            //           // Navigate to drivers with subscription filter
            //           _navigateToDriversWithFilter('subscribers');
            //         },
            //       ),
            //     ),
            //   ],
            // ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  void _navigateToTab(int tabIndex) {
    // Use the global key to access the navigation container state
    margdarshakNavigationKey.currentState?.switchToTab(tabIndex);
  }
}
