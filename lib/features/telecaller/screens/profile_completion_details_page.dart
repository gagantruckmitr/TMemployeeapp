import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/state_code_mapper.dart';

class ProfileCompletionDetailsPage extends StatefulWidget {
  final DriverContact contact;
  final bool isTransporter;

  const ProfileCompletionDetailsPage({
    super.key,
    required this.contact,
    this.isTransporter = false,
  });

  @override
  State<ProfileCompletionDetailsPage> createState() =>
      _ProfileCompletionDetailsPageState();
}

class _ProfileCompletionDetailsPageState
    extends State<ProfileCompletionDetailsPage>
    with SingleTickerProviderStateMixin {
  ProfileCompletion? _detailedCompletion;
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String? _userRole; // Store the user role from API

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadDetailedProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetailedProfileData() async {
    try {
      print('🔵 Loading profile details for user ID: ${widget.contact.id}');
      final detailed = await ApiService.getProfileCompletionDetails(
        widget.contact.id,
      );

      if (mounted) {
        setState(() {
          // If detailed data is available and has document values, use it
          if (detailed != null && detailed.documentValues.isNotEmpty) {
            print(
              '✅ Using detailed API data with ${detailed.documentValues.length} values',
            );
            _detailedCompletion = detailed;
          } else if (detailed != null && detailed.documentStatus.isNotEmpty) {
            print('⚠️ API returned status but no values, using it anyway');
            _detailedCompletion = detailed;
          } else {
            print('❌ No detailed data, using fallback');
            _detailedCompletion = _createFallbackCompletion();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile details: $e');
      if (mounted) {
        setState(() {
          _detailedCompletion = _createFallbackCompletion();
          _isLoading = false;
        });
      }
    }
  }

  ProfileCompletion _createFallbackCompletion() {
    final percentage = widget.contact.profileCompletion?.percentage ?? 0;

    // Create basic field mapping with available contact data (excluding system fields)
    final fieldValues = <String, String?>{
      'name': widget.contact.name,
      'email': null,
      'city': null,
      'sex': null,
      'vehicle_type': null,
      'father_name': null,
      'images': null,
      'address': null,
      'dob': null,
      'type_of_license': null,
      'driving_experience': null,
      'highest_education': null,
      'license_number': null,
      'expiry_date_of_license': null,
      'expected_monthly_income': null,
      'current_monthly_income': null,
      'marital_status': null,
      'preferred_location': null,
      'aadhar_number': null,
      'aadhar_photo': null,
      'driving_license': null,
      'previous_employer': null,
      'job_placement': null,
    };

    final documentStatus = <String, bool>{};
    final documentValues = <String, String?>{};

    // Set status based on whether value exists
    fieldValues.forEach((field, value) {
      final hasValue = value != null && value.isNotEmpty;
      documentStatus[field] = hasValue;
      documentValues[field] = value;
    });

    return ProfileCompletion(
      percentage: percentage,
      documentStatus: documentStatus,
      documentValues: documentValues,
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 80) {
      return const Color(0xFF4CAF50);
    } else if (percentage >= 50) {
      return const Color(0xFFFFC107);
    } else {
      return const Color(0xFFF44336);
    }
  }

  List<DocumentItem> _getDriverDocuments() {
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final docs = completion?.documentStatus ?? {};
    final values = completion?.documentValues ?? {};

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 _getDriverDocuments() CALLED');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Use the flag passed from the calling page, or check document keys as fallback
    final allKeys = docs.keys.map((k) => k.toLowerCase()).toList();
    final isTransporterFromKeys =
        allKeys.contains('transport_name') ||
        allKeys.contains('pan_number') ||
        allKeys.contains('fleet_size') ||
        allKeys.contains('gst_certificate');

    final isTransporter = widget.isTransporter || isTransporterFromKeys;

    print(
      '🔍 widget.isTransporter (from constructor) = ${widget.isTransporter}',
    );
    print(
      '🔍 isTransporterFromKeys (detected from API) = $isTransporterFromKeys',
    );
    print('🔍 isTransporter (FINAL DECISION) = $isTransporter');
    print('🔍 All document keys from API: ${docs.keys.toList()}');
    print('🔍 All keys (lowercase): $allKeys');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    if (isTransporter) {
      // Return transporter-specific fields
      return [
        DocumentItem('Name', 'name', docs['name'] ?? false, values['name']),
        DocumentItem('Email', 'email', docs['email'] ?? false, values['email']),
        DocumentItem(
          'Mobile',
          'mobile',
          docs['mobile'] ?? false,
          values['mobile'],
        ),
        DocumentItem(
          'Transport Name',
          'transport_name',
          docs['transport_name'] ?? false,
          values['transport_name'],
        ),
        DocumentItem(
          'Year of Establishment',
          'year_of_establishment',
          docs['year_of_establishment'] ?? false,
          values['year_of_establishment'],
        ),
        DocumentItem(
          'Fleet Size',
          'fleet_size',
          docs['fleet_size'] ?? false,
          values['fleet_size'],
        ),
        DocumentItem(
          'Operational Segment',
          'operational_segment',
          docs['operational_segment'] ?? false,
          values['operational_segment'],
        ),
        DocumentItem(
          'Average KM',
          'average_km',
          docs['average_km'] ?? false,
          values['average_km'],
        ),
        DocumentItem('City', 'city', docs['city'] ?? false, values['city']),
        DocumentItem('State', 'state', docs['state'] ?? false, values['state']),
        DocumentItem(
          'Profile Photo',
          'images',
          docs['images'] ?? false,
          values['images'],
        ),
        DocumentItem(
          'Address',
          'address',
          docs['address'] ?? false,
          values['address'],
        ),
        DocumentItem(
          'PAN Number',
          'pan_number',
          docs['pan_number'] ?? false,
          values['pan_number'],
        ),
        DocumentItem(
          'PAN Image',
          'pan_image',
          docs['pan_image'] ?? false,
          values['pan_image'],
        ),
        DocumentItem(
          'GST Certificate',
          'gst_certificate',
          docs['gst_certificate'] ?? false,
          values['gst_certificate'],
        ),
      ];
    }

    // Return driver-specific fields (23 records total)
    return [
      DocumentItem(
        'Basic Information',
        'name',
        docs['name'] ?? false,
        values['name'],
      ),
      DocumentItem('Email', 'email', docs['email'] ?? false, values['email']),
      DocumentItem('Mobile', 'mobile', docs['mobile'] ?? false, values['mobile']),
      DocumentItem('State', 'state', docs['state'] ?? false, values['state']),
      DocumentItem(
        'Vehicle Type',
        'vehicle_type',
        docs['vehicle_type'] ?? false,
        values['vehicle_type'],
      ),
      DocumentItem(
        'Father Name',
        'father_name',
        docs['father_name'] ?? false,
        values['father_name'],
      ),
      DocumentItem(
        'Profile Photo',
        'images',
        docs['images'] ?? false,
        values['images'],
      ),
      DocumentItem(
        'Address',
        'address',
        docs['address'] ?? false,
        values['address'],
      ),
      DocumentItem('Date of Birth', 'dob', docs['dob'] ?? false, values['dob']),
      DocumentItem(
        'License Type',
        'type_of_license',
        docs['type_of_license'] ?? false,
        values['type_of_license'],
      ),
      DocumentItem(
        'Driving Experience (Yrs)',
        'driving_experience',
        docs['driving_experience'] ?? false,
        values['driving_experience'],
      ),
      DocumentItem(
        'Education',
        'highest_education',
        docs['highest_education'] ?? false,
        values['highest_education'],
      ),
      DocumentItem(
        'License Number',
        'license_number',
        docs['license_number'] ?? false,
        values['license_number'],
      ),
      DocumentItem(
        'License Expiry',
        'expiry_date_of_license',
        docs['expiry_date_of_license'] ?? false,
        values['expiry_date_of_license'],
      ),
      DocumentItem(
        'Expected Income',
        'expected_monthly_income',
        docs['expected_monthly_income'] ?? false,
        values['expected_monthly_income'],
      ),
      DocumentItem(
        'Current Income',
        'current_monthly_income',
        docs['current_monthly_income'] ?? false,
        values['current_monthly_income'],
      ),
      DocumentItem(
        'Marital Status',
        'marital_status',
        docs['marital_status'] ?? false,
        values['marital_status'],
      ),
      DocumentItem(
        'Preferred Location',
        'preferred_location',
        docs['preferred_location'] ?? false,
        values['preferred_location'],
      ),
      DocumentItem(
        'Aadhar Number',
        'aadhar_number',
        docs['aadhar_number'] ?? false,
        values['aadhar_number'],
      ),
      DocumentItem(
        'Aadhar Photo',
        'aadhar_photo',
        docs['aadhar_photo'] ?? false,
        values['aadhar_photo'],
      ),
      DocumentItem(
        'Driving License',
        'driving_license',
        docs['driving_license'] ?? false,
        values['driving_license'],
      ),
      DocumentItem(
        'Previous Employer',
        'previous_employer',
        docs['previous_employer'] ?? false,
        values['previous_employer'],
      ),
      DocumentItem(
        'Job Placement',
        'job_placement',
        docs['job_placement'] ?? false,
        values['job_placement'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🚨🚨🚨 BUILD METHOD CALLED 🚨🚨🚨');
    print('🚨 isTransporter flag = ${widget.isTransporter}');
    print('🚨 Contact name = ${widget.contact.name}');
    print('🚨 Contact ID = ${widget.contact.id}');
    print('═══════════════════════════════════════════════════════');
    print('');

    // Calculate completion based on the displayed documents list ONLY
    // This ensures count matches the list shown to user
    final documents = _getDriverDocuments();
    final totalDocs = documents.length;
    
    // Count completed docs by checking actual values, not just API status
    // This handles special cases like mobile (from contact) and state (from TMID)
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final values = completion?.documentValues ?? {};
    
    int completedDocs = 0;
    for (var doc in documents) {
      var value = values[doc.fieldName];
      
      // Special handling for mobile - fallback to contact phone
      if (doc.fieldName == 'mobile' && (value == null || value.isEmpty)) {
        value = widget.contact.phoneNumber;
      }
      
      // Special handling for state - extract from TMID
      if (doc.fieldName == 'state' && (value == null || value.isEmpty)) {
        value = StateCodeMapper.getStateName(widget.contact.tmid);
      }
      
      // Check if value is valid
      if (_isValidValue(value)) {
        completedDocs++;
      }
    }

    // Recalculate percentage from visible docs
    // This ensures displayed percentage matches the displayed fraction (X/Y Records)
    final percentage = totalDocs > 0
        ? ((completedDocs / totalDocs) * 100).round()
        : 0;

    final progressColor = _getProgressColor(percentage);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Profile Completion',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Section
                _buildProfileSection(
                  percentage,
                  progressColor,
                  completedDocs,
                  totalDocs,
                ),

                // Tab Navigation
                _buildTabNavigation(),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonalDetailTab(),
                      _buildDrivingDetailsTab(),
                      _buildUploadedDocumentsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSection(
    int percentage,
    Color progressColor,
    int completedDocs,
    int totalDocs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Circular Progress with Profile Image
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Progress Circle (120x120)
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),

              // Inner Profile Image/Avatar (100x100)
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B82F6),
                ),
                child: ClipOval(
                  child:
                      widget.contact.profilePicture != null &&
                          widget.contact.profilePicture!.isNotEmpty
                      ? Image.network(
                          widget.contact.profilePicture!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            // Show first letter if image fails to load
                            return Container(
                              color: const Color(0xFF3B82F6),
                              child: Center(
                                child: Text(
                                  widget.contact.name.isNotEmpty
                                      ? widget.contact.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF3B82F6),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 3,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            widget.contact.name.isNotEmpty
                                ? widget.contact.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),

              // Percentage Badge (Bottom-right)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TM ID
          Text(
            widget.contact.tmid,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          // Completion Status
          Text(
            '$completedDocs/$totalDocs Records',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final docs = completion?.documentStatus ?? {};
    final allKeys = docs.keys.map((k) => k.toLowerCase()).toList();
    final isTransporterFromKeys =
        allKeys.contains('transport_name') ||
        allKeys.contains('pan_number') ||
        allKeys.contains('fleet_size');
    final isTransporter = widget.isTransporter || isTransporterFromKeys;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem('Personal\nDetail', 0),
          _buildTabItem(
            isTransporter ? 'Fleet\nDetails' : 'Driving\nDetails',
            1,
          ),
          _buildTabItem('Uploaded\nDocs', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalDetailTab() {
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final values = completion?.documentValues ?? {};
    final docs = completion?.documentStatus ?? {};

    // Check if transporter
    final allKeys = docs.keys.map((k) => k.toLowerCase()).toList();
    final isTransporterFromKeys =
        allKeys.contains('transport_name') ||
        allKeys.contains('pan_number') ||
        allKeys.contains('fleet_size');
    final isTransporter = widget.isTransporter || isTransporterFromKeys;

    // Get missing documents
    final missingDocs = docs.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    List<Map<String, dynamic>> personalFields;

    if (isTransporter) {
      // Transporter personal fields
      personalFields = [
        {'key': 'name', 'label': 'Name', 'icon': Icons.person_outline},
        {'key': 'email', 'label': 'Email', 'icon': Icons.email_outlined},
        {'key': 'mobile', 'label': 'Mobile', 'icon': Icons.phone_outlined},
        {'key': 'address', 'label': 'Address', 'icon': Icons.home_outlined},
        {
          'key': 'state',
          'label': 'State',
          'icon': Icons.map_outlined,
          'useStateFromTMID': true,
        },
      ];
    } else {
      // Driver personal fields
      personalFields = [
        {'key': 'name', 'label': 'Full Name', 'icon': Icons.person_outline},
        {'key': 'email', 'label': 'Email', 'icon': Icons.email_outlined},
        {'key': 'mobile', 'label': 'Mobile', 'icon': Icons.phone_outlined},
        {
          'key': 'father_name',
          'label': 'Father Name',
          'icon': Icons.family_restroom_outlined,
        },
        {
          'key': 'dob',
          'label': 'DOB',
          'icon': Icons.cake_outlined,
          'isDate': true,
        },
        {'key': 'sex', 'label': 'Gender', 'icon': Icons.wc_outlined},
        {
          'key': 'marital_status',
          'label': 'Marital Status',
          'icon': Icons.favorite_outline,
        },
        {
          'key': 'highest_education',
          'label': 'Highest Education',
          'icon': Icons.school_outlined,
        },
        {'key': 'address', 'label': 'Address', 'icon': Icons.home_outlined},
        {'key': 'city', 'label': 'City', 'icon': Icons.location_city_outlined},
        {
          'key': 'state',
          'label': 'State',
          'icon': Icons.map_outlined,
          'useStateFromTMID': true,
        },
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Missing documents banner
          // if (missingDocs.isNotEmpty)
          //   Container(
          //     margin: const EdgeInsets.only(bottom: 16),
          //     padding: const EdgeInsets.all(16),
          //     decoration: BoxDecoration(
          //       color: const Color(0xFFFEF2F2),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: const Color(0xFFFCA5A5)),
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             const Icon(
          //               Icons.warning_amber_rounded,
          //               color: Color(0xFFEF4444),
          //               size: 20,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               'Missing Documents (${missingDocs.length})',
          //               style: const TextStyle(
          //                 color: Color(0xFFEF4444),
          //                 fontSize: 14,
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         Wrap(
          //           spacing: 6,
          //           runSpacing: 6,
          //           children: missingDocs.map((doc) {
          //             return Container(
          //               padding: const EdgeInsets.symmetric(
          //                 horizontal: 8,
          //                 vertical: 4,
          //               ),
          //               decoration: BoxDecoration(
          //                 color: Colors.white,
          //                 borderRadius: BorderRadius.circular(6),
          //                 border: Border.all(color: const Color(0xFFFCA5A5)),
          //               ),
          //               child: Text(
          //                 doc.replaceAll('_', ' ').toUpperCase(),
          //                 style: const TextStyle(
          //                   color: Color(0xFFEF4444),
          //                   fontSize: 11,
          //                   fontWeight: FontWeight.w500,
          //                 ),
          //               ),
          //             );
          //           }).toList(),
          //         ),
          //       ],
          //     ),
          //   ),

          // Personal fields
          ...personalFields.map((field) {
            final useStateFromTMID =
                field['useStateFromTMID'] as bool? ?? false;
            String? stateValue;

            if (useStateFromTMID && field['key'] == 'state') {
              // Extract state name from TMID using StateCodeMapper
              stateValue = StateCodeMapper.getStateName(widget.contact.tmid);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInfoCard(
                field['key'] as String,
                field['label'] as String,
                field['icon'] as IconData,
                useStateFromTMID && stateValue != null
                    ? {...values, 'state': stateValue}
                    : values,
                isDate: field['isDate'] as bool? ?? false,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDrivingDetailsTab() {
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final values = completion?.documentValues ?? {};
    final docs = completion?.documentStatus ?? {};

    // Check if transporter
    final allKeys = docs.keys.map((k) => k.toLowerCase()).toList();
    final isTransporterFromKeys =
        allKeys.contains('transport_name') ||
        allKeys.contains('pan_number') ||
        allKeys.contains('fleet_size');
    final isTransporter = widget.isTransporter || isTransporterFromKeys;

    // For transporters, show Fleet Details
    if (isTransporter) {
      final fleetFields = [
        {
          'key': 'transport_name',
          'label': 'Transport Name',
          'icon': Icons.business_outlined,
        },
        {
          'key': 'year_of_establishment',
          'label': 'Year of Establishment',
          'icon': Icons.calendar_today_outlined,
        },
        {
          'key': 'fleet_size',
          'label': 'Fleet Size',
          'icon': Icons.local_shipping_outlined,
        },
        {
          'key': 'operational_segment',
          'label': 'Operational Segment',
          'icon': Icons.category_outlined,
        },
        {
          'key': 'average_km',
          'label': 'Average KM',
          'icon': Icons.speed_outlined,
        },
        {'key': 'city', 'label': 'City', 'icon': Icons.location_city_outlined},
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: fleetFields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInfoCard(
                field['key'] as String,
                field['label'] as String,
                field['icon'] as IconData,
                values,
              ),
            );
          }).toList(),
        ),
      );
    }

    // Driver driving fields
    final drivingFields = [
      {
        'key': 'vehicle_type',
        'label': 'Vehicle Type',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'key': 'driving_experience',
        'label': 'Driving Experience (Yrs)',
        'icon': Icons.speed_outlined,
      },
      {
        'key': 'preferred_location',
        'label': 'Preferred Location',
        'icon': Icons.location_on_outlined,
      },
      {
        'key': 'current_monthly_income',
        'label': 'Current Monthly Income',
        'icon': Icons.currency_rupee,
      },
      {
        'key': 'expected_monthly_income',
        'label': 'Expected Monthly Income',
        'icon': Icons.trending_up_outlined,
      },
      {
        'key': 'type_of_license',
        'label': 'Type of License',
        'icon': Icons.badge_outlined,
      },
      {
        'key': 'previous_employer',
        'label': 'Previous Employer',
        'icon': Icons.work_outline,
      },
      {
        'key': 'job_placement',
        'label': 'Job Placement',
        'icon': Icons.work_history_outlined,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: drivingFields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInfoCard(
              field['key'] as String,
              field['label'] as String,
              field['icon'] as IconData,
              values,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadedDocumentsTab() {
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final values = completion?.documentValues ?? {};
    final docs = completion?.documentStatus ?? {};

    // Check if transporter
    final allKeys = docs.keys.map((k) => k.toLowerCase()).toList();
    final isTransporterFromKeys =
        allKeys.contains('transport_name') ||
        allKeys.contains('pan_number') ||
        allKeys.contains('fleet_size');
    final isTransporter = widget.isTransporter || isTransporterFromKeys;

    if (isTransporter) {
      // Transporter documents
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildInfoCard(
              'pan_number',
              'PAN Number',
              Icons.credit_card_outlined,
              values,
            ),
            const SizedBox(height: 12),
            _buildDocumentPhotoCard(
              'pan_image',
              'PAN Image',
              Icons.photo_outlined,
              values,
            ),
            const SizedBox(height: 12),
            _buildDocumentPhotoCard(
              'gst_certificate',
              'GST Certificate',
              Icons.description_outlined,
              values,
            ),
            const SizedBox(height: 12),
            _buildDocumentPhotoCard(
              'images',
              'Profile Photo',
              Icons.photo_library_outlined,
              values,
            ),
          ],
        ),
      );
    }

    // Driver documents
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            'aadhar_number',
            'Aadhar Number',
            Icons.credit_card_outlined,
            values,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            'aadhar_photo',
            'Uploaded Aadhar Photo',
            Icons.photo_outlined,
            values,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'license_number',
            'License Number',
            Icons.drive_eta_outlined,
            values,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'expiry_date_of_license',
            'Expiry Date of License',
            Icons.event_outlined,
            values,
            isDate: true,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            'driving_license',
            'Uploaded Driving License Photo',
            Icons.photo_library_outlined,
            values,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String key,
    String label,
    IconData icon,
    Map<String, String?> values, {
    bool isDate = false,
  }) {
    var value = values[key];

    // Fallback for mobile if missing in values but present in contact
    if (key == 'mobile' && (value == null || value.isEmpty)) {
      value = widget.contact.phoneNumber;
    }

    final hasValue = _isValidValue(value);

    String displayValue = 'N/A';
    // Logic to masking mobile number
    final isMobile = key == 'mobile';

    if (hasValue) {
      if (isDate) {
        displayValue = _formatDate(value.toString());
      } else if (isMobile) {
        // Mask mobile number for both driver and transporters: 63****6798
        final mobile = value.toString();
        if (mobile.length >= 10) {
          displayValue =
              '${mobile.substring(0, 2)}******${mobile.substring(mobile.length - 2)}';
        } else {
          displayValue = mobile;
        }
      } else {
        displayValue = value.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? const Color(0xFFE5E7EB) : const Color(0xFFFEE2E2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasValue
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : const Color(0xFFEF4444).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: hasValue
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFEF4444),
            ),
          ),

          const SizedBox(width: 14),

          // Label and Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (isMobile && hasValue)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mobile number copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayValue,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasValue
                          ? const Color(0xFF111827)
                          : const Color(0xFFF87171),
                    ),
                    maxLines: label == 'Address' ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Status Icon
          if (hasValue)
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 18,
            )
          else
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
        ],
      ),
    );
  }

  Widget _buildDocumentPhotoCard(
    String key,
    String label,
    IconData icon,
    Map<String, String?> values,
  ) {
    final value = values[key];
    final hasValue = _isValidValue(value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? const Color(0xFFE5E7EB) : const Color(0xFFFEE2E2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasValue
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: hasValue
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFEF4444),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Icon(
                hasValue ? Icons.check_circle : Icons.error_outline,
                size: 20,
                color: hasValue
                    ? const Color(0xFF34D399)
                    : const Color(0xFFEF4444),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Photo Preview or N/A Message
          if (hasValue)
            GestureDetector(
              onTap: () => _showFullImageDialog(value.toString()),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    value.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Color(0xFFF87171),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No document uploaded',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFF87171),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 40,
                  maxHeight: MediaQuery.of(context).size.height - 100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.black, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidValue(dynamic value) {
    if (value == null) return false;

    final String stringValue = value.toString().trim();

    if (stringValue.isEmpty) return false;
    if (stringValue.toLowerCase() == 'null') return false;
    if (stringValue.toLowerCase() == 'n/a') return false;

    return true;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class DocumentItem {
  final String displayName;
  final String fieldName;
  final bool isPresent;
  final String? value;

  DocumentItem(this.displayName, this.fieldName, this.isPresent, this.value);
}
