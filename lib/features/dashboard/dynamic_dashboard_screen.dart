import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/job_model.dart';
import '../../models/phase2_user_model.dart';
import '../jobs/dynamic_jobs_screen.dart';

import '../calls/call_history_hub_screen.dart';
import '../analytics/call_analytics_screen.dart';
import '../telecaller/screens/dynamic_profile_screen.dart';
import 'widgets/activity_feed_item.dart';
import 'widgets/job_card.dart';
import '../../widgets/coming_soon_screen.dart';

class DynamicDashboardScreen extends StatefulWidget {
  const DynamicDashboardScreen({super.key});

  @override
  State<DynamicDashboardScreen> createState() => _DynamicDashboardScreenState();
}

class _DynamicDashboardScreenState extends State<DynamicDashboardScreen> {
  DashboardStats? _stats;
  List<JobModel> _recentJobs = [];
  List<RecentActivity> _recentActivities = [];
  Phase2User? _currentUser;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Load current user
      final user = await Phase2AuthService.getCurrentUser();

      // Load stats first (required)
      final stats = await Phase2ApiService.fetchDashboardStats();

      // Load jobs and activities (optional - don't fail if these error)
      List<JobModel> jobs = [];
      List<RecentActivity> activities = [];

      try {
        jobs = await Phase2ApiService.fetchJobs(filter: 'all');
        // Filter to only show approved and active jobs
        jobs = jobs
            .where((job) => job.isApproved == true && job.isActive == true)
            .toList();
      } catch (e) {
        debugPrint('Error loading jobs: $e');
      }

      try {
        activities = await Phase2ApiService.fetchRecentActivities(limit: 10);
      } catch (e) {
        debugPrint('Error loading activities: $e');
      }

      setState(() {
        _currentUser = user;
        _stats = stats;
        _recentJobs = jobs.take(5).toList();
        _recentActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser?.name ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Subtle shadow
        shadowColor: Colors.black.withValues(alpha: 0.05),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hi ${userName.split(' ').first}!',
              style: const TextStyle(
                color: Color(0xFF1A1F3A), // Dark blue
                fontSize: 24,
                fontWeight: FontWeight.w600, // Semi-bold
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getGreeting(),
              style: const TextStyle(
                color: Color(0xFF6B7280), // Grey
                fontSize: 14,
                fontWeight: FontWeight.w400, // Regular
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell icon
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF6B7280),
              size: 24,
            ),
            onPressed: () {
              // Add notification functionality here
            },
          ),
          const SizedBox(width: 8),
          // Profile circle avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DynamicProfileScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 22, // 44dp diameter
                backgroundColor: const Color(0xFF5B86E5), // Accent blue
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? const MatchMakingComingSoon()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 100,
                      top: 16,
                    ),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildKPISection(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        _buildCallButton(),
                        const SizedBox(height: 24),
                        _buildRecentJobsSection(),
                        const SizedBox(height: 24),
                        _buildRecentActivitySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD), // Light background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB), // Light grey border
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Search icon
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280), // Grey
            size: 20,
          ),
          const SizedBox(width: 12),

          // Search text field
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search jobs, drivers, transporters...',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF), // Light grey
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                // Navigate to search screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DynamicJobsScreen(initialFilter: 'all'),
                  ),
                );
              },
              readOnly: true,
            ),
          ),

          const SizedBox(width: 12),

          // Filter button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Light grey
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF6B7280), // Grey
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Job Status Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildKPICard(
                'Total Jobs',
                _stats!.totalJobs.toString(),
                Icons.work_outline_rounded,
                const Color(0xFF6366F1), // Indigo
                const Color(0xFFEEF2FF), // Indigo light
                () => _navigateToJobs('all'),
              ),
              const SizedBox(width: 8),
              _buildKPICard(
                'Approved',
                _stats!.approvedJobs.toString(),
                Icons.check_circle_outline_rounded,
                const Color(0xFF10B981), // Green
                const Color(0xFFECFDF5), // Green light
                () => _navigateToJobs('approved'),
              ),
              const SizedBox(width: 8),
              _buildKPICard(
                'Pending',
                _stats!.pendingJobs.toString(),
                Icons.schedule_rounded,
                const Color(0xFFF59E0B), // Amber
                const Color(0xFFFEF3C7), // Amber light
                () => _navigateToJobs('pending'),
              ),
              const SizedBox(width: 8),
              _buildKPICard(
                'Inactive',
                _stats!.inactiveJobs.toString(),
                Icons.pause_circle_outline_rounded,
                const Color(0xFF6B7280), // Grey
                const Color(0xFFF3F4F6), // Grey light
                () => _navigateToJobs('inactive'),
              ),
              const SizedBox(width: 8),
              _buildKPICard(
                'Expired',
                _stats!.expiredJobs.toString(),
                Icons.cancel_outlined,
                const Color(0xFFEF4444), // Red
                const Color(0xFFFEE2E2), // Red light
                () => _navigateToJobs('expired'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color iconBackground,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 7),

            // Number
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),

            // Label
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Call History',
            Icons.history,
            const Color(0xFF3B82F6),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CallHistoryHubScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Analytics',
            Icons.analytics,
            const Color(0xFF8B5CF6),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CallAnalyticsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color iconColor, VoidCallback onTap) {
    // Determine background color based on icon color
    final Color iconBackground = iconColor == const Color(0xFF3B82F6)
        ? const Color(0xFFDBEAFE) // Blue light for Call History
        : const Color(0xFFF3E8FF); // Purple light for Analytics

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular icon background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1F3A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton() {
    return Center(
      child: GestureDetector(
        onTap: () => _navigateToJobs('all'),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.65,
          height: MediaQuery.of(context).size.width * 0.65,
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A2472), // dark navy blue
                Color(0xFF1E40AF), // rich blue tone
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated circles background
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start Calling',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Connect with Jobs',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentJobsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Approved Jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentJobs.isEmpty)
          const Center(child: Text('No jobs available'))
        else
          ..._recentJobs.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _showJobDetailsModal(context, job),
                  child: JobCard(
                    job: {
                      'jobId': job.jobId,
                      'from': job.jobLocation.split('→').first.trim(),
                      'to': job.jobLocation.contains('→')
                          ? job.jobLocation.split('→').last.trim()
                          : '',
                      'truckType': job.vehicleType,
                      'load': job.requiredExperience,
                      'payRate': job.salaryRange,
                      'applicants': job.applicantsCount,
                      'status': job.isActive ? 'Active' : 'Inactive',
                    },
                    transporterName: job.transporterName,
                    transporterPhone: job.transporterPhone,
                  ),
                ),
              )),
      ],
    );
  }

  void _showJobDetailsModal(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobId,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: job.isActive ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Job Information', [
                      _buildDetailRow('Job ID', job.jobId),
                      _buildDetailRow('Job Title', job.jobTitle),
                      _buildDetailRow('Location', job.jobLocation),
                      _buildDetailRow('Description', job.jobDescription),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Requirements', [
                      _buildDetailRow('Vehicle Type', job.vehicleType),
                      _buildDetailRow('Vehicle Detail', job.vehicleTypeDetail),
                      _buildDetailRow('License Type', job.typeOfLicense),
                      _buildDetailRow('Experience', job.requiredExperience),
                      _buildDetailRow(
                          'Drivers Required', '${job.numberOfDriverRequired}'),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Compensation', [
                      _buildDetailRow('Salary Range', job.salaryRange),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Transporter Details', [
                      _buildDetailRow('Name', job.transporterName),
                      _buildDetailRow('TMID', job.transporterTmid),
                      _buildDetailRow('Phone', job.transporterPhone),
                      _buildDetailRow('Location',
                          '${job.transporterCity}, ${job.transporterState}'),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Application Info', [
                      _buildDetailRow('Applicants', '${job.applicantsCount}'),
                      _buildDetailRow(
                          'Active Positions', '${job.activePosition}'),
                      _buildDetailRow('Deadline', job.applicationDeadline),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.softGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentActivities.isEmpty)
          const Center(child: Text('No recent activities'))
        else
          ..._recentActivities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActivityFeedItem(
                  activity: {
                    'type': activity.type,
                    'name': activity.name,
                    'tmid': activity.tmid,
                    'activity': activity.activity,
                    'time': activity.time,
                    'city': activity.city,
                  },
                ),
              )),
      ],
    );
  }

  void _navigateToJobs(String filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicJobsScreen(initialFilter: filter),
      ),
    );
  }
}