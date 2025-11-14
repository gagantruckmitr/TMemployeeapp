import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  final String initialFilter;

  const ContactsScreen({
    super.key,
    this.initialFilter = 'All',
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'All Jobs';
  late TabController _tabController;
  final TextEditingController _remarkController = TextEditingController();

  final List<String> _filters = [
    'All Jobs',
    'Approved Jobs',
    'Pending Jobs',
    'Inactive Jobs',
    'Expired Jobs'
  ];

  // Enhanced job data with all required fields
  final List<Map<String, dynamic>> _allJobs = [
    {
      'status': 'Approved',
      'tmId': 'TM234TRUP345',
      'name': 'Gupta Logistics',
      'jobId': 'JB001234',
      'jobTitle': 'Long Distance Truck Driver',
      'jobLocation': 'Pune, Maharashtra',
      'driversRequired': 3,
      'route': 'Pune → Ahmedabad',
      'salary': '₹45,000',
      'totalApplications': 12,
      'lastDate': '2024-12-15',
      'requiredExperience': '3-5 years',
      'salaryRange': '₹40,000 - ₹50,000',
      'typeOfLoad': 'General Cargo',
      'contactPerson': 'Rajesh Gupta',
      'contactNumber': '+91 98765 43210',
      'lastDateToApply': '2024-12-15',
    },
    {
      'status': 'Approved',
      'tmId': 'TM874TRUP998',
      'name': 'Bansal Transport',
      'jobId': 'JB001235',
      'jobTitle': 'Regional Delivery Driver',
      'jobLocation': 'Delhi, NCR',
      'driversRequired': 2,
      'route': 'Delhi → Jaipur',
      'salary': '₹35,000',
      'totalApplications': 8,
      'lastDate': '2024-11-30',
      'requiredExperience': '2-4 years',
      'salaryRange': '₹30,000 - ₹40,000',
      'typeOfLoad': 'Consumer Goods',
      'contactPerson': 'Amit Bansal',
      'contactNumber': '+91 98765 43211',
      'lastDateToApply': '2024-11-30',
    },
    {
      'status': 'Pending',
      'tmId': 'TM567TRUP234',
      'name': 'Sharma Freight',
      'jobId': 'JB001236',
      'jobTitle': 'Interstate Cargo Driver',
      'jobLocation': 'Mumbai, Maharashtra',
      'driversRequired': 4,
      'route': 'Mumbai → Indore',
      'salary': '₹55,000',
      'totalApplications': 15,
      'lastDate': '2024-10-31',
      'requiredExperience': '5+ years',
      'salaryRange': '₹50,000 - ₹60,000',
      'typeOfLoad': 'Heavy Machinery',
      'contactPerson': 'Vikram Sharma',
      'contactNumber': '+91 98765 43212',
      'lastDateToApply': '2024-10-31',
    },
    {
      'status': 'Inactive',
      'tmId': 'TM123TRUP456',
      'name': 'Kumar Transport',
      'jobId': 'JB001237',
      'jobTitle': 'City Delivery Driver',
      'jobLocation': 'Chennai, Tamil Nadu',
      'driversRequired': 1,
      'route': 'Chennai → Bangalore',
      'salary': '₹28,000',
      'totalApplications': 5,
      'lastDate': '2024-12-20',
      'requiredExperience': '1-3 years',
      'salaryRange': '₹25,000 - ₹32,000',
      'typeOfLoad': 'Parcels & Documents',
      'contactPerson': 'Suresh Kumar',
      'contactNumber': '+91 98765 43213',
      'lastDateToApply': '2024-12-20',
    },
    {
      'status': 'Inactive',
      'tmId': 'TM789TRUP123',
      'name': 'Patel Logistics',
      'jobId': 'JB001238',
      'jobTitle': 'Freight Transport Driver',
      'jobLocation': 'Kolkata, West Bengal',
      'driversRequired': 2,
      'route': 'Kolkata → Bhubaneswar',
      'salary': '₹32,000',
      'totalApplications': 3,
      'lastDate': '2024-11-25',
      'requiredExperience': '2-5 years',
      'salaryRange': '₹28,000 - ₹35,000',
      'typeOfLoad': 'Industrial Goods',
      'contactPerson': 'Kiran Patel',
      'contactNumber': '+91 98765 43214',
      'lastDateToApply': '2024-11-25',
    },
    {
      'status': 'Inactive',
      'tmId': 'TM456TRUP789',
      'name': 'Singh Transport',
      'jobId': 'JB001239',
      'jobTitle': 'Highway Cargo Driver',
      'jobLocation': 'Hyderabad, Telangana',
      'driversRequired': 3,
      'route': 'Hyderabad → Vijayawada',
      'salary': '₹38,000',
      'totalApplications': 9,
      'lastDate': '2024-12-10',
      'requiredExperience': '2-4 years',
      'salaryRange': '₹35,000 - ₹42,000',
      'typeOfLoad': 'Agricultural Products',
      'contactPerson': 'Harpreet Singh',
      'contactNumber': '+91 98765 43215',
      'lastDateToApply': '2024-12-10',
    },
    {
      'status': 'Expired',
      'tmId': 'TM321TRUP654',
      'name': 'Rajesh Movers',
      'jobId': 'JB001240',
      'jobTitle': 'Local Delivery Driver',
      'jobLocation': 'Bangalore, Karnataka',
      'driversRequired': 1,
      'route': 'Bangalore → Mysore',
      'salary': '₹25,000',
      'totalApplications': 7,
      'lastDate': '2024-11-28',
      'requiredExperience': '1-2 years',
      'salaryRange': '₹22,000 - ₹28,000',
      'typeOfLoad': 'Household Items',
      'contactPerson': 'Rajesh Mohan',
      'contactNumber': '+91 98765 43216',
      'lastDateToApply': '2024-11-28',
    },
    {
      'status': 'Approved',
      'tmId': 'TM987TRUP321',
      'name': 'Metro Logistics',
      'jobId': 'JB001241',
      'jobTitle': 'Express Delivery Driver',
      'jobLocation': 'Ahmedabad, Gujarat',
      'driversRequired': 2,
      'route': 'Ahmedabad → Surat',
      'salary': '₹42,000',
      'totalApplications': 18,
      'lastDate': '2024-10-15',
      'requiredExperience': '3-6 years',
      'salaryRange': '₹38,000 - ₹45,000',
      'typeOfLoad': 'Electronics & Gadgets',
      'contactPerson': 'Deepak Shah',
      'contactNumber': '+91 98765 43217',
      'lastDateToApply': '2024-10-15',
    },
  ];

  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'All Jobs') {
      print('Showing all jobs: ${_allJobs.length}');
      return _allJobs;
    }
    String status = _selectedFilter.replaceAll(' Jobs', '');
    final filtered = _allJobs.where((job) => job['status'] == status).toList();
    print(
        'Filter: $_selectedFilter, Status: $status, Found: ${filtered.length} jobs');
    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF4CAF50); // Green
      case 'Approved':
        return const Color(0xFF4CAF50); // Green
      case 'Inactive':
        return const Color(0xFF9E9E9E); // Grey
      case 'Pending':
        return const Color(0xFFFFC107); // Yellow
      case 'Expired':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  Color _getTabColor(String filter) {
    if (filter.contains('Approved')) return const Color(0xFF4CAF50);
    if (filter.contains('Pending')) return const Color(0xFFFFC107);
    if (filter.contains('Inactive')) return const Color(0xFF9E9E9E);
    if (filter.contains('Expired')) return const Color(0xFFF44336);
    return const Color(0xFF2196F3);
  }

  void _showJobDescriptionModal(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobDescriptionModal(
        job: job,
        remarkController: _remarkController,
      ),
    );
  }

  void _makeCall(String companyName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $companyName...'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _changeJobStatus(Map<String, dynamic> job, String newStatus) {
    setState(() {
      job['status'] = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job status changed to $newStatus'),
        backgroundColor: _getStatusColor(newStatus),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);

    // Set initial filter based on widget parameter
    if (widget.initialFilter != 'All') {
      String filterName = '${widget.initialFilter} Jobs';
      if (_filters.contains(filterName)) {
        _selectedFilter = filterName;
        int index = _filters.indexOf(filterName);
        _tabController.index = index;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print filters to console
    print('Filters: $_filters');
    print('Selected filter: $_selectedFilter');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF212121)),
                  ),
                  const Text(
                    'Jobs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Tab Menu
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  final tabColor = _getTabColor(filter);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tabColor.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color:
                              isSelected ? tabColor : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: tabColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected ? tabColor : const Color(0xFF757575),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Job Cards Section
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = _filteredJobs[index];
                  return ModernJobCard(
                    job: job,
                    onSeeMore: () => _showJobDescriptionModal(job),
                    onCall: () => _makeCall(job['name']),
                    onStatusChange: (newStatus) =>
                        _changeJobStatus(job, newStatus),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onSeeMore;
  final VoidCallback onCall;
  final Function(String) onStatusChange;

  const ModernJobCard({
    super.key,
    required this.job,
    required this.onSeeMore,
    required this.onCall,
    required this.onStatusChange,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF4CAF50); // Green
      case 'Approved':
        return const Color(0xFF4CAF50); // Green
      case 'Inactive':
        return const Color(0xFF9E9E9E); // Grey
      case 'Pending':
        return const Color(0xFFFFC107); // Yellow
      case 'Expired':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'Approved':
        return 'Active';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(job['status']);
    final displayStatus = _getDisplayStatus(job['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section - Company Name, TM ID and Status
          Row(
            children: [
              // Profile Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Company Name and TM ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job['tmId'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge (Upper Right Corner)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Job Details Grid - Clean and Properly Aligned
          Column(
            children: [
              // Row 1: Job ID and Route
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Job ID', job['jobId']),
                  ),
                  Expanded(
                    child: _buildInfoItem('Route', job['route']),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Drivers Required and Salary
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                        'Drivers Required', '${job['driversRequired']}'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Salary', job['salary']),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Total Applications and Last Date
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                        'Total Applications', '${job['totalApplications']}'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Last Date', job['lastDate']),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bottom Section - Buttons
          Row(
            children: [
              // Call Button (Small Rectangular)
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: onCall,
                  icon: const Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const Spacer(),

              // See More Button with Underline
              TextButton(
                onPressed: onSeeMore,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2196F3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text(
                  'See More',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF757575),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class JobDescriptionModal extends StatelessWidget {
  final Map<String, dynamic> job;
  final TextEditingController remarkController;

  const JobDescriptionModal({
    super.key,
    required this.job,
    required this.remarkController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Job Description',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow('TM ID', job['tmId']),
                  _buildDivider(),
                  _buildDetailRow('Job ID', job['jobId']),
                  _buildDivider(),
                  _buildDetailRow('Job Title', job['jobTitle']),
                  _buildDivider(),
                  _buildDetailRow('Job Location', job['jobLocation']),
                  _buildDivider(),
                  _buildDetailRow('Route', job['route']),
                  _buildDivider(),
                  _buildDetailRow(
                      'Required Experience', job['requiredExperience']),
                  _buildDivider(),
                  _buildDetailRow('Salary Range', job['salaryRange']),
                  _buildDivider(),
                  _buildDetailRow('Type of Load', job['typeOfLoad']),
                  _buildDivider(),
                  _buildDetailRow(
                      'Total Applications', '${job['totalApplications']}'),
                  _buildDivider(),
                  _buildDetailRow(
                      'Drivers Required', '${job['driversRequired']}'),
                  _buildDivider(),
                  _buildDetailRow('Contact Person', job['contactPerson']),
                  _buildDivider(),
                  _buildDetailRow('Contact Number', job['contactNumber']),
                  _buildDivider(),
                  _buildDetailRow('Last Date to Apply', job['lastDateToApply']),
                  _buildDivider(),
                  _buildDetailRow('Status', job['status']),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Remark Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Remark:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: remarkController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type your remark here…',
                      hintStyle: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (remarkController.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Remark submitted successfully'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                        Navigator.pop(context);
                        remarkController.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a remark'),
                            backgroundColor: Color(0xFFF44336),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF212121),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF0F0F0),
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }
}
