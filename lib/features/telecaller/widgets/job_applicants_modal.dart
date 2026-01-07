import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/phase2_api_service.dart';
import '../../../../models/driver_applicant_model.dart';
import '../../../../models/smart_calling_models.dart';
import '../screens/profile_completion_details_page.dart';
import 'profile_completion_avatar.dart';

class JobApplicantsModal extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsModal({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsModal> createState() => _JobApplicantsModalState();
}

class _JobApplicantsModalState extends State<JobApplicantsModal> {
  List<DriverApplicant> _applicants = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final applicants = await Phase2ApiService.fetchJobApplicants(
        widget.jobId,
      );
      setState(() {
        _applicants = applicants;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Applicants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        widget.jobTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplicants,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No applicants yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _applicants.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final applicant = _applicants[index];
        return _buildApplicantCard(applicant);
      },
    );
  }

  Widget _buildApplicantCard(DriverApplicant applicant) {
    // Process image URL
    String? imageUrl = applicant.profileImage;
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      imageUrl = '${ApiConfig.publicUrl}/$imageUrl';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProfileCompletionAvatar(
            name: applicant.name,
            size: 50,
            completionPercentage: applicant.profileCompletion,
            imageUrl: imageUrl,
            onTap: () => _navigateToProfile(context, applicant, imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${applicant.city}, ${applicant.state}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (applicant.driverTmid.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: applicant.driverTmid),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: ${applicant.driverTmid}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Ensure minimal width for Row
                      children: [
                        Text(
                          applicant.driverTmid,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 12, color: Colors.blue.shade700),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Applied: ${_formatDate(applicant.appliedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _navigateToProfile(
    BuildContext context,
    DriverApplicant applicant,
    String? imageUrl,
  ) {
    // Map subscription status string to enum
    SubscriptionStatus subStatus = SubscriptionStatus.inactive;
    if (applicant.subscriptionStatus.toLowerCase() == 'active') {
      subStatus = SubscriptionStatus.active;
    } else if (applicant.subscriptionStatus.toLowerCase() == 'expired') {
      subStatus = SubscriptionStatus.expired;
    }

    final contact = DriverContact(
      id: applicant.driverId.toString(),
      tmid: applicant.driverTmid,
      name: applicant.name,
      company: '', // Drivers usually don't have company name here
      phoneNumber: applicant.mobile,
      state: applicant.state,
      subscriptionStatus: subStatus,
      status: CallStatus.pending, // Default
      profileCompletion: ProfileCompletion(
        percentage: applicant.profileCompletion,
        documentStatus: {},
      ),
      profilePicture: imageUrl ?? applicant.profileImage,
      licenseType: applicant.licenseType,
      role: 'driver',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileCompletionDetailsPage(contact: contact),
      ),
    );
  }
}
