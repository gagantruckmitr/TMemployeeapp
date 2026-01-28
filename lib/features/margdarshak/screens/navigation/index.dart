import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/index.dart';
import '../territory/index.dart';
import '../shops/index.dart';
import '../drivers/index.dart';
import '../earnings/index.dart';
import '../profile/index.dart';

// Global key for navigation - use this to call switchToTab from anywhere
final GlobalKey<MargdarshakNavigationContainerState> margdarshakNavigationKey =
    GlobalKey<MargdarshakNavigationContainerState>();

class MargdarshakNavigationContainer extends StatefulWidget {
  MargdarshakNavigationContainer({Key? key})
    : super(key: key ?? margdarshakNavigationKey);

  @override
  MargdarshakNavigationContainerState createState() =>
      MargdarshakNavigationContainerState();
}

class MargdarshakNavigationContainerState
    extends State<MargdarshakNavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MargdarshakDashboardPage(),
    const MargdarshakTerritoryPage(),
    const MargdarshakShopsPage(),
    const MargdarshakDriversPage(),
    const MargdarshakEarningsPage(),
    const MargdarshakProfilePage(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      activeColor: Color(0xFF2E7D32),
    ),
    NavigationItem(
      icon: Icons.map_rounded,
      label: 'Territory',
      activeColor: Color(0xFF1976D2),
    ),
    NavigationItem(
      icon: Icons.store_rounded,
      label: 'Shops',
      activeColor: Color(0xFFE65100),
    ),
    NavigationItem(
      icon: Icons.people_rounded,
      label: 'Drivers',
      activeColor: Color(0xFF7B1FA2),
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Earnings',
      activeColor: Color(0xFF388E3C),
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      activeColor: Color(0xFF5D4037),
    ),
  ];

  void switchToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    switchToTab(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? item.activeColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            color: isActive
                                ? item.activeColor
                                : Colors.grey.shade600,
                            size: isActive ? 24 : 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isActive
                                ? item.activeColor
                                : Colors.grey.shade600,
                            fontSize: isActive ? 10 : 9,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
