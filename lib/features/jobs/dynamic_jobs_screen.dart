import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/job_model.dart';
import 'widgets/modern_job_card.dart';

class DynamicJobsScreen extends StatefulWidget {
  final String initialFilter;
  final VoidCallback? onBackToDashboard;

  const DynamicJobsScreen({
    super.key,
    this.initialFilter = 'all',
    this.onBackToDashboard,
  });

  @override
  State<DynamicJobsScreen> createState() => _DynamicJobsScreenState();
}

class _DynamicJobsScreenState extends State<DynamicJobsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<JobModel> _jobs = [];
  List<JobModel> _allJobs = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _error = '';
  int? _currentUserId;
  String _currentFilter = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = [
    'all',
    'approved',
    'pending',
    'expired',
    'closed',
  ];
  final List<String> _filterLabels = [
    'Total Jobs',
    'Approved',
    'Pending',
    'Expired',
    'Closed',
  ];

  final List<IconData> _filterIcons = [
    Icons.work_rounded,
    Icons.check_circle_rounded,
    Icons.schedule_rounded,
    Icons.timer_off_rounded,
    Icons.lock_rounded,
  ];
  
  final List<Color> _filterColors = [
    const Color(0xFF007AFF), // Apple Blue
    const Color(0xFF34C759), // Apple Green
    const Color(0xFFFF9500), // Apple Orange
    const Color(0xFFFF3B30), // Apple Red
    const Color(0xFF8E8E93), // Apple Gray
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _searchController.addListener(_onSearchChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadCurrentUser();
    _loadJobs();
  }

  Future<void> _loadCurrentUser() async {
    final user = await Phase2AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _jobs = _allJobs;
        _isSearching = false;
      });
    } else {
      _performSearch(_searchController.text);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await Phase2ApiService.searchJobs(
        query: query,
        filter: _currentFilter,
      );
      setState(() {
        _jobs = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _searchController.clear();
    });
    try {
      final jobs = await Phase2ApiService.fetchJobs(filter: _currentFilter);
      setState(() {
        _jobs = jobs;
        _allJobs = jobs;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _currentFilter = filter);
    _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Pinned header with back button and title (always visible)
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 56,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap:
                          widget.onBackToDashboard ??
                          () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF007AFF),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Job Matching',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF000000),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.work_rounded,
                            size: 14,
                            color: Color(0xFF007AFF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_jobs.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Search bar (scrolls away)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildSearchBar(),
              ),
            ),
            // Pinned filter bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterBarDelegate(
                child: Container(
                  color: Colors.white,
                  child: _buildFilterBar(),
                ),
              ),
            ),
          ];
        },
        body: _buildJobsList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF000000),
          letterSpacing: -0.3,
        ),
        decoration: InputDecoration(
          hintText: 'Search jobs...',
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.black.withOpacity(0.4),
            letterSpacing: -0.3,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.search_rounded,
              color: Colors.black.withOpacity(0.4),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 28),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                )
              : _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onTap: () => HapticFeedback.selectionClick(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final label = _filterLabels[index];
          final icon = _filterIcons[index];
          final filterColor = _filterColors[index];
          final isSelected = _currentFilter == filter;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _onFilterChanged(filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? filterColor : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? filterColor : const Color(0xFFE8E8E8),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon, 
                    size: 14, 
                    color: isSelected ? Colors.white : filterColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black.withOpacity(0.7),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobsList() {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 30,
                  color: Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No job is Assigned to you',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ask Admin',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _loadJobs();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 36,
                color: Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Jobs Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / _jobs.length) * 0.4,
                      ((index / _jobs.length) * 0.4) + 0.6,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModernJobCard(
                job: _jobs[index],
                isSearchResult: _searchController.text.isNotEmpty,
                currentUserId: _currentUserId,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SkeletonJobCard(delay: index * 100),
        );
      },
    );
  }
}

// Delegate for pinned filter bar
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterBarDelegate({required this.child});

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

// Skeleton Job Card with shimmer effect
class _SkeletonJobCard extends StatefulWidget {
  final int delay;
  
  const _SkeletonJobCard({this.delay = 0});

  @override
  State<_SkeletonJobCard> createState() => _SkeletonJobCardState();
}

class _SkeletonJobCardState extends State<_SkeletonJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
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
              // Header row
              Row(
                children: [
                  _buildShimmerBox(width: 80, height: 14),
                  const Spacer(),
                  _buildShimmerBox(width: 60, height: 22, borderRadius: 6),
                ],
              ),
              const SizedBox(height: 14),
              // Title
              _buildShimmerBox(width: double.infinity, height: 18),
              const SizedBox(height: 10),
              // Location row
              Row(
                children: [
                  _buildShimmerCircle(size: 16),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 120, height: 14),
                ],
              ),
              const SizedBox(height: 14),
              // Info chips row
              Row(
                children: [
                  _buildShimmerBox(width: 70, height: 26, borderRadius: 8),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 90, height: 26, borderRadius: 8),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 60, height: 26, borderRadius: 8),
                ],
              ),
              const SizedBox(height: 14),
              // Bottom row
              Row(
                children: [
                  _buildShimmerCircle(size: 32),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 100, height: 12),
                      const SizedBox(height: 4),
                      _buildShimmerBox(width: 70, height: 10),
                    ],
                  ),
                  const Spacer(),
                  _buildShimmerBox(width: 36, height: 36, borderRadius: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
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
            Color(0xFFF5F5F5),
            Color(0xFFEEEEEE),
          ],
          stops: [
            (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
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
            Color(0xFFF5F5F5),
            Color(0xFFEEEEEE),
          ],
          stops: [
            (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
