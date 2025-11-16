import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../core/services/smart_calling_service.dart';
import '../../models/job_model.dart';
import 'transporter_call_history_screen.dart';
import 'call_history_screen.dart';
import '../main_container.dart' as main;
import '../jobs/widgets/job_brief_feedback_modal.dart';
import '../telecaller/widgets/call_type_selection_dialog.dart';
import '../telecaller/widgets/ivr_call_waiting_overlay.dart';

class CallHistoryHubScreen extends StatefulWidget {
  const CallHistoryHubScreen({Key? key}) : super(key: key);

  @override
  State<CallHistoryHubScreen> createState() => _CallHistoryHubScreenState();
}

class _CallHistoryHubScreenState extends State<CallHistoryHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 48,
        leadingWidth: 40,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
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
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'My Calls', icon: Icon(Icons.phone_callback, size: 20)),
              Tab(
                  text: 'Transporters',
                  icon: Icon(Icons.local_shipping, size: 20)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CallHistoryScreen(),
          TransporterListScreen(),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // Transporter list
        Expanded(
          child: _buildBody(),
        ),
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

  Future<void> _makeCall(BuildContext context, Map<String, dynamic> transporter) async {
    final transporterName = _getDisplayName(transporter);
    final transporterTmid = transporter['tmid'] ?? '';
    final phoneNumber = transporter['phone']?.toString() ?? '';
    
    // Check if phone number is available
    if (phoneNumber.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Phone Number Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Phone number not available for $transporterName. Please update the contact details in the Jobs section.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show call type selection dialog
    final callType = await showDialog<String>(
      context: context,
      builder: (context) => CallTypeSelectionDialog(
        driverName: transporterName,
      ),
    );

    if (callType == null) return;

    try {
      final callerId = await Phase2AuthService.getUserId();
      final cleanMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      if (callType == 'manual') {
        // Manual call
        final result = await SmartCallingService.instance.initiateManualCall(
          driverMobile: cleanMobile,
          callerId: callerId,
          driverId: transporterTmid,
        );

        if (result['success'] == true) {
          final driverMobileRaw = result['data']?['driver_mobile_raw'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling $transporterName...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);
          await Future.delayed(const Duration(milliseconds: 500));

          if (context.mounted) {
            _showFeedbackModal(context, transporter);
          }
        }
      } else if (callType == 'click2call') {
        // IVR call
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📞 Initiating IVR call...'),
            duration: Duration(seconds: 2),
          ),
        );

        final result = await SmartCallingService.instance.initiateClick2CallIVR(
          driverMobile: cleanMobile,
          callerId: callerId,
          driverId: transporterTmid,
        );

        if (context.mounted) {
          if (result['success'] == true) {
            final referenceId = result['data']?['reference_id'];

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ IVR call initiated! Both phones will ring.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => PopScope(
                  canPop: false,
                  child: IVRCallWaitingOverlay(
                    driverName: transporterName,
                    referenceId: referenceId,
                    onCallEnded: () {
                      Navigator.of(context).pop();
                      _showFeedbackModal(context, transporter);
                    },
                  ),
                ),
              ),
            );
          } else {
            final errorMsg = result['error'] ?? 'Unknown error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to initiate IVR call: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFeedbackModal(BuildContext context, Map<String, dynamic> transporter) {
    final transporterName = _getDisplayName(transporter);
    final transporterTmid = transporter['tmid'] ?? '';
    
    // Generate a placeholder job ID for direct transporter calls
    final placeholderJobId = 'DIRECT_CALL_${transporterTmid}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create a minimal job object for the feedback modal
    final dummyJob = JobModel(
      id: 0,
      jobId: placeholderJobId,
      jobTitle: 'Call to $transporterName',
      transporterId: transporter['id']?.toString() ?? '0',
      transporterName: transporterName,
      transporterTmid: transporterTmid,
      transporterPhone: transporter['phone']?.toString() ?? '',
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
    );
    
    // Show feedback modal
    showJobBriefFeedbackModal(
      context: context,
      job: dummyJob,
      onSubmit: () {
        // Refresh the list after feedback is submitted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call feedback saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  String _getDisplayName(Map<String, dynamic> transporter) {
    final name = transporter['name']?.toString().trim();
    final company = transporter['company']?.toString().trim();
    final tmid = transporter['tmid']?.toString().trim();

    if (name != null && name.isNotEmpty && name.toLowerCase() != 'null') {
      return name;
    }
    if (company != null && company.isNotEmpty && company.toLowerCase() != 'null') {
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
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
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
                                colors: [Colors.red.shade400, Colors.red.shade600],
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.badge_outlined, size: 11, color: Colors.blue.shade700),
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
                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
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
                            colors: [Colors.green.shade400, Colors.green.shade600],
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
                          icon: const Icon(Icons.phone, color: Colors.white, size: 20),
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
                            child: Icon(Icons.phone_in_talk, size: 14, color: Colors.green.shade700),
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
                              child: Icon(Icons.access_time_rounded, size: 14, color: Colors.blue.shade700),
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
