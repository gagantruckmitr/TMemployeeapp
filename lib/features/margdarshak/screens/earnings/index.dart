import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/index.dart';

class MargdarshakEarningsPage extends ConsumerStatefulWidget {
  const MargdarshakEarningsPage({super.key});

  @override
  ConsumerState<MargdarshakEarningsPage> createState() =>
      _MargdarshakEarningsPageState();
}

class _MargdarshakEarningsPageState
    extends ConsumerState<MargdarshakEarningsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _earningsData = {};

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _earningsData = {
          'summary': {
            'totalEarnings': 2340,
            'eligibleEarnings': 1890,
            'pendingVerification': 450,
            'paidEarnings': 1440,
            'thisMonth': 780,
            'thisWeek': 120,
            'today': 30,
          },
          'eligibleDrivers': 189,
          'totalDrivers': 234,
          'earningsPerDriver': 10,
          'payoutThreshold': 500,
          'nextPayoutDate': '2024-02-01',
          'recentEarnings': [
            {
              'driverName': 'Rajesh Kumar',
              'shopName': 'Sharma Dhaba',
              'amount': 10,
              'date': '2024-01-25',
              'status': 'eligible',
            },
            {
              'driverName': 'Suresh Patel',
              'shopName': 'Highway Dhaba',
              'amount': 10,
              'date': '2024-01-24',
              'status': 'eligible',
            },
            {
              'driverName': 'Amit Singh',
              'shopName': 'Quick Fix Puncture',
              'amount': 10,
              'date': '2024-01-23',
              'status': 'pending',
            },
          ],
          'payoutHistory': [
            {
              'id': 'PO001',
              'amount': 500,
              'date': '2024-01-15',
              'status': 'paid',
              'method': 'UPI',
              'transactionId': 'TXN123456789',
            },
            {
              'id': 'PO002',
              'amount': 450,
              'date': '2024-01-01',
              'status': 'paid',
              'method': 'Bank Transfer',
              'transactionId': 'TXN987654321',
            },
          ],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Earnings',
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
              _showEarningsRules();
            },
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF2D2D5F),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Overview
                    _buildEarningsOverview(),

                    const SizedBox(height: 24),

                    // Stats Grid
                    _buildStatsGrid(),

                    const SizedBox(height: 24),

                    // Payout Section
                    _buildPayoutSection(),

                    const SizedBox(height: 24),

                    // Recent Earnings
                    _buildRecentEarnings(),

                    const SizedBox(height: 24),

                    // Payout History
                    _buildPayoutHistory(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEarningsOverview() {
    final summary = _earningsData['summary'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF388E3C).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      'This Month',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹${summary['thisMonth'] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Today: ₹${summary['today'] ?? 0}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Text(
                'This Week: ₹${summary['thisWeek'] ?? 0}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsGrid() {
    final summary = _earningsData['summary'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Eligible Earnings',
                '₹${summary['eligibleEarnings'] ?? 0}',
                Icons.check_circle_rounded,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending Verification',
                '₹${summary['pendingVerification'] ?? 0}',
                Icons.pending_rounded,
                const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Paid Earnings',
                '₹${summary['paidEarnings'] ?? 0}',
                Icons.payment_rounded,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Eligible Drivers',
                '${_earningsData['eligibleDrivers'] ?? 0}/${_earningsData['totalDrivers'] ?? 0}',
                Icons.people_rounded,
                const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0);
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

  Widget _buildPayoutSection() {
    final summary = _earningsData['summary'] ?? {};
    final eligibleAmount = summary['eligibleEarnings'] ?? 0;
    final threshold = _earningsData['payoutThreshold'] ?? 500;

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
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payout Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D5F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Payouts are processed automatically by admin',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Eligible Amount: ₹$eligibleAmount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D5F),
                    ),
                  ),
                  Text(
                    'Threshold: ₹$threshold',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (eligibleAmount / threshold).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  eligibleAmount >= threshold
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                ),
              ),
            ],
          ),

          if (_earningsData['nextPayoutDate'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Scheduled Payout',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D5F),
                          ),
                        ),
                        Text(
                          _earningsData['nextPayoutDate'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecentEarnings() {
    final recentEarnings = _earningsData['recentEarnings'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Earnings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: recentEarnings.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent earnings',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: recentEarnings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final earning = entry.value;
                    final isLast = index == recentEarnings.length - 1;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF388E3C,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF388E3C),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  earning['driverName'] ?? 'Unknown Driver',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D2D5F),
                                  ),
                                ),
                                Text(
                                  'via ${earning['shopName'] ?? 'Unknown Shop'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  earning['date'] ?? 'Unknown Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${earning['amount'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEarningStatusColor(
                                    earning['status'],
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  earning['status'] ?? 'unknown',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getEarningStatusColor(
                                      earning['status'],
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPayoutHistory() {
    final payoutHistory = _earningsData['payoutHistory'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payout History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: payoutHistory.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No payout history',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: payoutHistory.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payout = entry.value;
                    final isLast = index == payoutHistory.length - 1;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2196F3,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payment_rounded,
                              color: Color(0xFF2196F3),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payout ${payout['id'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D2D5F),
                                  ),
                                ),
                                Text(
                                  '${payout['method'] ?? 'Unknown Method'} • ${payout['date'] ?? 'Unknown Date'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (payout['transactionId'] != null)
                                  Text(
                                    'TXN: ${payout['transactionId']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${payout['amount'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payout['status'] ?? 'unknown',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 800.ms).slideY(begin: 0.2, end: 0);
  }

  Color _getEarningStatusColor(String? status) {
    switch (status) {
      case 'eligible':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'paid':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  void _showEarningsRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EarningsRulesModal(),
    );
  }
}

class EarningsRulesModal extends StatelessWidget {
  const EarningsRulesModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Earnings Rules',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D5F),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRuleSection('Earning Rate', [
                    '₹10 per driver added through shops linked to you',
                    'Earnings are calculated automatically when drivers are onboarded',
                  ]),

                  const SizedBox(height: 24),

                  _buildRuleSection('Eligibility Conditions', [
                    'Driver must be unique (not a duplicate)',
                    'Driver must complete basic profile/KYC',
                    'Driver must be added via shops in your territory',
                    'Shop must be approved and active',
                  ]),

                  const SizedBox(height: 24),

                  _buildRuleSection('Payout Process', [
                    'Minimum payout threshold: ₹500',
                    'Payouts processed automatically by admin',
                    'Payouts scheduled twice a month (1st and 15th)',
                    'Earnings verified before payout approval',
                    'Payment sent to registered bank account/UPI',
                  ]),

                  const SizedBox(height: 24),

                  _buildRuleSection('Payment Methods', [
                    'UPI (Instant transfer)',
                    'Bank transfer (1-2 business days)',
                    'Update payment details in profile settings',
                    'Ensure bank details are correct to avoid delays',
                  ]),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Note: Payouts are processed automatically by admin. You cannot request payouts manually.',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(String title, List<String> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        const SizedBox(height: 12),
        ...rules
            .map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF388E3C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
