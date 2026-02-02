import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../add_shop/index.dart';
import '../navigation/index.dart';
import '../view_shop_detail/index.dart';
import '../../services/margdarshak_api_service.dart';

class MargdarshakShopsPage extends StatefulWidget {
  const MargdarshakShopsPage({super.key});

  @override
  State<MargdarshakShopsPage> createState() => _MargdarshakShopsPageState();
}

class _MargdarshakShopsPageState extends State<MargdarshakShopsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = MargdarshakApiService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _shops = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 Loading territory shops with filter: $_selectedFilter');

      // Fetch real data from API
      final response = await _apiService.getTerritoryShops(
        filter: _selectedFilter,
      );

      if (response['status'] == true && response['data'] != null) {
        final shopsData = response['data'] as List;
        print('✅ Loaded ${shopsData.length} shops from API');

        setState(() {
          _shops = shopsData.map((shop) => _mapApiShopToLocal(shop)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load shops');
      }
    } catch (e) {
      print('❌ Failed to load shops: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shops: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadShops,
            ),
          ),
        );
      }
    }
  }

  /// Map API response to local shop format
  Map<String, dynamic> _mapApiShopToLocal(Map<String, dynamic> apiShop) {
    // Helper to get valid location
    String getDistrict() {
      var city = apiShop['city'];
      var state = apiShop['state_name'];

      bool isValid(dynamic val) {
        if (val == null) return false;
        String s = val.toString().trim();
        return s.isNotEmpty && s.toLowerCase() != 'null';
      }

      if (isValid(city)) return city.toString();
      if (isValid(state)) return state.toString();
      return 'Unknown';
    }

    return {
      'id': apiShop['id']?.toString() ?? '',
      'name': apiShop['shop_name'] ?? 'Unknown Shop',
      'type': apiShop['role'] ?? 'unknown', // 'dhaba' or 'puncture'
      'owner': apiShop['owner_name'] ?? 'Unknown Owner',
      'mobile': apiShop['mobile'] ?? 'N/A',
      'address': apiShop['address'] ?? 'No address provided',
      'district': getDistrict(),
      'status': apiShop['status'] == '1' ? 'approved' : 'pending',
      'driversCount': apiShop['driver_count'] ?? 0,
      'addedDate': apiShop['created_at'] ?? '',
      'source': apiShop['onboarding_type']?.toLowerCase() == 'direct'
          ? 'manual'
          : 'auto',
      'uniqueId': apiShop['unique_id'] ?? '',
      'referralCode': apiShop['referral_code'] ?? '',
      'displayType': apiShop['display_type'] ?? '',
    };
  }

  List<Map<String, dynamic>> get filteredShops {
    // API already filters by type, but we handle 'pending' filter locally
    if (_selectedFilter == 'pending') {
      return _shops.where((shop) => shop['status'] == 'pending').toList();
    }
    return _shops;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Shops',
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
            onPressed: () {
              _showAddShopModal();
            },
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2D2D5F)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),

          // Quick Actions
          // _buildQuickActions(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadShops,
                    child: filteredShops.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredShops.length,
                            itemBuilder: (context, index) {
                              final shop = filteredShops[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildShopCard(shop, index),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddShopModal();
        },
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Shop'),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Dhabas', 'dhaba'),
            const SizedBox(width: 8),
            _buildFilterChip('Puncture', 'puncture'),
          ],
        ),
      ),
    );
  }

  // Widget _buildQuickActions() {
  //   return Container(
  //     color: Colors.white,
  //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Quick Actions',
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: Color(0xFF2D2D5F),
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildQuickActionButton(
  //                 'Add Dhaba',
  //                 Icons.restaurant_rounded,
  //                 const Color(0xFFFF6B35),
  //                 () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => const AddShopScreen(),
  //                     ),
  //                   ).then((_) => _loadShops());
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildQuickActionButton(
  //                 'Add Puncture',
  //                 Icons.build_rounded,
  //                 const Color(0xFF6C5CE7),
  //                 () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => const AddShopScreen(),
  //                     ),
  //                   ).then((_) => _loadShops());
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildQuickActionButton(
  //                 'View Drivers',
  //                 Icons.people_outline_rounded,
  //                 const Color(0xFF7B1FA2),
  //                 () {
  //                   _navigateToTab(3); // Navigate to drivers tab
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildQuickActionButton(
  //                 'Territory',
  //                 Icons.map_outlined,
  //                 const Color(0xFF1976D2),
  //                 () {
  //                   _navigateToTab(1); // Navigate to territory tab
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        // Reload shops with new filter
        _loadShops();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE65100) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, int index) {
    final isApproved = shop['status'] == 'approved';
    // final isPending = shop['status'] == 'pending';
    final isDhaba = shop['type'] == 'dhaba';

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(
            //   color: isPending
            //       ? Colors.orange.shade200
            //       : isApproved
            //       ? Colors.green.shade200
            //       : Colors.grey.shade200,
            //   width: 1,
            // ),
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (isDhaba
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFF6C5CE7))
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDhaba ? Icons.restaurant_rounded : Icons.build_rounded,
                      color: isDhaba
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF6C5CE7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['name'] ?? 'Unknown Shop',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D5F),
                          ),
                        ),
                        Text(
                          shop['owner'] ?? 'Unknown Owner',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(shop['status']),
                      if (shop['displayType'] != null &&
                          shop['displayType'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            shop['displayType'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on_rounded,
                      shop['district'] ?? 'Unknown',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone_rounded,
                      shop['mobile'] ?? 'N/A',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.people_rounded,
                      '${shop['driversCount'] ?? 0} drivers',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      shop['source'] == 'auto'
                          ? Icons.auto_awesome_rounded
                          : Icons.person_add_rounded,
                      shop['source'] == 'auto' ? 'Auto-linked' : 'Manual',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Address (Hide if empty or placeholder)
              if (shop['address'] != null &&
                  shop['address'] != 'No address provided' &&
                  shop['address'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shop['address'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopDetailsScreen(
                              uniqueId: shop['uniqueId'] ?? '',
                              userId: shop['id'] ?? '',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  if (isApproved && (shop['driversCount'] ?? 0) >= 1) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showShopDriversBottomSheet(shop);
                        },
                        icon: const Icon(
                          Icons.people_outline_rounded,
                          size: 16,
                        ),
                        label: Text('Drivers (${shop['driversCount'] ?? 0})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7B1FA2),
                          side: const BorderSide(color: Color(0xFF7B1FA2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
        )
        .slideX(begin: 0.2, end: 0, duration: 300.ms);
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = const Color(0xFF4CAF50);
        text = 'Approved';
        break;
      case 'pending':
        color = const Color(0xFFFF9800);
        text = 'Pending';
        break;
      case 'rejected':
        color = const Color(0xFFF44336);
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
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
              Icons.store_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No shops found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first shop',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddShopModal();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Shop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddShopModal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShopScreen()),
    ).then((_) {
      // Refresh shops list when returning from add shop screen
      _loadShops();
    });
  }

  void _showShopDriversBottomSheet(Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ShopDriversBottomSheet(shop: shop, apiService: _apiService),
    );
  }
}

/// Bottom sheet widget to display shop drivers
class _ShopDriversBottomSheet extends StatefulWidget {
  final Map<String, dynamic> shop;
  final MargdarshakApiService apiService;

  const _ShopDriversBottomSheet({required this.shop, required this.apiService});

  @override
  State<_ShopDriversBottomSheet> createState() =>
      _ShopDriversBottomSheetState();
}

class _ShopDriversBottomSheetState extends State<_ShopDriversBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _drivers = [];
  String? _errorMessage;
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _loadShopDrivers();
  }

  Future<void> _loadShopDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final referralCode = widget.shop['referralCode'] ?? '';

      if (referralCode.isEmpty) {
        throw Exception('Referral code not found for this shop');
      }

      print('🔵 Loading drivers for shop: ${widget.shop['name']}');
      print('   Referral Code: $referralCode');

      final response = await widget.apiService.getShopDrivers(
        referralCode: referralCode,
      );

      if (response['status'] == true && response['data'] != null) {
        final driversData = response['data'] as List;
        print('✅ Loaded ${driversData.length} drivers for shop');

        setState(() {
          _shopName = response['shop_name'] ?? widget.shop['name'];
          _drivers = driversData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load drivers');
      }
    } catch (e) {
      print('❌ Failed to load shop drivers: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Color(0xFF7B1FA2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shopName.isNotEmpty ? _shopName : widget.shop['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D5F),
                        ),
                      ),
                      Text(
                        '${widget.shop['driversCount'] ?? 0} Drivers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : _drivers.isEmpty
                ? _buildEmptyState()
                : _buildDriversList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load drivers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadShopDrivers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This shop has no drivers linked yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        return _buildDriverCard(driver);
      },
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final subscriptionStatus =
        driver['subscription_status'] ?? 'Never Subscribed';

    // Handle contact_timeline which can be either a String or a Map
    final rawContactTimeline = driver['contact_timeline'];
    String contactTimelineDisplay;
    String? callTime;
    String? assignedTo;
    bool isContacted;

    if (rawContactTimeline is Map<String, dynamic>) {
      // It's an object with status, assigned_to, call_time
      final status = rawContactTimeline['status'] ?? 'Unknown';
      assignedTo = rawContactTimeline['assigned_to']?.toString();
      callTime = rawContactTimeline['call_time']?.toString();

      contactTimelineDisplay = status.toString();
      isContacted = !status.toString().toLowerCase().contains('not contacted');
    } else {
      // It's a String - show "Pending" instead of "Not Contacted"
      final rawStatus = rawContactTimeline?.toString() ?? 'Not Contacted';
      contactTimelineDisplay = rawStatus.toLowerCase().contains('not contacted')
          ? 'Pending'
          : rawStatus;
      isContacted = !rawStatus.toLowerCase().contains('not contacted');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF7B1FA2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'] ?? 'Unknown Driver',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D5F),
                      ),
                    ),
                    Text(
                      driver['unique_id'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSubscriptionBadge(subscriptionStatus),
            ],
          ),

          const SizedBox(height: 12),

          // Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.phone_rounded,
                  driver['mobile'] ?? 'N/A',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.location_on_rounded,
                  driver['state_name'] ?? 'N/A',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today_rounded,
                  _formatDate(driver['created_at']),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.account_balance_wallet_rounded,
                  '₹${driver['earning_per_user'] ?? 0}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Contact Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isContacted ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isContacted
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isContacted ? Icons.check_circle : Icons.schedule,
                      size: 18,
                      color: isContacted
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contactTimelineDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: isContacted
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show additional details if contacted
                if (isContacted &&
                    (assignedTo != null || callTime != null)) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        if (assignedTo != null && assignedTo.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Assigned to: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                assignedTo,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        if (callTime != null && callTime.isNotEmpty) ...[
                          if (assignedTo != null && assignedTo.isNotEmpty)
                            const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Last call: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _formatCallTime(callTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCallTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateStr);

      // Month names
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      // Format time as HH:MM AM/PM
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final timeStr =
          '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';

      // Format date as "DD MMM YYYY"
      final dateFormatted =
          '${date.day} ${months[date.month - 1]} ${date.year}';

      return '$dateFormatted at $timeStr';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBadge(String status) {
    Color color;
    String text;

    if (status.toLowerCase().contains('active')) {
      color = const Color(0xFF4CAF50);
      text = 'Active';
    } else if (status.toLowerCase().contains('expired')) {
      color = const Color(0xFFFF9800);
      text = 'Expired';
    } else {
      color = Colors.grey;
      text = 'No Plan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateStr);

      // Month names
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      // Format date as "DD MMM YYYY"
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
