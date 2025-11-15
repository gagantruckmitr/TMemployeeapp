import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/toll_free_lead_model.dart';

class TollFreeProfileDetailsScreen extends StatefulWidget {
  final TollFreeUser user;

  const TollFreeProfileDetailsScreen({super.key, required this.user});

  @override
  State<TollFreeProfileDetailsScreen> createState() =>
      _TollFreeProfileDetailsScreenState();
}

class _TollFreeProfileDetailsScreenState
    extends State<TollFreeProfileDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getCompletionPercentage() {
    if (widget.user.profileCompletion != null) {
      try {
        return int.parse(widget.user.profileCompletion!.replaceAll('%', ''));
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  Color _getProgressColor() {
    final percentage = _getCompletionPercentage();
    return percentage == 100
        ? const Color(0xFF34D399)
        : const Color(0xFFEF4444);
  }

  String _getVehicleTypeName(String? code) {
    if (code == null || code.isEmpty) return null.toString();
    switch (code) {
      case '1':
        return 'Light Motor Vehicle (LMV)';
      case '2':
        return 'Heavy Motor Vehicle (HMV)';
      case '3':
        return 'Medium Motor Vehicle (MMV)';
      default:
        return code;
    }
  }

  String _getStateName(String? stateId) {
    if (stateId == null || stateId.isEmpty) return null.toString();

    // Map of state IDs to state names based on API data
    const stateMap = {
      '1': 'Andaman and Nicobar',
      '2': 'Andhra Pradesh',
      '3': 'Arunachal Pradesh',
      '4': 'Assam',
      '5': 'Bihar',
      '6': 'Chandigarh',
      '7': 'Chhattisgarh',
      '8': 'Dadra and Nagar Haveli',
      '9': 'Daman and Diu',
      '10': 'Delhi',
      '11': 'Goa',
      '12': 'Gujarat',
      '13': 'Haryana',
      '14': 'Himachal Pradesh',
      '15': 'Jammu and Kashmir',
      '16': 'Jharkhand',
      '17': 'Karnataka',
      '18': 'Kerala',
      '19': 'Lakshadweep',
      '20': 'Madhya Pradesh',
      '21': 'Maharashtra',
      '22': 'Manipur',
      '23': 'Meghalaya',
      '24': 'Mizoram',
      '25': 'Nagaland',
      '26': 'Odisha',
      '27': 'Puducherry',
      '28': 'Punjab',
      '29': 'Rajasthan',
      '30': 'Sikkim',
      '31': 'Tamil Nadu',
      '32': 'Telangana',
      '33': 'Tripura',
      '34': 'Uttar Pradesh',
      '35': 'Uttarakhand',
      '36': 'West Bengal',
    };

    return stateMap[stateId] ?? stateId;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _getCompletionPercentage();
    final progressColor = _getProgressColor();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Completion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: Column(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                // Circular Progress with Avatar
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),

                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          image: widget.user.profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.user.profileImage!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.user.profileImage == null
                            ? Center(
                                child: Text(
                                  widget.user.name.isNotEmpty
                                      ? widget.user.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),

                      // Percentage Badge
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
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // TM ID
                Text(
                  widget.user.uniqueId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 4),

                // Completion Status
                Text(
                  '${_getFilledFieldsCount()}/23 docs',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Tab Navigation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Personal Detail'),
                Tab(text: 'Driving Details'),
                Tab(text: 'Documents'),
                Tab(text: 'Payment'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalDetails(),
                _buildDrivingDetails(),
                _buildUploadedDocuments(),
                _buildPaymentDetails(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getFilledFieldsCount() {
    // Calculate based on available data
    int count = 0;
    if (widget.user.name.isNotEmpty) count++;
    if (widget.user.email != null && widget.user.email!.isNotEmpty) count++;
    if (widget.user.mobile.isNotEmpty) count++;
    // Add more fields as needed
    return count;
  }

  Widget _buildPersonalDetails() {
    // Format DOB
    String? formattedDob;
    if (widget.user.dob != null) {
      try {
        final dob = DateTime.parse(widget.user.dob!);
        formattedDob = DateFormat('dd MMM yyyy').format(dob);
      } catch (e) {
        formattedDob = widget.user.dob;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: widget.user.name,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: widget.user.email,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.phone_outlined,
            label: 'Mobile',
            value: widget.user.mobile,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.family_restroom_outlined,
            label: 'Father Name',
            value: widget.user.fatherName,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: formattedDob,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.wc_outlined,
            label: 'Gender',
            value: widget.user.sex,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.favorite_outline,
            label: 'Marital Status',
            value: widget.user.maritalStatus,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.school_outlined,
            label: 'Highest Education',
            value: widget.user.highestEducation,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.home_outlined,
            label: 'Address',
            value: widget.user.address,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: widget.user.city,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.pin_drop_outlined,
            label: 'Pincode',
            value: widget.user.pincode,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.map_outlined,
            label: 'State',
            value: widget.user.states != null && widget.user.states!.isNotEmpty
                ? _getStateName(widget.user.states)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDrivingDetails() {
    // Format driving experience
    String? formattedExperience;
    if (widget.user.drivingExperience != null &&
        widget.user.drivingExperience!.isNotEmpty) {
      formattedExperience = '${widget.user.drivingExperience} years';
    }

    // Get vehicle type name
    String? vehicleTypeName;
    if (widget.user.vehicleType != null &&
        widget.user.vehicleType!.isNotEmpty) {
      vehicleTypeName = _getVehicleTypeName(widget.user.vehicleType);
    }

    // Format previous employer
    String? previousEmployer;
    if (widget.user.previousEmployer != null &&
        widget.user.previousEmployer!.isNotEmpty) {
      previousEmployer = widget.user.previousEmployer == 'no'
          ? 'No Previous Employer'
          : widget.user.previousEmployer;
    }

    // Format job placement
    String? jobPlacement;
    if (widget.user.jobPlacement != null &&
        widget.user.jobPlacement!.isNotEmpty) {
      jobPlacement = widget.user.jobPlacement == 'no'
          ? 'No Job Placement'
          : widget.user.jobPlacement;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.local_shipping_outlined,
            label: 'Vehicle Type',
            value: vehicleTypeName,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.speed_outlined,
            label: 'Driving Experience',
            value: formattedExperience,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            label: 'Preferred Location',
            value: widget.user.preferredLocation,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.currency_rupee,
            label: 'Current Monthly Income',
            value: widget.user.currentMonthlyIncome,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.trending_up_outlined,
            label: 'Expected Monthly Income',
            value: widget.user.expectedMonthlyIncome,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.badge_outlined,
            label: 'Type of License',
            value: widget.user.typeOfLicense,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.work_outline,
            label: 'Previous Employer',
            value: previousEmployer,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.work_history_outlined,
            label: 'Job Placement',
            value: jobPlacement,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedDocuments() {
    // Format license expiry date
    String? formattedExpiryDate;
    if (widget.user.expiryDateOfLicense != null) {
      try {
        final expiry = DateTime.parse(widget.user.expiryDateOfLicense!);
        formattedExpiryDate = DateFormat('dd MMM yyyy').format(expiry);
      } catch (e) {
        formattedExpiryDate = widget.user.expiryDateOfLicense;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.credit_card_outlined,
            label: 'Aadhar Number',
            value: widget.user.aadharNumber,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            icon: Icons.photo_outlined,
            label: 'Uploaded Aadhar Photo',
            imageUrl: widget.user.aadharPhoto,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.drive_eta_outlined,
            label: 'License Number',
            value: widget.user.licenseNumber,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.event_outlined,
            label: 'Expiry Date of License',
            value: formattedExpiryDate,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            icon: Icons.photo_library_outlined,
            label: 'Uploaded Driving License Photo',
            imageUrl: widget.user.drivingLicense,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    final payment = widget.user.latestPayment;
    final hasPayment = payment != null;

    String amount = 'N/A';
    String paymentStatus = 'N/A';
    String paymentType = 'N/A';
    String startDate = 'N/A';
    String endDate = 'N/A';
    String createdAt = 'N/A';

    if (hasPayment) {
      amount = payment['amount']?.toString() ?? 'N/A';
      paymentStatus = payment['payment_status']?.toString() ?? 'N/A';
      paymentType = payment['payment_type']?.toString() ?? 'N/A';

      try {
        if (payment['start_at'] != null) {
          final start = DateTime.fromMillisecondsSinceEpoch(
            (payment['start_at'] as int) * 1000,
          );
          startDate = DateFormat('dd MMM yyyy, hh:mm a').format(start);
        }
      } catch (e) {
        startDate = 'N/A';
      }

      try {
        if (payment['end_at'] != null) {
          final end = DateTime.fromMillisecondsSinceEpoch(
            (payment['end_at'] as int) * 1000,
          );
          endDate = DateFormat('dd MMM yyyy, hh:mm a').format(end);
        }
      } catch (e) {
        endDate = 'N/A';
      }

      try {
        if (payment['created_at'] != null) {
          final created = DateTime.parse(payment['created_at'].toString());
          createdAt = DateFormat('dd MMM yyyy, hh:mm a').format(created);
        }
      } catch (e) {
        createdAt = 'N/A';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Subscription Status Card
          if (hasPayment)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF4CAF50).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Active Subscription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹$amount',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Active Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No payment information available',
                    style: TextStyle(fontSize: 14, color: Color(0xFFF87171)),
                  ),
                ],
              ),
            ),

          // Payment Details - Clickable Cards
          GestureDetector(
            onTap: () => _showPaymentDetailsDialog(payment),
            child: _buildInfoCard(
              icon: Icons.currency_rupee,
              label: 'Amount',
              value: amount != 'N/A' ? '₹$amount' : null,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showPaymentDetailsDialog(payment),
            child: _buildInfoCard(
              icon: Icons.info_outline,
              label: 'Payment Status',
              value: paymentStatus != 'N/A'
                  ? paymentStatus.toUpperCase()
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showPaymentDetailsDialog(payment),
            child: _buildInfoCard(
              icon: Icons.account_balance_wallet,
              label: 'Payment Type',
              value: paymentType != 'N/A' ? paymentType : null,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showPaymentDetailsDialog(payment),
            child: _buildInfoCard(
              icon: Icons.calendar_today,
              label: 'Created At',
              value: createdAt != 'N/A' ? createdAt : null,
            ),
          ),
          const SizedBox(height: 16),

          // Subscription Period Section
          if (hasPayment) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 20,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Subscription Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 16,
                                  color: const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              startDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.stop,
                                  size: 16,
                                  color: const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              endDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String? value,
    int maxLines = 1,
  }) {
    final bool isFilled = value != null && value.isNotEmpty;
    final Color borderColor = isFilled
        ? const Color(0xFFE5E7EB)
        : const Color(0xFFFEE2E2);
    final Color iconBgColor = isFilled
        ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
        : const Color(0xFFEF4444).withValues(alpha: 0.05);
    final Color iconColor = isFilled
        ? const Color(0xFF3B82F6)
        : const Color(0xFFEF4444);
    final Color textColor = isFilled
        ? const Color(0xFF1F2937)
        : const Color(0xFFF87171);
    final IconData statusIcon = isFilled
        ? Icons.check_circle
        : Icons.error_outline;
    final Color statusColor = isFilled
        ? const Color(0xFF34D399)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
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
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
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
                  isFilled ? value : 'N/A',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Status Icon
          Icon(statusIcon, size: 24, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildDocumentPhotoCard({
    required IconData icon,
    required String label,
    required String? imageUrl,
  }) {
    final bool isUploaded = imageUrl != null && imageUrl.isNotEmpty;
    final Color borderColor = isUploaded
        ? const Color(0xFFE5E7EB)
        : const Color(0xFFFEE2E2);
    final Color iconBgColor = isUploaded
        ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
        : const Color(0xFFEF4444).withValues(alpha: 0.05);
    final Color iconColor = isUploaded
        ? const Color(0xFF3B82F6)
        : const Color(0xFFEF4444);
    final IconData statusIcon = isUploaded
        ? Icons.check_circle
        : Icons.error_outline;
    final Color statusColor = isUploaded
        ? const Color(0xFF34D399)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Icon Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),

              const SizedBox(width: 14),

              // Label
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

              // Status Icon
              Icon(statusIcon, size: 24, color: statusColor),
            ],
          ),

          const SizedBox(height: 12),

          // Photo Preview
          if (isUploaded)
            GestureDetector(
              onTap: () => _showFullImageDialog(imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildNoDocumentContainer();
                  },
                ),
              ),
            )
          else
            _buildNoDocumentContainer(),
        ],
      ),
    );
  }

  Widget _buildNoDocumentContainer() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 32, color: Color(0xFFF87171)),
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
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetailsDialog(Map<String, dynamic>? payment) {
    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment information available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6),
                      const Color(0xFF3B82F6).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPaymentDetailRow(
                        'Payment ID',
                        payment['payment_id']?.toString() ?? 'N/A',
                        Icons.payment,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'Order ID',
                        payment['order_id']?.toString() ?? 'N/A',
                        Icons.receipt_long,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'Amount',
                        '₹${payment['amount']?.toString() ?? 'N/A'}',
                        Icons.currency_rupee,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'Status',
                        (payment['payment_status']?.toString() ?? 'N/A')
                            .toUpperCase(),
                        Icons.info_outline,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'Payment Type',
                        payment['payment_type']?.toString() ?? 'N/A',
                        Icons.account_balance_wallet,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'Created At',
                        _formatPaymentDate(payment['created_at']),
                        Icons.calendar_today,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'Start Date',
                        _formatTimestamp(payment['start_at']),
                        Icons.play_arrow,
                      ),
                      const Divider(height: 24),
                      _buildPaymentDetailRow(
                        'End Date',
                        _formatTimestamp(payment['end_at']),
                        Icons.stop,
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

  Widget _buildPaymentDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 14),
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
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(
        (timestamp as int) * 1000,
      );
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatPaymentDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}
