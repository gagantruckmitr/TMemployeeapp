import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../core/services/smart_calling_service.dart';
import '../../core/services/call_feedback_guard_service.dart';
import '../../core/services/match_making_feedback_guard_service.dart';
import '../../core/services/real_auth_service.dart';
import '../../models/job_model.dart';
import 'transporter_call_history_screen.dart';
import 'call_history_screen.dart';
import '../main_container.dart' as main;
import '../jobs/widgets/job_brief_feedback_modal.dart';
import '../jobs/widgets/job_call_status_selection_modal.dart';
import '../telecaller/widgets/call_type_selection_dialog.dart';
import '../telecaller/widgets/easygo_ivr_call_helper.dart';

class CallHistoryHubScreen extends StatefulWidget {
  const CallHistoryHubScreen({Key? key}) : super(key: key);

  @override
  State<CallHistoryHubScreen> createState() => _CallHistoryHubScreenState();
}

class _CallHistoryHubScreenState extends State<CallHistoryHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'today';

  final List<Map<String, String>> _periodFilters = [
    {'key': 'today', 'label': 'Today'},
    {'key': 'yesterday', 'label': 'Yesterday'},
    {'key': 'week', 'label': 'Week'},
    {'key': 'month', 'label': 'Month'},
    {'key': 'all', 'label': 'All'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPendingFeedback();
  }

  Future<void> _checkPendingFeedback() async {
    // Check for pending call feedback
    final hasPendingCall = await CallFeedbackGuardService.instance
        .hasLastCallPendingFeedback();
    if (hasPendingCall && mounted) {
      CallFeedbackGuardService.showPendingFeedbackToast(context);
      return;
    }

    // Check for pending match-making feedback
    final hasPendingMatchMaking = await MatchMakingFeedbackGuardService.instance
        .hasLastMatchMakingCallPendingFeedback();
    if (hasPendingMatchMaking && mounted) {
      MatchMakingFeedbackGuardService.showPendingMatchMakingFeedbackToast(
        context,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS system background
      body: Column(
        children: [
          // Apple-style slim header with time dropdown
          _buildAppleHeader(context),
          // Tab bar for Drivers / Transporters
          _buildCategoryTabs(),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CallHistoryScreen(initialPeriod: _selectedPeriod),
                const TransporterListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Back button - iOS style
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const main.MainContainer(),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              const Text(
                'Call History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E), // iOS label color
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              // Time period dropdown
              GestureDetector(
                onTap: () => _showPeriodPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _periodFilters.firstWhere(
                          (f) => f['key'] == _selectedPeriod,
                        )['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Time Period',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              // Period options
              ..._periodFilters.map((filter) {
                final isSelected = _selectedPeriod == filter['key'];
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = filter['key']!;
                    });
                    Navigator.pop(context);
                  },
                  leading: Icon(
                    _getPeriodIcon(filter['key']!),
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                  title: Text(
                    filter['label']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF1C1C1E),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : null,
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPeriodIcon(String period) {
    switch (period) {
      case 'today':
        return Icons.today_rounded;
      case 'yesterday':
        return Icons.history_rounded;
      case 'week':
        return Icons.date_range_rounded;
      case 'month':
        return Icons.calendar_month_rounded;
      case 'all':
        return Icons.all_inclusive_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Widget _buildCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: const Color(0xFF8E8E93),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        tabs: [
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, size: 18),
                const SizedBox(width: 6),
                const Text('Drivers'),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_rounded, size: 18),
                const SizedBox(width: 6),
                const Text('Transporters'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransporterListScreen extends StatefulWidget {
  const TransporterListScreen({Key? key}) : super(key: key);

  @override
  State<TransporterListScreen> createState() => _TransporterListScreenState();
}

class _TransporterListScreenState extends State<TransporterListScreen> {
  List<Map<String, dynamic>> _transporters = [];
  List<Map<String, dynamic>> _filteredTransporters = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransporters();
    _searchController.addListener(_filterTransporters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransporters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch transporters with call history
      final transporters =
          await Phase2ApiService.getTransportersWithCallHistory();

      setState(() {
        _transporters = transporters;
        _filteredTransporters = _transporters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTransporters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTransporters = _transporters;
      } else {
        _filteredTransporters = _transporters.where((t) {
          final name = t['name']?.toString().toLowerCase() ?? '';
          final tmid = t['tmid']?.toString().toLowerCase() ?? '';
          final company = t['company']?.toString().toLowerCase() ?? '';
          return name.contains(query) ||
              tmid.contains(query) ||
              company.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search transporters...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),

        // Transporter list
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransporters,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredTransporters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.local_shipping
                  : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No transporters found'
                  : 'No results for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransporters,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransporters.length,
        itemBuilder: (context, index) {
          final transporter = _filteredTransporters[index];
          return _TransporterCard(
            transporter: transporter,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterCallHistoryScreen(
                    transporterTmid: transporter['tmid'],
                    transporterName: transporter['name'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TransporterCard extends StatelessWidget {
  final Map<String, dynamic> transporter;
  final VoidCallback onTap;

  const _TransporterCard({
    Key? key,
    required this.transporter,
    required this.onTap,
  }) : super(key: key);

  Future<void> _makeCall(
    BuildContext context,
    Map<String, dynamic> transporter,
  ) async {
    final transporterName = _getDisplayName(transporter);
    final transporterTmid = transporter['tmid'] ?? '';
    final transporterPhone = transporter['phone']?.toString() ?? '';

    if (transporterPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show call type selection dialog
      final callType = await showDialog<String>(
        context: context,
        builder: (context) =>
            CallTypeSelectionDialog(driverName: transporterName),
      );

      if (callType == null) return; // User cancelled

      // Use the actual job_id from the transporter data, or generate a unique ID for direct calls
      final latestJobId = transporter['latestJobId']?.toString() ?? '';
      final jobId = latestJobId.isNotEmpty && latestJobId != 'null'
          ? latestJobId
          : 'TMJB${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // Create a minimal job object for the feedback modal
      final dummyJob = JobModel(
        id: 0,
        jobId: jobId,
        jobTitle: jobId.startsWith('TMJB') ? 'Direct Call' : 'Job: $jobId',
        transporterId: transporter['id']?.toString() ?? '0',
        transporterName: transporterName,
        transporterTmid: transporterTmid,
        transporterPhone: transporterPhone,
        transporterCity: transporter['city']?.toString() ?? '',
        transporterState: transporter['state']?.toString() ?? '',
        transporterProfileCompletion: 0,
        jobLocation: transporter['location']?.toString() ?? '',
        jobDescription: '',
        salaryRange: '',
        requiredExperience: '',
        preferredStatus: '',
        typeOfLicense: '',
        vehicleType: '',
        vehicleTypeDetail: '',
        applicationDeadline: '',
        jobManagementDate: '',
        jobManagementId: '',
        jobDescriptionId: '',
        numberOfDriverRequired: 1,
        activePosition: 0,
        createdVehicleDetail: '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        status: 1,
        applicantsCount: 0,
        isApproved: true,
        isActive: true,
        isExpired: false,
        assignedTo: null,
        assignedToName: null,
        isClosed: false,
      );

      if (callType == 'manual') {
        await _handleManualCall(context, dummyJob);
      } else if (callType == 'easygo_ivr') {
        await _handleEasyGoIVR(context, dummyJob);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleManualCall(BuildContext context, JobModel job) async {
    try {
      final callerId = await Phase2AuthService.getUserId();
      final cleanMobile = job.transporterPhone.replaceAll(RegExp(r'[^\d]'), '');

      // Log manual call
      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: job.transporterId,
      );

      if (result['success'] == true) {
        final transporterMobileRaw = result['data']?['driver_mobile_raw'];

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${job.transporterName}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Make direct call
        await FlutterPhoneDirectCaller.callNumber(transporterMobileRaw);
        await Future.delayed(const Duration(milliseconds: 500));

        // Show call status selection modal after call (same flow as IVR)
        if (context.mounted) {
          _showCallStatusModalAfterCall(context, job, null);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manual call error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEasyGoIVR(BuildContext context, JobModel job) async {
    // Get current user ID for assignedTo
    final currentUser = await Phase2AuthService.getCurrentUser();
    final currentUserId = currentUser?.id ?? 0;

    // Parse transporter ID - it should be numeric
    final transporterUserId = int.tryParse(job.transporterId) ?? 0;

    await EasyGoIVRCallHelper.initiateCall(
      context: context,
      clientName: job.transporterName,
      clientPhone: job.transporterPhone,
      clientId: transporterUserId.toString(),
      tmid: job.transporterTmid,
      contactType: 'transporter',
      callSource:
          'job_posting', // Use job_posting to trigger Laravel job brief API
      onCallCompleted: (jobBriefId) {
        // After call ends, show call status selection modal (same as modern_job_card.dart)
        _showCallStatusModalAfterCall(context, job, jobBriefId);
      },
      jobId: job.jobId,
      assignedTo: currentUserId,
      jobBriefTransporterUserId: transporterUserId,
    );
  }

  // Show call status selection modal after call ends (same flow as dynamic_jobs_screen)
  Future<void> _showCallStatusModalAfterCall(
    BuildContext context,
    JobModel job,
    String? jobBriefId,
  ) async {
    if (!context.mounted) return;

    print(
      '🔵 _showCallStatusModalAfterCall called with jobBriefId: $jobBriefId',
    );

    // Show modal and get result via callback
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => PopScope(
        canPop: false,
        child: JobCallStatusSelectionModal(
          transporterName: job.transporterName,
          onStatusSelected:
              (
                String status,
                String? feedback,
                String? remarks,
                bool shouldCloseJob,
              ) async {
                print(
                  '🔵 onStatusSelected: status=$status, feedback=$feedback, remarks=$remarks, closeJob=$shouldCloseJob',
                );

                // Close the modal first
                Navigator.of(modalContext).pop();

                // Small delay to ensure modal animation completes
                await Future.delayed(const Duration(milliseconds: 100));

                if (!context.mounted) return;

                // Handle the selection based on feedback type
                if (status == 'Connected' &&
                    feedback == 'Transporter Confirmed Job Details') {
                  print('🔵 Opening Job Brief modal');
                  // Open Job Brief modal
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      showJobBriefFeedbackModal(
                        context: context,
                        job: job,
                        jobBriefId: jobBriefId,
                        hideCallStatusFields: true,
                        preSelectedCallStatus: 'connected',
                        preSelectedCallFeedback:
                            'Transporter Confirmed Job Details',
                        preSelectedRemarks: remarks,
                        onSubmit: () {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Job brief feedback saved successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    }
                  });
                } else {
                  // For other feedbacks, update via API
                  print('🔵 Submitting feedback via API: $status - $feedback');
                  await _updateJobBriefCallStatus(
                    context: context,
                    job: job,
                    jobBriefId: jobBriefId,
                    status: status,
                    feedback: feedback!,
                    remarks: remarks,
                    closeJob: shouldCloseJob,
                  );
                }
              },
        ),
      ),
    );
  }

  Future<void> _updateJobBriefCallStatus({
    required BuildContext context,
    required JobModel job,
    String? jobBriefId,
    required String status,
    required String feedback,
    String? remarks,
    bool closeJob = false,
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        print('✗ No user found');
        return;
      }

      // Get authentication token
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        print('✗ No auth token found');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication error. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Map status to API format
      String apiCallStatus;
      if (status == 'Connected') {
        apiCallStatus = 'connected';
      } else if (status == 'Not Connected') {
        apiCallStatus = 'not_connected';
      } else if (status == 'Call Back Later') {
        apiCallStatus = 'callback_later';
      } else {
        apiCallStatus = status.toLowerCase().replaceAll(' ', '_');
      }

      // Build request body with important fields only
      final requestBody = {
        'id': jobBriefId ?? '',
        'call_status': apiCallStatus,
        'call_feedback': feedback,
        'call_remarks': remarks ?? '',
        'name': job.transporterName,
        'transporter_tmid': job.transporterTmid,
        'assigned_to': user.id,
        'closed_job': closeJob ? 1 : 0,
        'job_id': job.jobId,
      };

      print('🔵 API Request Body: $requestBody');
      print('🔵 Auth Token: ${token.substring(0, 20)}...');

      // Call the API to update job brief with call status
      final response = await http.post(
        Uri.parse(
          'https://truckmitr.com/api/telehead/ivr-call-update-jobBrief',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('🔵 API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          print('✓ Job brief call status updated successfully');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  closeJob
                      ? 'Job closed successfully'
                      : 'Feedback saved successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('✗ Failed to update call status: ${data['message']}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to save feedback: ${data['message'] ?? 'Unknown error'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('✗ API error: ${response.statusCode}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('✗ Error updating call status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getDisplayName(Map<String, dynamic> transporter) {
    final name = transporter['name']?.toString().trim();
    final company = transporter['company']?.toString().trim();
    final tmid = transporter['tmid']?.toString().trim();

    if (name != null && name.isNotEmpty && name.toLowerCase() != 'null') {
      return name;
    }
    if (company != null &&
        company.isNotEmpty &&
        company.toLowerCase() != 'null') {
      return company;
    }
    if (tmid != null && tmid.isNotEmpty && tmid.toLowerCase() != 'null') {
      return 'Contact ($tmid)';
    }
    return 'Unknown Contact';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      // Compare calendar dates, not time differences
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

      final daysDiff = todayOnly.difference(dateOnly).inDays;

      if (dateOnly == todayOnly) {
        return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (dateOnly == yesterdayOnly) {
        return 'Yesterday';
      } else if (daysDiff < 7 && daysDiff > 0) {
        return '$daysDiff days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final callCount = transporter['callCount'] ?? 0;
    final location = transporter['location']?.toString();
    final lastCallDate = transporter['lastCallDate']?.toString();
    final latestJobId = transporter['latestJobId']?.toString() ?? '';

    // Debug: Print job ID for this transporter
    print(
      '🔵 TransporterCard: tmid=${transporter['tmid']}, latestJobId="$latestJobId"',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern gradient icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      if (callCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              callCount > 99 ? '99+' : callCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(transporter),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGray,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // TMID Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 11,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                transporter['tmid'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Job ID Badge - below TMID, only show if valid job ID
                        if (latestJobId.isNotEmpty &&
                            latestJobId.toLowerCase() != 'null' &&
                            latestJobId.toLowerCase() != 'n/a' &&
                            !latestJobId.startsWith('DIRECT_CALL')) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 11,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  latestJobId,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons column
                  Column(
                    children: [
                      // Call button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _makeCall(context, transporter),
                          tooltip: 'Call',
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // View history indicator
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),

              // Stats row
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Call count
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.phone_in_talk,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Calls',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$callCount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),

                    // Last call
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Call',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(lastCallDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}
