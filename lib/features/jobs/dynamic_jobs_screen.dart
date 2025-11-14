import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../models/job_model.dart';
import 'widgets/modern_job_card.dart';

class DynamicJobsScreen extends StatefulWidget {
  final String initialFilter;
  final VoidCallback? onBackToDashboard;

  const DynamicJobsScreen(
      {super.key, this.initialFilter = 'all', this.onBackToDashboard});

  @override
  State<DynamicJobsScreen> createState() => _DynamicJobsScreenState();
}

class _DynamicJobsScreenState extends State<DynamicJobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<JobModel> _jobs = [];
  List<JobModel> _allJobs = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _error = '';
  String _currentFilter = 'all';

  final List<String> _filters = [
    'all',
    'approved',
    'active',
    'pending',
    'inactive',
    'expired',
    'closed'
  ];
  final List<String> _filterLabels = [
    'All',
    'Approved',
    'Active',
    'Pending',
    'Inactive',
    'Expired',
    'Closed'
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _searchController.addListener(_onSearchChanged);
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      // Search ALL jobs (including those assigned to others)
      final results = await Phase2ApiService.searchJobs(
          query: query, filter: _currentFilter);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        color: const Color(0xFF007BFF),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF007BFF),
            leading: IconButton(
              onPressed: widget.onBackToDashboard ?? () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
            ),
            title: const Text(
              'Job Postings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Text(
                    '${_jobs.length} Jobs',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipPath(
                clipper: CurvedHeaderClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF007BFF), Color(0xFF0056D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Job Postings',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildSearchBar(),
                            const SizedBox(height: 16),
                            _build3DNavigationTabs(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: _buildJobsList(),
          ),
        ],
        ),
      ),
    );
  }



  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search Job ID, TMID, Name, Location...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.grey.shade400, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : _isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _build3DNavigationTabs() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final label = _filterLabels[index];
          final isSelected = _currentFilter == filter;
          return GestureDetector(
            onTap: () => _onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? (filter == 'expired' 
                        ? const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFFFF5F8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ))
                    : null,
                color: isSelected 
                    ? null 
                    : (filter == 'expired' 
                        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: isSelected
                      ? (filter == 'expired' 
                          ? const Color(0xFFEF4444)
                          : Colors.white.withValues(alpha: 0.6))
                      : (filter == 'expired'
                          ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.3)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected 
                        ? (filter == 'expired' ? Colors.white : AppColors.primary)
                        : (filter == 'expired' ? const Color(0xFFEF4444) : Colors.white),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobsList() {
    if (_isLoading) {
      return SliverFillRemaining(
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error loading jobs',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadJobs,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_off_outlined,
                  size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No jobs found',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ModernJobCard(
            job: _jobs[index],
            isSearchResult: _searchController.text.isNotEmpty,
          ),
        ),
        childCount: _jobs.length,
      ),
    );
  }
}

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
