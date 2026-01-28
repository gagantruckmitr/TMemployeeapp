import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LocationConsentScreen extends StatefulWidget {
  const LocationConsentScreen({super.key});

  @override
  State<LocationConsentScreen> createState() => _LocationConsentScreenState();
}

class _LocationConsentScreenState extends State<LocationConsentScreen> {
  bool _hasReadPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Location Tracking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D2D5F)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 64,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 32),

            // Title
            const Text(
                  'Location Tracking Consent',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D5F),
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 16),

            // Subtitle
            Text(
                  'We need your location to provide the best field agent experience',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 32),

            // Why we collect location
            _buildInfoSection('Why we collect your location', [
                  _buildInfoItem(
                    Icons.business_rounded,
                    'Verify shop visits and check-ins',
                  ),
                  _buildInfoItem(
                    Icons.route_rounded,
                    'Track territory coverage',
                  ),
                  _buildInfoItem(
                    Icons.payment_rounded,
                    'Calculate accurate earnings',
                  ),
                  _buildInfoItem(Icons.security_rounded, 'Ensure agent safety'),
                  _buildInfoItem(
                    Icons.analytics_rounded,
                    'Improve operational efficiency',
                  ),
                ])
                .animate()
                .fadeIn(duration: 600.ms, delay: 600.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 24),

            // When we track
            _buildInfoSection('When we track your location', [
                  _buildInfoItem(Icons.work_rounded, 'Only during duty hours'),
                  _buildInfoItem(
                    Icons.toggle_on_rounded,
                    'When you start duty tracking',
                  ),
                  _buildInfoItem(
                    Icons.store_rounded,
                    'Near registered shops (geofencing)',
                  ),
                  _buildInfoItem(Icons.stop_rounded, 'Stops when you end duty'),
                ])
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 24),

            // Your rights
            _buildInfoSection('Your rights and control', [
                  _buildInfoItem(Icons.pause_rounded, 'Stop tracking anytime'),
                  _buildInfoItem(
                    Icons.visibility_rounded,
                    'View your location data',
                  ),
                  _buildInfoItem(Icons.delete_rounded, 'Request data deletion'),
                  _buildInfoItem(
                    Icons.settings_rounded,
                    'Manage permissions in settings',
                  ),
                ])
                .animate()
                .fadeIn(duration: 600.ms, delay: 1000.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 32),

            // Privacy Policy
            Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasReadPolicy,
                            onChanged: (value) {
                              setState(() {
                                _hasReadPolicy = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF4CAF50),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _hasReadPolicy = !_hasReadPolicy;
                                });
                              },
                              child: const Text(
                                'I have read and agree to the Privacy Policy and Terms of Service',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _showPrivacyPolicy(),
                              child: const Text('View Privacy Policy'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => _showTermsOfService(),
                              child: const Text('View Terms of Service'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms, delay: 1200.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _hasReadPolicy
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: const Text(
                          'Accept & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 600.ms, delay: 1400.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D5F),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D5F)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is where your privacy policy content would go. '
            'It should detail how location data is collected, stored, '
            'used, and protected. Include information about data '
            'retention, sharing policies, and user rights.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This is where your terms of service content would go. '
            'It should outline the terms and conditions for using '
            'the location tracking features, including user '
            'responsibilities and service limitations.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
