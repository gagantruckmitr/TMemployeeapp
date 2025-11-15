import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileCompletionDetailsScreen extends StatefulWidget {
  final String userName;
  final String tmId;
  final int completionPercentage;
  final Map<String, dynamic> profileData;

  const ProfileCompletionDetailsScreen({
    super.key,
    required this.userName,
    required this.tmId,
    required this.completionPercentage,
    required this.profileData,
  });

  @override
  State<ProfileCompletionDetailsScreen> createState() =>
      _ProfileCompletionDetailsScreenState();
}

class _ProfileCompletionDetailsScreenState
    extends State<ProfileCompletionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Calculate completion status using proper validation
  int get _completedFields {
    int count = 0;
    _getAllFields().forEach((field) {
      final value = widget.profileData[field['key']];
      if (_isValidValue(value)) {
        count++;
      }
    });
    return count;
  }

  int get _totalFields => 23;

  Color get _progressColor {
    return widget.completionPercentage >= 100
        ? const Color(0xFF34D399) // Green
        : const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
      body: Column(
        children: [
          // Profile Section
          _buildProfileSection(),

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

  Widget _buildProfileSection() {
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
                  value: widget.completionPercentage / 100,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              ),

              // Inner Profile Image/Avatar (100x100)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.profileData['profile_photo'] != null
                      ? Colors.transparent
                      : const Color(0xFF3B82F6),
                ),
                child: widget.profileData['profile_photo'] != null
                    ? ClipOval(
                        child: Image.network(
                          widget.profileData['profile_photo'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildInitialAvatar();
                          },
                        ),
                      )
                    : _buildInitialAvatar(),
              ),

              // Percentage Badge (Bottom-right)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _progressColor,
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
                    '${widget.completionPercentage}%',
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
            widget.tmId,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          // Completion Status
          Text(
            '$_completedFields/$_totalFields docs',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem('Personal Detail', 0),
          _buildTabItem('Driving Details', 1),
          _buildTabItem('Uploaded Documents', 2),
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
    final personalFields = [
      {'key': 'full_name', 'label': 'Full Name', 'icon': Icons.person_outline},
      {'key': 'email', 'label': 'Email', 'icon': Icons.email_outlined},
      {
        'key': 'father_name',
        'label': 'Father Name',
        'icon': Icons.family_restroom_outlined
      },
      {'key': 'dob', 'label': 'DOB', 'icon': Icons.cake_outlined},
      {'key': 'gender', 'label': 'Gender', 'icon': Icons.wc_outlined},
      {
        'key': 'marital_status',
        'label': 'Marital Status',
        'icon': Icons.favorite_outline
      },
      {
        'key': 'highest_education',
        'label': 'Highest Education',
        'icon': Icons.school_outlined
      },
      {'key': 'address', 'label': 'Address', 'icon': Icons.home_outlined},
      {'key': 'city', 'label': 'City', 'icon': Icons.location_city_outlined},
      {'key': 'state', 'label': 'State', 'icon': Icons.map_outlined},
    ];

    return _buildTabContent(personalFields);
  }

  Widget _buildDrivingDetailsTab() {
    final drivingFields = [
      {
        'key': 'vehicle_type',
        'label': 'Vehicle Type',
        'icon': Icons.local_shipping_outlined
      },
      {
        'key': 'driving_experience',
        'label': 'Driving Experience',
        'icon': Icons.speed_outlined
      },
      {
        'key': 'preferred_location',
        'label': 'Preferred Location',
        'icon': Icons.location_on_outlined
      },
      {
        'key': 'current_monthly_income',
        'label': 'Current Monthly Income',
        'icon': Icons.currency_rupee
      },
      {
        'key': 'expected_monthly_income',
        'label': 'Expected Monthly Income',
        'icon': Icons.trending_up_outlined
      },
      {
        'key': 'type_of_license',
        'label': 'Type of License',
        'icon': Icons.badge_outlined
      },
      {
        'key': 'previous_employer',
        'label': 'Previous Employer',
        'icon': Icons.work_outline
      },
      {
        'key': 'job_placement',
        'label': 'Job Placement',
        'icon': Icons.work_history_outlined
      },
    ];

    return _buildTabContent(drivingFields);
  }

  Widget _buildUploadedDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            'aadhar_number',
            'Aadhar Number',
            Icons.credit_card_outlined,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            'aadhar_photo',
            'Uploaded Aadhar Photo',
            Icons.photo_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'license_number',
            'License Number',
            Icons.drive_eta_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'expiry_date_of_license',
            'Expiry Date of License',
            Icons.event_outlined,
            isDate: true,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            'driving_license_photo',
            'Uploaded Driving License Photo',
            Icons.photo_library_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<Map<String, dynamic>> fields) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: fields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInfoCard(
              field['key'],
              field['label'],
              field['icon'],
              isDate: field['key'] == 'dob',
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard(String key, String label, IconData icon,
      {bool isDate = false}) {
    final value = widget.profileData[key];

    // CRITICAL FIX: Check for null, empty string, or whitespace
    final bool hasValue = _isValidValue(value);

    // Use the actual value if present, otherwise show N/A
    final String displayValue = hasValue
        ? (isDate ? _formatDate(value.toString()) : value.toString())
        : 'N/A';

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
      child: Row(
        children: [
          // Icon Container
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
              color:
                  hasValue ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
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
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    color: hasValue
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF87171),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: label == 'Address' ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status Icon
          Icon(
            hasValue ? Icons.check_circle : Icons.error_outline,
            size: 20,
            color: hasValue ? const Color(0xFF34D399) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPhotoCard(String key, String label, IconData icon) {
    final value = widget.profileData[key];

    // CRITICAL: N/A only if photo is genuinely not uploaded
    final bool hasValue = _isValidValue(value);

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

          // Photo Preview
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
                    Icons.upload_file,
                    size: 32,
                    color: Color(0xFFF87171),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No document uploaded',
                    style: TextStyle(
                      fontSize: 14,
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
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper method to check if value is valid (not null, not empty, not "null", not "N/A")
  bool _isValidValue(dynamic value) {
    if (value == null) return false;

    final String stringValue = value.toString().trim();

    if (stringValue.isEmpty) return false;
    if (stringValue.toLowerCase() == 'null') return false;
    if (stringValue.toLowerCase() == 'n/a') return false;

    return true;
  }

  List<Map<String, dynamic>> _getAllFields() {
    return [
      {'key': 'full_name', 'label': 'Full Name'},
      {'key': 'email', 'label': 'Email'},
      {'key': 'father_name', 'label': 'Father Name'},
      {'key': 'dob', 'label': 'DOB'},
      {'key': 'gender', 'label': 'Gender'},
      {'key': 'marital_status', 'label': 'Marital Status'},
      {'key': 'highest_education', 'label': 'Highest Education'},
      {'key': 'address', 'label': 'Address'},
      {'key': 'city', 'label': 'City'},
      {'key': 'state', 'label': 'State'},
      {'key': 'vehicle_type', 'label': 'Vehicle Type'},
      {'key': 'driving_experience', 'label': 'Driving Experience'},
      {'key': 'preferred_location', 'label': 'Preferred Location'},
      {'key': 'current_monthly_income', 'label': 'Current Monthly Income'},
      {'key': 'expected_monthly_income', 'label': 'Expected Monthly Income'},
      {'key': 'type_of_license', 'label': 'Type of License'},
      {'key': 'previous_employer', 'label': 'Previous Employer'},
      {'key': 'job_placement', 'label': 'Job Placement'},
      {'key': 'aadhar_number', 'label': 'Aadhar Number'},
      {'key': 'aadhar_photo', 'label': 'Aadhar Photo'},
      {'key': 'license_number', 'label': 'License Number'},
      {'key': 'expiry_date_of_license', 'label': 'License Expiry'},
      {'key': 'driving_license_photo', 'label': 'Driving License Photo'},
    ];
  }
}
