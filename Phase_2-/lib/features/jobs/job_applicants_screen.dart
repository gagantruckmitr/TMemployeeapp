import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/driver_applicant_model.dart';
import '../../widgets/profile_completion_avatar.dart';
import 'match_making_screen.dart';
import '../calls/widgets/call_feedback_modal.dart';
import '../main_container.dart' as main;

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen(
      {super.key, required this.jobId, required this.jobTitle});

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  List<DriverApplicant> _applicants = [];
  List<DriverApplicant> _filteredApplicants = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadApplicants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortApplicants() {
    _applicants.sort((a, b) {
      // Sort by feedback status: no feedback first, then feedback submitted
      final aHasFeedback = a.callFeedback != null && a.callFeedback!.isNotEmpty;
      final bHasFeedback = b.callFeedback != null && b.callFeedback!.isNotEmpty;

      if (aHasFeedback && !bHasFeedback) return 1; // a goes to bottom
      if (!aHasFeedback && bHasFeedback) return -1; // b goes to bottom

      // If both have same feedback status, sort by applied date (newest first)
      return b.appliedAt.compareTo(a.appliedAt);
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredApplicants = _applicants;
      } else {
        _filteredApplicants = _applicants.where((driver) {
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
      final applicants =
          await Phase2ApiService.fetchJobApplicants(widget.jobId);
      setState(() {
        _applicants = applicants;
        _sortApplicants();
        _filteredApplicants = _applicants;
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
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF007BFF),
              leading: IconButton(
                onPressed: () {
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
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
              ),
              title: const Text(
                'Job Applicants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_applicants.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.compare_arrows_rounded,
                              color: Colors.white, size: 16),
                        ],
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
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 80, 16, 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Search applicants...',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  prefixIcon: Icon(Icons.search_rounded,
                                      color: AppColors.primary, size: 22),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear_rounded,
                                              color: Colors.grey.shade600,
                                              size: 20),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
              Text('Error loading applicants',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadApplicants,
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
    if (_applicants.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined,
                  size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No applicants yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    if (_filteredApplicants.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No results found',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text('Try different search terms',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final isLast = index == _filteredApplicants.length - 1;
          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              bottom: isLast ? 24 : 12,
            ),
            child: _buildDriverCard(_filteredApplicants[index]),
          );
        },
        childCount: _filteredApplicants.length,
      ),
    );
  }

  Widget _buildDriverCard(DriverApplicant driver) {
    final hasFeedback =
        driver.callFeedback != null && driver.callFeedback!.isNotEmpty;
    final hasMatchStatus =
        driver.matchStatus != null && driver.matchStatus!.isNotEmpty;

    // Determine card color based on match status first, then feedback
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    int borderWidth = 1;

    if (hasMatchStatus) {
      cardColor = _getMatchStatusColor(driver.matchStatus);
      borderColor = _getMatchStatusBorderColor(driver.matchStatus);
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
            Row(
              children: [
                ProfileCompletionAvatar(
                  name: driver.name,
                  userId: driver.driverId,
                  userType: 'driver',
                  size: 56,
                  completionPercentage: driver.profileCompletion,
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
                        '${driver.city}, ${driver.state}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () async {
                      await _makePhoneCall(driver.mobile);
                      _showCallFeedbackModal(driver);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child:
                          const Icon(Icons.call, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show match status first (higher priority)
            if (driver.matchStatus != null &&
                driver.matchStatus!.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getMatchStatusBorderColor(driver.matchStatus)
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 16,
                      color: _getMatchStatusTextColor(driver.matchStatus),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: ${driver.matchStatus}',
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
              const SizedBox(height: 12),
            ] else if (driver.callFeedback != null &&
                driver.callFeedback!.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getFeedbackBorderColor(driver.callFeedback)
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 16,
                      color: _getFeedbackTextColor(driver.callFeedback),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: ${driver.callFeedback}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getFeedbackTextColor(driver.callFeedback),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _buildInfoItem('Vehicle',
                driver.vehicleType.isNotEmpty ? driver.vehicleType : 'N/A'),
            const SizedBox(height: 8),
            _buildInfoItem(
                'Experience',
                driver.drivingExperience.isNotEmpty
                    ? driver.drivingExperience
                    : 'N/A'),
            const SizedBox(height: 8),
            _buildInfoItem('License',
                driver.licenseType.isNotEmpty ? driver.licenseType : 'N/A'),
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
                    width: 80,
                    child: Text(
                      'Subscription:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDate(driver.subscriptionStartDate ?? ''),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (driver.subscriptionAmount != null &&
                      driver.subscriptionAmount!.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        '₹${driver.subscriptionAmount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDriverDetails(context, driver),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Profile',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
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

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';

    try {
      DateTime dt;

      // Try different parsing approaches
      if (date.contains('-')) {
        // Handle YYYY-MM-DD or YYYY-MM-DD HH:MM:SS format
        dt = DateTime.parse(date);
      } else if (date.contains('/')) {
        // Handle DD/MM/YYYY format
        final parts =
            date.split(' ')[0].split('/'); // Take only date part if datetime
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          var year = int.parse(parts[2]);

          // Fix 2-digit year to 4-digit year
          if (year < 100) {
            if (year > 50) {
              year += 1900; // 51-99 -> 1951-1999
            } else {
              year += 2000; // 00-50 -> 2000-2050
            }
          }

          dt = DateTime(year, month, day);
        } else {
          throw FormatException('Invalid date format');
        }
      } else {
        // Try parsing as-is
        dt = DateTime.parse(date);
      }

      // Ensure datetime is reasonable (not in future, not too old)
      final now = DateTime.now();
      final currentYear = now.year;

      // Log if datetime is in future but display the actual database date
      if (dt.isAfter(now)) {
        print('ℹ️ Database contains future date: $dt (displaying original)');
        // Keep and display the original database date
      }

      var correctedYear = dt.year;

      // Only correct year if it's unreasonably old (before 2020)
      // Current year (2025) and future years are now valid
      if (dt.year < 2020) {
        // If year is too old (before 2020), use current year
        correctedYear = currentYear;
        print('⚠️ Old year detected: ${dt.year}, corrected to: $correctedYear');
      }

      return '${dt.day}/${dt.month}/$correctedYear';
    } catch (e) {
      // Last resort: try to extract numbers and format them
      try {
        final numbers =
            RegExp(r'\d+').allMatches(date).map((m) => m.group(0)!).toList();
        if (numbers.length >= 3) {
          var day = int.parse(numbers[0]);
          var month = int.parse(numbers[1]);
          var year = int.parse(numbers[2]);

          // Fix 2-digit year
          if (year < 100) {
            if (year > 50) {
              year += 1900;
            } else {
              year += 2000;
            }
          }

          // Only fix unreasonably old years (before 2020)
          if (year < 2020) {
            year = DateTime.now().year;
          }

          // Ensure valid day/month
          if (day > 31) day = 1;
          if (month > 12) month = 1;

          return '$day/$month/$year';
        }

        return date; // Return original if can't parse
      } catch (e2) {
        return date; // Return original if all parsing fails
      }
    }
  }

  String _formatTime(String date) {
    if (date.isEmpty) return 'N/A';

    // Debug: Show original database time
    print('📅 Original database time: $date');

    try {
      DateTime dt;

      // Try parsing the full datetime string
      if (date.contains('-')) {
        dt = DateTime.parse(date);
      } else if (date.contains('/') && date.contains(' ')) {
        // Handle DD/MM/YYYY HH:MM:SS format
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

            // Fix 2-digit year
            if (year < 100) {
              year += (year > 50) ? 1900 : 2000;
            }

            dt = DateTime(year, month, day, hour, minute);
          } else {
            throw FormatException('Invalid datetime format');
          }
        } else {
          throw FormatException('No time part found');
        }
      } else {
        dt = DateTime.parse(date);
      }

      // Log if datetime is in the future but keep the original time from database
      final now = DateTime.now();

      if (dt.isAfter(now)) {
        print(
            'ℹ️ Database contains future datetime: $dt, current: $now (keeping original)');
        // Keep the original database time - don't modify it
      }

      // Format time as HH:MM AM/PM
      final hour = dt.hour;
      final minute = dt.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final formattedMinute = minute.toString().padLeft(2, '0');

      return '$displayHour:$formattedMinute $period';
    } catch (e) {
      // Try to extract time manually
      try {
        final timeRegex = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');
        final match = timeRegex.firstMatch(date);

        if (match != null) {
          final hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);

          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          final formattedMinute = minute.toString().padLeft(2, '0');

          return '$displayHour:$formattedMinute $period';
        }

        return 'N/A';
      } catch (e2) {
        return 'N/A';
      }
    }
  }

  Color _getFeedbackColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.white;

    switch (feedback.toLowerCase()) {
      // Green - Connected/Interview related
      case 'interview done':
      case 'interview fixed':
      case 'ready for interview':
      case 'will confirm later':
      case 'match making done':
        return Colors.green.shade50;

      // Yellow - Call issues
      case 'ringing':
      case 'call busy':
      case 'switched off':
      case 'not reachable':
      case 'disconnected':
        return Colors.yellow.shade50;

      // Blue - Call back later
      case 'busy right now':
      case 'call tomorrow morning':
      case 'call in evening':
      case 'call after 2 days':
        return Colors.blue.shade50;

      // Red - Not selected/interested
      case 'not selected':
      case 'not interested':
        return Colors.red.shade50;

      default:
        return Colors.grey.shade50;
    }
  }

  Color _getFeedbackBorderColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.grey.shade200;

    switch (feedback.toLowerCase()) {
      // Green - Connected/Interview related
      case 'interview done':
      case 'interview fixed':
      case 'ready for interview':
      case 'will confirm later':
      case 'match making done':
        return Colors.green.shade200;

      // Yellow - Call issues
      case 'ringing':
      case 'call busy':
      case 'switched off':
      case 'not reachable':
      case 'disconnected':
        return Colors.yellow.shade200;

      // Blue - Call back later
      case 'busy right now':
      case 'call tomorrow morning':
      case 'call in evening':
      case 'call after 2 days':
        return Colors.blue.shade200;

      // Red - Not selected/interested
      case 'not selected':
      case 'not interested':
        return Colors.red.shade200;

      default:
        return Colors.grey.shade300;
    }
  }

  Color _getFeedbackTextColor(String? feedback) {
    if (feedback == null || feedback.isEmpty) return Colors.grey.shade600;

    switch (feedback.toLowerCase()) {
      // Green - Connected/Interview related
      case 'interview done':
      case 'interview fixed':
      case 'ready for interview':
      case 'will confirm later':
      case 'match making done':
        return Colors.green.shade700;

      // Yellow - Call issues
      case 'ringing':
      case 'call busy':
      case 'switched off':
      case 'not reachable':
      case 'disconnected':
        return Colors.yellow.shade700;

      // Blue - Call back later
      case 'busy right now':
      case 'call tomorrow morning':
      case 'call in evening':
      case 'call after 2 days':
        return Colors.blue.shade700;

      // Red - Not selected/interested
      case 'not selected':
      case 'not interested':
        return Colors.red.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  Color _getMatchStatusColor(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Colors.white;

    switch (matchStatus.toLowerCase()) {
      case 'selected':
        return Colors.green.shade50;
      case 'not selected':
        return Colors.red.shade50;
      case 'pending':
        return Colors.yellow.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getMatchStatusBorderColor(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Colors.grey.shade200;

    switch (matchStatus.toLowerCase()) {
      case 'selected':
        return Colors.green.shade200;
      case 'not selected':
        return Colors.red.shade200;
      case 'pending':
        return Colors.yellow.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getMatchStatusTextColor(String? matchStatus) {
    if (matchStatus == null || matchStatus.isEmpty) return Colors.grey.shade600;

    switch (matchStatus.toLowerCase()) {
      case 'selected':
        return Colors.green.shade700;
      case 'not selected':
        return Colors.red.shade700;
      case 'pending':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) return;
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  void _showDriverDetails(BuildContext context, DriverApplicant driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriverDetailsSheet(driver: driver, onCall: () => _makePhoneCall(driver.mobile)),
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
              driverTmid: driver.driverTmid,
              driverName: driver.name,
              feedback: feedback,
              matchStatus: matchStatus,
              notes: notes,
              jobId: widget.jobId,
            );

            // Update the driver's feedback status locally
            setState(() {
              final index =
                  _applicants.indexWhere((d) => d.driverId == driver.driverId);
              if (index != -1) {
                _applicants[index] = DriverApplicant(
                  jobId: driver.jobId,
                  jobTitle: driver.jobTitle,
                  contractorId: driver.contractorId,
                  driverId: driver.driverId,
                  driverTmid: driver.driverTmid,
                  name: driver.name,
                  mobile: driver.mobile,
                  email: driver.email,
                  city: driver.city,
                  state: driver.state,
                  vehicleType: driver.vehicleType,
                  drivingExperience: driver.drivingExperience,
                  licenseType: driver.licenseType,
                  licenseNumber: driver.licenseNumber,
                  preferredLocation: driver.preferredLocation,
                  aadharNumber: driver.aadharNumber,
                  panNumber: driver.panNumber,
                  gstNumber: driver.gstNumber,
                  status: driver.status,
                  createdAt: driver.createdAt,
                  updatedAt: driver.updatedAt,
                  appliedAt: driver.appliedAt,
                  profileCompletion: driver.profileCompletion,
                  subscriptionAmount: driver.subscriptionAmount,
                  subscriptionStartDate: driver.subscriptionStartDate,
                  subscriptionEndDate: driver.subscriptionEndDate,
                  subscriptionStatus: driver.subscriptionStatus,
                  callFeedback: feedback,
                  matchStatus: matchStatus,
                  feedbackNotes: notes,
                );
              }
              _sortApplicants();
              _onSearchChanged(); // Refresh filtered list
            });

            // Show toast using global key - more reliable
            _scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text('Feedback submitted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } catch (e) {
            // Show error toast using global key
            _scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                    'Error: Exception: Failed to save call feedback: Exception: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      ),
    );
  }
}

// Driver Details Sheet with Tab Navigation
class _DriverDetailsSheet extends StatefulWidget {
  final DriverApplicant driver;
  final VoidCallback onCall;

  const _DriverDetailsSheet({required this.driver, required this.onCall});

  @override
  State<_DriverDetailsSheet> createState() => _DriverDetailsSheetState();
}

class _DriverDetailsSheetState extends State<_DriverDetailsSheet> {
  int _selectedTabIndex = 0;
  final ScrollController _tabScrollController = ScrollController();

  final List<_TabData> _tabs = [
    _TabData(
      label: 'Contact Info',
      icon: Icons.contact_phone_rounded,
      color: Color(0xFF2196F3),
    ),
    _TabData(
      label: 'Professional',
      icon: Icons.work_rounded,
      color: Color(0xFF4CAF50),
    ),
    _TabData(
      label: 'Application',
      icon: Icons.description_rounded,
      color: Color(0xFFFF9800),
    ),
    _TabData(
      label: 'Documents',
      icon: Icons.folder_rounded,
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    
    // Auto-scroll selected tab into view
    if (_tabScrollController.hasClients) {
      final double tabWidth = 130.0;
      final double targetScroll = (index * (tabWidth + 8)) - 50;
      _tabScrollController.animateTo(
        targetScroll.clamp(0.0, _tabScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with name
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.driver.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        widget.driver.driverTmid.isNotEmpty
                            ? widget.driver.driverTmid
                            : 'ID: ${widget.driver.driverId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.softGray,
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

          // Single card with tabs and content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Horizontal scrollable tabs
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListView.builder(
                        controller: _tabScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _tabs.length,
                        itemBuilder: (context, index) {
                          final tab = _tabs[index];
                          final isSelected = _selectedTabIndex == index;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildTabChip(
                              label: tab.label,
                              icon: tab.icon,
                              color: tab.color,
                              isSelected: isSelected,
                              onTap: () => _onTabTapped(index),
                            ),
                          );
                        },
                      ),
                    ),

                    // Content area
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildContent(_selectedTabIndex),
                      ),
                    ),

                    // Call button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onCall,
                          icon: const Icon(
                            Icons.call_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Call Driver',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(int tabIndex) {
    return SingleChildScrollView(
      key: ValueKey(tabIndex),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _getFieldsForTab(tabIndex).map((field) {
          // Special styling for Job ID field
          final isJobId = field.label == 'Job ID';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Job ID gets special chip styling
                if (isJobId)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        SelectableText(
                          field.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    field.value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey.shade200),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_FieldData> _getFieldsForTab(int tabIndex) {
    final driver = widget.driver;
    
    switch (tabIndex) {
      case 0: // Contact Info - Mobile removed for privacy
        return [
          _FieldData('Email', driver.email.isNotEmpty ? driver.email : 'N/A'),
          _FieldData('City', driver.city),
          _FieldData('State', driver.state),
        ];
      
      case 1: // Professional
        return [
          _FieldData('Vehicle Type', driver.vehicleType.isNotEmpty ? driver.vehicleType : 'N/A'),
          _FieldData('Experience', driver.drivingExperience.isNotEmpty ? driver.drivingExperience : 'N/A'),
          _FieldData('License Type', driver.licenseType.isNotEmpty ? driver.licenseType : 'N/A'),
          _FieldData('License Number', driver.licenseNumber.isNotEmpty ? driver.licenseNumber : 'N/A'),
          _FieldData('Preferred Location', driver.preferredLocation.isNotEmpty ? driver.preferredLocation : 'N/A'),
        ];
      
      case 2: // Application - Full Job ID and Job Title added
        return [
          _FieldData('Job ID', 'TMJB${driver.jobId.toString().padLeft(5, '0')}'),
          _FieldData('Applied For', driver.jobTitle.isNotEmpty ? driver.jobTitle : 'N/A'),
          _FieldData('Applied Date', _formatDate(driver.appliedAt)),
          _FieldData('Applied Time', _formatTime(driver.appliedAt)),
          _FieldData('Status', driver.status.isNotEmpty ? driver.status : 'N/A'),
          if (driver.subscriptionStartDate != null && driver.subscriptionStartDate!.isNotEmpty)
            _FieldData('Subscription', _formatDate(driver.subscriptionStartDate!)),
        ];
      
      case 3: // Documents
        return [
          _FieldData('Aadhar', driver.aadharNumber.isNotEmpty ? driver.aadharNumber : 'N/A'),
          _FieldData('PAN', driver.panNumber.isNotEmpty ? driver.panNumber : 'N/A'),
          _FieldData('GST', driver.gstNumber.isNotEmpty ? driver.gstNumber : 'N/A'),
          _FieldData('Driving License', driver.licenseNumber.isNotEmpty ? driver.licenseNumber : 'N/A'),
        ];
      
      default:
        return [];
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';

    try {
      DateTime dt;

      if (date.contains('-')) {
        dt = DateTime.parse(date);
      } else if (date.contains('/')) {
        final parts = date.split(' ')[0].split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          var year = int.parse(parts[2]);

          if (year < 100) {
            if (year > 50) {
              year += 1900;
            } else {
              year += 2000;
            }
          }

          dt = DateTime(year, month, day);
        } else {
          throw FormatException('Invalid date format');
        }
      } else {
        dt = DateTime.parse(date);
      }

      var correctedYear = dt.year;

      if (dt.year < 2020) {
        correctedYear = DateTime.now().year;
      }

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
        dt = DateTime.parse(date);
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

            if (year < 100) {
              year += (year > 50) ? 1900 : 2000;
            }

            dt = DateTime(year, month, day, hour, minute);
          } else {
            throw FormatException('Invalid datetime format');
          }
        } else {
          throw FormatException('No time part found');
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
}

class _TabData {
  final String label;
  final IconData icon;
  final Color color;

  _TabData({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _FieldData {
  final String label;
  final String value;

  _FieldData(this.label, this.value);
}

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left corner
    path.lineTo(0, 0);

    // Draw top edge
    path.lineTo(size.width, 0);

    // Draw right edge to the curve start point
    path.lineTo(size.width, size.height - 50);

    // Create a simple rounded bottom curve
    path.quadraticBezierTo(
      size.width * 0.5, // Control point X (center)
      size.height, // Control point Y (bottom)
      0, // End point X (left edge)
      size.height - 50, // End point Y
    );

    // Draw left edge back to start
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
