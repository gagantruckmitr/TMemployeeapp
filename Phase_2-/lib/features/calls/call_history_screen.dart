import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import '../../core/services/phase2_auth_service.dart';
import '../../models/call_history_model.dart';
import '../../models/phase2_user_model.dart';
import 'widgets/call_feedback_modal.dart';
import 'package:intl/intl.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<CallHistoryLog> _callLogs = [];
  bool _isLoading = true;
  String _selectedPeriod = 'all';
  String? _selectedFeedback;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Phase2User? _currentUser;

  final ScrollController _scrollController = ScrollController();
  bool _showFilters = true;
  double _lastScrollOffset = 0;

  final List<String> _periods = ['all', 'today', 'week', 'month'];
  final List<String> _feedbackTypes = [
    'All',
    'Interview Done',
    'Not Selected',
    'Switched Off',
    'Match Making Done',
    'Will Confirm Later',
    'Ringing',
    'Call Busy',
    'Busy Right Now',
    'Not Reachable',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = _periods[_tabController.index];
        });
        _loadData();
      }
    });

    _scrollController.addListener(_onScroll);
    _loadCurrentUser();
    _loadData();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // Show filters when scrolling down or at top, hide when scrolling up
    if (delta > 5 && _showFilters && currentOffset > 50) {
      setState(() => _showFilters = false);
    } else if (delta < -5 && !_showFilters) {
      setState(() => _showFilters = true);
    } else if (currentOffset <= 0 && !_showFilters) {
      setState(() => _showFilters = true);
    }

    _lastScrollOffset = currentOffset;
  }

  Future<void> _loadCurrentUser() async {
    final user = await Phase2AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await Phase2ApiService.fetchCallHistory(
        period: _selectedPeriod,
        feedbackFilter: _selectedFeedback == 'All' ? null : _selectedFeedback,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      final logs = (result['logs'] as List)
          .map((json) => CallHistoryLog.fromJson(json))
          .toList();

      setState(() {
        _callLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildPeriodTabs(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showFilters ? null : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showFilters ? 1.0 : 0.0,
              child: _buildFilters(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _callLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildCallList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Call History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: _loadData,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Today'),
          Tab(text: 'Week'),
          Tab(text: 'Month'),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _loadData();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => _loadData(),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _feedbackTypes.map((type) {
                final isSelected = _selectedFeedback == type ||
                    (type == 'All' && _selectedFeedback == null);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(type, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeedback = type == 'All' ? null : type;
                      });
                      _loadData();
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _callLogs.length,
        itemBuilder: (context, index) {
          final log = _callLogs[index];
          return _buildCallCard(log);
        },
      ),
    );
  }

  Widget _buildCallCard(CallHistoryLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showCallDetail(log),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _getFeedbackColor(log.feedback).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getFeedbackIcon(log.feedback),
                        color: _getFeedbackColor(log.feedback),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.contactName.isEmpty
                                ? 'Unknown Contact'
                                : log.contactName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: log.contactType == 'Driver'
                                      ? Colors.blue.shade50
                                      : Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.contactType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: log.contactType == 'Driver'
                                        ? Colors.blue.shade700
                                        : Colors.purple.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log.contactId,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Call Icon Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.phone,
                            color: Colors.green.shade700, size: 22),
                        onPressed: () => _makeCall(log),
                        tooltip: 'Call ${log.contactName}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Feedback Status
                Row(
                  children: [
                    Icon(Icons.feedback_outlined,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Feedback:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              _getFeedbackColor(log.feedback).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getFeedbackColor(log.feedback)
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          log.feedback,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getFeedbackColor(log.feedback),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                // Match Status (if available)
                if (log.matchStatus.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Match Status:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getMatchStatusColor(log.matchStatus)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          log.matchStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getMatchStatusColor(log.matchStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Job ID (if available)
                if (log.jobId.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.work_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Job ID:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.jobId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Remark (if available)
                if (log.remark.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note_alt_outlined,
                                size: 14, color: Colors.amber.shade800),
                            const SizedBox(width: 6),
                            Text(
                              'Remark:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          log.remark,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Footer Row
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(log.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Action Buttons
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showEditFeedbackModal(log),
                        color: AppColors.primary,
                        tooltip: 'Update Feedback',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDelete(log),
                        color: Colors.red.shade700,
                        tooltip: 'Delete',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No call history found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call logs will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDetail(CallHistoryLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.1), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            _getFeedbackColor(log.feedback).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getFeedbackIcon(log.feedback),
                        color: _getFeedbackColor(log.feedback),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Call Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.contactName.isEmpty
                                ? 'Unknown Contact'
                                : log.contactName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Contact Information', [
                      _buildDetailRow('Name', log.contactName),
                      _buildDetailRow('Type', log.contactType),
                      _buildDetailRow('ID', log.contactId),
                      if (log.callerName.isNotEmpty)
                        _buildDetailRow('Called By', log.callerName),
                    ]),

                    const SizedBox(height: 20),

                    _buildDetailSection('Call Feedback', [
                      _buildDetailRow('Feedback', log.feedback),
                      if (log.matchStatus.isNotEmpty)
                        _buildDetailRow('Match Status', log.matchStatus),
                      if (log.remark.isNotEmpty)
                        _buildDetailRow('Remark', log.remark),
                    ]),

                    if (log.jobId.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Job Information', [
                        _buildDetailRow('Job ID', log.jobId),
                      ]),
                    ],

                    const SizedBox(height: 20),

                    _buildDetailSection('Timestamps', [
                      _buildDetailRow(
                          'Called At', _formatDateTime(log.createdAt)),
                      _buildDetailRow(
                          'Updated At', _formatDateTime(log.updatedAt)),
                    ]),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _makeCall(log);
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditFeedbackModal(log);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Make a phone call
  Future<void> _makeCall(CallHistoryLog log) async {
    // First, show feedback modal after call intent
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: log.contactType.toLowerCase(),
        userName: log.contactName,
        userTmid: log.contactId,
        transporterTmid:
            log.uniqueIdTransporter.isNotEmpty ? log.uniqueIdTransporter : null,
        jobId: log.jobId.isNotEmpty ? log.jobId : null,
        onSubmit: (feedback, matchStatus, notes) async {
          try {
            await Phase2ApiService.saveCallFeedback(
              callerId: _currentUser?.id ?? 0,
              transporterTmid: log.uniqueIdTransporter.isNotEmpty
                  ? log.uniqueIdTransporter
                  : null,
              driverTmid:
                  log.uniqueIdDriver.isNotEmpty ? log.uniqueIdDriver : null,
              driverName: log.driverName,
              transporterName: log.transporterName,
              feedback: feedback,
              matchStatus: matchStatus,
              notes: notes,
              jobId: log.jobId.isNotEmpty ? log.jobId : null,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call feedback saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadData();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving feedback: $e')),
              );
            }
          }
        },
      ),
    );

    // Attempt to make the call (this will open the phone dialer)
    // Note: You'll need to extract phone number from the contact
    // For now, we'll show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening dialer for ${log.contactName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show edit feedback modal with role-based options
  void _showEditFeedbackModal(CallHistoryLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        userType: log.contactType.toLowerCase(),
        userName: log.contactName,
        userTmid: log.contactId,
        transporterTmid:
            log.uniqueIdTransporter.isNotEmpty ? log.uniqueIdTransporter : null,
        jobId: log.jobId.isNotEmpty ? log.jobId : null,
        onSubmit: (feedback, matchStatus, notes) async {
          try {
            await Phase2ApiService.updateCallLog(
              id: log.id,
              feedback: feedback,
              matchStatus: matchStatus,
              remark: notes,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadData();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating feedback: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(CallHistoryLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call Log'),
        content: const Text('Are you sure you want to delete this call log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Phase2ApiService.deleteCallLog(log.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call log deleted')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getFeedbackColor(String feedback) {
    switch (feedback.toLowerCase()) {
      case 'interview done':
      case 'match making done':
        return Colors.green.shade600;
      case 'not selected':
        return Colors.red.shade600;
      case 'switched off':
      case 'not reachable':
      case 'disconnected':
        return Colors.orange.shade600;
      case 'will confirm later':
      case 'busy right now':
      case 'call tomorrow morning':
      case 'call in evening':
      case 'call after 2 days':
        return Colors.blue.shade600;
      case 'ringing':
      case 'call busy':
      case 'didn\'t pick':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getMatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selected':
        return Colors.green.shade600;
      case 'not selected':
        return Colors.red.shade600;
      case 'pending':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getFeedbackIcon(String feedback) {
    switch (feedback.toLowerCase()) {
      case 'interview done':
      case 'match making done':
        return Icons.check_circle;
      case 'not selected':
        return Icons.cancel;
      case 'switched off':
      case 'not reachable':
        return Icons.phone_disabled;
      case 'will confirm later':
        return Icons.schedule;
      default:
        return Icons.phone;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }
}
