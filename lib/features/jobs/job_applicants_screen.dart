import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/driver_applicant_model.dart';
import '../../widgets/profile_completion_avatar.dart';
import 'match_making_screen.dart';
import '../calls/widgets/call_feedback_modal.dart';
import '../telecaller/widgets/call_type_selection_dialog.dart';
import '../telecaller/widgets/easygo_ivr_call_helper.dart';
import '../telecaller/widgets/manual_call_job_matching_helper.dart';
import 'driver_detailed_info_screen.dart';
import '../main_container.dart' as main;

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  List<DriverApplicant> _applicants = [];
  List<DriverApplicant> _filteredApplicants = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedFeedbackFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Job details for IVR call
  String _transporterTmid = '';
  String _transporterName = '';
  int _transporterUserId = 0;
  int _assignedTo = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadApplicants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sortApplicants() {
    _applicants.sort((a, b) {
      final aHasFeedback = a.callFeedback != null && a.callFeedback!.isNotEmpty;
      final bHasFeedback = b.callFeedback != null && b.callFeedback!.isNotEmpty;
      if (aHasFeedback && !bHasFeedback) return 1;
      if (!aHasFeedback && bHasFeedback) return -1;
      return b.appliedAt.compareTo(a.appliedAt);
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      var filtered = _applicants;
      if (_selectedFeedbackFilter != 'All') {
        if (_selectedFeedbackFilter == 'No Feedback') {
          filtered = filtered.where((driver) {
            return driver.callFeedback == null || driver.callFeedback!.isEmpty;
          }).toList();
        } else if (_selectedFeedbackFilter == 'Rejected') {
          // Filter by rejection status
          filtered = filtered.where((driver) {
            return driver.status.toLowerCase() == 'rejected';
          }).toList();
        } else {
          filtered = filtered.where((driver) {
            return driver.callFeedback?.toLowerCase() ==
                _selectedFeedbackFilter.toLowerCase();
          }).toList();
        }
      }
      if (query.isEmpty) {
        _filteredApplicants = filtered;
      } else {
        _filteredApplicants = filtered.where((driver) {
          return driver.name.toLowerCase().contains(query) ||
              driver.driverTmid.toLowerCase().contains(query) ||
              driver.city.toLowerCase().contains(query) ||
              driver.state.toLowerCase().contains(query) ||
              driver.vehicleType.toLowerCase().contains(query) ||
              driver.mobile.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // First, fetch job details to get transporter info
      final jobs = await Phase2ApiService.fetchJobs();
      final job = jobs.firstWhere(
        (j) => j.jobId == widget.jobId,
        orElse: () => jobs.first,
      );

      // Store transporter info for IVR calls
      _transporterTmid = job.transporterTmid;
      _transporterName = job.transporterName;
      _transporterUserId = int.tryParse(job.transporterId) ?? 0;
      _assignedTo = job.assignedTo ?? (await Phase2AuthService.getUserId());

      print('🔵 Job Details for IVR:');
      print('   Transporter TMID: $_transporterTmid');
      print('   Transporter Name: $_transporterName');
      print('   Transporter User ID: $_transporterUserId');
      print('   Assigned To: $_assignedTo');

      final applicants = await Phase2ApiService.fetchJobApplicants(
        widget.jobId,
      );
      setState(() {
        _applicants = applicants;
        _sortApplicants();
        _filteredApplicants = _applicants;
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

  Future<void> _addToBucket(DriverApplicant driver) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Bucket'),
        content: Text('Do you want to add ${driver.name} to the bucket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_assignedTo == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Job assigned user ID not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final currentUserId = await Phase2AuthService.getUserId();
      await Phase2ApiService.addToDriverBucket(
        userId: driver.driverId, // Driver's ID from the card
        uniqueId: driver.driverTmid,
        assignedTo: currentUserId, // Current logged-in user (telecaller)
        jobId: widget.jobId,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(
              '${driver.name} has been added to the bucket successfully.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Remove "Exception: " prefix for cleaner display
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        if (errorMessage.contains('already in the bucket')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Already Added'),
              content: Text('${driver.name} is already in the driver bucket.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage), // Show the clean message
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String? _getProfileImageUrl(String imagePath) {
    if (imagePath.isEmpty || imagePath.toLowerCase() == 'null') return null;
    try {
      final decoded = json.decode(imagePath);
      if (decoded is List && decoded.isNotEmpty) {
        imagePath = decoded[0].toString();
      }
    } catch (e) {
      // Not JSON
    }
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('/')) imagePath = imagePath.substring(1);
      return ApiConfig.getPublicUrl(imagePath);
    }
    return null;
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

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Pinned header
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: const Color(0xFFF2F2F7),
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                toolbarHeight: 56,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const main.MainContainer(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                        'Applicants',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Filter button
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedFeedbackFilter != 'All'
                                ? const Color(0xFF007AFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: _selectedFeedbackFilter != 'All'
                                ? Colors.white
                                : const Color(0xFF8E8E93),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Count + Match making
                      GestureDetector(
                        onTap: _applicants.isNotEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MatchMakingScreen(jobId: widget.jobId),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF007AFF,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_filteredApplicants.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.compare_arrows_rounded,
                                size: 14,
                                color: Color(0xFF007AFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFF2F2F7),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      if (_selectedFeedbackFilter != 'All') ...[
                        const SizedBox(height: 8),
                        _buildActiveFilterChip(),
                      ],
                    ],
                  ),
                ),
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: _loadApplicants,
            color: const Color(0xFF007AFF),
            backgroundColor: Colors.white,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1C1C1E),
          letterSpacing: -0.3,
        ),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFF8E8E93),
            letterSpacing: -0.3,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8, right: 4),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF8E8E93),
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E8E93).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onTap: () => HapticFeedback.selectionClick(),
      ),
    );
  }

  Widget _buildActiveFilterChip() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt, size: 13, color: Color(0xFF007AFF)),
              const SizedBox(width: 4),
              Text(
                _selectedFeedbackFilter,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedFeedbackFilter = 'All';
                    _onSearchChanged();
                  });
                },
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
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
                'Unable to Load',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Check your connection',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _loadApplicants();
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

    if (_applicants.isEmpty) {
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
                Icons.person_off_outlined,
                size: 36,
                color: Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Applicants Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredApplicants.isEmpty) {
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
                Icons.search_off_rounded,
                size: 36,
                color: Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try different search terms',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredApplicants.length,
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
                      (index / _filteredApplicants.length) * 0.4,
                      ((index / _filteredApplicants.length) * 0.4) + 0.6,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDriverCard(_filteredApplicants[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverCard(DriverApplicant driver) {
    final hasCallStatus =
        driver.callStatus != null &&
        driver.callStatus!.isNotEmpty &&
        driver.callStatus!.toLowerCase() != 'null';
    final hasFeedback =
        driver.callFeedback != null &&
        driver.callFeedback!.isNotEmpty &&
        driver.callFeedback!.toLowerCase() != 'null';
    final hasMatchStatus =
        driver.matchStatus != null &&
        driver.matchStatus!.isNotEmpty &&
        driver.matchStatus!.toLowerCase() != 'null';
    final isRejected = driver.status.toLowerCase() == 'rejected';

    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    int borderWidth = 1;

    // Rejected status takes priority
    if (isRejected) {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      borderWidth = 2;
    } else if (hasMatchStatus) {
      cardColor = _getMatchStatusColor(driver.matchStatus);
      borderColor = _getMatchStatusBorderColor(driver.matchStatus);
      borderWidth = 2;
    } else if (hasCallStatus) {
      // Use callStatus for color determination (connected, not_connected, callback_later)
      cardColor = _getCallStatusColor(driver.callStatus);
      borderColor = _getCallStatusBorderColor(driver.callStatus);
      borderWidth = 2;
    } else if (hasFeedback) {
      cardColor = _getFeedbackColor(driver.callFeedback);
      borderColor = _getFeedbackBorderColor(driver.callFeedback);
      borderWidth = 2;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth.toDouble()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show Rejected Badge at top if rejected
            if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'REJECTED',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Builder(
                  builder: (context) {
                    final imageUrl =
                        driver.profileImage != null &&
                            driver.profileImage!.isNotEmpty
                        ? _getProfileImageUrl(driver.profileImage!)
                        : null;
                    return ProfileCompletionAvatar(
                      name: driver.name,
                      userId: driver.driverId,
                      userType: 'driver',
                      size: 56,
                      completionPercentage: driver.profileCompletion,
                      profileImageUrl: imageUrl,
                      gender: driver.gender,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driver.city.isNotEmpty && driver.state.isNotEmpty
                            ? '${driver.city}, ${driver.state}'
                            : driver.city.isNotEmpty
                            ? driver.city
                            : driver.state,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: driver.driverTmid.isNotEmpty
                            ? () {
                                Clipboard.setData(
                                  ClipboardData(text: driver.driverTmid),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('TMID copied to clipboard'),
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              driver.driverTmid.isNotEmpty
                                  ? driver.driverTmid
                                  : 'No TMID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (driver.driverTmid.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _initiateCall(driver),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _addToBucket(driver),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      child: const Icon(
                        Icons.add_shopping_cart, // Bucket icon
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show Match Status if available
            if (driver.matchStatus != null &&
                driver.matchStatus!.isNotEmpty &&
                driver.matchStatus!.toLowerCase() != 'null') ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getMatchStatusBorderColor(
                    driver.matchStatus,
                  ).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMatchStatusIcon(driver.matchStatus),
                      size: 16,
                      color: _getMatchStatusTextColor(driver.matchStatus),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Match: ${_formatMatchStatus(driver.matchStatus)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getMatchStatusTextColor(driver.matchStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Show Call Logs Details if any call data is available
            if ((driver.callStatus != null && driver.callStatus!.isNotEmpty) ||
                (driver.callFeedback != null &&
                    driver.callFeedback!.isNotEmpty) ||
                (driver.callRemarks != null &&
                    driver.callRemarks!.isNotEmpty)) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getFeedbackBorderColor(
                    driver.callFeedback ?? driver.callStatus,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getFeedbackBorderColor(
                      driver.callFeedback ?? driver.callStatus,
                    ).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Call Logs title
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: _getFeedbackTextColor(
                            driver.callFeedback ?? driver.callStatus,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Call Logs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getFeedbackTextColor(
                              driver.callFeedback ?? driver.callStatus,
                            ),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Call Status Row
                    if (driver.callStatus != null &&
                        driver.callStatus!.isNotEmpty) ...[
                      _buildCallLogRow(
                        'Call Status',
                        _formatCallStatus(driver.callStatus),
                        _getCallStatusIcon(driver.callStatus),
                        _getCallStatusTextColor(driver.callStatus),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Call Feedback Row
                    if (driver.callFeedback != null &&
                        driver.callFeedback!.isNotEmpty) ...[
                      _buildCallLogRow(
                        'Feedback',
                        driver.callFeedback!,
                        Icons.feedback_outlined,
                        _getFeedbackTextColor(driver.callFeedback),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Call Remarks Row
                    if (driver.callRemarks != null &&
                        driver.callRemarks!.isNotEmpty) ...[
                      _buildCallLogRow(
                        'Remarks',
                        driver.callRemarks!,
                        Icons.note_outlined,
                        Colors.grey.shade700,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Vehicle',
              driver.vehicleType.isNotEmpty ? driver.vehicleType : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Experience',
              driver.drivingExperience.isNotEmpty
                  ? driver.drivingExperience
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'License',
              driver.licenseType.isNotEmpty ? driver.licenseType : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoItem('Applied', _formatDate(driver.appliedAt)),
            const SizedBox(height: 8),
            _buildInfoItem('Time', _formatTime(driver.appliedAt)),
            const SizedBox(height: 8),
            if (driver.subscriptionStartDate != null &&
                driver.subscriptionStartDate!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 75,
                    child: Text(
                      'Subscription:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDate(driver.subscriptionStartDate ?? ''),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (driver.subscriptionAmount != null &&
                      driver.subscriptionAmount!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '₹${driver.subscriptionAmount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (driver.feedbackNotes != null &&
                driver.feedbackNotes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.feedbackNotes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverDetailedInfoScreen(
                                driverId: driver.driverId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Jobs (${driver.totalJobsApplied})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _showRejectConfirmation(driver),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Colors.red.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Reject',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _addToBucket(driver),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.purple.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Bucket',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCallLogRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  DateTime _parseISTDateTime(String dateStr) {
    final cleanStr = dateStr.split('.')[0];
    final parts = cleanStr.split(' ');
    final dateParts = parts[0].split('-');
    final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0', '0'];
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
    return DateTime(year, month, day, hour, minute, second);
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';
    try {
      DateTime dt;
      if (date.contains('-')) {
        dt = _parseISTDateTime(date);
      } else if (date.contains('/')) {
        final parts = date.split(' ')[0].split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          var year = int.parse(parts[2]);
          if (year < 100) year += (year > 50) ? 1900 : 2000;
          dt = DateTime(year, month, day);
        } else {
          throw const FormatException('Invalid date format');
        }
      } else {
        dt = DateTime.parse(date);
      }
      var correctedYear = dt.year;
      if (dt.year < 2020) correctedYear = DateTime.now().year;
      return '${dt.day}/${dt.month}/$correctedYear';
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String date) {
    if (date.isEmpty) return 'N/A';
    try {
      DateTime dt;
      if (date.contains('-')) {
        dt = _parseISTDateTime(date);
      } else if (date.contains('/') && date.contains(' ')) {
        final parts = date.split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0].split('/');
          final timePart = parts[1].split(':');
          if (datePart.length == 3 && timePart.length >= 2) {
            final day = int.parse(datePart[0]);
            final month = int.parse(datePart[1]);
            var year = int.parse(datePart[2]);
            final hour = int.parse(timePart[0]);
            final minute = int.parse(timePart[1]);
            if (year < 100) year += (year > 50) ? 1900 : 2000;
            dt = DateTime(year, month, day, hour, minute);
          } else {
            throw const FormatException('Invalid datetime format');
          }
        } else {
          throw const FormatException('No time part found');
        }
      } else {
        dt = DateTime.parse(date);
      }
      final hour = dt.hour;
      final minute = dt.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final formattedMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$formattedMinute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getFeedbackColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.white;
    final feedbackLower = feedback.toLowerCase();

    // Check for category prefix first (most reliable)
    // IMPORTANT: Check "not connected" BEFORE "connected" because "not connected" contains "connected"
    if (feedbackLower.startsWith('not connected:') ||
        feedbackLower.contains('not connected:')) {
      return Colors.red.shade50;
    }
    if (feedbackLower.startsWith('connected:') ||
        feedbackLower.contains('connected:')) {
      return Colors.green.shade50;
    }
    if (feedbackLower.startsWith('call back later:') ||
        feedbackLower.contains('call back later:')) {
      return Colors.yellow.shade50;
    }

    // Fallback: Check for known option keywords
    // Not Connected options
    if (feedbackLower.contains('ringing') ||
        feedbackLower.contains('switched off') ||
        feedbackLower.contains('not reachable') ||
        feedbackLower.contains('call disconnected') ||
        feedbackLower.contains('number busy') ||
        feedbackLower.contains('wrong number') ||
        feedbackLower.contains('third person received')) {
      return Colors.red.shade50;
    }
    // Call Back Later options
    if (feedbackLower.contains('busy right now') ||
        feedbackLower.contains('call tomorrow morning') ||
        feedbackLower.contains('call in evening') ||
        feedbackLower.contains('call after 2 days')) {
      return Colors.yellow.shade50;
    }
    // Connected options (all driver-related feedback)
    if (feedbackLower.contains('driver interested') ||
        feedbackLower.contains('driver not interested') ||
        feedbackLower.contains('driver already booked') ||
        feedbackLower.contains('driver does not work on that route') ||
        feedbackLower.contains('driver rate mismatch') ||
        feedbackLower.contains('vehicle not available') ||
        feedbackLower.contains('vehicle type not matching') ||
        feedbackLower.contains('driver wants more details') ||
        feedbackLower.contains('driver wants to speak to transporter') ||
        feedbackLower.contains('driver wants call back later') ||
        feedbackLower.contains('driver requested callback on whatsapp') ||
        feedbackLower.contains('interview done')) {
      return Colors.green.shade50;
    }
    return Colors.grey.shade50;
  }

  Color _getFeedbackBorderColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.grey.shade200;
    final feedbackLower = feedback.toLowerCase();

    // Check for category prefix first
    // IMPORTANT: Check "not connected" BEFORE "connected"
    if (feedbackLower.startsWith('not connected:') ||
        feedbackLower.contains('not connected:')) {
      return Colors.red.shade300;
    }
    if (feedbackLower.startsWith('connected:') ||
        feedbackLower.contains('connected:')) {
      return Colors.green.shade300;
    }
    if (feedbackLower.startsWith('call back later:') ||
        feedbackLower.contains('call back later:')) {
      return Colors.yellow.shade600;
    }

    // Fallback: Check for known option keywords
    // Not Connected options
    if (feedbackLower.contains('ringing') ||
        feedbackLower.contains('switched off') ||
        feedbackLower.contains('not reachable') ||
        feedbackLower.contains('call disconnected') ||
        feedbackLower.contains('number busy') ||
        feedbackLower.contains('wrong number') ||
        feedbackLower.contains('third person received')) {
      return Colors.red.shade300;
    }
    // Call Back Later options
    if (feedbackLower.contains('busy right now') ||
        feedbackLower.contains('call tomorrow morning') ||
        feedbackLower.contains('call in evening') ||
        feedbackLower.contains('call after 2 days')) {
      return Colors.yellow.shade600;
    }
    // Connected options
    if (feedbackLower.contains('driver interested') ||
        feedbackLower.contains('driver not interested') ||
        feedbackLower.contains('driver already booked') ||
        feedbackLower.contains('driver does not work on that route') ||
        feedbackLower.contains('driver rate mismatch') ||
        feedbackLower.contains('vehicle not available') ||
        feedbackLower.contains('vehicle type not matching') ||
        feedbackLower.contains('driver wants more details') ||
        feedbackLower.contains('driver wants to speak to transporter') ||
        feedbackLower.contains('driver wants call back later') ||
        feedbackLower.contains('driver requested callback on whatsapp') ||
        feedbackLower.contains('interview done')) {
      return Colors.green.shade300;
    }
    return Colors.grey.shade300;
  }

  Color _getFeedbackTextColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.grey.shade600;
    final feedbackLower = feedback.toLowerCase();

    // Check for category prefix first
    // IMPORTANT: Check "not connected" BEFORE "connected"
    if (feedbackLower.startsWith('not connected:') ||
        feedbackLower.contains('not connected:')) {
      return Colors.red.shade700;
    }
    if (feedbackLower.startsWith('connected:') ||
        feedbackLower.contains('connected:')) {
      return Colors.green.shade700;
    }
    if (feedbackLower.startsWith('call back later:') ||
        feedbackLower.contains('call back later:')) {
      return Colors.yellow.shade800;
    }

    // Fallback: Check for known option keywords
    // Not Connected options
    if (feedbackLower.contains('ringing') ||
        feedbackLower.contains('switched off') ||
        feedbackLower.contains('not reachable') ||
        feedbackLower.contains('call disconnected') ||
        feedbackLower.contains('number busy') ||
        feedbackLower.contains('wrong number') ||
        feedbackLower.contains('third person received')) {
      return Colors.red.shade700;
    }
    // Call Back Later options
    if (feedbackLower.contains('busy right now') ||
        feedbackLower.contains('call tomorrow morning') ||
        feedbackLower.contains('call in evening') ||
        feedbackLower.contains('call after 2 days')) {
      return Colors.yellow.shade800;
    }
    // Connected options
    if (feedbackLower.contains('driver interested') ||
        feedbackLower.contains('driver not interested') ||
        feedbackLower.contains('driver already booked') ||
        feedbackLower.contains('driver does not work on that route') ||
        feedbackLower.contains('driver rate mismatch') ||
        feedbackLower.contains('vehicle not available') ||
        feedbackLower.contains('vehicle type not matching') ||
        feedbackLower.contains('driver wants more details') ||
        feedbackLower.contains('driver wants to speak to transporter') ||
        feedbackLower.contains('driver wants call back later') ||
        feedbackLower.contains('driver requested callback on whatsapp') ||
        feedbackLower.contains('interview done')) {
      return Colors.green.shade700;
    }
    return Colors.grey.shade700;
  }

  // New functions to use callStatus field directly for card colors
  Color _getCallStatusColor(String? callStatus) {
    if (callStatus == null || callStatus.isEmpty) return Colors.white;
    final statusLower = callStatus.toLowerCase();

    if (statusLower == 'connected') {
      return Colors.green.shade50;
    } else if (statusLower == 'not_connected' ||
        statusLower == 'not connected') {
      return Colors.red.shade50;
    } else if (statusLower == 'callback_later' ||
        statusLower == 'callback' ||
        statusLower == 'call back later') {
      return Colors.yellow.shade50;
    }
    return Colors.grey.shade50;
  }

  Color _getCallStatusBorderColor(String? callStatus) {
    if (callStatus == null || callStatus.isEmpty) return Colors.grey.shade200;
    final statusLower = callStatus.toLowerCase();

    if (statusLower == 'connected') {
      return Colors.green.shade300;
    } else if (statusLower == 'not_connected' ||
        statusLower == 'not connected') {
      return Colors.red.shade300;
    } else if (statusLower == 'callback_later' ||
        statusLower == 'callback' ||
        statusLower == 'call back later') {
      return Colors.yellow.shade600;
    }
    return Colors.grey.shade300;
  }

  Color _getMatchStatusColor(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Colors.white;
    final statusLower = matchStatus.toLowerCase();
    if (statusLower == 'selected' ||
        statusLower.contains('matchmaking done') ||
        statusLower.contains('match making done')) {
      return Colors.green.shade50;
    }
    if (statusLower == 'not selected' ||
        statusLower.contains('rejected') ||
        statusLower.contains('not interested')) {
      return Colors.red.shade50;
    }
    if (statusLower == 'pending' || statusLower.contains('in progress')) {
      return Colors.orange.shade50;
    }
    return Colors.grey.shade50;
  }

  Color _getMatchStatusBorderColor(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Colors.grey.shade200;
    final statusLower = matchStatus.toLowerCase();
    if (statusLower == 'selected' ||
        statusLower.contains('matchmaking done') ||
        statusLower.contains('match making done')) {
      return Colors.green.shade300;
    }
    if (statusLower == 'not selected' ||
        statusLower.contains('rejected') ||
        statusLower.contains('not interested')) {
      return Colors.red.shade300;
    }
    if (statusLower == 'pending' || statusLower.contains('in progress')) {
      return Colors.orange.shade300;
    }
    return Colors.grey.shade300;
  }

  Color _getMatchStatusTextColor(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Colors.grey.shade700;
    final statusLower = matchStatus.toLowerCase();
    if (statusLower == 'selected' ||
        statusLower.contains('matchmaking done') ||
        statusLower.contains('match making done')) {
      return Colors.green.shade700;
    }
    if (statusLower == 'not selected' ||
        statusLower.contains('rejected') ||
        statusLower.contains('not interested')) {
      return Colors.red.shade700;
    }
    if (statusLower == 'pending' || statusLower.contains('in progress')) {
      return Colors.orange.shade700;
    }
    return Colors.grey.shade700;
  }

  // Format match status for display
  String _formatMatchStatus(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return 'Unknown';
    final statusLower = matchStatus.toLowerCase();
    switch (statusLower) {
      case 'selected':
        return 'Selected';
      case 'not selected':
        return 'Not Selected';
      case 'pending':
        return 'Pending';
      default:
        return matchStatus;
    }
  }

  // Get icon for match status
  IconData _getMatchStatusIcon(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Icons.help_outline;
    final statusLower = matchStatus.toLowerCase();
    if (statusLower == 'selected' ||
        statusLower.contains('matchmaking done') ||
        statusLower.contains('match making done')) {
      return Icons.check_circle_outline;
    }
    if (statusLower == 'not selected' ||
        statusLower.contains('rejected') ||
        statusLower.contains('not interested')) {
      return Icons.cancel_outlined;
    }
    if (statusLower == 'pending' || statusLower.contains('in progress')) {
      return Icons.hourglass_empty;
    }
    return Icons.help_outline;
  }

  // Helper methods for call status display
  String _formatCallStatus(String? callStatus) {
    if (callStatus == null || callStatus.isEmpty) return 'Unknown';
    switch (callStatus.toLowerCase()) {
      case 'connected':
        return 'Connected';
      case 'not_connected':
        return 'Not Connected';
      case 'callback_later':
        return 'Call Back Later';
      default:
        return callStatus;
    }
  }

  IconData _getCallStatusIcon(String? callStatus) {
    if (callStatus == null || callStatus.isEmpty) return Icons.phone_outlined;
    switch (callStatus.toLowerCase()) {
      case 'connected':
        return Icons.check_circle_outline;
      case 'not_connected':
        return Icons.phone_disabled_outlined;
      case 'callback_later':
        return Icons.schedule_outlined;
      default:
        return Icons.phone_outlined;
    }
  }

  Color _getCallStatusTextColor(String? callStatus) {
    if (callStatus == null || callStatus.isEmpty) return Colors.grey.shade700;
    final statusLower = callStatus.toLowerCase();

    if (statusLower == 'connected') {
      return Colors.green.shade700;
    } else if (statusLower == 'not_connected' ||
        statusLower == 'not connected') {
      return Colors.red.shade700;
    } else if (statusLower == 'callback_later' ||
        statusLower == 'callback' ||
        statusLower == 'call back later') {
      return Colors.yellow.shade800;
    }
    return Colors.grey.shade700;
  }

  void _showFilterBottomSheet(BuildContext context) {
    final feedbackOptions = [
      'All',
      'No Feedback',
      'Rejected', // Added rejection filter
      'Driver Interested',
      'Driver Not Interested',
      'Driver Already Booked / Busy',
      'Driver Does Not Work on That Route',
      'Driver Rate Mismatch',
      'Vehicle Not Available',
      'Vehicle Type Not Matching',
      'Driver Wants More Details',
      'Driver Wants to Speak to Transporter',
      'Driver Wants Call Back Later',
      'Driver Requested Callback on WhatsApp',
      'Ringing – No Answer',
      'Switched Off',
      'Not Reachable',
      'Call Disconnected',
      'Number Busy',
      'Wrong Number',
      'Third Person Received – Asked to Call Later',
      'Busy Right Now',
      'Call Tomorrow Morning',
      'Call in Evening',
      'Call After 2 Days',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  if (_selectedFeedbackFilter != 'All')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFeedbackFilter = 'All';
                          _onSearchChanged();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: feedbackOptions.length,
                itemBuilder: (context, index) {
                  final option = feedbackOptions[index];
                  final isSelected = _selectedFeedbackFilter == option;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFeedbackFilter = option;
                        _onSearchChanged();
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF007AFF).withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF007AFF),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateCall(DriverApplicant driver) async {
    if (driver.mobile.isEmpty) return;

    try {
      final callType = await showDialog<String>(
        context: context,
        builder: (context) => CallTypeSelectionDialog(driverName: driver.name),
      );

      if (callType == null) return;

      final callerId = await Phase2AuthService.getUserId();

      if (callType == 'manual') {
        await _handleManualCall(driver, callerId);
      } else if (callType == 'easygo_ivr') {
        // Use job matching IVR API for job applicants
        // API: ${ApiConfig.ivrCallJobMatchingApi}
        await EasyGoIVRCallHelper.initiateCall(
          context: context,
          clientName: driver.name,
          clientPhone: driver.mobile,
          clientId: driver.driverId.toString(),
          tmid: driver.driverTmid,
          contactType: 'driver',
          callSource: 'job_applicants',
          // Pass job matching parameters
          transporterTmid: _transporterTmid,
          transporterName: _transporterName,
          transporterUserId: _transporterUserId,
          driverUserId: driver.driverId,
          jobId: widget.jobId,
          assignedTo: _assignedTo,
          onCallCompleted: (matchId) =>
              _showCallFeedbackModalWithMatchId(driver, matchId),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleManualCall(DriverApplicant driver, int callerId) async {
    // Use the new Laravel job matching manual call API
    await ManualCallJobMatchingHelper.initiateJobMatchingCall(
      context: context,
      uniqueIdTransporter: _transporterTmid,
      uniqueIdDriver: driver.driverTmid,
      userIdTransporter: _transporterUserId.toString(),
      userIdDriver: driver.driverId.toString(),
      jobId: widget.jobId,
      driverName: driver.name,
      transporterName: _transporterName,
      phoneNumber: driver.mobile,
      onCallInitiated: (id) {
        print('📞 Callback onCallInitiated triggered with ID: $id');
        // Show feedback modal after call is initiated
        if (mounted) {
          _showJobMatchingFeedbackModal(driver, id);
        }
      },
    );
  }

  // Show job matching feedback modal for manual calls
  // Uses the same CallFeedbackModal as IVR calls for consistency
  void _showJobMatchingFeedbackModal(DriverApplicant driver, int callId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: 'driver',
        userName: driver.name,
        userTmid: driver.driverTmid,
        jobId: widget.jobId,
        onSubmit: (feedback, matchStatus, notes) {
          // This is required but won't be called since we use onSubmitWithRecording
        },
        onSubmitWithRecording: (feedback, matchStatus, notes, recordingFile) async {
          try {
            // Extract call_status from feedback string
            String callStatus = 'not_connected'; // default

            // Check for category prefix in feedback
            // IMPORTANT: Check "Not Connected" BEFORE "Connected" because "not connected" contains "connected"
            if (feedback.startsWith('Not Connected:') ||
                feedback.toLowerCase().contains('not connected:')) {
              callStatus = 'not_connected';
            } else if (feedback.startsWith('Call Back Later:') ||
                feedback.toLowerCase().contains('call back later:')) {
              callStatus = 'callback_later';
            } else if (feedback.startsWith('Connected:') ||
                feedback.toLowerCase().contains('connected:')) {
              callStatus = 'connected';
            } else {
              // Fallback: check if feedback matches known options
              final connectedOptions = [
                'Driver Interested',
                'Driver Not Interested',
                'Driver Already Booked / Busy',
                'Driver Does Not Work on That Route',
                'Driver Rate Mismatch',
                'Vehicle Not Available',
                'Vehicle Type Not Matching',
                'Driver Wants More Details',
                'Driver Wants to Speak to Transporter',
                'Driver Wants Call Back Later',
                'Driver Requested Callback on WhatsApp',
                'Interview Done',
              ];
              final notConnectedOptions = [
                'Ringing – No Answer',
                'Switched Off',
                'Not Reachable',
                'Call Disconnected',
                'Number Busy',
                'Wrong Number',
                'Third Person Received – Asked to Call Later',
              ];
              final callBackOptions = [
                'Busy Right Now',
                'Call Tomorrow Morning',
                'Call in Evening',
                'Call After 2 Days',
              ];

              if (connectedOptions.any(
                (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
              )) {
                callStatus = 'connected';
              } else if (notConnectedOptions.any(
                (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
              )) {
                callStatus = 'not_connected';
              } else if (callBackOptions.any(
                (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
              )) {
                callStatus = 'callback_later';
              }
            }

            // Extract just the option name (e.g., "Driver Interested" from "Connected: Driver Interested")
            String callFeedback = feedback;
            if (feedback.contains(':')) {
              callFeedback = feedback.split(':').last.trim();
            }

            // Update the job matching call with feedback and recording
            await ManualCallJobMatchingHelper.updateJobMatchingCall(
              context: context,
              id: callId,
              callStatus: callStatus,
              callFeedback: callFeedback,
              callRemarks: notes,
              matchStatus: matchStatus,
              driverName: driver.name,
              transporterName: _transporterName,
              callRecording: recordingFile,
            );

            // Close modal
            if (mounted) {
              Navigator.of(context).pop();
            }

            // Refresh the applicants list
            _loadApplicants();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCallFeedbackModal(DriverApplicant driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: 'driver',
        userName: driver.name,
        userTmid: driver.driverTmid,
        jobId: widget.jobId,
        onSubmit: (feedback, matchStatus, notes) async {
          try {
            final callerId = await Phase2AuthService.getUserId();

            await Phase2ApiService.saveCallFeedback(
              callerId: callerId,
              driverTmid: driver.driverTmid.isNotEmpty
                  ? driver.driverTmid
                  : null,
              driverId: driver.driverId,
              driverName: driver.name,
              feedback: feedback,
              matchStatus: matchStatus,
              notes: notes,
              jobId: widget.jobId,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadApplicants();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Show feedback modal with match_id for job matching IVR calls
  // Uses API: ${ApiConfig.laravelApiBase}/ivr-call-update-jobMatching
  void _showCallFeedbackModalWithMatchId(
    DriverApplicant driver,
    String? matchId,
  ) {
    print('🔵 _showCallFeedbackModalWithMatchId called with matchId: $matchId');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: 'driver',
        userName: driver.name,
        userTmid: driver.driverTmid,
        jobId: widget.jobId,
        onSubmit: (feedback, matchStatus, notes) async {
          try {
            if (matchId != null && matchId.isNotEmpty) {
              // Use the job matching update API with correct field names
              print('🔵 Updating job matching call with matchId: $matchId');
              print('🔵 Feedback: $feedback');
              print('🔵 Match Status: $matchStatus');
              print('🔵 Notes: $notes');

              // Extract call_status from feedback string
              String callStatus = 'not_connected'; // default

              // Check for category prefix in feedback
              // IMPORTANT: Check "Not Connected" BEFORE "Connected" because "not connected" contains "connected"
              if (feedback.startsWith('Not Connected:') ||
                  feedback.toLowerCase().contains('not connected:')) {
                callStatus = 'not_connected';
              } else if (feedback.startsWith('Call Back Later:') ||
                  feedback.toLowerCase().contains('call back later:')) {
                callStatus = 'callback_later';
              } else if (feedback.startsWith('Connected:') ||
                  feedback.toLowerCase().contains('connected:')) {
                callStatus = 'connected';
              } else {
                // Fallback: check if feedback matches known options
                final connectedOptions = [
                  'Driver Interested',
                  'Driver Not Interested',
                  'Driver Already Booked / Busy',
                  'Driver Does Not Work on That Route',
                  'Driver Rate Mismatch',
                  'Vehicle Not Available',
                  'Vehicle Type Not Matching',
                  'Driver Wants More Details',
                  'Driver Wants to Speak to Transporter',
                  'Driver Wants Call Back Later',
                  'Driver Requested Callback on WhatsApp',
                  'Interview Done',
                ];
                final notConnectedOptions = [
                  'Ringing – No Answer',
                  'Switched Off',
                  'Not Reachable',
                  'Call Disconnected',
                  'Number Busy',
                  'Wrong Number',
                  'Third Person Received – Asked to Call Later',
                ];
                final callBackOptions = [
                  'Busy Right Now',
                  'Call Tomorrow Morning',
                  'Call in Evening',
                  'Call After 2 Days',
                ];

                if (connectedOptions.any(
                  (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
                )) {
                  callStatus = 'connected';
                } else if (notConnectedOptions.any(
                  (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
                )) {
                  callStatus = 'not_connected';
                } else if (callBackOptions.any(
                  (opt) => feedback.toLowerCase().contains(opt.toLowerCase()),
                )) {
                  callStatus = 'callback_later';
                }
              }

              // Extract just the option name (e.g., "Driver Interested" from "Connected: Driver Interested")
              String callFeedback = feedback;
              if (feedback.contains(':')) {
                callFeedback = feedback.split(':').last.trim();
              }

              print('🔵 Extracted call_status: $callStatus');
              print('🔵 Extracted call_feedback: $callFeedback');

              await Phase2ApiService.updateIVRCallJobMatchingFeedback(
                matchId: matchId,
                callStatus: callStatus,
                callFeedback: callFeedback,
                callRemarks: notes,
                matchStatus: matchStatus,
              );
            } else {
              // Fallback to regular feedback save
              print('⚠️ No matchId, using regular feedback save');
              final callerId = await Phase2AuthService.getUserId();
              await Phase2ApiService.saveCallFeedback(
                callerId: callerId,
                driverTmid: driver.driverTmid.isNotEmpty
                    ? driver.driverTmid
                    : null,
                driverId: driver.driverId,
                driverName: driver.name,
                feedback: feedback,
                matchStatus: matchStatus,
                notes: notes,
                jobId: widget.jobId,
              );
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadApplicants();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRejectConfirmation(DriverApplicant driver) {
    // Extract numeric job ID from widget.jobId (e.g., "TMJB00593" -> 593)
    int numericJobId = 0;
    String jobIdStr = widget.jobId;
    if (jobIdStr.startsWith('TMJB')) {
      final numStr = jobIdStr
          .replaceFirst('TMJB', '')
          .replaceFirst(RegExp(r'^0+'), '');
      numericJobId = int.tryParse(numStr) ?? 0;
    } else {
      numericJobId = int.tryParse(jobIdStr) ?? 0;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reject Applicant',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to reject ${driver.name}\'s application?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final callerId = await Phase2AuthService.getUserId();

                print('🔴 Rejection params:');
                print('   driver_id: ${driver.driverId}');
                print('   job_id: $numericJobId');
                print('   contractor_id (transporter): $_transporterUserId');
                print('   assigned_id: $callerId');

                await Phase2ApiService.rejectJobApplicant(
                  callerId: callerId,
                  driverId: driver.driverId,
                  jobId: numericJobId,
                  driverTmid: driver.driverTmid,
                  jobIdString: widget.jobId,
                  contractorId:
                      _transporterUserId, // transporter_id from job data
                  reason: 'Rejected from applicants screen',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Applicant rejected successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadApplicants();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ApplicantSkeletonCard(delay: index * 80),
        );
      },
    );
  }
}

// Skeleton Card for Applicants
class _ApplicantSkeletonCard extends StatefulWidget {
  final int delay;

  const _ApplicantSkeletonCard({this.delay = 0});

  @override
  State<_ApplicantSkeletonCard> createState() => _ApplicantSkeletonCardState();
}

class _ApplicantSkeletonCardState extends State<_ApplicantSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar skeleton
                  _buildShimmerCircle(size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmer(width: 120, height: 15),
                        const SizedBox(height: 6),
                        _buildShimmer(width: 90, height: 12),
                        const SizedBox(height: 6),
                        _buildShimmer(width: 70, height: 12),
                      ],
                    ),
                  ),
                  _buildShimmer(width: 35, height: 35, borderRadius: 10),
                ],
              ),
              const SizedBox(height: 12),
              // Info chips row
              Row(
                children: [
                  _buildShimmer(width: 80, height: 24, borderRadius: 8),
                  const SizedBox(width: 8),
                  _buildShimmer(width: 100, height: 24, borderRadius: 8),
                  const Spacer(),
                  _buildShimmer(width: 60, height: 24, borderRadius: 8),
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
