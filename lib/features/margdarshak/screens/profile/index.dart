import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/real_auth_service.dart';
import '../navigation/index.dart';
import '../../providers/profile_provider.dart';
import '../bank-details/index.dart';

class MargdarshakProfilePage extends ConsumerStatefulWidget {
  const MargdarshakProfilePage({super.key});

  @override
  ConsumerState<MargdarshakProfilePage> createState() =>
      _MargdarshakProfilePageState();
}

class _MargdarshakProfilePageState
    extends ConsumerState<MargdarshakProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    // Load bank details
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final user = RealAuthService.instance.currentUser;

      // Simulate API call for additional profile data
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _profileData = {
          'name': user?.name ?? 'Margdarshak',
          'email': user?.email ?? 'margdarshak@truckmitr.com',
          'mobile': user?.mobile ?? '+91 98765 43210',
          'employeeId': user?.id ?? 'MG001',
          'role': 'Field Agent',
          'territory': {
            'state': 'Maharashtra',
            'districts': ['Pune', 'Mumbai', 'Nashik'],
          },
          'joinDate': '2024-01-01',
          'stats': {
            'totalShops': 45,
            'totalDrivers': 234,
            'totalEarnings': 2340,
            'activeDays': 25,
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
              _showEditProfileModal();
            },
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF2D2D5F)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),

                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsCards(),

                    const SizedBox(height: 24),

                    // Territory Info
                    _buildTerritoryInfo(),

                    const SizedBox(height: 24),

                    // Personal Information
                    _buildPersonalInfo(),

                    const SizedBox(height: 24),

                    // Payment Details
                    _buildPaymentDetails(),

                    const SizedBox(height: 24),

                    // Settings & Actions
                    _buildSettingsActions(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileData['name'] ?? 'Margdarshak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profileData['role'] ?? 'Field Agent',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_profileData['employeeId'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsCards() {
    final stats = _profileData['stats'] ?? {};

    return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Shops',
                    '${stats['totalShops'] ?? 0}',
                    Icons.store_rounded,
                    const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Drivers',
                    '${stats['totalDrivers'] ?? 0}',
                    Icons.people_rounded,
                    const Color(0xFF7B1FA2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Earnings',
                    '₹${stats['totalEarnings'] ?? 0}',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF388E3C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Days',
                    '${stats['activeDays'] ?? 0}',
                    Icons.calendar_today_rounded,
                    const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
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
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D5F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTerritoryInfo() {
    final territory = _profileData['territory'] ?? {};
    final districts = territory['districts'] as List? ?? [];

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                    'Territory Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D5F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildInfoRow('State', territory['state'] ?? 'N/A'),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Districts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: districts
                        .map(
                          (district) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1976D2,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              district.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPersonalInfo() {
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF7B1FA2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D5F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildInfoRow('Full Name', _profileData['name'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Email', _profileData['email'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Mobile', _profileData['mobile'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Employee ID', _profileData['employeeId'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Join Date', _profileData['joinDate'] ?? 'N/A'),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPaymentDetails() {
    final bankDetails = ref.watch(profileProvider).bankDetails;

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                      color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Color(0xFF388E3C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D5F),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BankDetailsScreen(),
                        ),
                      );
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildInfoRow(
                'UPI ID',
                bankDetails.upiId.isEmpty ? 'Not set' : bankDetails.upiId,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Account Number',
                bankDetails.accountNumber.isEmpty
                    ? 'Not set'
                    : bankDetails.accountNumber,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Bank Name',
                bankDetails.bankName.isEmpty ? 'Not set' : bankDetails.bankName,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'IFSC Code',
                bankDetails.ifscCode.isEmpty ? 'Not set' : bankDetails.ifscCode,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSettingsActions() {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActionTile(
                'Notification Settings',
                Icons.notifications_outlined,
                const Color(0xFFFF9800),
                () {
                  // Handle notification settings
                },
              ),
              _buildActionTile(
                'Help & Support',
                Icons.help_outline_rounded,
                const Color(0xFF4CAF50),
                () {
                  // Handle help & support
                },
              ),
              _buildActionTile(
                'Logout',
                Icons.logout_rounded,
                const Color(0xFFF44336),
                () {
                  print('Logout button tapped'); // Debug log
                  HapticFeedback.mediumImpact(); // Haptic feedback
                  _showLogoutConfirmation();
                },
                isLast: true,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 1000.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D2D5F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D2D5F),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileModal() {
    // Implement edit profile modal
  }

  void _showLogoutConfirmation() {
    print('_showLogoutConfirmation called'); // Debug log
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('Logout cancelled'); // Debug log
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              print('Logout confirmed, starting process...'); // Debug log
              
              // Close the dialog first
              Navigator.pop(dialogContext);
              
              // Show loading indicator
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const AlertDialog(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Logging out...'),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                print('Calling RealAuthService.logout()...'); // Debug log
                
                // Perform logout
                await RealAuthService.instance.logout();
                
                print('Logout successful, navigating to login...'); // Debug log
                
                // Close loading dialog and navigate to login
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  
                  // Navigate to login page and clear all routes
                  context.goNamed('margdarshak-login');
                }
              } catch (e) {
                print('Logout error: $e'); // Debug log
                
                // Close loading dialog and show error
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () => _showLogoutConfirmation(),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
