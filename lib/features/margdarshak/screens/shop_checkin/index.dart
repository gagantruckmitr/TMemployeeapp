import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ShopCheckInScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
  final String shopType;
  final double distance;

  const ShopCheckInScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.shopType,
    required this.distance,
  });

  @override
  State<ShopCheckInScreen> createState() => _ShopCheckInScreenState();
}

class _ShopCheckInScreenState extends State<ShopCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  File? _selfieImage;
  File? _shopImage;
  bool _isLoading = false;
  String _selectedPurpose = 'visit';

  final List<Map<String, dynamic>> _visitPurposes = [
    {
      'value': 'visit',
      'label': 'Regular Visit',
      'icon': Icons.visibility_rounded,
    },
    {
      'value': 'onboarding',
      'label': 'New Driver Onboarding',
      'icon': Icons.person_add_rounded,
    },
    {
      'value': 'support',
      'label': 'Support/Issue Resolution',
      'icon': Icons.support_agent_rounded,
    },
    {
      'value': 'maintenance',
      'label': 'Maintenance Check',
      'icon': Icons.build_rounded,
    },
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Shop Check-In',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Info Card
              _buildShopInfoCard(),

              const SizedBox(height: 20),

              // Visit Purpose
              _buildVisitPurposeSection(),

              const SizedBox(height: 20),

              // Photo Section
              _buildPhotoSection(),

              const SizedBox(height: 20),

              // Notes Section
              _buildNotesSection(),

              const SizedBox(height: 32),

              // Check-In Button
              _buildCheckInButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (widget.shopType == 'dhaba'
                              ? const Color(0xFFFF6B35)
                              : const Color(0xFF6C5CE7))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.shopType == 'dhaba'
                      ? Icons.restaurant_rounded
                      : Icons.build_rounded,
                  color: widget.shopType == 'dhaba'
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFF6C5CE7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shopName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D5F),
                      ),
                    ),
                    Text(
                      widget.shopType == 'dhaba' ? 'Dhaba' : 'Puncture Shop',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'You are ${widget.distance.toStringAsFixed(0)}m away from this shop',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildVisitPurposeSection() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purpose of Visit',
              style: TextStyle(
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
              child: Column(
                children: _visitPurposes.map((purpose) {
                  final isSelected = _selectedPurpose == purpose['value'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPurpose = purpose['value'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE65100).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE65100)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              purpose['icon'],
                              color: isSelected
                                  ? const Color(0xFFE65100)
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                purpose['label'],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFE65100)
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFE65100),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPhotoSection() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D5F),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoCard(
                    'Selfie',
                    'Take a selfie for verification',
                    Icons.face_rounded,
                    _selfieImage,
                    () => _takePicture(ImageSource.camera, 'selfie'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoCard(
                    'Shop Photo',
                    'Take a photo of the shop',
                    Icons.store_rounded,
                    _shopImage,
                    () => _takePicture(ImageSource.camera, 'shop'),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPhotoCard(
    String title,
    String subtitle,
    IconData icon,
    File? image,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null
                ? const Color(0xFF4CAF50)
                : Colors.grey.shade300,
          ),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.grey.shade400, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D5F),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add any notes about your visit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE65100),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCheckInButton() {
    final bool canCheckIn = _selfieImage != null && _shopImage != null;

    return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canCheckIn && !_isLoading ? _handleCheckIn : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _isLoading ? 'Checking In...' : 'Check In to Shop',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Future<void> _takePicture(ImageSource source, String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (type == 'selfie') {
            _selfieImage = File(image.path);
          } else {
            _shopImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Create check-in data
      final checkInData = {
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'purpose': _selectedPurpose,
        'notes': _notesController.text,
        'distance': widget.distance,
        'timestamp': DateTime.now().toIso8601String(),
        'selfieImage': _selfieImage?.path,
        'shopImage': _shopImage?.path,
      };

      // TODO: Send to API
      print('Check-in data: $checkInData');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully checked in to shop!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
