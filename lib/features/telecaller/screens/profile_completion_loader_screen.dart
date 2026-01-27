import 'package:flutter/material.dart';
import '../../../models/smart_calling_models.dart';
import 'profile_completion_details_page.dart';

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
  DriverContact? _driverContact;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Simulate API call to load profile data
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock DriverContact object - replace with actual API call
      _driverContact = DriverContact(
        id: widget.userId.toString(),
        tmid: widget.tmId ?? 'TM${widget.userId}',
        name: widget.userName,
        company: 'Unknown',
        phoneNumber: '0000000000',
        state: 'Unknown',
        subscriptionStatus: SubscriptionStatus.inactive,
        status: CallStatus.pending,
        registrationDate: DateTime.now(),
        profileCompletion: ProfileCompletion(
          percentage: 75,
          documentStatus: {
            'phone': false,
            'address': false,
            'license': true,
          },
          documentValues: {},
        ),
      );

      setState(() {
        _isLoading = false;
      });

      // Navigate to profile completion details
      if (mounted && _driverContact != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileCompletionDetailsPage(
              contact: _driverContact!,
              isTransporter: widget.userType.toLowerCase() == 'transporter',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${widget.userName}\'s profile...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}