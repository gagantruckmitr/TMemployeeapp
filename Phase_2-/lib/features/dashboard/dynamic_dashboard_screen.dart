import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/job_model.dart';
import '../../models/phase2_user_model.dart';
import '../jobs/dynamic_jobs_screen.dart';
import '../applications/applications_screen.dart';
import '../calls/call_history_hub_screen.dart';
import '../analytics/call_analytics_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/activity_feed_item.dart';
import 'widgets/job_card.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: CustomScrollView(
                      slivers: [
                        _buildAppBar(),
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
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
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApplicationsScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.assignment, color: Colors.white),
        label: const Text(
          'Applications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final userName = _currentUser?.name ?? 'User';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 2,
      toolbarHeight: 60,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          onPressed: _loadDashboardData,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search jobs, drivers, transporters...',
          hintStyle:
              TextStyle(color: AppColors.softGray.withValues(alpha: 0.6)),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: 22),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.primary, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onTap: () {
          // Navigate to search screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DynamicJobsScreen(initialFilter: 'all'),
            ),
          );
        },
        readOnly: true,
      ),
    );
  }

  Widget _buildKPISection() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Status Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildKPICard(
                'Total Jobs',
                _stats!.totalJobs.toString(),
                Icons.work,
                const Color(0xFF2563EB),
                () => _navigateToJobs('all'),
              ),
              const SizedBox(width: 12),
              _buildKPICard(
                'Approved Jobs',
                _stats!.approvedJobs.toString(),
                Icons.check_circle,
                const Color(0xFF10B981),
                () => _navigateToJobs('approved'),
              ),
              const SizedBox(width: 12),
              _buildKPICard(
                'Pending Jobs',
                _stats!.pendingJobs.toString(),
                Icons.schedule,
                const Color(0xFFF59E0B),
                () => _navigateToJobs('pending'),
              ),
              const SizedBox(width: 12),
              _buildKPICard(
                'Inactive Jobs',
                _stats!.inactiveJobs.toString(),
                Icons.pause_circle,
                const Color(0xFF6B7280),
                () => _navigateToJobs('inactive'),
              ),
              const SizedBox(width: 12),
              _buildKPICard(
                'Expired Jobs',
                _stats!.expiredJobs.toString(),
                Icons.cancel,
                const Color(0xFFEF4444),
                () => _navigateToJobs('expired'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
              textAlign: TextAlign.center,
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
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
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
              'Recent Jobs',
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
              )),
      ],
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
