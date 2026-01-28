import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../add_shop/index.dart';
import '../navigation/index.dart';

class MargdarshakShopsPage extends StatefulWidget {
  const MargdarshakShopsPage({super.key});

  @override
  State<MargdarshakShopsPage> createState() => _MargdarshakShopsPageState();
}

class _MargdarshakShopsPageState extends State<MargdarshakShopsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _shops = [
          {
            'id': '1',
            'name': 'Sharma Dhaba',
            'type': 'dhaba',
            'owner': 'Rajesh Sharma',
            'mobile': '+91 98765 43210',
            'address': 'NH-48, Pune-Mumbai Highway',
            'district': 'Pune',
            'status': 'approved',
            'driversCount': 23,
            'addedDate': '2024-01-15',
            'source': 'manual',
          },
          {
            'id': '2',
            'name': 'Quick Fix Puncture',
            'type': 'puncture',
            'owner': 'Amit Kumar',
            'mobile': '+91 87654 32109',
            'address': 'Katraj, Pune',
            'district': 'Pune',
            'status': 'pending',
            'driversCount': 0,
            'addedDate': '2024-01-20',
            'source': 'manual',
          },
          {
            'id': '3',
            'name': 'Highway Dhaba',
            'type': 'dhaba',
            'owner': 'Suresh Patel',
            'mobile': '+91 76543 21098',
            'address': 'Mumbai-Nashik Highway',
            'district': 'Mumbai',
            'status': 'approved',
            'driversCount': 45,
            'addedDate': '2024-01-10',
            'source': 'auto',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredShops {
    switch (_selectedFilter) {
      case 'dhaba':
        return _shops.where((shop) => shop['type'] == 'dhaba').toList();
      case 'puncture':
        return _shops.where((shop) => shop['type'] == 'puncture').toList();
      case 'pending':
        return _shops.where((shop) => shop['status'] == 'pending').toList();
      default:
        return _shops;
    }
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
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending'),
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

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int tabIndex) {
    // Use the global key to access the navigation container
    final navigationState = margdarshakNavigationKey.currentState;
    if (navigationState != null) {
      navigationState.switchToTab(tabIndex);
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
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
    final isPending = shop['status'] == 'pending';
    final isDhaba = shop['type'] == 'dhaba';

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPending
                  ? Colors.orange.shade200
                  : isApproved
                  ? Colors.green.shade200
                  : Colors.grey.shade200,
              width: 1,
            ),
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
                  _buildStatusBadge(shop['status']),
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

              // Address
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
                        shop['address'] ?? 'No address provided',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isApproved) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // View drivers
                        },
                        icon: const Icon(
                          Icons.people_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('View Drivers'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7B1FA2),
                          side: const BorderSide(color: Color(0xFF7B1FA2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Edit shop
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: index * 100),
        )
        .slideX(begin: 0.2, end: 0);
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
}
