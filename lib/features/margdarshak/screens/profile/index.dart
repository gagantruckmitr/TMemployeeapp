import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/api_config.dart';
import '../../services/margdarshak_auth_service.dart';
import '../../services/margdarshak_api_service.dart';
import '../navigation/index.dart';
import '../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class MargdarshakProfilePage extends ConsumerStatefulWidget {
  const MargdarshakProfilePage({super.key});

  @override
  ConsumerState<MargdarshakProfilePage> createState() =>
      _MargdarshakProfilePageState();
}

class _MargdarshakProfilePageState
    extends ConsumerState<MargdarshakProfilePage> {
  final _authService = MargdarshakAuthService();
  final _apiService = MargdarshakApiService();

  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    // Load bank details
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch profile from API
      final response = await _apiService.getProfile();

      if (response['status'] == true && response['data'] != null) {
        final responseData = response['data'];
        // Handle both new structure (nested user/stats) and fallback
        final data = responseData['user'] != null
            ? responseData['user']
            : responseData;
        final stats = responseData['stats'];

        // Parse territory info
        final territoryInfo = data['territory_info']?.toString() ?? '';
        final districts = territoryInfo.isNotEmpty
            ? territoryInfo.split(',').map((e) => e.trim()).toList()
            : <String>[];

        setState(() {
          _profileData = {
            'name': data['name'] ?? 'Margdarshak',
            'email': data['email'] ?? 'Not provided',
            'mobile': data['mobile'] ?? 'N/A',
            'employeeId': data['employee_id'] ?? 'N/A',
            'role': data['role'] == 'field_agent'
                ? 'Field Agent'
                : 'Margdarshak',
            'territory': {
              'state':
                  data['state_name'] ?? data['working_state_name'] ?? 'N/A',
              'districts': districts,
            },
            'joinDate': data['join_date'] ?? 'N/A',
            'status': data['status'] ?? 'active',
            'profileImage': data['profile_image'],
            'bankDetails': {
              'accountHolderName': data['account_holder_name'],
              'accountNumber': data['account_number'],
              'ifscCode': data['ifsc_code'],
              'bankName': data['bank_name'],
              'upiId': data['upi_id'],
            },
            'stats': {
              'totalShops': stats?['total_shops'] ?? 0,
              'totalDrivers': stats?['total_drivers'] ?? 0,
              'totalEarnings': stats?['total_earnings'] ?? 0,
              'monthlyEarnings': stats?['monthly_earnings'] ?? 0,
              'activeDays': stats?['active_days'] ?? 0,
            },
          };
          _isLoading = false;
        });
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ Profile error: $e');

      // Fallback to auth service data
      final user = _authService.currentUser;

      if (mounted) {
        setState(() {
          _profileData = {
            'name': user?.name ?? 'Margdarshak',
            'email': user?.email ?? 'Not provided',
            'mobile': user?.mobile ?? 'N/A',
            'employeeId': user?.employeeId ?? 'N/A',
            'role': 'Field Agent',
            'territory': {
              'state': user?.stateName ?? 'N/A',
              'districts': <String>[],
            },
            'joinDate': user?.joinDate?.toString().split(' ')[0] ?? 'N/A',
            'status': user?.status ?? 'active',
            'profileImage': user?.profileImage,
            'bankDetails': {
              'accountHolderName': user?.accountHolderName,
              'accountNumber': user?.accountNumber,
              'ifscCode': user?.ifscCode,
              'bankName': user?.bankName,
              'upiId': user?.upiId,
            },
            'stats': {
              'totalShops': 0,
              'totalDrivers': 0,
              'totalEarnings': 0,
              'activeDays': 0,
            },
          };
          _errorMessage = 'Using offline data';
          _isLoading = false;
        });
      }
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
          // IconButton(
          //   onPressed: _navigateToEditProfile,
          //   icon: const Icon(Icons.edit_rounded, color: Color(0xFF2D2D5F)),
          //   tooltip: 'Edit Profile',
          // ),
          IconButton(
            onPressed: _loadProfileData,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D2D5F)),
            tooltip: 'Refresh',
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
                    // Error banner if any
                    if (_errorMessage != null) _buildErrorBanner(),

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

  Future<void> _navigateToEditProfile() async {
    if (_profileData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for profile to load'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profileData: _profileData),
      ),
    );

    // If profile was updated, reload
    if (result == true) {
      _loadProfileData();
    }
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

  Widget _buildProfileHeader() {
    final profileImage = _profileData['profileImage'];
    final hasProfileImage = profileImage != null && profileImage.isNotEmpty;
    final profileImageUrl = hasProfileImage
        ? '${ApiConfig.publicStorageBase}/$profileImage'
        : null;

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
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  image: hasProfileImage
                      ? DecorationImage(
                          image: NetworkImage(profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasProfileImage
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _navigateToEditProfile,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF5D4037),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
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
                  '${_profileData['employeeId'] ?? 'N/A'}',
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
                    'Monthly Earnings',
                    '₹${stats['monthlyEarnings'] ?? 0}',
                    Icons.attach_money_rounded,
                    const Color(0xFF00ACC1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Earnings',
                    '₹${stats['totalEarnings'] ?? 0}',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Days',
                    '${stats['activeDays'] ?? 0}',
                    Icons.calendar_today_rounded,
                    const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 12),
                const Spacer(),
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
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const BankDetailsScreen(),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text('Edit'),
                  // ),
                ],
              ),
              const SizedBox(height: 16),

              _buildInfoRow(
                'UPI ID',
                _profileData['bankDetails']?['upiId'] ?? 'Not set',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Account Number',
                _profileData['bankDetails']?['accountNumber'] ?? 'Not set',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Bank Name',
                _profileData['bankDetails']?['bankName'] ?? 'Not set',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'IFSC Code',
                _profileData['bankDetails']?['ifscCode'] ?? 'Not set',
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
                print(
                  'Calling MargdarshakAuthService.logout()...',
                ); // Debug log

                // Perform logout
                await _authService.logout();

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
