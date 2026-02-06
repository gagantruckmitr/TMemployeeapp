import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import '../../services/margdarshak_api_service.dart';
import '../t&c_privacy_policy/index.dart';

class AddShopScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const AddShopScreen({super.key, this.editData});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late TabController _tabController;

  // API Service
  final _apiService = MargdarshakApiService();

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
  bool _isFetchingPincode = false;

  // OTP & Verification State
  bool _isVerifyingOtp = false;
  bool _isPhoneVerified = false;
  int _otpResendTimer = 0;
  Timer? _resendTimer;

  // Location Data
  double? _latitude;
  double? _longitude;
  bool _isLocationCaptured = false;

  // States Data from API
  List<Map<String, dynamic>> _statesData = [];
  String? _selectedStateId;
  bool _isLoadingStates = false;

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

  final _punctureServices = [
    'Tire Repair',
    'Tire Replacement',
    'Wheel Balancing',
    'Air Filling',
    'Emergency Service',
    'Tube Patching',
    'Valve Repair',
    'Mobile Service',
  ];

  // Additional Controllers for Dhaba Profile
  final _emailController = TextEditingController();
  final _yearEstablishedController = TextEditingController();
  final _specialDishesController = TextEditingController();
  final _peakHoursController = TextEditingController();
  final _avgWaitTimeController = TextEditingController();
  final _avgPriceRangeController = TextEditingController();

  // Banking Controllers
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  // Dhaba User ID (from OTP verification)
  int? _dhabaUserId;

  // Food Type Selection
  List<String> _selectedFoodTypes = [];
  final List<String> _foodTypeOptions = ['Veg', 'Non-Veg', 'Both'];

  // Meal Times
  bool _mealBreakfast = false;
  bool _mealLunch = false;
  bool _mealDinner = false;
  bool _mealNight = false;

  // Facilities
  bool _sittingFacility = false;
  bool _cleanRestrooms = false;
  bool _drinkingWater = false;
  bool _parkingSmall = false;
  bool _parkingLarge = false;
  bool _sleepingArea = false;
  bool _washingArea = false;
  bool _electricPoint = false;
  bool _cctv = false;
  bool _securityStaff = false;
  bool _wheelAlignment = false;
  bool _mechanicAvailable = false;

  // Operation
  bool _is24x7 = false;

  // Engagement Settings
  bool _allowCall = true;
  bool _allowMessages = true;
  bool _allowPromotions = false;

  // Location Source
  String _locationSource = 'Pinned via GPS';

  // Photo Categories
  String _selectedPhotoCategory = 'Exterior';
  final List<String> _photoCategories = ['Exterior'];

  // Puncture Shop Specific Variables
  int? _punctureUserId; // User ID from OTP verification
  String _selectedPunctureType = 'Roadside Service';
  final List<String> _punctureTypeOptions = [
    'Roadside Service',
    'Workshop',
    'Mobile Service',
    'Highway Service',
  ];

  // Puncture Services
  bool _tyreRepair = false;
  bool _airFilling = false;
  bool _tyreReplacement = false;
  bool _wheelBalancing = false;
  bool _emergencyService = false;
  bool _tubePatching = false;
  bool _valveRepair = false;
  bool _mobileService = false;

  // Puncture Photo Categories
  final List<String> _puncturePhotoCategories = ['Exterior'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadStates();
    if (widget.editData != null) {
      _populateEditData();
    }
  }

  void _populateEditData() {
    final data = widget.editData!;
    final userInfo = data['user_info'] ?? {};
    final businessInfo = data['business_info'] ?? {};
    final location = data['location'] ?? {};
    final operation = data['operation'] ?? {};
    final facilities = data['facilities'] ?? {};
    final food = data['food'] ?? {};

    // 1. User/Business Info
    _dhabaUserId = userInfo['id']; // Important for updates
    _shopNameController.text = businessInfo['dhaba_name'] ?? '';
    _ownerNameController.text =
        businessInfo['owner_name'] ?? userInfo['name'] ?? '';
    _mobileController.text = businessInfo['mobile'] ?? userInfo['mobile'] ?? '';
    _selectedShopType = businessInfo['dhaba_type'] ?? 'dhaba';

    if (_mobileController.text.isNotEmpty) {
      _isPhoneVerified = true;
    }

    // 2. Location
    _addressController.text = location['full_address'] ?? '';
    _landmarkController.text = location['landmark'] ?? '';
    _districtController.text = location['district'] ?? userInfo['city'] ?? '';
    _pincodeController.text = location['pincode'] ?? '';
    _selectedStateId = location['state_id']?.toString();

    if (location['latitude'] != null) {
      _latitude = double.tryParse(location['latitude'].toString());
      _longitude = double.tryParse(location['longitude'].toString());
      _isLocationCaptured = _latitude != null && _longitude != null;
    }

    // 3. Operations
    _is24x7 = operation['is_24x7'] == true;
    if (!_is24x7) {
      _operatingHours['opening'] = operation['opening_time'] ?? '06:00';
      _operatingHours['closing'] = operation['closing_time'] ?? '22:00';
    }

    // 4. Facilities
    _sittingFacility = facilities['sitting_facility'] == true;
    _cleanRestrooms = facilities['clean_restrooms'] == true;
    _drinkingWater = facilities['drinking_water'] == true;
    _parkingSmall = facilities['parking_small'] == true;
    _parkingLarge = facilities['parking_large'] == true;
    _sleepingArea = facilities['sleeping_area'] == true;
    _washingArea = facilities['washing_area'] == true;
    _electricPoint = facilities['electric_point'] == true;
    _cctv = facilities['cctv'] == true;
    _securityStaff = facilities['security_staff'] == true;
    _wheelAlignment = facilities['wheel_alignment'] == true;
    _mechanicAvailable = facilities['mechanic'] == true;

    // 5. Food
    _mealBreakfast = food['meal_breakfast'] == true;
    _mealLunch = food['meal_lunch'] == true;
    _mealDinner = food['meal_dinner'] == true;
    _mealNight = food['meal_night'] == true;
    _specialDishesController.text = food['special_dishes'] ?? '';
    _avgPriceRangeController.text = food['avg_price_range']?.toString() ?? '';

    // Note: Photos and detailed lists like services might need more complex handling
    // but this covers the essentials for editing.
  }

  Future<void> _loadStates() async {
    setState(() => _isLoadingStates = true);
    try {
      final states = await _apiService.getStates();
      setState(() {
        _statesData = states;
        _isLoadingStates = false;
      });
    } catch (e) {
      setState(() => _isLoadingStates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load states: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchPincodeData(String pincode) async {
    if (pincode.length != 6) return;

    setState(() => _isFetchingPincode = true);

    try {
      final url = Uri.parse('https://api.postalpincode.in/pincode/$pincode');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          final result = data[0];

          if (result['Status'] == 'Success' && result['PostOffice'] != null) {
            final postOffices = result['PostOffice'] as List;

            if (postOffices.isNotEmpty) {
              final firstOffice = postOffices[0];
              final district = firstOffice['District'] as String?;

              if (district != null && district.isNotEmpty) {
                setState(() {
                  _districtController.text = district;
                  _isFetchingPincode = false;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('District auto-filled: $district'),
                      backgroundColor: const Color(0xFF34C759),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }
            }
          }
        }
      }

      // If we reach here, pincode lookup failed
      setState(() => _isFetchingPincode = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid pincode or district not found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isFetchingPincode = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch pincode data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        title: Text(
          _selectedShopType == 'puncture'
              ? 'Add Puncture Shop Partner'
              : 'Add Dhaba Partner',
          style: const TextStyle(
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
          tabs: _selectedShopType == 'puncture'
              ? const [
                  Tab(text: 'Registration'),
                  Tab(text: 'Business Info'),
                  Tab(text: 'Location'),
                  Tab(text: 'Operation'),
                  Tab(text: 'Services'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Review'),
                ]
              : const [
                  Tab(text: 'Registration'),
                  Tab(text: 'Business Info'),
                  Tab(text: 'Location'),
                  Tab(text: 'Operation'),
                  Tab(text: 'Food & Menu'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Review'),
                ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: _selectedShopType == 'puncture'
              ? [
                  _buildRegistrationTab(),
                  _buildPunctureBusinessInfoTab(),
                  _buildLocationTab(),
                  _buildPunctureOperationTab(),
                  _buildPunctureServicesTab(),
                  _buildPhotosTab(),
                  _buildPunctureReviewTab(),
                ]
              : [
                  _buildRegistrationTab(),
                  _buildBusinessInfoTab(),
                  _buildLocationTab(),
                  _buildOperationTab(),
                  _buildFoodMenuTab(),
                  _buildPhotosTab(),
                  _buildReviewTab(),
                ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildRegistrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner Type Selection - Apple Style
          _buildAppleStyleSectionTitle('Partner Type'),
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

          // Owner Details Section - Apple Style
          _buildAppleStyleSectionTitle('Owner Details'),
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
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  placeholder: 'Enter owner full name',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF34C759),
                  isFirst: true,
                  isDisabled: _isPhoneVerified, // Disable after verification
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

          // Consent Checkbox (Apple Style Card)
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), // Subtle shadow
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _consentGiven,
                    activeColor: const Color(0xFF34C759), // Apple Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // Softer corners
                    ),
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    onChanged: (value) {
                      setState(() {
                        _consentGiven = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1C1C1E),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: const TextStyle(
                            color: Color(0xFF007AFF), // Apple Blue
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              TermsPolicyService.showTermsAndConditions(
                                context,
                              );
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              TermsPolicyService.showPrivacyPolicy(context);
                            },
                        ),
                        const TextSpan(
                          text:
                              ', and verify that valid consent has been obtained.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildBusinessInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Details Section
          _buildAppleStyleSectionTitle('Business Information'),
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
                _buildAppleTextFieldReadOnly(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF34C759),
                  isFirst: true,
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _shopNameController,
                  label: 'Dhaba Name',
                  placeholder: 'Enter dhaba name',
                  icon: Icons.store_rounded,
                  iconColor: const Color(0xFFFF9500),
                ),
                _buildAppleDivider(),
                _buildAppleTextFieldReadOnly(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF5856D6),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  placeholder: 'Enter email address',
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFF007AFF),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _yearEstablishedController,
                  label: 'Year Established',
                  placeholder: 'e.g. 2015',
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFFAF52DE),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Dhaba Type Section
          _buildAppleStyleSectionTitle('Dhaba Type'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDhabaTypeOption(
                  'Highway Dhaba',
                  Icons.local_shipping_rounded,
                ),
                _buildAppleDivider(),
                _buildDhabaTypeOption(
                  'City Dhaba',
                  Icons.location_city_rounded,
                ),
                _buildAppleDivider(),
                _buildDhabaTypeOption('Village Dhaba', Icons.home_rounded),
                _buildAppleDivider(),
                _buildDhabaTypeOption('Tourist Dhaba', Icons.tour_rounded),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  String _selectedDhabaType = 'Highway Dhaba';

  Widget _buildDhabaTypeOption(String type, IconData icon) {
    final isSelected = _selectedDhabaType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedDhabaType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF9500).withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFFF9500)
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFFF9500)
                      : const Color(0xFF1C1C1E),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF9500),
                size: 22,
              ),
          ],
        ),
      ),
    );
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

  Widget _buildPincodeField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.pin_drop_rounded,
              color: Color(0xFFFF9500),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pincode',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1C1E),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    if (value.length == 6) {
                      _fetchPincodeData(value);
                    } else if (value.length < 6) {
                      // Clear district if pincode is incomplete
                      setState(() {
                        _districtController.clear();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '6-digit pincode',
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
          if (_isFetchingPincode)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF9500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistrictField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _districtController.text.isNotEmpty
            ? const Color(0xFF34C759).withValues(alpha: 0.05)
            : Colors.white,
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
              Icons.location_city_rounded,
              color: Color(0xFF5856D6),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'District',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_districtController.text.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Auto-filled',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _districtController,
                  enabled: _districtController
                      .text
                      .isEmpty, // Allow manual entry if not auto-filled
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _districtController.text.isNotEmpty
                        ? const Color(0xFF34C759)
                        : const Color(0xFF1C1C1E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter pincode to auto-fill',
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
          if (_districtController.text.isNotEmpty)
            const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 20),
        ],
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
    final isDisabled = _isPhoneVerified; // Disable after phone verification

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
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
          color: isDisabled
              ? Colors.grey.shade100
              : (isSelected ? color : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : (isSelected ? color : const Color(0xFFE5E5EA)),
            width: isSelected && !isDisabled ? 2 : 1,
          ),
          boxShadow: isSelected && !isDisabled
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
            Icon(
              icon,
              size: 32,
              color: isDisabled
                  ? Colors.grey.shade400
                  : (isSelected ? Colors.white : color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? Colors.grey.shade500
                    : (isSelected ? Colors.white : const Color(0xFF1C1C1E)),
              ),
            ),
            if (isDisabled) ...[
              const SizedBox(height: 4),
              Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade400),
            ],
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
    bool isDisabled = false, // Add disabled parameter
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade50 : Colors.white,
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
                  enabled: !isDisabled,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDisabled
                        ? Colors.grey.shade600
                        : const Color(0xFF1C1C1E),
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
          if (isDisabled)
            Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }

  Widget _buildAppleTextFieldReadOnly({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
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
                Text(
                  controller.text.isEmpty ? 'Not set' : controller.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: controller.text.isEmpty
                        ? Colors.grey.shade400
                        : const Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }

  Widget _buildAppleStateDropdown() {
    final isDisabled = _isPhoneVerified; // Disable after phone verification

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade50 : Colors.white,
      ),
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
                  onTap: isDisabled ? null : () => _showStatePickerModal(),
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
                        isDisabled
                            ? Icons.lock_rounded
                            : Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: isDisabled ? 18 : 22,
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

  // Duplicate for Location tab without verify check
  Widget _buildLocationStateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.map_rounded,
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
      decoration: BoxDecoration(
        color: _isPhoneVerified ? Colors.grey.shade50 : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                  enabled: !_isPhoneVerified, // Disable after verification
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isPhoneVerified
                        ? Colors.grey.shade600
                        : const Color(0xFF1C1C1E),
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
            Row(
              children: [
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
                const SizedBox(width: 8),
                Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 18),
              ],
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
        height: MediaQuery.of(context).size.height * 0.9,
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
              child: _isLoadingStates
                  ? const Center(child: CircularProgressIndicator())
                  : _statesData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No states available',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadStates();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _statesData.length,
                      itemBuilder: (context, index) {
                        final state = _statesData[index];
                        final stateName = state['name'] as String;
                        final stateId = state['id'].toString();
                        final isSelected = _selectedStateId == stateId;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFF007AFF,
                                  ).withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF007AFF)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: stateId,
                            groupValue: _selectedStateId,
                            onChanged: (value) {
                              if (value != null) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _stateController.text = stateName;
                                  _selectedStateId = value;
                                });
                                Navigator.pop(context);
                              }
                            },
                            title: Text(
                              stateName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: const Color(0xFF1C1C1E),
                              ),
                            ),
                            activeColor: const Color(0xFF007AFF),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

  void _showOtpVerificationModal() async {
    // Validate required fields
    if (_ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter owner name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedStateId == null || _stateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    setState(() => _isLoading = true);

    try {
      // Send OTP via API - use different endpoint based on shop type
      final response = _selectedShopType == 'dhaba'
          ? await _apiService.sendDhabaRegistrationOtp(
              mobile: _mobileController.text,
              name: _ownerNameController.text,
              stateId: _selectedStateId!,
            )
          : await _apiService.sendPunctureRegistrationOtp(
              mobile: _mobileController.text,
              name: _ownerNameController.text,
              stateId: _selectedStateId!,
            );

      setState(() => _isLoading = false);

      if (response['success'] == true) {
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

        // Show OTP modal
        _showOtpModal();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOtpModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (modalContext) {
        // Request focus on first OTP field after modal is shown
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_otpFocusNodes.isNotEmpty) {
            _otpFocusNodes[0].requestFocus();
          }
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
                  maxHeight: MediaQuery.of(builderContext).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with Handle and Close Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Handle
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          //     // Close Button
                          // Positioned(
                          //   right: 16,
                          //   top: 8,
                          //   child: GestureDetector(
                          //     onTap: () => Navigator.pop(modalContext),
                          //     child: Container(
                          //       padding: const EdgeInsets.all(8),
                          //       decoration: BoxDecoration(
                          //         color: Colors.grey.shade100,
                          //         shape: BoxShape.circle,
                          //       ),
                          //       child: const Icon(
                          //         Icons.close,
                          //         size: 20,
                          //         color: Colors.black54,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          0,
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
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace &&
                            _otpControllers[index].text.isEmpty &&
                            index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.number,
                        maxLength: null,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          height: 1.0,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
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
                          if (value.isNotEmpty) {
                            if (value.length > 1) {
                              // Overwrite behavior: take the last char
                              final lastChar = value.characters.last;
                              _otpControllers[index].text = lastChar;
                              _otpControllers[index].selection =
                                  TextSelection.fromPosition(
                                    const TextPosition(offset: 1),
                                  );
                            }
                            // Move to next field
                            if (index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }
                          setModalState(() {});
                        },
                      ),
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
                      ? () async {
                          setModalState(() => _otpResendTimer = 30);

                          // Resend OTP logic - use correct API based on shop type
                          try {
                            final response = _selectedShopType == 'dhaba'
                                ? await _apiService.sendDhabaRegistrationOtp(
                                    mobile: _mobileController.text,
                                    name: _ownerNameController.text,
                                    stateId: _selectedStateId!,
                                  )
                                : await _apiService.sendPunctureRegistrationOtp(
                                    mobile: _mobileController.text,
                                    name: _ownerNameController.text,
                                    stateId: _selectedStateId!,
                                  );

                            if (response['success'] == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP resent successfully'),
                                  backgroundColor: Color(0xFF34C759),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to resend OTP: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
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
    final otpCode = _getOtpString();

    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setModalState(() => _isVerifyingOtp = true);

    try {
      // Verify OTP via API
      final response = await _apiService.verifyDhabaRegistrationOtp(
        mobile: _mobileController.text,
        otp: otpCode,
      );

      setModalState(() => _isVerifyingOtp = false);

      if (response['success'] == true) {
        // Extract and store the user_id for subsequent API calls
        final userData = response['user'];
        setState(() {
          _isPhoneVerified = true;
          if (_selectedShopType == 'puncture') {
            _punctureUserId = userData?['id'];
          } else {
            _dhabaUserId = userData?['id'];
          }
        });

        // Close keyboard before closing modal
        FocusManager.instance.primaryFocus?.unfocus();

        // Small delay to ensure keyboard closes before modal dismisses
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          Navigator.pop(context);
        }

        // Show success message with user info
        final uniqueId = userData?['unique_id'] ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Expanded(child: Text('Registration successful!')),
                  ],
                ),
                if (uniqueId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Unique ID: $uniqueId',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Invalid OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setModalState(() => _isVerifyingOtp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                _buildPincodeField(), // Pincode field with auto-fetch
                _buildAppleDivider(),
                _buildDistrictField(), // District field (auto-filled)
                _buildAppleDivider(),
                _buildLocationStateDropdown(), // New state dropdown
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

  Widget _buildOperationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operating Hours Section
          _buildAppleStyleSectionTitle('Operating Hours'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 24x7 Toggle
                SwitchListTile(
                  value: _is24x7,
                  onChanged: (value) => setState(() => _is24x7 = value),
                  title: const Text(
                    'Open 24x7',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Available round the clock'),
                  activeColor: const Color(0xFF34C759),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_is24x7) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime('opening'),
                          child: _buildTimeCard(
                            'Opening',
                            _operatingHours['opening']!,
                            Icons.wb_sunny_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime('closing'),
                          child: _buildTimeCard(
                            'Closing',
                            _operatingHours['closing']!,
                            Icons.nightlight_round,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Facilities Section
          _buildAppleStyleSectionTitle('Facilities'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFacilitySwitch(
                  'Sitting Area',
                  Icons.chair_rounded,
                  _sittingFacility,
                  (v) => setState(() => _sittingFacility = v),
                ),
                _buildFacilitySwitch(
                  'Clean Restrooms',
                  Icons.wc_rounded,
                  _cleanRestrooms,
                  (v) => setState(() => _cleanRestrooms = v),
                ),
                _buildFacilitySwitch(
                  'Drinking Water',
                  Icons.water_drop_rounded,
                  _drinkingWater,
                  (v) => setState(() => _drinkingWater = v),
                ),
                _buildFacilitySwitch(
                  'Parking (Small)',
                  Icons.local_parking_rounded,
                  _parkingSmall,
                  (v) => setState(() => _parkingSmall = v),
                ),
                _buildFacilitySwitch(
                  'Parking (Truck)',
                  Icons.local_shipping_rounded,
                  _parkingLarge,
                  (v) => setState(() => _parkingLarge = v),
                ),
                _buildFacilitySwitch(
                  'Sleeping Area',
                  Icons.hotel_rounded,
                  _sleepingArea,
                  (v) => setState(() => _sleepingArea = v),
                ),
                _buildFacilitySwitch(
                  'Vehicle Washing',
                  Icons.local_car_wash_rounded,
                  _washingArea,
                  (v) => setState(() => _washingArea = v),
                ),
                _buildFacilitySwitch(
                  'Electric Charging',
                  Icons.ev_station_rounded,
                  _electricPoint,
                  (v) => setState(() => _electricPoint = v),
                ),
                _buildFacilitySwitch(
                  'CCTV',
                  Icons.videocam_rounded,
                  _cctv,
                  (v) => setState(() => _cctv = v),
                ),
                _buildFacilitySwitch(
                  'Security Staff',
                  Icons.security_rounded,
                  _securityStaff,
                  (v) => setState(() => _securityStaff = v),
                ),
                _buildFacilitySwitch(
                  'Wheel Alignment',
                  Icons.build_rounded,
                  _wheelAlignment,
                  (v) => setState(() => _wheelAlignment = v),
                ),
                _buildFacilitySwitch(
                  'Mechanic Available',
                  Icons.engineering_rounded,
                  _mechanicAvailable,
                  (v) => setState(() => _mechanicAvailable = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTimeCard(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: icon == Icons.wb_sunny_rounded
                    ? Colors.amber
                    : Colors.indigoAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.expand_more_rounded,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilitySwitch(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? const Color(0xFF34C759) : Colors.grey.shade400,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF34C759),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodMenuTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppleStyleSectionTitle('Food Type'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _foodTypeOptions.map((type) {
                final isSelected = _selectedFoodTypes.contains(type);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isSelected) {
                          _selectedFoodTypes.remove(type);
                        } else {
                          _selectedFoodTypes.add(type);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF34C759).withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF34C759)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF34C759)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          _buildAppleStyleSectionTitle('Meal Services'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFacilitySwitch(
                  'Breakfast',
                  Icons.free_breakfast_rounded,
                  _mealBreakfast,
                  (v) => setState(() => _mealBreakfast = v),
                ),
                _buildFacilitySwitch(
                  'Lunch',
                  Icons.lunch_dining_rounded,
                  _mealLunch,
                  (v) => setState(() => _mealLunch = v),
                ),
                _buildFacilitySwitch(
                  'Dinner',
                  Icons.dinner_dining_rounded,
                  _mealDinner,
                  (v) => setState(() => _mealDinner = v),
                ),
                _buildFacilitySwitch(
                  'Night Service',
                  Icons.nightlight_round,
                  _mealNight,
                  (v) => setState(() => _mealNight = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildAppleStyleSectionTitle('Menu Details'),
          const SizedBox(height: 14),

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
                  controller: _specialDishesController,
                  label: 'Special Dishes',
                  placeholder: 'e.g. Dal Makhani, Butter Chicken',
                  icon: Icons.restaurant_menu_rounded,
                  iconColor: const Color(0xFFFF9500),
                  isFirst: true,
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _avgPriceRangeController,
                  label: 'Avg Price Per Plate',
                  placeholder: 'e.g. ₹80-150',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF34C759),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPhotosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppleStyleSectionTitle('Shop Photos (Max 7)'),
          const SizedBox(height: 14),

          SizedBox(
            height: 160,
            child: _shopImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No photos yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _shopImages.length,
                    itemBuilder: (context, index) {
                      final photo = _shopImages[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: DecorationImage(
                            image: FileImage(photo),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _shopImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: _addPhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Color(0xFFFF9500),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to capture or select',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppleStyleSectionTitle('Banking Details (Optional)'),
          const SizedBox(height: 14),

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
                  controller: _accountHolderController,
                  label: 'Account Holder Name',
                  placeholder: 'Enter name as per bank',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF007AFF),
                  isFirst: true,
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  placeholder: 'e.g. State Bank of India',
                  icon: Icons.account_balance_rounded,
                  iconColor: const Color(0xFF5856D6),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  placeholder: 'Enter account number',
                  icon: Icons.numbers_rounded,
                  iconColor: const Color(0xFFFF9500),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _ifscCodeController,
                  label: 'IFSC Code',
                  placeholder: 'e.g. SBIN0001234',
                  icon: Icons.code_rounded,
                  iconColor: const Color(0xFF34C759),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildAppleStyleSectionTitle('Engagement Settings'),
          const SizedBox(height: 14),

          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(16),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withValues(alpha: 0.06),
          //         blurRadius: 20,
          //         offset: const Offset(0, 4),
          //       ),
          //     ],
          //   ),
          //   padding: const EdgeInsets.all(16),
          //   child: Column(
          //     children: [
          //       _buildFacilitySwitch(
          //         'Allow Calls',
          //         Icons.call_rounded,
          //         _allowCall,
          //         (v) => setState(() => _allowCall = v),
          //       ),
          //       _buildFacilitySwitch(
          //         'Allow Messages',
          //         Icons.message_rounded,
          //         _allowMessages,
          //         (v) => setState(() => _allowMessages = v),
          //       ),
          //       _buildFacilitySwitch(
          //         'Allow Promotions',
          //         Icons.campaign_rounded,
          //         _allowPromotions,
          //         (v) => setState(() => _allowPromotions = v),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 24),

          // Photos Section
          _buildAppleStyleSectionTitle('Shop Photos (${_shopImages.length})'),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(16),
            child: _shopImages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No photos added',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _shopImages.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _shopImages[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
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

  // ==========================================
  // PUNCTURE SHOP SPECIFIC TABS
  // ==========================================

  Widget _buildPunctureBusinessInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Details Section
          _buildAppleStyleSectionTitle('Business Information'),
          const SizedBox(height: 14),

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
                _buildAppleTextFieldReadOnly(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF34C759),
                  isFirst: true,
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _shopNameController,
                  label: 'Puncture Shop Name',
                  placeholder: 'Enter shop name',
                  icon: Icons.build_rounded,
                  iconColor: const Color(0xFF5856D6),
                ),
                _buildAppleDivider(),
                _buildAppleTextFieldReadOnly(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF5856D6),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  placeholder: 'Enter email address',
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFF007AFF),
                ),
                _buildAppleDivider(),
                _buildAppleTextField(
                  controller: _yearEstablishedController,
                  label: 'Year Established',
                  placeholder: 'e.g. 2015',
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFFAF52DE),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Puncture Type Section
          _buildAppleStyleSectionTitle('Shop Type'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPunctureTypeOption(
                  'Roadside Service',
                  Icons.directions_car_rounded,
                ),
                _buildAppleDivider(),
                _buildPunctureTypeOption('Workshop', Icons.home_work_rounded),
                _buildAppleDivider(),
                _buildPunctureTypeOption(
                  'Mobile Service',
                  Icons.local_shipping_rounded,
                ),
                _buildAppleDivider(),
                _buildPunctureTypeOption(
                  'Highway Service',
                  Icons.route_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPunctureTypeOption(String type, IconData icon) {
    final isSelected = _selectedPunctureType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPunctureType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5856D6).withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF5856D6)
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF5856D6)
                      : const Color(0xFF1C1C1E),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF5856D6),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunctureOperationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operating Hours Section
          _buildAppleStyleSectionTitle('Operating Hours'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 24x7 Toggle
                SwitchListTile(
                  value: _is24x7,
                  onChanged: (value) => setState(() => _is24x7 = value),
                  title: const Text(
                    'Open 24x7',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Available round the clock'),
                  activeColor: const Color(0xFF34C759),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_is24x7) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime('opening'),
                          child: _buildTimeCard(
                            'Opening',
                            _operatingHours['opening']!,
                            Icons.wb_sunny_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime('closing'),
                          child: _buildTimeCard(
                            'Closing',
                            _operatingHours['closing']!,
                            Icons.nightlight_round,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPunctureServicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppleStyleSectionTitle('Services Offered'),
          const SizedBox(height: 14),

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFacilitySwitch(
                  'Tire Repair',
                  Icons.build_circle_rounded,
                  _tyreRepair,
                  (v) => setState(() => _tyreRepair = v),
                ),
                _buildFacilitySwitch(
                  'Air Filling',
                  Icons.air_rounded,
                  _airFilling,
                  (v) => setState(() => _airFilling = v),
                ),
                _buildFacilitySwitch(
                  'Tire Replacement',
                  Icons.change_circle_rounded,
                  _tyreReplacement,
                  (v) => setState(() => _tyreReplacement = v),
                ),
                _buildFacilitySwitch(
                  'Wheel Balancing',
                  Icons.settings_rounded,
                  _wheelBalancing,
                  (v) => setState(() => _wheelBalancing = v),
                ),
                _buildFacilitySwitch(
                  'Emergency Service',
                  Icons.emergency_rounded,
                  _emergencyService,
                  (v) => setState(() => _emergencyService = v),
                ),
                _buildFacilitySwitch(
                  'Tube Patching',
                  Icons.handyman_rounded,
                  _tubePatching,
                  (v) => setState(() => _tubePatching = v),
                ),
                _buildFacilitySwitch(
                  'Valve Repair',
                  Icons.plumbing_rounded,
                  _valveRepair,
                  (v) => setState(() => _valveRepair = v),
                ),
                _buildFacilitySwitch(
                  'Mobility Service',
                  Icons.directions_car_rounded,
                  _mobileService,
                  (v) => setState(() => _mobileService = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPunctureReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5856D6), Color(0xFF007AFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review & Submit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Verify all details before submission',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Business Info Summary
          _buildAppleStyleSectionTitle('Business Information'),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Shop Name', _shopNameController.text),
                const Divider(height: 24),
                _buildSummaryRow('Owner Name', _ownerNameController.text),
                const Divider(height: 24),
                _buildSummaryRow('Mobile', _mobileController.text),
                const Divider(height: 24),
                _buildSummaryRow('Shop Type', _selectedPunctureType),
                if (_emailController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildSummaryRow('Email', _emailController.text),
                ],
                if (_yearEstablishedController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Established',
                    _yearEstablishedController.text,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Location Summary
          _buildAppleStyleSectionTitle('Location'),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Address', _addressController.text),
                if (_landmarkController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildSummaryRow('Landmark', _landmarkController.text),
                ],
                const Divider(height: 24),
                _buildSummaryRow('District', _districtController.text),
                const Divider(height: 24),
                _buildSummaryRow('State', _stateController.text),
                const Divider(height: 24),
                _buildSummaryRow('Pincode', _pincodeController.text),
                if (_latitude != null && _longitude != null) ...[
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'GPS',
                    '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Operation Summary
          _buildAppleStyleSectionTitle('Operation'),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(16),
            child: _buildSummaryRow(
              'Hours',
              _is24x7
                  ? '24x7 Open'
                  : '${_operatingHours['opening']} - ${_operatingHours['closing']}',
            ),
          ),

          const SizedBox(height: 16),

          // Services Summary
          _buildAppleStyleSectionTitle('Services'),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_tyreRepair) _buildServiceChip('Tire Repair'),
                if (_airFilling) _buildServiceChip('Air Filling'),
                if (_tyreReplacement) _buildServiceChip('Tire Replacement'),
                if (_wheelBalancing) _buildServiceChip('Wheel Balancing'),
                if (_emergencyService) _buildServiceChip('Emergency Service'),
                if (_tubePatching) _buildServiceChip('Tube Patching'),
                if (_valveRepair) _buildServiceChip('Valve Repair'),
                if (_mobileService) _buildServiceChip('Mobile Service'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Photos Summary
          _buildAppleStyleSectionTitle('Shop Photos (${_shopImages.length})'),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(16),
            child: _shopImages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No photos added',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _shopImages.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _shopImages[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // Consent
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consentGiven,
                  onChanged: (v) => setState(() => _consentGiven = v ?? false),
                  activeColor: const Color(0xFF5856D6),
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
                        'I confirm all information is accurate and consent to data processing.',
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
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPunctureProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5856D6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildServiceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF34C759).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF34C759),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // END PUNCTURE SHOP SPECIFIC TABS
  // ==========================================

  // Missing Methods Implementation
  Widget _buildBottomNavigation() {
    // Check if phone is verified for Registration tab (index 0)
    final bool canProceedFromRegistration =
        _tabController.index != 0 || (_isPhoneVerified && _consentGiven);

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
            flex: 1,
            child: ElevatedButton(
              onPressed: (_isLoading || !canProceedFromRegistration)
                  ? null
                  : () => _handleNextStep(),
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
                      _tabController.index < 6
                          ? 'Save & Next'
                          : 'Submit Partner',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle step-by-step navigation with API calls
  Future<void> _handleNextStep() async {
    final currentIndex = _tabController.index;
    print('🔄 Handling next step for tab index: $currentIndex');
    print('🔄 Shop type: $_selectedShopType');

    // Route based on shop type
    if (_selectedShopType == 'puncture') {
      await _handlePunctureNextStep(currentIndex);
    } else {
      await _handleDhabaNextStep(currentIndex);
    }
  }

  /// Handle Dhaba flow
  Future<void> _handleDhabaNextStep(int currentIndex) async {
    switch (currentIndex) {
      case 0: // Registration
        print('✅ Moving from Registration to Business Info');
        _tabController.animateTo(1);
        break;
      case 1: // Business Info
        print('🚀 Saving Business Info...');
        await _saveBusinessInfo();
        break;
      case 2: // Location
        print('🚀 Saving Location...');
        await _saveLocation();
        break;
      case 3: // Operation
        print('🚀 Saving Operation & Facilities...');
        await _saveOperationAndFacilities();
        break;
      case 4: // Food & Menu
        print('🚀 Saving Food Details...');
        await _saveFoodDetails();
        break;
      case 5: // Photos
        print('🚀 Uploading Photos...');
        await _savePhotos();
        break;
      case 6: // Review
        print('🚀 Completing Dhaba Profile...');
        await _completeDhabaProfile();
        break;
    }
  }

  /// Handle Puncture flow
  Future<void> _handlePunctureNextStep(int currentIndex) async {
    switch (currentIndex) {
      case 0: // Registration
        print('✅ Moving from Registration to Business Info');
        _tabController.animateTo(1);
        break;
      case 1: // Business Info
        print('🚀 Saving Puncture Business Info...');
        await _savePunctureBusinessInfoStep();
        break;
      case 2: // Location
        print('🚀 Saving Puncture Location...');
        await _savePunctureLocationStep();
        break;
      case 3: // Operation
        print('🚀 Saving Puncture Operation...');
        await _savePunctureOperationStep();
        break;
      case 4: // Services
        print('🚀 Saving Puncture Services...');
        await _savePunctureServicesStep();
        break;
      case 5: // Photos
        print('🚀 Uploading Puncture Photos...');
        await _savePuncturePhotosStep();
        break;
      case 6: // Review
        print('🚀 Submitting Puncture Profile...');
        await _submitPunctureProfile();
        break;
    }
  }

  /// Step 1: Save Business Info
  Future<void> _saveBusinessInfo() async {
    if (_dhabaUserId == null) {
      _showError('Registration not complete. Please verify phone first.');
      return;
    }

    if (_shopNameController.text.isEmpty || _ownerNameController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.saveDhabaBusinessInfo(
        dhabaUserId: _dhabaUserId!,
        dhabaName: _shopNameController.text,
        ownerName: _ownerNameController.text,
        mobile: _mobileController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        yearEstablished: _yearEstablishedController.text.isNotEmpty
            ? _yearEstablishedController.text
            : null,
        dhabaType: _selectedDhabaType,
      );

      if (response['success'] == true) {
        _showSuccess('Business info saved successfully');
        _tabController.animateTo(2);
      } else {
        _showError(response['message'] ?? 'Failed to save business info');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 2: Save Location
  Future<void> _saveLocation() async {
    if (_dhabaUserId == null) {
      _showError('Registration not complete');
      return;
    }

    if (_addressController.text.isEmpty ||
        _latitude == null ||
        _longitude == null) {
      _showError('Please capture location and fill address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.saveDhabaLocation(
        dhabaUserId: _dhabaUserId!,
        fullAddress: _addressController.text,
        landmark: _landmarkController.text.isNotEmpty
            ? _landmarkController.text
            : null,
        stateId: int.tryParse(_selectedStateId ?? '1') ?? 1,
        district: _districtController.text.isNotEmpty
            ? _districtController.text
            : null,
        pincode: _pincodeController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        locationSource: _locationSource,
      );

      if (response['success'] == true) {
        _showSuccess('Location saved successfully');
        _tabController.animateTo(3);
      } else {
        _showError(response['message'] ?? 'Failed to save location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 3: Save Operation and Facilities
  Future<void> _saveOperationAndFacilities() async {
    if (_dhabaUserId == null) {
      _showError('Registration not complete');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save operation details
      final operationResponse = await _apiService.saveDhabaOperation(
        dhabaUserId: _dhabaUserId!,
        openingTime: _is24x7 ? null : _operatingHours['opening'],
        closingTime: _is24x7 ? null : _operatingHours['closing'],
        is24x7: _is24x7,
        peakHours: _peakHoursController.text.isNotEmpty
            ? _peakHoursController.text
            : null,
        avgWaitTime: _avgWaitTimeController.text.isNotEmpty
            ? _avgWaitTimeController.text
            : null,
      );

      if (operationResponse['success'] != true) {
        _showError(operationResponse['message'] ?? 'Failed to save operation');
        return;
      }

      // Save facilities
      final facilitiesResponse = await _apiService.saveDhabaFacilities(
        dhabaUserId: _dhabaUserId!,
        sittingFacility: _sittingFacility,
        cleanRestrooms: _cleanRestrooms,
        drinkingWater: _drinkingWater,
        parkingSmall: _parkingSmall,
        parkingLarge: _parkingLarge,
        sleepingArea: _sleepingArea,
        washingArea: _washingArea,
        electricPoint: _electricPoint,
        cctv: _cctv,
        securityStaff: _securityStaff,
        wheelAlignment: _wheelAlignment,
        mechanic: _mechanicAvailable,
      );

      if (facilitiesResponse['success'] == true) {
        _showSuccess('Operation & Facilities saved successfully');
        _tabController.animateTo(4);
      } else {
        _showError(
          facilitiesResponse['message'] ?? 'Failed to save facilities',
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 4: Save Food Details
  Future<void> _saveFoodDetails() async {
    if (_dhabaUserId == null) {
      _showError('Registration not complete');
      return;
    }

    if (_selectedFoodTypes.isEmpty) {
      _showError('Please select at least one food type');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.saveDhabaFood(
        dhabaUserId: _dhabaUserId!,
        foodType: _selectedFoodTypes.toList(),
        specialDishes: _specialDishesController.text.isNotEmpty
            ? _specialDishesController.text
            : null,
        mealBreakfast: _mealBreakfast,
        mealLunch: _mealLunch,
        mealDinner: _mealDinner,
        mealNight: _mealNight,
        avgPriceRange: _avgPriceRangeController.text.isNotEmpty
            ? _avgPriceRangeController.text
            : null,
      );

      if (response['success'] == true) {
        _showSuccess('Food details saved successfully');
        _tabController.animateTo(5);
      } else {
        _showError(response['message'] ?? 'Failed to save food details');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 5: Save Photos
  Future<void> _savePhotos() async {
    if (_dhabaUserId == null) {
      _showError('Registration not complete');
      return;
    }

    if (_shopImages.isEmpty) {
      _showError('Please add at least one photo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert File list to path strings
      final imagePaths = _shopImages.map((f) => f.path).toList();

      final response = await _apiService.uploadDhabaPhotos(
        dhabaUserId: _dhabaUserId!,
        category: _selectedPhotoCategory,
        imagePaths: imagePaths,
      );

      if (response['success'] == true) {
        _showSuccess('Photos uploaded successfully');
        _tabController.animateTo(6);
      } else {
        _showError(response['message'] ?? 'Failed to upload photos');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 6: Complete profile with banking and engagement
  Future<void> _completeDhabaProfile() async {
    if (_dhabaUserId == null) {
      _showError('Registration not complete');
      return;
    }

    if (!_consentGiven) {
      _showError('Please accept the terms and consent');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save banking details (if provided)
      if (_accountNumberController.text.isNotEmpty) {
        print('🚀 Saving Banking Details...');
        final bankingResponse = await _apiService.saveDhabaBanking(
          dhabaUserId: _dhabaUserId!,
          accountHolderName: _accountHolderController.text,
          bankName: _bankNameController.text,
          accountNumber: _accountNumberController.text,
          ifscCode: _ifscCodeController.text,
        );

        if (bankingResponse['success'] == true) {
          print('✅ Banking details saved successfully');
        } else {
          print('⚠️ Banking info not saved: ${bankingResponse['message']}');
          // We don't stop here as banking is optional, but it's good to know
        }
      } else {
        print('ℹ️ Banking details skipped (not provided)');
      }

      // Save engagement settings
      print('🚀 Saving Engagement Settings...');
      final engagementResponse = await _apiService.saveDhabaEngagement(
        dhabaUserId: _dhabaUserId!,
        allowCall: _allowCall,
        allowMessages: _allowMessages,
        allowPromotions: _allowPromotions,
      );

      if (engagementResponse['success'] == true) {
        print('✅ Engagement settings saved successfully');
        _showSuccess('Partner profile completed successfully!');

        // Wait a small moment to let the user see the success message
        await Future.delayed(const Duration(milliseconds: 1500));

        // Navigate back or to success screen
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showError(
          engagementResponse['message'] ?? 'Failed to save engagement settings',
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    // Log the full error to terminal
    print('🔴 UI Error: $message');

    // Sanitize message for user display
    String displayMessage = message;
    if (message.contains('SQLSTATE') ||
        message.contains('Constraint violation') ||
        message.contains('HTTP 500') ||
        message.contains('Exception:')) {
      displayMessage = 'Server Error. Please try again later.';
    } else if (message.startsWith('Error: Exception:')) {
      displayMessage = 'Server connection failed.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFF9500),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1C1C1E),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      // Format to 12-hour format with AM/PM
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formattedTime = '$hour:$minute $period';

      setState(() {
        _operatingHours[type] = formattedTime;
      });
    }
  }

  Future<void> _addPhoto() async {
    if (_shopImages.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 7 photos allowed'),
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
            title: const Text('Partner Submitted Successfully!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your ${_selectedShopType == 'dhaba' ? 'dhaba' : 'puncture partner'} "${_shopNameController.text}" has been submitted for approval.',
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
                        '• Partner will be reviewed within 24-48 hours\n• You will receive notification on approval\n• Once approved, drivers can be linked to this partner',
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
                  Navigator.of(context).pop(); // Go back to partners page
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
            content: Text('Failed to submit partner. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // PUNCTURE SHOP SAVE METHODS
  // ==========================================

  /// Step 1: Save Puncture Business Info (with navigation)
  Future<void> _savePunctureBusinessInfoStep() async {
    if (_punctureUserId == null) {
      _showError('Registration not complete. Please verify phone first.');
      return;
    }

    if (_shopNameController.text.isEmpty || _ownerNameController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.savePunctureBusinessInfo(
        punctureUserId: _punctureUserId!,
        punctureName: _shopNameController.text,
        ownerName: _ownerNameController.text,
        mobile: _mobileController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        yearEstablished: _yearEstablishedController.text.isNotEmpty
            ? _yearEstablishedController.text
            : null,
        punctureType: _selectedPunctureType,
      );

      if (response['success'] == true) {
        print('✅ Puncture business info saved');
        _showSuccess('Business info saved successfully');
        _tabController.animateTo(2);
      } else {
        _showError(response['message'] ?? 'Failed to save business info');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 2: Save Puncture Location (with navigation)
  Future<void> _savePunctureLocationStep() async {
    if (_punctureUserId == null) {
      _showError('Registration not complete');
      return;
    }

    if (_addressController.text.isEmpty ||
        _selectedStateId == null ||
        _pincodeController.text.isEmpty ||
        _latitude == null ||
        _longitude == null) {
      _showError('Please fill in all location details and capture GPS');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.savePunctureLocation(
        punctureUserId: _punctureUserId!,
        fullAddress: _addressController.text,
        landmark: _landmarkController.text.isNotEmpty
            ? _landmarkController.text
            : null,
        stateId: int.parse(_selectedStateId!),
        district: _districtController.text.isNotEmpty
            ? _districtController.text
            : null,
        pincode: _pincodeController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        locationSource: _locationSource,
      );

      if (response['success'] == true) {
        print('✅ Puncture location saved');
        _showSuccess('Location saved successfully');
        _tabController.animateTo(3);
      } else {
        _showError(response['message'] ?? 'Failed to save location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 3: Save Puncture Operation (with navigation)
  Future<void> _savePunctureOperationStep() async {
    if (_punctureUserId == null) {
      _showError('Registration not complete');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.savePunctureOperation(
        punctureUserId: _punctureUserId!,
        openingTime: _is24x7 ? null : '${_operatingHours['opening']}:00',
        closingTime: _is24x7 ? null : '${_operatingHours['closing']}:00',
        is24x7: _is24x7,
      );

      if (response['success'] == true) {
        print('✅ Puncture operation saved');
        _showSuccess('Operation details saved successfully');
        _tabController.animateTo(4);
      } else {
        _showError(response['message'] ?? 'Failed to save operation');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 4: Save Puncture Services (with navigation)
  Future<void> _savePunctureServicesStep() async {
    if (_punctureUserId == null) {
      _showError('Registration not complete');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.savePunctureServices(
        punctureUserId: _punctureUserId!,
        tyreRepair: _tyreRepair,
        airFilling: _airFilling,
        mechanic: _mechanicAvailable,
        tyreReplacement: _tyreReplacement,
        wheelBalancing: _wheelBalancing,
        emergencyService: _emergencyService,
        tubePatching: _tubePatching,
        valveRepair: _valveRepair,
        mobileService: _mobileService,
      );

      if (response['success'] == true) {
        print('✅ Puncture services saved');
        _showSuccess('Services saved successfully');
        _tabController.animateTo(5);
      } else {
        _showError(response['message'] ?? 'Failed to save services');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 5: Save Puncture Photos (with navigation)
  Future<void> _savePuncturePhotosStep() async {
    if (_punctureUserId == null) {
      _showError('Registration not complete');
      return;
    }

    if (_shopImages.isEmpty) {
      _showError('Please add at least one photo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imagePaths = _shopImages.map((file) => file.path).toList();

      final response = await _apiService.uploadPuncturePhotos(
        punctureUserId: _punctureUserId!,
        category: _selectedPhotoCategory,
        imagePaths: imagePaths,
      );

      if (response['success'] == true) {
        print('✅ Puncture photos uploaded');
        _showSuccess('Photos uploaded successfully');
        _tabController.animateTo(6);
      } else {
        _showError(response['message'] ?? 'Failed to upload photos');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Submit Complete Puncture Profile (Final Step)
  Future<void> _submitPunctureProfile() async {
    if (_punctureUserId == null) {
      _showError('Registration not complete. Please verify phone first.');
      return;
    }

    if (!_consentGiven) {
      _showError('Please accept the terms and consent');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // All data is already saved in previous steps
      // Just show success dialog
      print('✅ Puncture profile completed successfully');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Color(0xFF34C759),
              size: 64,
            ),
            title: const Text('Profile Completed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Puncture shop "${_shopNameController.text}" has been successfully registered.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '✓ Profile is now live',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Drivers can now find and connect with this shop',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
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
                  Navigator.of(context).pop(); // Go back to shops list
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Failed to complete profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Individual save methods for batch submission (if needed)
  /// These are used by the final submit if you want to re-save everything
  Future<void> _savePunctureBusinessInfo() async {
    if (_punctureUserId == null) {
      throw Exception('Registration not complete');
    }

    if (_shopNameController.text.isEmpty || _ownerNameController.text.isEmpty) {
      throw Exception('Please fill in all required fields');
    }

    final response = await _apiService.savePunctureBusinessInfo(
      punctureUserId: _punctureUserId!,
      punctureName: _shopNameController.text,
      ownerName: _ownerNameController.text,
      mobile: _mobileController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      yearEstablished: _yearEstablishedController.text.isNotEmpty
          ? _yearEstablishedController.text
          : null,
      punctureType: _selectedPunctureType,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to save business info');
    }

    print('✅ Puncture business info saved');
  }

  /// Step 2: Save Puncture Location
  Future<void> _savePunctureLocation() async {
    if (_punctureUserId == null) {
      throw Exception('Registration not complete');
    }

    if (_addressController.text.isEmpty ||
        _selectedStateId == null ||
        _pincodeController.text.isEmpty ||
        _latitude == null ||
        _longitude == null) {
      throw Exception('Please fill in all location details and capture GPS');
    }

    final response = await _apiService.savePunctureLocation(
      punctureUserId: _punctureUserId!,
      fullAddress: _addressController.text,
      landmark: _landmarkController.text.isNotEmpty
          ? _landmarkController.text
          : null,
      stateId: int.parse(_selectedStateId!),
      district: _districtController.text.isNotEmpty
          ? _districtController.text
          : null,
      pincode: _pincodeController.text,
      latitude: _latitude!,
      longitude: _longitude!,
      locationSource: _locationSource,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to save location');
    }

    print('✅ Puncture location saved');
  }

  /// Step 3: Save Puncture Operation
  Future<void> _savePunctureOperation() async {
    if (_punctureUserId == null) {
      throw Exception('Registration not complete');
    }

    final response = await _apiService.savePunctureOperation(
      punctureUserId: _punctureUserId!,
      openingTime: _is24x7 ? null : '${_operatingHours['opening']}:00',
      closingTime: _is24x7 ? null : '${_operatingHours['closing']}:00',
      is24x7: _is24x7,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to save operation');
    }

    print('✅ Puncture operation saved');
  }

  /// Step 4: Save Puncture Services
  Future<void> _savePunctureServices() async {
    if (_punctureUserId == null) {
      throw Exception('Registration not complete');
    }

    final response = await _apiService.savePunctureServices(
      punctureUserId: _punctureUserId!,
      tyreRepair: _tyreRepair,
      airFilling: _airFilling,
      mechanic: _mechanicAvailable,
      tyreReplacement: _tyreReplacement,
      wheelBalancing: _wheelBalancing,
      emergencyService: _emergencyService,
      tubePatching: _tubePatching,
      valveRepair: _valveRepair,
      mobileService: _mobileService,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to save services');
    }

    print('✅ Puncture services saved');
  }

  /// Step 5: Save Puncture Photos
  Future<void> _savePuncturePhotos() async {
    if (_punctureUserId == null) {
      throw Exception('Registration not complete');
    }

    if (_shopImages.isEmpty) {
      throw Exception('Please add at least one photo');
    }

    // Group photos by category and upload
    final imagePaths = _shopImages.map((file) => file.path).toList();

    final response = await _apiService.uploadPuncturePhotos(
      punctureUserId: _punctureUserId!,
      category: _selectedPhotoCategory,
      imagePaths: imagePaths,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to upload photos');
    }

    print('✅ Puncture photos uploaded');
  }

  // ==========================================
  // END PUNCTURE SHOP SAVE METHODS
  // ==========================================
}
