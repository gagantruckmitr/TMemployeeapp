import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/api_service.dart';

class ProfileCompletionDetailsPage extends StatefulWidget {
  final DriverContact contact;

  const ProfileCompletionDetailsPage({super.key, required this.contact});

  @override
  State<ProfileCompletionDetailsPage> createState() =>
      _ProfileCompletionDetailsPageState();
}

class _ProfileCompletionDetailsPageState
    extends State<ProfileCompletionDetailsPage> {
  ProfileCompletion? _detailedCompletion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetailedProfileData();
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

    // Create basic field mapping with available contact data
    final fieldValues = <String, String?>{
      'name': widget.contact.name,
      'email': null, // Will be fetched from API
      'city': null, // Will be fetched from API
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

    return [
      DocumentItem(
        'Basic Information',
        'name',
        docs['name'] ?? false,
        values['name'],
      ),
      DocumentItem('Email', 'email', docs['email'] ?? false, values['email']),
      DocumentItem('City', 'city', docs['city'] ?? false, values['city']),
      DocumentItem('Gender', 'sex', docs['sex'] ?? false, values['sex']),
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
        'Driving Experience',
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
    final completion = _detailedCompletion ?? widget.contact.profileCompletion;
    final percentage = completion?.percentage ?? 0;
    final progressColor = _getProgressColor(percentage);
    final documents = _getDriverDocuments();
    final completedDocs = documents.where((doc) => doc.isPresent).length;
    final totalDocs = documents.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Profile Completion',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with circular progress
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: percentage / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.contact.name
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Name
                        Text(
                          widget.contact.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // TMID
                        Text(
                          widget.contact.tmid,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Percentage
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: progressColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                percentage >= 80
                                    ? Icons.check_circle
                                    : percentage >= 50
                                    ? Icons.warning_amber_rounded
                                    : Icons.error_outline,
                                color: progressColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percentage% Complete',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: progressColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Document count
                        Text(
                          '$completedDocs of $totalDocs documents completed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Completed Documents Section
                  if (completedDocs > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Completed Documents ($completedDocs)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: documents
                                .where((doc) => doc.isPresent)
                                .length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                              indent: 56,
                            ),
                            itemBuilder: (context, index) {
                              final completedDocsList = documents
                                  .where((doc) => doc.isPresent)
                                  .toList();
                              return _buildDocumentItem(
                                completedDocsList[index],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Missing Documents Section
                  if (totalDocs - completedDocs > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF44336,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFF44336),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Missing Documents (${totalDocs - completedDocs})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: documents
                                .where((doc) => !doc.isPresent)
                                .length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                              indent: 56,
                            ),
                            itemBuilder: (context, index) {
                              final missingDocsList = documents
                                  .where((doc) => !doc.isPresent)
                                  .toList();
                              return _buildDocumentItem(missingDocsList[index]);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentItem(DocumentItem doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: doc.isPresent
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              doc.isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
              color: doc.isPresent
                  ? const Color(0xFF4CAF50)
                  : Colors.grey.shade400,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Document name and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.value ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: doc.isPresent
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF44336),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentItem {
  final String displayName;
  final String fieldName;
  final bool isPresent;
  final String? value;

  DocumentItem(this.displayName, this.fieldName, this.isPresent, this.value);
}
