import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  // Sample contact data
  final List<Map<String, dynamic>> _sampleContacts = [
    {
      'name': 'Moin',
      'tmid': 'TM2512DLTR23370',
      'role': 'TRANSPORTER',
      'completionPercentage': 27,
      'registrationDate': '19-Dec-25 10:26PM',
      'state': 'Delhi',
      'fleetSize': 'N/A',
      'postedJobs': 0,
      'matchMaking': 0,
      'callHistory': 0,
      'isDriver': false,
    },
    {
      'name': 'Sayyed Hanzala Sadekh',
      'tmid': 'TM2512MHTR23360',
      'role': 'TRANSPORTER',
      'completionPercentage': 27,
      'registrationDate': '19-Dec-25 05:57PM',
      'state': 'Maharashtra',
      'fleetSize': 'N/A',
      'postedJobs': 0,
      'matchMaking': 0,
      'callHistory': 0,
      'isDriver': false,
    },
    {
      'name': 'Ramesh Kumar',
      'tmid': 'TM2508UPDL12345',
      'role': 'DRIVER',
      'completionPercentage': 67,
      'registrationDate': '18-Dec-25 02:30PM',
      'state': 'Delhi',
      'vehicleType': 'Truck - 16 Wheeler',
      'appliedJobs': 3,
      'matchMaking': 1,
      'callHistory': 2,
      'isDriver': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: Color(0xFF6366F1),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Details',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Leads For Profile Completion',
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_sampleContacts.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sampleContacts.length,
        itemBuilder: (context, index) {
          final contact = _sampleContacts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildContactCard(contact, index),
          );
        },
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, int index) {
    final int completionPercentage = contact['completionPercentage'] as int;
    final bool isDriver = contact['isDriver'] as bool;

    final progressColor = completionPercentage >= 80
        ? const Color(0xFF4CAF50)
        : completionPercentage >= 50
        ? const Color(0xFFFFC107)
        : const Color(0xFFF44336);

    final roleColor = isDriver ? Colors.blue : Colors.orange;

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Name/TMID, Call Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with profile completion - TAPPABLE
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showProfileDetails(contact);
                    },
                    child: Column(
                      children: [
                        // Avatar with circular progress
                        Stack(
                          children: [
                            // Progress ring
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: CustomPaint(
                                painter: _CircularProgressPainter(
                                  progress: completionPercentage / 100,
                                  color: progressColor,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                            // Avatar
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (contact['name'] as String).isNotEmpty
                                        ? (contact['name'] as String)[0]
                                              .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Percentage badge
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: progressColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$completionPercentage%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: roleColor.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            contact['role'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: roleColor.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and TMID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          contact['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                contact['tmid'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: contact['tmid'] as String,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'TMID copied: ${contact['tmid']}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Call button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Registration Date',
                      contact['registrationDate'] as String,
                    ),
                  ),
                  Expanded(child: _buildInfoColumn('Subscription Date', 'N/A')),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'State',
                      contact['state'] as String,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      isDriver ? 'Vehicle Type' : 'Fleet Size',
                      isDriver
                          ? (contact['vehicleType'] as String? ?? 'N/A')
                          : (contact['fleetSize'] as String? ?? 'N/A'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom badges row
              Row(
                children: [
                  // Posted Jobs / Applied Jobs badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          '${isDriver ? contact['appliedJobs'] : contact['postedJobs']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Match Making badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.handshake_rounded,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${contact['matchMaking']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Call History badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Call History :',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.phone_in_talk,
                          size: 16,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${contact['callHistory']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: 100 * index),
        )
        .slideY(begin: 0.05);
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showProfileDetails(Map<String, dynamic> contact) {
    final bool isDriver = contact['isDriver'] as bool;
    final int completionPercentage = contact['completionPercentage'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
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
              _buildProfileHeader(contact, completionPercentage, isDriver),
              // Tabs
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          labelColor: AppTheme.primaryBlue,
                          unselectedLabelColor: Colors.grey.shade600,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorPadding: const EdgeInsets.all(4),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: [
                            const Tab(text: 'Personal\nDetail'),
                            Tab(
                              text: isDriver
                                  ? 'Driving\nDetails'
                                  : 'Fleet\nDetails',
                            ),
                            const Tab(text: 'Uploaded\nDocs'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPersonalDetailsTab(contact, isDriver),
                            _buildDetailsTab(contact, isDriver),
                            _buildDocumentsTab(isDriver),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic> contact,
    int percentage,
    bool isDriver,
  ) {
    final progressColor = percentage >= 80
        ? const Color(0xFF4CAF50)
        : percentage >= 50
        ? const Color(0xFFFFC107)
        : const Color(0xFFF44336);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar with progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (contact['name'] as String)[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contact['tmid'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getCompletedFieldsCount(isDriver)}/${_getTotalFieldsCount(isDriver)} Records',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  int _getCompletedFieldsCount(bool isDriver) => isDriver ? 15 : 10;
  int _getTotalFieldsCount(bool isDriver) => isDriver ? 23 : 15;

  Widget _buildPersonalDetailsTab(Map<String, dynamic> contact, bool isDriver) {
    final fields = isDriver
        ? [
            {
              'label': 'Full Name',
              'value': contact['name'],
              'icon': Icons.person_outline,
              'completed': true,
            },
            {
              'label': 'Email',
              'value': 'driver@email.com',
              'icon': Icons.email_outlined,
              'completed': true,
            },
            {
              'label': 'Mobile',
              'value': '98765XXXXX',
              'icon': Icons.phone_outlined,
              'completed': true,
            },
            {
              'label': 'Father Name',
              'value': 'Suresh Kumar',
              'icon': Icons.family_restroom_outlined,
              'completed': true,
            },
            {
              'label': 'Date of Birth',
              'value': '15-Aug-1990',
              'icon': Icons.cake_outlined,
              'completed': true,
            },
            {
              'label': 'Gender',
              'value': 'Male',
              'icon': Icons.wc_outlined,
              'completed': true,
            },
            {
              'label': 'Marital Status',
              'value': 'Married',
              'icon': Icons.favorite_outline,
              'completed': true,
            },
            {
              'label': 'Education',
              'value': '12th Pass',
              'icon': Icons.school_outlined,
              'completed': true,
            },
            {
              'label': 'Address',
              'value': null,
              'icon': Icons.home_outlined,
              'completed': false,
            },
            {
              'label': 'City',
              'value': null,
              'icon': Icons.location_city_outlined,
              'completed': false,
            },
            {
              'label': 'State',
              'value': contact['state'],
              'icon': Icons.map_outlined,
              'completed': true,
            },
          ]
        : [
            {
              'label': 'Company Name',
              'value': contact['name'],
              'icon': Icons.business_outlined,
              'completed': true,
            },
            {
              'label': 'Transport Name',
              'value': 'ABC Transport Pvt Ltd',
              'icon': Icons.local_shipping_outlined,
              'completed': true,
            },
            {
              'label': 'Email',
              'value': 'contact@abctransport.com',
              'icon': Icons.email_outlined,
              'completed': true,
            },
            {
              'label': 'Mobile',
              'value': '98989XXXXX',
              'icon': Icons.phone_outlined,
              'completed': true,
            },
            {
              'label': 'Address',
              'value': null,
              'icon': Icons.home_outlined,
              'completed': false,
            },
            {
              'label': 'City',
              'value': null,
              'icon': Icons.location_city_outlined,
              'completed': false,
            },
            {
              'label': 'State',
              'value': contact['state'],
              'icon': Icons.map_outlined,
              'completed': true,
            },
          ];

    return _buildFieldsList(fields);
  }

  Widget _buildDetailsTab(Map<String, dynamic> contact, bool isDriver) {
    final fields = isDriver
        ? [
            {
              'label': 'Vehicle Type',
              'value': contact['vehicleType'] ?? 'Truck - 16 Wheeler',
              'icon': Icons.directions_car_outlined,
              'completed': true,
            },
            {
              'label': 'License Type',
              'value': 'Heavy Vehicle',
              'icon': Icons.card_membership_outlined,
              'completed': true,
            },
            {
              'label': 'Experience',
              'value': '8 Years',
              'icon': Icons.work_history_outlined,
              'completed': true,
            },
            {
              'label': 'License Number',
              'value': 'DL14XXXXXXX',
              'icon': Icons.credit_card_outlined,
              'completed': true,
            },
            {
              'label': 'License Expiry',
              'value': '20-Dec-2028',
              'icon': Icons.event_outlined,
              'completed': true,
            },
            {
              'label': 'Expected Income',
              'value': '₹45,000',
              'icon': Icons.attach_money_outlined,
              'completed': true,
            },
            {
              'label': 'Current Income',
              'value': null,
              'icon': Icons.payments_outlined,
              'completed': false,
            },
            {
              'label': 'Preferred Location',
              'value': 'North India',
              'icon': Icons.location_on_outlined,
              'completed': true,
            },
          ]
        : [
            {
              'label': 'Year Established',
              'value': '2010',
              'icon': Icons.calendar_today_outlined,
              'completed': true,
            },
            {
              'label': 'Fleet Size',
              'value': contact['fleetSize'] ?? '25 Vehicles',
              'icon': Icons.directions_bus_outlined,
              'completed': false,
            },
            {
              'label': 'Segment',
              'value': 'Long Haul',
              'icon': Icons.category_outlined,
              'completed': true,
            },
            {
              'label': 'Average KM',
              'value': null,
              'icon': Icons.speed_outlined,
              'completed': false,
            },
            {
              'label': 'PAN Number',
              'value': 'AAACAXXXXX',
              'icon': Icons.badge_outlined,
              'completed': true,
            },
          ];

    return _buildFieldsList(fields);
  }

  Widget _buildDocumentsTab(bool isDriver) {
    final fields = isDriver
        ? [
            {
              'label': 'Profile Photo',
              'value': 'Uploaded',
              'icon': Icons.camera_alt_outlined,
              'completed': true,
            },
            {
              'label': 'Aadhar Number',
              'value': 'XXXX-XXXX-1234',
              'icon': Icons.credit_card_outlined,
              'completed': true,
            },
            {
              'label': 'Aadhar Photo',
              'value': 'Uploaded',
              'icon': Icons.photo_outlined,
              'completed': true,
            },
            {
              'label': 'Driving License',
              'value': null,
              'icon': Icons.card_membership_outlined,
              'completed': false,
            },
          ]
        : [
            {
              'label': 'Company Photo',
              'value': null,
              'icon': Icons.camera_alt_outlined,
              'completed': false,
            },
            {
              'label': 'PAN Card',
              'value': 'Uploaded',
              'icon': Icons.photo_outlined,
              'completed': true,
            },
            {
              'label': 'GST Certificate',
              'value': null,
              'icon': Icons.description_outlined,
              'completed': false,
            },
          ];

    return _buildFieldsList(fields);
  }

  Widget _buildFieldsList(List<Map<String, dynamic>> fields) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fields.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final field = fields[index];
        final bool isCompleted = field['completed'] as bool;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  field['icon'] as IconData,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.red.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? (field['value'] as String? ?? 'N/A')
                          : 'Not Provided',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted
                            ? Colors.grey.shade900
                            : Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.red.shade400,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom painter for circular progress ring
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle (gray)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
