import 'package:flutter/material.dart';
import '../../../models/database_models.dart';

class CallbackProfileDetailsScreen extends StatefulWidget {
  final CallbackRequest request;

  const CallbackProfileDetailsScreen({super.key, required this.request});

  @override
  State<CallbackProfileDetailsScreen> createState() =>
      _CallbackProfileDetailsScreenState();
}

class _CallbackProfileDetailsScreenState
    extends State<CallbackProfileDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getCompletionPercentage() {
    if (widget.request.profileCompletion != null) {
      try {
        return int.parse(
          widget.request.profileCompletion!.replaceAll(RegExp(r'[^0-9]'), ''),
        );
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

  int _getFilledFieldsCount() {
    // For now, calculate based on percentage (23 total fields)
    final percentage = _getCompletionPercentage();
    return ((percentage / 100) * 23).round();
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
                          image: widget.request.profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.request.profileImage!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.request.profileImage == null
                            ? Center(
                                child: Text(
                                  widget.request.userName.isNotEmpty
                                      ? widget.request.userName[0].toUpperCase()
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
                  widget.request.uniqueId ?? 'TM ID unavailable',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: widget.request.userName,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.phone_outlined,
            label: 'Mobile',
            value: widget.request.mobileNumber,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.family_restroom_outlined,
            label: 'Father Name',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.wc_outlined,
            label: 'Gender',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.favorite_outline,
            label: 'Marital Status',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.school_outlined,
            label: 'Highest Education',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.home_outlined,
            label: 'Address',
            value: null,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.map_outlined,
            label: 'State',
            value: null,
          ),
        ],
      ),
    );
  }

  Widget _buildDrivingDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.local_shipping_outlined,
            label: 'Vehicle Type',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.speed_outlined,
            label: 'Driving Experience',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            label: 'Preferred Location',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.currency_rupee,
            label: 'Current Monthly Income',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.trending_up_outlined,
            label: 'Expected Monthly Income',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.badge_outlined,
            label: 'Type of License',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.work_outline,
            label: 'Previous Employer',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.work_history_outlined,
            label: 'Job Placement',
            value: null,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedDocuments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.credit_card_outlined,
            label: 'Aadhar Number',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            icon: Icons.photo_outlined,
            label: 'Uploaded Aadhar Photo',
            imageUrl: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.drive_eta_outlined,
            label: 'License Number',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.event_outlined,
            label: 'Expiry Date of License',
            value: null,
          ),
          const SizedBox(height: 12),
          _buildDocumentPhotoCard(
            icon: Icons.photo_library_outlined,
            label: 'Uploaded Driving License Photo',
            imageUrl: null,
          ),
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
}