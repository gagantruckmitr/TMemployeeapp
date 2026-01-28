import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/drivers_provider.dart';
import '../navigation/index.dart';

class MargdarshakDriversPage extends ConsumerStatefulWidget {
  const MargdarshakDriversPage({super.key});

  @override
  ConsumerState<MargdarshakDriversPage> createState() =>
      _MargdarshakDriversPageState();
}

class _MargdarshakDriversPageState extends ConsumerState<MargdarshakDriversPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load drivers via Riverpod
    Future.microtask(() {
      ref.read(driversProvider.notifier).loadDrivers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(driversProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Drivers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D2D5F)),
          onPressed: () {
            // Navigate to Dashboard tab
            margdarshakNavigationKey.currentState?.switchToTab(0);
          },
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: driversState.hasActiveFilters,
              backgroundColor: const Color(0xFFE65100),
              smallSize: 8,
              child: const Icon(Icons.tune_rounded, color: Color(0xFF2D2D5F)),
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFE65100),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE65100),
          tabs: const [
            Tab(text: 'All Drivers'),
            Tab(text: 'New'),
            Tab(text: 'Connected'),
            Tab(text: 'Subscribers'),
          ],
        ),
      ),
      endDrawer: _buildFilterDrawer(driversState),
      body: Column(
        children: [
          _buildSearchBar(driversState),
          Expanded(
            child: driversState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDriversList(driversState.getDriversForTab(0)),
                      _buildDriversList(driversState.getDriversForTab(1)),
                      _buildDriversList(driversState.getDriversForTab(2)),
                      _buildDriversList(driversState.getDriversForTab(3)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(DriversState driversState) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => ref.read(driversProvider.notifier).setSearchQuery(v),
        decoration: InputDecoration(
          hintText: 'Search drivers, shops, or phone numbers...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          suffixIcon: driversState.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(driversProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDrawer(DriversState driversState) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D5F),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(driversProvider.notifier).clearFilters();
                      _searchController.clear();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection('Source Type', [
                      _buildFilterOption(
                        'All Sources',
                        'all',
                        driversState.selectedSource,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSourceFilter(v),
                      ),
                      _buildFilterOption(
                        'Dhaba',
                        'dhaba',
                        driversState.selectedSource,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSourceFilter(v),
                      ),
                      _buildFilterOption(
                        'Puncture Shop',
                        'puncture',
                        driversState.selectedSource,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSourceFilter(v),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildFilterSection('Subscription Status', [
                      _buildFilterOption(
                        'All',
                        'all',
                        driversState.selectedSubscription,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSubscriptionFilter(v),
                      ),
                      _buildFilterOption(
                        'Active',
                        'active',
                        driversState.selectedSubscription,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSubscriptionFilter(v),
                      ),
                      _buildFilterOption(
                        'Trial',
                        'trial',
                        driversState.selectedSubscription,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSubscriptionFilter(v),
                      ),
                      _buildFilterOption(
                        'Expired',
                        'expired',
                        driversState.selectedSubscription,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSubscriptionFilter(v),
                      ),
                      _buildFilterOption(
                        'Never Subscribed',
                        'never_subscribed',
                        driversState.selectedSubscription,
                        (v) => ref
                            .read(driversProvider.notifier)
                            .setSubscriptionFilter(v),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D5F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: options),
      ],
    );
  }

  Widget _buildFilterOption(
    String label,
    String value,
    String selected,
    Function(String) onTap,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE65100).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDriversList(List<Driver> drivers) {
    if (drivers.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () => ref.read(driversProvider.notifier).loadDrivers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (context, index) =>
            _buildDriverCard(drivers[index], index),
      ),
    );
  }

  Widget _buildDriverCard(Driver driver, int index) {
    return GestureDetector(
          onTap: () => _showDriverDetails(driver),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          driver.name
                              .split(' ')
                              .map((n) => n[0])
                              .take(2)
                              .join(),
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            driver.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D2D5F),
                            ),
                          ),
                          Text(
                            driver.maskedPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: driver.earnings.eligible
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        driver.earnings.eligible
                            ? '₹${driver.earnings.amount}'
                            : 'Not Eligible',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: driver.earnings.eligible
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Source Shop
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        driver.shopType == 'dhaba'
                            ? Icons.restaurant_rounded
                            : Icons.build_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From: ${driver.sourceShop} (${driver.shopType == 'dhaba' ? 'Dhaba' : 'Puncture Shop'})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Status Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(
                      driver.kycStatus == 'verified'
                          ? 'KYC Done'
                          : 'KYC Pending',
                      driver.kycStatus == 'verified'
                          ? const Color(0xFF4CAF50)
                          : Colors.orange,
                    ),
                    _buildStatusChip(
                      driver.teleStatus.contacted
                          ? 'Contacted'
                          : 'Not Contacted',
                      driver.teleStatus.contacted
                          ? const Color(0xFF2196F3)
                          : Colors.red,
                    ),
                    _buildStatusChip(
                      _getSubscriptionText(driver.subscription.status),
                      _getSubscriptionColor(driver.subscription.status),
                    ),
                  ],
                ),

                // Tele Info
                if (driver.teleStatus.contacted) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Last Call: ${driver.teleStatus.lastCallDate ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            if (driver.teleStatus.telecaller != null) ...[
                              const Spacer(),
                              Text(
                                'by ${driver.teleStatus.telecaller}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (driver.teleStatus.outcome != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _getOutcomeIcon(driver.teleStatus.outcome),
                                size: 14,
                                color: _getOutcomeColor(
                                  driver.teleStatus.outcome,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getOutcomeText(driver.teleStatus.outcome),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getOutcomeColor(
                                    driver.teleStatus.outcome,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Subscription Info
                if (driver.subscription.plan != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getSubscriptionColor(
                        driver.subscription.status,
                      ).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getSubscriptionColor(
                          driver.subscription.status,
                        ).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.card_membership_rounded,
                          size: 14,
                          color: _getSubscriptionColor(
                            driver.subscription.status,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            driver.subscription.plan!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getSubscriptionColor(
                                driver.subscription.status,
                              ),
                            ),
                          ),
                        ),
                        if (driver.subscription.expiryDate != null)
                          Text(
                            'Exp: ${driver.subscription.expiryDate}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDriverDetails(driver),
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7B1FA2),
                          side: const BorderSide(color: Color(0xFF7B1FA2)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callDriver(driver),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: index * 80),
        )
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No drivers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionText(String? status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'trial':
        return 'Trial';
      case 'never_subscribed':
        return 'No Plan';
      default:
        return 'Unknown';
    }
  }

  Color _getSubscriptionColor(String? status) {
    switch (status) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'expired':
        return Colors.red;
      case 'trial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getOutcomeIcon(String? outcome) {
    switch (outcome) {
      case 'interested':
        return Icons.thumb_up_rounded;
      case 'not_interested':
        return Icons.thumb_down_rounded;
      case 'follow_up':
        return Icons.schedule_rounded;
      case 'not_reachable':
        return Icons.phone_disabled_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getOutcomeColor(String? outcome) {
    switch (outcome) {
      case 'interested':
        return const Color(0xFF4CAF50);
      case 'not_interested':
        return Colors.red;
      case 'follow_up':
        return Colors.orange;
      case 'not_reachable':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getOutcomeText(String? outcome) {
    switch (outcome) {
      case 'interested':
        return 'Interested';
      case 'not_interested':
        return 'Not Interested';
      case 'follow_up':
        return 'Follow-up Required';
      case 'not_reachable':
        return 'Not Reachable';
      default:
        return 'Unknown';
    }
  }

  void _showDriverDetails(Driver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriverDetailsModal(driver: driver),
    );
  }

  void _callDriver(Driver driver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${driver.name}...'),
        backgroundColor: const Color(0xFFE65100),
      ),
    );
  }
}

// Driver Details Modal
class _DriverDetailsModal extends StatelessWidget {
  final Driver driver;
  const _DriverDetailsModal({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      driver.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                        driver.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D5F),
                        ),
                      ),
                      Text(
                        driver.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'From: ${driver.sourceShop}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: driver.earnings.eligible
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        driver.earnings.eligible
                            ? '₹${driver.earnings.amount}'
                            : 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: driver.earnings.eligible
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSection('Driver Status', [
                    _row(
                      'Onboarding',
                      driver.onboardingStatus == 'completed'
                          ? 'Completed ✓'
                          : 'Pending',
                    ),
                    _row(
                      'KYC Status',
                      driver.kycStatus == 'verified' ? 'Verified ✓' : 'Pending',
                    ),
                    _row('Profile Completion', '${driver.profileCompletion}%'),
                  ]),

                  _buildSection('Contact Timeline', [
                    _row(
                      'Status',
                      driver.teleStatus.contacted
                          ? 'Contacted ✓'
                          : 'Not Contacted',
                    ),
                    if (driver.teleStatus.lastCallDate != null)
                      _row('Last Call', driver.teleStatus.lastCallDate!),
                    if (driver.teleStatus.outcome != null)
                      _row('Outcome', _outcomeText(driver.teleStatus.outcome)),
                    if (driver.teleStatus.telecaller != null)
                      _row('Telecaller', driver.teleStatus.telecaller!),
                  ]),

                  _buildSection('Subscription', [
                    _row(
                      'Status',
                      _subscriptionText(driver.subscription.status),
                    ),
                    if (driver.subscription.plan != null)
                      _row('Plan', driver.subscription.plan!),
                    if (driver.subscription.expiryDate != null)
                      _row('Expiry', driver.subscription.expiryDate!),
                  ]),

                  _buildSection('Linked Shop', [
                    _row('Shop Name', driver.sourceShop),
                    _row(
                      'Type',
                      driver.shopType == 'dhaba' ? 'Dhaba' : 'Puncture Shop',
                    ),
                  ]),

                  _buildNotesSection(),

                  const SizedBox(height: 20),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D5F),
              ),
            ),
          ),
          const Divider(height: 1),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agent Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Driver seems genuine and interested. Good candidate for subscription.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Added by: Field Agent • Jan 20',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Admin Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Profile verified. KYC approved. Good track record.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Updated by: Admin Team • Jan 21',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Call Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message_rounded, size: 18),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.note_add_rounded, size: 18),
                label: const Text('Add Note'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7B1FA2),
                  side: const BorderSide(color: Color(0xFF7B1FA2)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Schedule'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFE65100)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _outcomeText(String? outcome) {
    switch (outcome) {
      case 'interested':
        return 'Interested';
      case 'not_interested':
        return 'Not Interested';
      case 'follow_up':
        return 'Follow-up Required';
      case 'not_reachable':
        return 'Not Reachable';
      default:
        return 'Unknown';
    }
  }

  String _subscriptionText(String? status) {
    switch (status) {
      case 'active':
        return 'Active ✓';
      case 'expired':
        return 'Expired';
      case 'trial':
        return 'Trial';
      case 'never_subscribed':
        return 'Never Subscribed';
      default:
        return 'Unknown';
    }
  }
}
