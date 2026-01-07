import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../core/services/real_auth_service.dart';
import '../../models/job_model.dart';
import '../../models/phase2_user_model.dart';
import '../jobs/dynamic_jobs_screen.dart';
import '../calls/call_history_hub_screen.dart';
import '../analytics/analytics_screen.dart';
import '../telecaller/screens/dynamic_profile_screen.dart';
import '../drivers/driver_bucket_screen.dart';
import 'widgets/activity_feed_item.dart';
import 'widgets/job_card.dart';
import '../../widgets/coming_soon_screen.dart';

class DynamicDashboardScreen extends StatefulWidget {
  const DynamicDashboardScreen({super.key});

  @override
  State<DynamicDashboardScreen> createState() => _DynamicDashboardScreenState();
}

class _DynamicDashboardScreenState extends State<DynamicDashboardScreen> {
  List<JobModel> _allJobs = [];
  List<JobModel> _recentJobs = [];
  List<RecentActivity> _recentActivities = [];
  Phase2User? _currentUser;
  bool _isLoading = true;
  String _error = '';

  // Calculated KPI stats from jobs - matches Phase2ApiService.fetchJobs filter logic exactly
  int get _totalJobs => _allJobs.length;
  int get _approvedJobs => _allJobs
      .where((job) => job.isApproved && !job.isExpiredByDeadline)
      .length;
  int get _pendingJobs => _allJobs
      .where((job) => !job.isApproved && !job.isExpiredByDeadline)
      .length;
  int get _expiredJobs =>
      _allJobs.where((job) => job.isExpiredByDeadline).length;
  int get _closedJobs => _allJobs.where((job) => job.isClosed).length;

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
      final user = await Phase2AuthService.getCurrentUser();
      List<JobModel> allJobs = [];
      List<RecentActivity> activities = [];

      try {
        allJobs = await Phase2ApiService.fetchJobs(filter: 'all');
      } catch (e) {
        debugPrint('Error loading jobs: $e');
      }

      final recentJobs = allJobs
          .where(
            (job) =>
                job.isApproved == true &&
                job.isActive == true &&
                !job.isExpiredByDeadline,
          )
          .toList();

      try {
        activities = await Phase2ApiService.fetchRecentActivities(limit: 10);
      } catch (e) {
        debugPrint('Error loading activities: $e');
      }

      setState(() {
        _currentUser = user;
        _allJobs = allJobs;
        _recentJobs = recentJobs.take(5).toList();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? _buildSkeletonLoading()
            : _error.isNotEmpty
            ? const MatchMakingComingSoon()
            : RefreshIndicator.adaptive(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildAppleAppBar(userName),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          _buildKPISection(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          _buildJobMatchingCard(),
                          const SizedBox(height: 28),
                          _buildRecentJobsSection(),
                          const SizedBox(height: 28),
                          _buildRecentActivitySection(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppleAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 28),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi ${userName.split(' ').first}!',
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _getGreeting(),
              style: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground],
      ),
      actions: [
        // Notification button - Apple style
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 251, 251, 251),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF000000),
                size: 22,
              ),
            ),
            onPressed: () {},
          ),
        ),
        // Profile avatar
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DynamicProfileScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            child: _buildProfileAvatar(userName),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildProfileAvatar(String userName) {
    final user = RealAuthService.instance.currentUser;
    final photoUrl = user?.photoUrl;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                placeholder: (context, url) =>
                    _buildAvatarPlaceholder(userName),
                errorWidget: (context, url, error) =>
                    _buildAvatarPlaceholder(userName),
              )
            : _buildAvatarPlaceholder(userName),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String userName) {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DynamicJobsScreen(initialFilter: 'all'),
          ),
        );
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Colors.black.withOpacity(0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search jobs, drivers, transporters...',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: Colors.black.withOpacity(0.5),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Status Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            children: [
              _buildAppleKPICard(
                'Total Jobs',
                _totalJobs.toString(),
                Icons.work_rounded,
                const Color(0xFF007AFF), // Apple Blue
                () => _navigateToJobs('all'),
              ),
              const SizedBox(width: 10),
              _buildAppleKPICard(
                'Approved',
                _approvedJobs.toString(),
                Icons.check_circle_rounded,
                const Color(0xFF34C759), // Apple Green
                () => _navigateToJobs('approved'),
              ),
              const SizedBox(width: 10),
              _buildAppleKPICard(
                'Pending',
                _pendingJobs.toString(),
                Icons.schedule_rounded,
                const Color(0xFFFF9500), // Apple Orange
                () => _navigateToJobs('pending'),
              ),
              const SizedBox(width: 10),
              _buildAppleKPICard(
                'Expired',
                _expiredJobs.toString(),
                Icons.timer_off_rounded,
                const Color(0xFFFF3B30), // Apple Red
                () => _navigateToJobs('expired'),
              ),
              const SizedBox(width: 10),
              _buildAppleKPICard(
                'Closed',
                _closedJobs.toString(),
                Icons.lock_rounded,
                const Color(0xFF8E8E93), // Apple Gray
                () => _navigateToJobs('closed'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppleKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.5),
              ),
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
          child: _buildAppleActionCard(
            'Call History',
            Icons.history_rounded,
            const Color(0xFF007AFF),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CallHistoryHubScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAppleActionCard(
            'Driver Bucket',
            Icons.people_alt_rounded,
            const Color(0xFF34C759),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverBucketScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAppleActionCard(
            'Analytics',
            Icons.analytics_rounded,
            const Color(0xFFAF52DE), // Apple Purple
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppleActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
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

  Widget _buildJobMatchingCard() {
    return GestureDetector(
      onTap: () => _navigateToJobs('all'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Matching',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start automated IVR call sequence for your next best lead.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildCallButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.25),
        ),
        child: const Center(
          child: Icon(
            Icons.phone_in_talk_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Approved Jobs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToJobs('approved'),
              child: Text(
                'See All',
                style: TextStyle(
                  color: const Color(0xFF007AFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentJobs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.work_off_rounded,
                    size: 48,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No jobs available',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentJobs.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _showJobDetailsModal(context, job),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
              ),
            ),
          ),
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
          color: Color(0xFFF2F2F7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar - Apple style
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF000000),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: job.isActive
                                ? const Color(0xFF34C759).withOpacity(0.15)
                                : Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            job.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: job.isActive
                                  ? const Color(0xFF34C759)
                                  : Colors.black.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppleDetailSection('Job Information', [
                      _buildAppleDetailRow('Job ID', job.jobId),
                      _buildAppleDetailRow('Job Title', job.jobTitle),
                      _buildAppleDetailRow('Location', job.jobLocation),
                      _buildAppleDetailRow('Description', job.jobDescription),
                    ]),
                    const SizedBox(height: 20),
                    _buildAppleDetailSection('Requirements', [
                      _buildAppleDetailRow('Vehicle Type', job.vehicleType),
                      _buildAppleDetailRow(
                        'Vehicle Detail',
                        job.vehicleTypeDetail,
                      ),
                      _buildAppleDetailRow('License Type', job.typeOfLicense),
                      _buildAppleDetailRow(
                        'Experience',
                        job.requiredExperience,
                      ),
                      _buildAppleDetailRow(
                        'Drivers Required',
                        '${job.numberOfDriverRequired}',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildAppleDetailSection('Compensation', [
                      _buildAppleDetailRow('Salary Range', job.salaryRange),
                    ]),
                    const SizedBox(height: 20),
                    _buildAppleDetailSection('Transporter Details', [
                      _buildAppleDetailRow('Name', job.transporterName),
                      _buildAppleDetailRow('TMID', job.transporterTmid),
                      _buildAppleDetailRow('Phone', job.transporterPhone),
                      _buildAppleDetailRow(
                        'Location',
                        '${job.transporterCity}, ${job.transporterState}',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildAppleDetailSection('Application Info', [
                      _buildAppleDetailRow(
                        'Applicants',
                        '${job.applicantsCount}',
                      ),
                      _buildAppleDetailRow(
                        'Active Positions',
                        '${job.activePosition}',
                      ),
                      _buildAppleDetailRow('Deadline', job.applicationDeadline),
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

  Widget _buildAppleDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAppleDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF000000),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activities',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _recentActivities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
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
                    ),
                    if (index < _recentActivities.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.black.withOpacity(0.06),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
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

  Widget _buildSkeletonLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ShimmerBox(width: 120, height: 24),
                    const SizedBox(height: 6),
                    const _ShimmerBox(width: 90, height: 14),
                  ],
                ),
                const Spacer(),
                const _ShimmerCircle(size: 40),
              ],
            ),
            const SizedBox(height: 24),
            // Search bar skeleton
            const _ShimmerBox(
              width: double.infinity,
              height: 50,
              borderRadius: 12,
            ),
            const SizedBox(height: 24),
            // KPI section skeleton
            const _ShimmerBox(width: 150, height: 20),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: _ShimmerBox(
                      width: 95,
                      height: 100,
                      borderRadius: 14,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // Quick actions skeleton
            const Row(
              children: [
                Expanded(
                  child: _ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Job matching card skeleton
            const _ShimmerBox(
              width: double.infinity,
              height: 140,
              borderRadius: 20,
            ),
            const SizedBox(height: 28),
            // Recent jobs section skeleton
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(width: 160, height: 22),
                _ShimmerBox(width: 60, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _DashboardSkeletonJobCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer box widget
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF8F8F8),
                Color(0xFFEEEEEE),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Shimmer circle widget
class _ShimmerCircle extends StatefulWidget {
  final double size;

  const _ShimmerCircle({required this.size});

  @override
  State<_ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<_ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF8F8F8),
                Color(0xFFEEEEEE),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Skeleton Job Card for Dashboard
class _DashboardSkeletonJobCard extends StatefulWidget {
  const _DashboardSkeletonJobCard();

  @override
  State<_DashboardSkeletonJobCard> createState() =>
      _DashboardSkeletonJobCardState();
}

class _DashboardSkeletonJobCardState extends State<_DashboardSkeletonJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildShimmer(width: 80, height: 14),
                  const Spacer(),
                  _buildShimmer(width: 60, height: 22, borderRadius: 6),
                ],
              ),
              const SizedBox(height: 12),
              _buildShimmer(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildShimmerCircle(size: 14),
                  const SizedBox(width: 6),
                  _buildShimmer(width: 100, height: 12),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildShimmer(width: 70, height: 24, borderRadius: 6),
                  const SizedBox(width: 8),
                  _buildShimmer(width: 80, height: 24, borderRadius: 6),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmer({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFEEEEEE),
            Color(0xFFF8F8F8),
            Color(0xFFEEEEEE),
          ],
          stops: [
            (_animation.value - 1).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 1).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFEEEEEE),
            Color(0xFFF8F8F8),
            Color(0xFFEEEEEE),
          ],
          stops: [
            (_animation.value - 1).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 1).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
