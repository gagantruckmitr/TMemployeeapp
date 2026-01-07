import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import 'package:intl/intl.dart';

class DriverDetailedInfoScreen extends StatefulWidget {
  final int driverId;

  const DriverDetailedInfoScreen({super.key, required this.driverId});

  @override
  State<DriverDetailedInfoScreen> createState() =>
      _DriverDetailedInfoScreenState();
}

class _DriverDetailedInfoScreenState extends State<DriverDetailedInfoScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _driverData;
  late TabController _tabController;
  String _selectedTelecaller = 'All';
  String _selectedJobId = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await Phase2ApiService.fetchDriverDetailedInfo(
        widget.driverId,
      );
      setState(() {
        _driverData = data;
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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildCompactAppBar(),
      body: _isLoading
          ? _buildSkeletonContent()
          : _error.isNotEmpty
          ? _buildErrorState()
          : _driverData == null
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  PreferredSizeWidget _buildCompactAppBar() {
    final driver = _driverData?['driver'] ?? {};
    final driverName = driver['name'] ?? 'Driver Details';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      toolbarHeight: 48,
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
      ),
      title: Text(
        _isLoading ? 'Loading...' : driverName,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, size: 20, color: Colors.grey.shade600),
          onPressed: _loadData,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSkeletonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Driver Header Skeleton
          _buildSkeletonCard(
            child: Row(
              children: [
                _buildShimmerBox(width: 50, height: 50, borderRadius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 120, height: 16, borderRadius: 4),
                      const SizedBox(height: 6),
                      _buildShimmerBox(width: 90, height: 12, borderRadius: 4),
                      const SizedBox(height: 4),
                      _buildShimmerBox(width: 70, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                _buildShimmerBox(width: 50, height: 50, borderRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Skeleton
          _buildSkeletonCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _buildShimmerBox(
                    width: double.infinity,
                    height: 32,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildShimmerBox(
                    width: double.infinity,
                    height: 32,
                    borderRadius: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Content Skeleton
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildShimmerBox(
                          width: 160,
                          height: 14,
                          borderRadius: 4,
                        ),
                        _buildShimmerBox(
                          width: 50,
                          height: 20,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 10,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 6),
                    _buildShimmerBox(width: 180, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person_outline,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Data Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Driver details are not available',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildCompactDriverHeader(),
        const SizedBox(height: 12),
        Expanded(child: _buildTabSection()),
      ],
    );
  }

  Widget _buildCompactDriverHeader() {
    final driver = _driverData!['driver'] ?? {};
    final totalJobs = _driverData!['totalJobsApplied'] ?? 0;
    final uniqueId = driver['uniqueId']?.toString();
    final hasUniqueId =
        uniqueId != null && uniqueId.isNotEmpty && uniqueId != 'null';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (driver['name'] ?? 'D')
                    .toString()
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['name'] ?? 'Unknown Driver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _copyToClipboard(driver['mobile'], 'Mobile'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        driver['mobile'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, size: 10, color: Colors.grey.shade400),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => _copyToClipboard(uniqueId, 'TMID'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        hasUniqueId ? uniqueId : 'TMID not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUniqueId
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          fontStyle: hasUniqueId
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                      if (hasUniqueId) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 10, color: Colors.grey.shade400),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Jobs Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '$totalJobs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Jobs',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String? text, String label) {
    if (text != null && text.isNotEmpty && text != 'null') {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Tab Bar
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Applied Jobs', height: 32),
                Tab(text: 'Call History', height: 32),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAppliedJobsTab(), _buildCallHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedJobsTab() {
    final allJobs = _driverData!['appliedJobs'] as List? ?? [];

    if (allJobs.isEmpty) {
      return _buildEmptyTabState(
        icon: Icons.work_off_outlined,
        title: 'No Jobs Applied',
        subtitle: 'No job applications found for this driver',
      );
    }

    // Extract unique telecallers
    final telecallers = <String>{'All'};
    for (var job in allJobs) {
      if (job['assignedTelecaller'] != null &&
          job['assignedTelecaller'].toString().isNotEmpty) {
        telecallers.add(job['assignedTelecaller']);
      }
    }

    // Filter jobs
    final filteredJobs = _selectedTelecaller == 'All'
        ? allJobs
        : allJobs
              .where((job) => job['assignedTelecaller'] == _selectedTelecaller)
              .toList();

    return Column(
      children: [
        // Compact Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTelecaller,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: telecallers.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'All' ? Icons.people : Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value == 'All' ? 'All Telecallers' : value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTelecaller = newValue!;
                  });
                },
              ),
            ),
          ),
        ),

        // Jobs List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: filteredJobs.length,
            itemBuilder: (context, index) {
              final job = filteredJobs[index];
              return _buildJobCard(job);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final callStatus = job['callStatus']?.toString() ?? '';
    final callFeedback =
        job['callFeedback']?.toString() ?? job['feedback']?.toString() ?? '';
    final callRemarks =
        job['callRemarks']?.toString() ?? job['remarks']?.toString() ?? '';
    final hasCallStatus = callStatus.isNotEmpty;
    final hasFeedback = callFeedback.isNotEmpty;
    final hasRemarks = callRemarks.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  job['jobTitle'] ?? 'Unknown Job',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  job['jobId'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Info Rows
          _buildCompactInfoRow(
            Icons.business,
            'Transporter',
            job['transporterName'],
          ),
          _buildCompactInfoRow(
            Icons.person,
            'Assigned To',
            job['assignedTelecaller'],
          ),
          _buildCompactInfoRow(
            Icons.calendar_today,
            'Applied',
            _formatDate(job['appliedDate']),
          ),

          // Call Status Section (always show if there's any call info)
          if (hasCallStatus || hasFeedback || hasRemarks) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusBgColor(callStatus),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _getStatusBorderColor(callStatus)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(callStatus),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getStatusIcon(callStatus),
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Call Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(callStatus),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasCallStatus
                              ? _formatCallStatus(callStatus)
                              : 'Pending',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Called By Info
                  if (job['calledBy'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Called by Agent ${job['calledBy']} on ${_formatDate(job['callUpdatedAt'])}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Feedback Section
                  if (hasFeedback) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: 12,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Feedback',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  callFeedback,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade900,
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

                  // Remarks Section
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasRemarks
                          ? Colors.amber.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasRemarks
                            ? Colors.amber.shade200
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 12,
                          color: hasRemarks
                              ? Colors.amber.shade700
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remarks',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: hasRemarks
                                      ? Colors.amber.shade700
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasRemarks ? callRemarks : 'No remarks added',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasRemarks
                                      ? Colors.amber.shade900
                                      : Colors.grey.shade400,
                                  fontWeight: hasRemarks
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  fontStyle: hasRemarks
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildCallHistoryTab() {
    final allHistory = _driverData!['callHistory'] as List? ?? [];

    // If call history is empty, use appliedJobs as call history (since they have call data)
    final callHistoryData = allHistory.isNotEmpty
        ? allHistory
        : (_driverData!['appliedJobs'] as List? ?? [])
              .where(
                (job) =>
                    (job['callStatus'] != null &&
                        job['callStatus'].toString().isNotEmpty) ||
                    (job['callFeedback'] != null &&
                        job['callFeedback'].toString().isNotEmpty),
              )
              .toList();

    if (callHistoryData.isEmpty) {
      return _buildEmptyTabState(
        icon: Icons.history_outlined,
        title: 'No Call History',
        subtitle: 'Call history will appear here once calls are made',
      );
    }

    // Extract unique Job IDs
    final jobIds = <String>{'All'};
    for (var call in callHistoryData) {
      final jobId = call['jobId']?.toString() ?? '';
      if (jobId.isNotEmpty) {
        jobIds.add(jobId);
      }
    }

    // Filter history
    final filteredHistory = _selectedJobId == 'All'
        ? callHistoryData
        : callHistoryData
              .where((call) => call['jobId'] == _selectedJobId)
              .toList();

    return Column(
      children: [
        // Compact Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedJobId,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: jobIds.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'All' ? Icons.work_outline : Icons.work,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value == 'All' ? 'All Jobs' : value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedJobId = newValue!;
                  });
                },
              ),
            ),
          ),
        ),

        // History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: filteredHistory.length,
            itemBuilder: (context, index) {
              final call = filteredHistory[index];
              return _buildCallHistoryCard(call);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCallHistoryCard(Map<String, dynamic> call) {
    final callStatus =
        call['callStatus']?.toString() ?? call['matchStatus']?.toString() ?? '';
    final feedback =
        call['callFeedback']?.toString() ?? call['feedback']?.toString() ?? '';
    final remarks =
        call['callRemarks']?.toString() ??
        call['remarks']?.toString() ??
        call['remark']?.toString() ??
        '';
    final callerName =
        call['callerName']?.toString() ??
        call['assignedTelecaller']?.toString() ??
        'Unknown Caller';
    final jobId = call['jobId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _getStatusBorderColor(callStatus)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusBgColor(callStatus),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(callStatus),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getStatusIcon(callStatus),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            callerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Job: ${call['jobTitle'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(callStatus),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        callStatus.isNotEmpty
                            ? _formatCallStatus(callStatus)
                            : 'Pending',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // Job ID Badge
                if (jobId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          jobId,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(
                        call['callTime'] ??
                            call['appliedDate'] ??
                            call['callUpdatedAt'],
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Feedback
                if (feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 12,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                feedback,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade900,
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

                // Remarks
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: remarks.isNotEmpty
                        ? Colors.amber.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: remarks.isNotEmpty
                          ? Colors.amber.shade200
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 12,
                        color: remarks.isNotEmpty
                            ? Colors.amber.shade700
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remarks',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: remarks.isNotEmpty
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              remarks.isNotEmpty ? remarks : 'No remarks added',
                              style: TextStyle(
                                fontSize: 11,
                                color: remarks.isNotEmpty
                                    ? Colors.amber.shade900
                                    : Colors.grey.shade400,
                                fontWeight: remarks.isNotEmpty
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                fontStyle: remarks.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCallStatus(String? status) {
    if (status == null || status.isEmpty) return 'Pending';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    final s = status.toLowerCase();
    // Check "not connected" FIRST before "connected" to avoid false positive
    if (s.contains('not_connected') ||
        s.contains('not connected') ||
        s.contains('not interested') ||
        s.contains('rejected')) {
      return const Color(0xFFFF3B30); // iOS Red
    }
    if (s.contains('interested') ||
        s.contains('selected') ||
        s.contains('match') ||
        s.contains('connected')) {
      return const Color(0xFF34C759); // iOS Green
    }
    if (s.contains('callback') || s.contains('later') || s.contains('busy')) {
      return const Color(0xFFFF9500); // iOS Orange
    }
    return const Color(0xFFFFCC00); // iOS Yellow
  }

  Color _getStatusBgColor(String? status) {
    final color = _getStatusColor(status);
    return color.withValues(alpha: 0.08);
  }

  Color _getStatusBorderColor(String? status) {
    final color = _getStatusColor(status);
    return color.withValues(alpha: 0.2);
  }

  IconData _getStatusIcon(String? status) {
    if (status == null || status.isEmpty) return Icons.pending_outlined;
    final s = status.toLowerCase();
    // Check "not connected" FIRST before "connected"
    if (s.contains('not_connected') ||
        s.contains('not connected') ||
        s.contains('not interested') ||
        s.contains('rejected')) {
      return Icons.cancel_outlined;
    }
    if (s.contains('interested') ||
        s.contains('selected') ||
        s.contains('match') ||
        s.contains('connected')) {
      return Icons.check_circle_outline;
    }
    if (s.contains('callback') || s.contains('later') || s.contains('busy')) {
      return Icons.schedule_outlined;
    }
    return Icons.help_outline;
  }
}
