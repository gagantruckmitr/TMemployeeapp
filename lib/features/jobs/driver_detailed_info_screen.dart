import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/phase2_api_service.dart';
import 'package:intl/intl.dart';

class DriverDetailedInfoScreen extends StatefulWidget {
  final int driverId;

  const DriverDetailedInfoScreen({super.key, required this.driverId});

  @override
  State<DriverDetailedInfoScreen> createState() => _DriverDetailedInfoScreenState();
}

class _DriverDetailedInfoScreenState extends State<DriverDetailedInfoScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _driverData;
  late TabController _tabController;

  String _selectedTelecaller = 'All';

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
      final data = await Phase2ApiService.fetchDriverDetailedInfo(widget.driverId);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Driver Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Applied Jobs'),
            Tab(text: 'Call History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Error: $_error'))
              : _driverData == null
                  ? const Center(child: Text('No data found'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAppliedJobsTab(),
                        _buildCallHistoryTab(),
                      ],
                    ),
    );
  }

  Widget _buildAppliedJobsTab() {
    final allJobs = _driverData!['appliedJobs'] as List;
    
    if (allJobs.isEmpty) {
      return const Center(child: Text('No jobs applied yet'));
    }

    // Extract unique telecallers
    final telecallers = <String>{'All'};
    for (var job in allJobs) {
      if (job['assignedTelecaller'] != null) {
        telecallers.add(job['assignedTelecaller']);
      }
    }

    // Filter jobs
    final filteredJobs = _selectedTelecaller == 'All'
        ? allJobs
        : allJobs.where((job) => job['assignedTelecaller'] == _selectedTelecaller).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Filter by Telecaller:', 
                style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedTelecaller,
                  isExpanded: true,
                  underline: Container(height: 1, color: AppColors.primary),
                  items: telecallers.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTelecaller = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredJobs.length,
            itemBuilder: (context, index) {
              final job = filteredJobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job['jobTitle'] ?? 'Unknown Job',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              job['jobId'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.business, 'Transporter:', job['transporterName']),
                      _buildInfoRow(Icons.person_outline, 'Assigned To:', job['assignedTelecaller']),
                      _buildInfoRow(Icons.calendar_today, 'Applied:', _formatDate(job['appliedDate'])),
                      
                      if (job['feedback'] != null || job['matchStatus'] != null) ...[
                        const Divider(height: 24),
                        const Text(
                          'Latest Feedback:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (job['matchStatus'] != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job['matchStatus']),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job['matchStatus'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusTextColor(job['matchStatus']),
                              ),
                            ),
                          ),
                        if (job['feedback'] != null)
                          Text(
                            job['feedback'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (job['notes'] != null && job['notes'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              job['notes'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (job['feedbackBy'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'By: ${job['feedbackBy']} on ${_formatDate(job['feedbackDate'])}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _selectedJobId = 'All';

  Widget _buildCallHistoryTab() {
    final allHistory = _driverData!['callHistory'] as List;

    if (allHistory.isEmpty) {
      return const Center(child: Text('No call history found'));
    }

    // Extract unique Job IDs
    final jobIds = <String>{'All'};
    for (var call in allHistory) {
      if (call['jobId'] != null && call['jobId'].toString().isNotEmpty) {
        jobIds.add(call['jobId']);
      }
    }

    // Filter history
    final filteredHistory = _selectedJobId == 'All'
        ? allHistory
        : allHistory.where((call) => call['jobId'] == _selectedJobId).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Filter by Job ID:', 
                style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedJobId,
                  isExpanded: true,
                  underline: Container(height: 1, color: AppColors.primary),
                  items: jobIds.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedJobId = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredHistory.length,
            itemBuilder: (context, index) {
              final call = filteredHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.call, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    call['callerName'] ?? 'Unknown Caller',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Job: ${call['jobTitle'] ?? call['jobId'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(call['callTime']),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (call['feedback'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            call['feedback'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: call['matchStatus'] != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(call['matchStatus']),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            call['matchStatus'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusTextColor(call['matchStatus']),
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
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
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey.shade100;
    final s = status.toLowerCase();
    if (s.contains('selected') || s.contains('match')) return Colors.green.shade50;
    if (s.contains('rejected') || s.contains('not')) return Colors.red.shade50;
    return Colors.yellow.shade50;
  }

  Color _getStatusTextColor(String? status) {
    if (status == null) return Colors.grey.shade700;
    final s = status.toLowerCase();
    if (s.contains('selected') || s.contains('match')) return Colors.green.shade700;
    if (s.contains('rejected') || s.contains('not')) return Colors.red.shade700;
    return Colors.yellow.shade800;
  }
}
