import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_completion_details_screen.dart';

class ProfileCompletionLoaderScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userType;
  final String? tmId;

  const ProfileCompletionLoaderScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userType,
    this.tmId,
  });

  @override
  State<ProfileCompletionLoaderScreen> createState() =>
      _ProfileCompletionLoaderScreenState();
}

class _ProfileCompletionLoaderScreenState
    extends State<ProfileCompletionLoaderScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://truckmitr.com/truckmitr-app/api/profile_completion_api.php?action=get_profile_details&user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final profileData = data['data'];
          final completion = profileData['profile_completion'];
          final documentValues = completion['document_values'] ?? {};

          // Navigate to the details screen with the loaded data
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileCompletionDetailsScreen(
                  userName: widget.userName,
                  tmId: widget.tmId ?? profileData['unique_id'] ?? 'TM${widget.userId}',
                  completionPercentage: completion['percentage'] ?? 0,
                  profileData: _mapProfileData(documentValues, profileData),
                ),
              ),
            );
          }
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapProfileData(
      Map<String, dynamic> documentValues, Map<String, dynamic> profileData) {
    // Map the API response to the format expected by ProfileCompletionDetailsScreen
    return {
      'full_name': documentValues['name'],
      'email': documentValues['email'],
      'father_name': documentValues['father_name'],
      'dob': documentValues['dob'],
      'gender': documentValues['sex'],
      'marital_status': documentValues['marital_status'],
      'highest_education': documentValues['highest_education'],
      'address': documentValues['address'],
      'city': documentValues['city'],
      'state': documentValues['state'],
      'vehicle_type': documentValues['vehicle_type_display'] ?? documentValues['vehicle_type'],
      'driving_experience': documentValues['driving_experience'],
      'preferred_location': documentValues['preferred_location_display'] ?? documentValues['preferred_location'],
      'current_monthly_income': documentValues['current_monthly_income'],
      'expected_monthly_income': documentValues['expected_monthly_income'],
      'type_of_license': documentValues['type_of_license'],
      'previous_employer': documentValues['previous_employer'],
      'job_placement': documentValues['job_placement'],
      'aadhar_number': _formatAadhar(documentValues['aadhar_number']),
      'aadhar_photo': _getDocumentUrl(documentValues['aadhar_photo']),
      'license_number': documentValues['license_number'],
      'expiry_date_of_license': documentValues['expiry_date_of_license'],
      'driving_license_photo': _getDocumentUrl(documentValues['driving_license']),
      'profile_photo': _getProfilePhotoUrl(documentValues['images']),
    };
  }

  String? _getProfilePhotoUrl(dynamic images) {
    if (images == null) return null;
    
    String imageStr = images.toString().trim();
    if (imageStr.isEmpty || imageStr.toLowerCase() == 'null') return null;
    
    // Try to parse as JSON array
    try {
      final decoded = json.decode(imageStr);
      if (decoded is List && decoded.isNotEmpty) {
        imageStr = decoded[0].toString();
      }
    } catch (e) {
      // Not JSON, use as is
    }
    
    // If it's already a full URL
    if (imageStr.startsWith('http')) {
      return imageStr;
    }
    
    // If it's a relative path, prepend the correct base URL
    if (imageStr.isNotEmpty) {
      // Remove leading slash if present
      if (imageStr.startsWith('/')) {
        imageStr = imageStr.substring(1);
      }
      return 'https://truckmitr.com/public/$imageStr';
    }
    
    return null;
  }

  String? _getDocumentUrl(dynamic doc) {
    if (doc == null) return null;
    
    String docStr = doc.toString().trim();
    if (docStr.isEmpty || docStr.toLowerCase() == 'null') return null;
    
    // If it's already a full URL
    if (docStr.startsWith('http')) {
      return docStr;
    }
    
    // If it's a relative path, prepend the correct base URL
    if (docStr.isNotEmpty) {
      // Remove leading slash if present
      if (docStr.startsWith('/')) {
        docStr = docStr.substring(1);
      }
      return 'https://truckmitr.com/public/$docStr';
    }
    
    return null;
  }

  String? _formatAadhar(dynamic aadhar) {
    if (aadhar == null) return null;
    
    String aadharStr = aadhar.toString();
    
    // Handle scientific notation (e.g., "6.49E+11")
    if (aadharStr.contains('E') || aadharStr.contains('e')) {
      try {
        double value = double.parse(aadharStr);
        aadharStr = value.toStringAsFixed(0);
      } catch (e) {
        return aadharStr;
      }
    }
    
    // Format as XXXX XXXX XXXX
    if (aadharStr.length == 12) {
      return '${aadharStr.substring(0, 4)} ${aadharStr.substring(4, 8)} ${aadharStr.substring(8, 12)}';
    }
    
    return aadharStr;
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'Failed to load profile',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadProfileData();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
