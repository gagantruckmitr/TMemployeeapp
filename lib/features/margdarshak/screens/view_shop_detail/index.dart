import 'package:flutter/material.dart';
import '../../services/margdarshak_api_service.dart';
import '../../../../core/config/api_config.dart';
import '../add_shop/index.dart';

class ShopDetailsScreen extends StatefulWidget {
  final String uniqueId;
  final String userId;
  final String shopType; // 'dhaba' or 'puncture'

  const ShopDetailsScreen({
    super.key,
    required this.uniqueId,
    required this.userId,
    this.shopType = 'dhaba',
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final _apiService = MargdarshakApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _shopDetails;
  String? _errorMessage;

  bool get isPunctureShop => widget.shopType == 'puncture';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;

      if (isPunctureShop) {
        // Use puncture details API
        response = await _apiService.getPunctureDetails(
          userId: widget.userId,
          uniqueId: widget.uniqueId,
        );
      } else {
        // Use dhaba details API
        response = await _apiService.getDhabaDetails(
          uniqueId: widget.uniqueId,
          userId: widget.userId,
        );
      }

      if (response['status'] == true && response['data'] != null) {
        setState(() {
          _shopDetails = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load details');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Apple-like background
      appBar: AppBar(
        title: Text(
          isPunctureShop ? 'Puncture Shop Details' : 'Shop Details',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.blue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_shopDetails != null && !isPunctureShop)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddShopScreen(editData: _shopDetails),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: $_errorMessage'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : isPunctureShop
          ? _buildPunctureContent()
          : _buildDhabaContent(),
    );
  }

  /// Build content for Puncture shop
  Widget _buildPunctureContent() {
    if (_shopDetails == null) return const SizedBox.shrink();

    final userInfo = _shopDetails!['user_info'] ?? {};
    final businessInfo = _shopDetails!['business_info'] ?? {};
    final location = _shopDetails!['location'] ?? {};
    final operation = _shopDetails!['operation'] ?? {};
    final services = _shopDetails!['services'] ?? {};
    // Handle photos - can be Map or List (empty array)
    final photosRaw = _shopDetails!['photos'];
    final Map<String, dynamic> photos = (photosRaw is Map<String, dynamic>)
        ? photosRaw
        : {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          _buildInfoCard(
            title: 'Owner Information',
            children: [
              _buildRow('Name', userInfo['name'] ?? 'N/A'),
              _buildRow('Mobile', userInfo['mobile'] ?? 'N/A'),
              _buildRow('Unique ID', userInfo['unique_id'] ?? 'N/A'),
              _buildRow('Referral Code', userInfo['referral_code'] ?? 'N/A'),
              _buildRow('Status', userInfo['status'] ?? 'N/A', isStatus: true),
              _buildRow('State', userInfo['state_name'] ?? 'N/A'),
              _buildRow('Drivers', '${userInfo['drivers_count'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 16),

          // Business Info Card
          _buildInfoCard(
            title: 'Business Info',
            children: [
              _buildRow(
                'Puncture Name',
                businessInfo['puncture_name'] ?? 'N/A',
              ),
              _buildRow('Owner Name', businessInfo['owner_name'] ?? 'N/A'),
              _buildRow('Mobile', businessInfo['mobile'] ?? 'N/A'),
              _buildRow('Email', businessInfo['email'] ?? 'N/A'),
              _buildRow('Type', businessInfo['puncture_type'] ?? 'N/A'),
              _buildRow(
                'Year Established',
                businessInfo['year_established'] ?? 'N/A',
              ),
              _buildRow(
                'Status',
                businessInfo['status'] ?? 'N/A',
                isStatus: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location Card
          _buildInfoCard(
            title: 'Location',
            children: [
              _buildRow('Address', location['full_address'] ?? 'N/A'),
              _buildRow('Landmark', location['landmark'] ?? 'N/A'),
              _buildRow('District', location['district'] ?? 'N/A'),
              _buildRow('State', location['state']?['name'] ?? 'N/A'),
              _buildRow('Pincode', location['pincode'] ?? 'N/A'),
              _buildRow(
                'Coords',
                '${location['latitude'] ?? ''}, ${location['longitude'] ?? ''}',
              ),
              _buildRow('Source', location['location_source'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),

          // Operation Card
          _buildInfoCard(
            title: 'Operations',
            children: [
              _buildRow('24x7', operation['is_24x7'] == '1' ? 'Yes' : 'No'),
              if (operation['is_24x7'] != '1') ...[
                _buildRow('Opening Time', operation['opening_time'] ?? 'N/A'),
                _buildRow('Closing Time', operation['closing_time'] ?? 'N/A'),
              ],
              _buildRow(
                'On Road Service',
                operation['on_road_service'] == '1' ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Services Card
          _buildInfoCard(
            title: 'Services Offered',
            children: [
              if (services['tube_puncture'] == '1')
                _buildBulletPoint('Tube Puncture'),
              if (services['tubeless_tyre_repair'] == '1')
                _buildBulletPoint('Tubeless Tyre Repair'),
              if (services['tyre_replacement'] == '1')
                _buildBulletPoint('Tyre Replacement'),
              if (services['nitrogen_air_filling'] == '1')
                _buildBulletPoint('Nitrogen Air Filling'),
              if (services['stepney_installation'] == '1')
                _buildBulletPoint('Stepney Installation'),
              if (services['wheel_balancing'] == '1')
                _buildBulletPoint('Wheel Balancing'),
              if (services['minor_mechanical_repair'] == '1')
                _buildBulletPoint('Minor Mechanical Repair'),
              if (services['jump_start_battery_help'] == '1')
                _buildBulletPoint('Jump Start / Battery Help'),
              if (services['emergency_night_service'] == '1')
                _buildBulletPoint('Emergency Night Service'),
            ],
          ),
          const SizedBox(height: 16),

          // Photos Section
          if (photos.isNotEmpty) ...[
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildPhotoSections(photos),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// Build photo sections from the photos map
  List<Widget> _buildPhotoSections(Map<String, dynamic> photos) {
    List<Widget> sections = [];

    photos.forEach((category, photosList) {
      if (photosList is List && photosList.isNotEmpty) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photosList.length,
                    itemBuilder: (context, index) {
                      final photo = photosList[index];
                      String imageUrl = photo['image_url'] ?? '';
                      if (imageUrl.startsWith('/')) {
                        final baseUrl = ApiConfig.publicUrl.endsWith('/')
                            ? ApiConfig.publicUrl.substring(
                                0,
                                ApiConfig.publicUrl.length - 1,
                              )
                            : ApiConfig.publicUrl;
                        imageUrl = '$baseUrl$imageUrl';
                      }

                      return GestureDetector(
                        onTap: () => _showFullImage(context, imageUrl),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return sections;
  }

  /// Show full image in a dialog
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build content for Dhaba shop (original implementation)
  Widget _buildDhabaContent() {
    if (_shopDetails == null) return const SizedBox.shrink();

    final userInfo = _shopDetails!['user_info'] ?? {};
    final businessInfo = _shopDetails!['business_info'] ?? {};
    final location = _shopDetails!['location'] ?? {};
    final operation = _shopDetails!['operation'] ?? {};
    final facilities =
        _shopDetails!['facilities'] as Map<String, dynamic>? ?? {};
    final food = _shopDetails!['food'] ?? {};
    final photos = (_shopDetails!['all_photos'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Business Info',
            children: [
              _buildRow('Shop Name', businessInfo['dhaba_name'] ?? 'N/A'),
              _buildRow(
                'Owner Name',
                businessInfo['owner_name'] ?? userInfo['name'] ?? 'N/A',
              ),
              _buildRow(
                'Mobile',
                businessInfo['mobile'] ?? userInfo['mobile'] ?? 'N/A',
              ),
              _buildRow(
                'Type',
                businessInfo['dhaba_type'] ?? userInfo['role'] ?? 'N/A',
              ),
              _buildRow(
                'Status',
                businessInfo['status'] ?? 'N/A',
                isStatus: true,
              ),
              _buildRow('Unique ID', userInfo['unique_id'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Location',
            children: [
              _buildRow('Address', location['full_address'] ?? 'N/A'),
              _buildRow('Landmark', location['landmark'] ?? 'N/A'),
              _buildRow(
                'District',
                location['district'] ?? userInfo['city'] ?? 'N/A',
              ),
              _buildRow(
                'State',
                location['state_name'] ?? userInfo['state_name'] ?? 'N/A',
              ),
              _buildRow('Pincode', location['pincode'] ?? 'N/A'),
              _buildRow(
                'Coords',
                '${location['latitude'] ?? ''}, ${location['longitude'] ?? ''}',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Operations',
            children: [
              _buildRow('24x7', operation['is_24x7'] == true ? 'Yes' : 'No'),
              if (operation['is_24x7'] != true) ...[
                _buildRow('Opening Time', operation['opening_time'] ?? 'N/A'),
                _buildRow('Closing Time', operation['closing_time'] ?? 'N/A'),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Facilities',
            children: facilities.entries
                .where((e) => e.key != 'id' && e.value == true)
                .map<Widget>((e) => _buildBulletPoint(_formatKey(e.key)))
                .toList(),
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Food & Menu',
            children: [
              _buildRow(
                'Types',
                (food['food_type'] as List?)?.join(', ') ?? 'N/A',
              ),
              _buildRow('Special Dishes', food['special_dishes'] ?? 'N/A'),
              _buildRow('Price Range', '₹${food['avg_price_range'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              const Text(
                'Available Meals:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              if (food['meal_breakfast'] == true)
                _buildBulletPoint('Breakfast'),
              if (food['meal_lunch'] == true) _buildBulletPoint('Lunch'),
              if (food['meal_dinner'] == true) _buildBulletPoint('Dinner'),
              if (food['meal_night'] == true) _buildBulletPoint('Night'),
            ],
          ),
          const SizedBox(height: 16),

          if (photos.isNotEmpty) ...[
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  // If image URL is relative, prepend base URL?
                  // The API response shows /storage/..., which usually implies needing a domain.
                  // I'll check ApiConfig for storageBase or assume relative to domain.
                  String imageUrl = photo['image_url'] ?? '';
                  if (imageUrl.startsWith('/')) {
                    // Use publicUrl from ApiConfig
                    final baseUrl = ApiConfig.publicUrl.endsWith('/')
                        ? ApiConfig.publicUrl.substring(
                            0,
                            ApiConfig.publicUrl.length - 1,
                          )
                        : ApiConfig.publicUrl;

                    imageUrl = '$baseUrl$imageUrl';
                  }

                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? _buildStatusBadge(value)
                : Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'approved') {
      color = Colors.green;
    } else if (status.toLowerCase() == 'pending') {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (str) => str.isNotEmpty
              ? '${str[0].toUpperCase()}${str.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
