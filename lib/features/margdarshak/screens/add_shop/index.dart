import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late TabController _tabController;

  // Form Controllers
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();

  // OTP Controllers
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Form Data
  String _selectedShopType = 'dhaba';
  List<String> _selectedServices = [];
  Map<String, String> _operatingHours = {
    'opening': '06:00',
    'closing': '22:00',
  };
  List<File> _shopImages = [];
  bool _consentGiven = false;
  bool _isLoading = false;

  // OTP & Verification State
  bool _isVerifyingOtp = false;
  bool _isPhoneVerified = false;
  int _otpResendTimer = 0;
  Timer? _resendTimer;

  // Location Data
  double? _latitude;
  double? _longitude;
  bool _isLocationCaptured = false;

  // Indian States List
  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  final List<String> _dhabaServices = [
    'Food Service',
    'Parking',
    'Restroom',
    'Fuel Station',
    'Truck Washing',
    'Mechanic Service',
    'ATM',
    'Mobile Charging',
  ];

  final List<String> _punctureServices = [
    'Tire Repair',
    'Tire Replacement',
    'Wheel Balancing',
    'Air Filling',
    'Emergency Service',
    'Tube Patching',
    'Valve Repair',
    'Mobile Service',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Add New Shop',
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFE65100),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE65100),
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Location'),
            Tab(text: 'Services'),
            Tab(text: 'Photos & Review'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildLocationTab(),
            _buildServicesTab(),
            _buildPhotosReviewTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Apple-style Header Card
          // Container(
          //   padding: const EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //       colors: [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)],
          //     ),
          //     borderRadius: BorderRadius.circular(20),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withValues(alpha: 0.2),
          //         blurRadius: 20,
          //         offset: const Offset(0, 10),
          //       ),
          //     ],
          //   ),
          //   // child: Row(
          //   //   children: [
          //   //     Container(
          //   //       padding: const EdgeInsets.all(12),
          //   //       decoration: BoxDecoration(
          //   //         color: Colors.white.withValues(alpha: 0.1),
          //   //         borderRadius: BorderRadius.circular(14),
          //   //       ),
          //   //       child: Icon(
          //   //         _selectedShopType == 'dhaba'
          //   //             ? Icons.restaurant_rounded
          //   //             : Icons.build_rounded,
          //   //         color: Colors.white,
          //   //         size: 28,
          //   //       ),
          //   //     ),
          //   //     const SizedBox(width: 16),
          //   //     // Expanded(
          //   //     //   child: Column(
          //   //     //     crossAxisAlignment: CrossAxisAlignment.start,
          //   //     //     children: [
          //   //     //       const Text(
          //   //     //         'New Shop Registration',
          //   //     //         style: TextStyle(
          //   //     //           color: Colors.white,
          //   //     //           fontSize: 18,
          //   //     //           fontWeight: FontWeight.w600,
          //   //     //           letterSpacing: -0.5,
          //   //     //         ),
          //   //     //       ),
          //   //     //       const SizedBox(height: 4),
          //   //     //       Text(
          //   //     //         'Fill in the details carefully',
          //   //     //         style: TextStyle(
          //   //     //           color: Colors.white.withValues(alpha: 0.7),
          //   //     //           fontSize: 14,
          //   //     //         ),
          //   //     //       ),
          //   //     //     ],
          //   //     //   ),
          //   //     // ),
          //   //   ],
          //   // ),
          // ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
          // const SizedBox(height: 28),

          // Shop Type Selection - Apple Style
          _buildAppleStyleSectionTitle('Shop Type'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAppleShopTypeCard(
                  'dhaba',
                  'Dhaba',
                  Icons.restaurant_rounded,
                  const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppleShopTypeCard(
                  'puncture',
                  'Puncture Shop',
                  Icons.build_rounded,
                  const Color(0xFF5856D6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Shop Details Section - Apple Style
          _buildAppleStyleSectionTitle('Shop Details'),
          const SizedBox(height: 14),

          // Apple-style grouped input card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildAppleTextField(
                  controller: _shopNameController,
                  label: 'Shop Name',
                  placeholder: 'Enter shop name',
                  icon: Icons.store_rounded,
                  iconColor: const Color(0xFFFF9500),
                  isFirst: true,
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  placeholder: 'Enter owner full name',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF34C759),
                ),
                _buildAppleDivider(),
                _buildAppleStateDropdown(),
                _buildAppleDivider(),
                _buildApplePhoneField(),
              ],
            ),
          ),

          // OTP Verification Status
          if (_isPhoneVerified) ...[
            const SizedBox(height: 16),
            Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF34C759).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number Verified',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Owner identity confirmed',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.95, 0.95)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildAppleStyleSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8E8E93),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAppleShopTypeCard(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedShopType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedShopType = type;
          _selectedServices.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E5EA),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _buildAppleTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    required Color iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1C1E),
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleStateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: Color(0xFF007AFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'State',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showStatePickerModal(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _stateController.text.isEmpty
                              ? 'Select state'
                              : _stateController.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _stateController.text.isEmpty
                                ? Colors.grey.shade400
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplePhoneField() {
    final mobileText = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final showOtpButton = mobileText.length == 10 && !_isPhoneVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5856D6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_rounded,
              color: Color(0xFF5856D6),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1C1E),
                  ),
                  onChanged: (value) => setState(() {}),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '10-digit mobile number',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          if (showOtpButton)
            GestureDetector(
                  onTap: () => _showOtpVerificationModal(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.9, 0.9)),
          if (_isPhoneVerified)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  void _showStatePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select State',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // States List
            Expanded(
              child: ListView.builder(
                itemCount: _indianStates.length,
                itemBuilder: (context, index) {
                  final state = _indianStates[index];
                  final isSelected = _stateController.text == state;
                  return ListTile(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stateController.text = state);
                      Navigator.pop(context);
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF007AFF).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      state,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF007AFF),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOtpVerificationModal() {
    // Clear previous OTP
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpResendTimer = 30;

    // Start resend timer
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpResendTimer > 0) {
        setState(() => _otpResendTimer--);
      } else {
        timer.cancel();
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: !_isVerifyingOtp,
      builder: (modalContext) {
        // Request focus on first OTP field after modal is shown
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _otpFocusNodes[0].requestFocus();
        });

        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            final keyboardHeight = MediaQuery.of(
              builderContext,
            ).viewInsets.bottom;
            final safeAreaBottom = MediaQuery.of(builderContext).padding.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(builderContext).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          20,
                          24,
                          20 + safeAreaBottom,
                        ),
                        child: _buildOtpModalContent(setModalState),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getOtpString() {
    return _otpControllers.map((c) => c.text).join();
  }

  Widget _buildOtpModalContent(StateSetter setModalState) {
    return Column(
      children: [
        // Icon section
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verify Phone Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to\n+91 ${_mobileController.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // OTP Input Boxes - Optimized for all screen sizes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final totalSpacing =
                  5 * 8 + 16; // 5 gaps of 8px + 1 larger gap of 16px
              final boxWidth = (availableWidth - totalSpacing) / 6;
              final finalBoxWidth = boxWidth.clamp(40.0, 56.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: finalBoxWidth,
                    height: 60,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                      right: index == 2 ? 16 : 0, // Gap after 3rd digit
                    ),
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.0,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
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
                            color: Color(0xFF007AFF),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                        setModalState(() {});
                      },
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 28),

        // Action buttons section
        Column(
          children: [
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _getOtpString().length == 6
                    ? () => _verifyOtp(setModalState)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  disabledBackgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isVerifyingOtp
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                GestureDetector(
                  onTap: _otpResendTimer == 0
                      ? () {
                          setModalState(() => _otpResendTimer = 30);
                          // Resend OTP logic here
                        }
                      : null,
                  child: Text(
                    _otpResendTimer > 0
                        ? 'Resend in ${_otpResendTimer}s'
                        : 'Resend',
                    style: TextStyle(
                      color: _otpResendTimer > 0
                          ? Colors.grey.shade400
                          : const Color(0xFF007AFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _verifyOtp(StateSetter setModalState) async {
    setModalState(() => _isVerifyingOtp = true);

    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));

    // For demo, accept any 6-digit OTP
    setModalState(() => _isVerifyingOtp = false);

    setState(() {
      _isPhoneVerified = true;
    });

    // Close keyboard before closing modal
    FocusManager.instance.primaryFocus?.unfocus();

    // Small delay to ensure keyboard closes before modal dismisses
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      Navigator.pop(context);
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF34C759),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Phone number verified successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address Section - Apple Style
          _buildAppleStyleSectionTitle('Address Details'),
          const SizedBox(height: 14),

          // Apple-style grouped input card for address
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildAppleTextField(
                  controller: _addressController,
                  label: 'Complete Address',
                  placeholder: 'Enter complete address with area details',
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFFF3B30),
                  isFirst: true,
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _districtController,
                  label: 'District',
                  placeholder: 'Enter district name',
                  icon: Icons.location_city_rounded,
                  iconColor: const Color(0xFF5856D6),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  placeholder: '6-digit pincode',
                  icon: Icons.pin_drop_rounded,
                  iconColor: const Color(0xFFFF9500),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _landmarkController,
                  label: 'Nearby Landmark',
                  placeholder: 'Enter nearby landmark (optional)',
                  icon: Icons.place_rounded,
                  iconColor: const Color(0xFF34C759),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // GPS Location Section - Apple Style
          _buildAppleStyleSectionTitle('GPS Location'),
          const SizedBox(height: 14),

          // Location Capture Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
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
                        gradient: _isLocationCaptured
                            ? const LinearGradient(
                                colors: [Color(0xFF34C759), Color(0xFF30D158)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isLocationCaptured
                            ? Icons.check_rounded
                            : Icons.gps_fixed_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLocationCaptured
                                ? 'Location Captured'
                                : 'Capture Shop Location',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _latitude != null && _longitude != null
                                ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                                : 'Tap button to capture GPS coordinates',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _captureLocation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            _isLocationCaptured
                                ? Icons.refresh_rounded
                                : Icons.my_location_rounded,
                            size: 20,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Capturing...'
                          : _isLocationCaptured
                          ? 'Update Location'
                          : 'Capture Location',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLocationCaptured
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live Map Preview - Apple Style
          _buildMapPreview(),

          const SizedBox(height: 24),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildMapPreview() {
    if (_latitude != null && _longitude != null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_latitude!, _longitude!),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tmemployeeapp.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_latitude!, _longitude!),
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // "Live" badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Coordinates overlay
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF34C759),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shop Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1C1C1E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Open in external maps app
                          // You can use url_launcher to open Google Maps
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
    }

    // Placeholder when no location captured
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.map_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Map Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture location to see map',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    final services = _selectedShopType == 'dhaba'
        ? _dhabaServices
        : _punctureServices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Services Section
          _buildSectionTitle('Services Offered'),
          const SizedBox(height: 8),
          Text(
            'Select all services available at this ${_selectedShopType == 'dhaba' ? 'dhaba' : 'puncture shop'}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Services Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final isSelected = _selectedServices.contains(service);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedServices.remove(service);
                    } else {
                      _selectedServices.add(service);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE65100).withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE65100)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? const Color(0xFFE65100)
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFE65100)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Operating Hours Section
          _buildSectionTitle('Operating Hours (Optional)'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Opening Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectTime('opening'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_operatingHours['opening']!),
                                ],
                              ),
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
                          const Text(
                            'Closing Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectTime('closing'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_operatingHours['closing']!),
                                ],
                              ),
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

          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPhotosReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos Section
          _buildSectionTitle('Shop Photos'),
          const SizedBox(height: 8),
          Text(
            'Add photos of shop front and signboard (minimum 2 photos required)',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Photo Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _shopImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _shopImages.length) {
                return _buildAddPhotoCard();
              }
              return _buildPhotoCard(_shopImages[index], index);
            },
          ),

          const SizedBox(height: 24),

          // Review Section
          _buildSectionTitle('Review & Consent'),
          const SizedBox(height: 16),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                  'Shop Type',
                  _selectedShopType == 'dhaba' ? 'Dhaba' : 'Puncture Shop',
                ),
                _buildSummaryRow(
                  'Shop Name',
                  _shopNameController.text.isEmpty
                      ? 'Not entered'
                      : _shopNameController.text,
                ),
                _buildSummaryRow(
                  'Owner Name',
                  _ownerNameController.text.isEmpty
                      ? 'Not entered'
                      : _ownerNameController.text,
                ),
                _buildSummaryRow(
                  'Mobile',
                  _mobileController.text.isEmpty
                      ? 'Not entered'
                      : _mobileController.text,
                ),
                _buildSummaryRow(
                  'District',
                  _districtController.text.isEmpty
                      ? 'Not entered'
                      : _districtController.text,
                ),
                _buildSummaryRow(
                  'Services',
                  _selectedServices.isEmpty
                      ? 'None selected'
                      : '${_selectedServices.length} services',
                ),
                _buildSummaryRow('Photos', '${_shopImages.length} photos'),
                _buildSummaryRow(
                  'GPS Location',
                  _latitude != null ? 'Captured' : 'Not captured',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Consent Checkbox
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentGiven,
                      onChanged: (value) {
                        setState(() {
                          _consentGiven = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFE65100),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terms & Data Consent',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'I confirm that all information provided is accurate and I consent to data collection and processing for business purposes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Show terms and conditions
                      },
                      child: const Text('View Terms & Conditions'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Show privacy policy
                      },
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  // Helper Widgets
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D2D5F),
      ),
    );
  }

  Widget _buildShopTypeCard(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedShopType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedShopType = type;
          _selectedServices.clear(); // Clear services when type changes
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D5F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFE65100)),
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
              borderSide: const BorderSide(color: Color(0xFFE65100), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              size: 32,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(File image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: FileImage(image), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _shopImages.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Missing Methods Implementation
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE65100)),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(color: Color(0xFFE65100)),
                ),
              ),
            ),
          if (_tabController.index > 0) const SizedBox(width: 12),
          Expanded(
            flex: _tabController.index == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_tabController.index < 3) {
                        _tabController.animateTo(_tabController.index + 1);
                      } else {
                        _handleSubmit();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _tabController.index < 3 ? 'Next' : 'Submit Shop',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      // Get high accuracy location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocationCaptured = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFE65100)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _operatingHours[type] = picked.format(context);
      });
    }
  }

  Future<void> _addPhoto() async {
    if (_shopImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 6 photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Photo Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _shopImages.add(File(image.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add photo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_shopImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 photos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture GPS location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide consent to proceed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 3));

      // Create shop data object for API submission
      final shopData = {
        'shopType': _selectedShopType,
        'shopName': _shopNameController.text,
        'ownerName': _ownerNameController.text,
        'mobile': _mobileController.text,
        'address': _addressController.text,
        'district': _districtController.text,
        'pincode': _pincodeController.text,
        'landmark': _landmarkController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'services': _selectedServices,
        'operatingHours': _operatingHours,
        'photos': _shopImages.length,
        'consentGiven': _consentGiven,
        'status': 'submitted',
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // TODO: Submit shopData to API
      print('Shop data to submit: $shopData');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 48,
            ),
            title: const Text('Shop Submitted Successfully!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your ${_selectedShopType == 'dhaba' ? 'dhaba' : 'puncture shop'} "${_shopNameController.text}" has been submitted for approval.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'What happens next?',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Shop will be reviewed within 24-48 hours\n• You will receive notification on approval\n• Once approved, drivers can be linked to this shop',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to shops page
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit shop. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
