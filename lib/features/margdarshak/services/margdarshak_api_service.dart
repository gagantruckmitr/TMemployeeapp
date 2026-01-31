import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import 'margdarshak_auth_service.dart';

/// Margdarshak API Service
/// Handles all API calls for field agent operations
class MargdarshakApiService {
  static const Duration _timeout = Duration(seconds: 30);
  final MargdarshakAuthService _authService = MargdarshakAuthService();

  // Singleton pattern
  static final MargdarshakApiService _instance =
      MargdarshakApiService._internal();
  factory MargdarshakApiService() => _instance;
  MargdarshakApiService._internal();

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDashboardApi);

      print('🔵 Fetching dashboard stats...');
      print('   URL: $url');
      print('   Has Auth Token: ${_authService.authToken != null}');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      print('🔵 Dashboard API Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dashboard stats fetched successfully');
        print('   Response Status: ${data['status']}');
        print('   Response Message: ${data['message']}');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch dashboard stats: $e');
      rethrow;
    }
  }

  /// Get shops list
  Future<List<Map<String, dynamic>>> getShops({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/shops',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch shops: $e');
      rethrow;
    }
  }

  /// Add new shop
  Future<Map<String, dynamic>> addShop(Map<String, dynamic> shopData) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/shops',
      );

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode(shopData),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Shop added successfully');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to add shop: $e');
      rethrow;
    }
  }

  /// Get drivers list
  Future<List<Map<String, dynamic>>> getDrivers({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/drivers',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch drivers: $e');
      rethrow;
    }
  }

  /// Get territory drivers (drivers in agent's territory)
  Future<Map<String, dynamic>> getTerritoryDrivers() async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakTerritoryDriversApi);

      print('🔵 Fetching territory drivers...');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      print('🔵 Territory Drivers Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Territory drivers fetched successfully');
        print('   Count: ${data['count']}');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch territory drivers: $e');
      rethrow;
    }
  }

  /// Get territory shops (shops in agent's territory)
  Future<Map<String, dynamic>> getTerritoryShops({
    String filter = 'all',
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakTerritoryShopsApi}?filter=$filter',
      );

      print('🔵 Fetching territory shops...');
      print('   Filter: $filter');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      print('🔵 Territory Shops Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Territory shops fetched successfully');
        print('   Count: ${data['count']}');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch territory shops: $e');
      rethrow;
    }
  }

  /// Get territory overview (overview of agent's territory)
  Future<Map<String, dynamic>> getTerritoryOverview() async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakTerritoryOverviewApi);

      print('🔵 Fetching territory overview...');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      print('🔵 Territory Overview Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Territory overview fetched successfully');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch territory overview: $e');
      rethrow;
    }
  }

  /// Get shop drivers (drivers linked to a specific shop)
  Future<Map<String, dynamic>> getShopDrivers({
    required String referralCode,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakShopDriversApi);

      print('🔵 Fetching shop drivers...');
      print('   Referral Code: $referralCode');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({'referral_code': referralCode}),
          )
          .timeout(_timeout);

      print('🔵 Shop Drivers Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Shop drivers fetched successfully');
        print('   Count: ${data['count']}');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch shop drivers: $e');
      rethrow;
    }
  }

  /// Get earnings summary
  Future<Map<String, dynamic>> getEarnings({
    String? period, // 'today', 'week', 'month'
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;

      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/earnings',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch earnings: $e');
      rethrow;
    }
  }

  /// Update duty status (check-in/check-out)
  Future<Map<String, dynamic>> updateDutyStatus({
    required String status, // 'check_in' or 'check_out'
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/duty-status',
      );

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'status': status,
              if (latitude != null) 'latitude': latitude,
              if (longitude != null) 'longitude': longitude,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Duty status updated: $status');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to update duty status: $e');
      rethrow;
    }
  }

  /// Update real-time location
  Future<void> updateRealtimeLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    double? heading,
    int? batteryLevel,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakLocationUpdateApi);

      // Fire and forget - don't wait for response to keep UI responsive
      // But we use await here to catch errors in this service layer if needed
      // Ideally handled in a background service queue

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': accuracy,
              'speed': speed,
              'heading': heading,
              'battery_level': batteryLevel,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('⚠️ Location update failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Failed to update location: $e');
      // Don't rethrow to avoid disrupting the tracking service loop
    }
  }

  /// Get territory information
  Future<Map<String, dynamic>> getTerritoryInfo() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/territory',
      );

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch territory info: $e');
      rethrow;
    }
  }

  /// Get profile information
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/profile',
      );

      print('🔵 Fetching profile...');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Profile fetched successfully');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch profile: $e');
      rethrow;
    }
  }

  /// Update profile information
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/profile-update',
      );

      print('🔵 Updating profile...');
      print('   Data: ${json.encode(profileData)}');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode(profileData),
          )
          .timeout(_timeout);

      print('🔵 Update Profile Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          print('✅ Profile updated successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to update profile: $e');
      rethrow;
    }
  }

  /// Get states list
  Future<List<Map<String, dynamic>>> getStates() async {
    try {
      final url = Uri.parse(ApiConfig.getStates);

      print('🔵 Fetching states...');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ States fetched successfully');
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch states: $e');
      rethrow;
    }
  }

  /// Send OTP for dhaba registration
  Future<Map<String, dynamic>> sendDhabaRegistrationOtp({
    required String mobile,
    required String name,
    required String stateId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/add-dhaba',
      );

      print('🔵 Sending dhaba registration OTP...');
      print('   Mobile: $mobile');
      print('   Name: $name');
      print('   State ID: $stateId');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'mobile': mobile,
              'name': name,
              'states': stateId,
            }),
          )
          .timeout(_timeout);

      print('🔵 Send OTP Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ OTP sent successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to send OTP: $e');
      rethrow;
    }
  }

  /// Send OTP for puncture shop registration
  Future<Map<String, dynamic>> sendPunctureRegistrationOtp({
    required String mobile,
    required String name,
    required String stateId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakApiBase}/margdarshak/add-puncture',
      );

      print('🔵 Sending puncture registration OTP...');
      print('   Mobile: $mobile');
      print('   Name: $name');
      print('   State ID: $stateId');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'mobile': mobile,
              'name': name,
              'states': stateId,
            }),
          )
          .timeout(_timeout);

      print('🔵 Send OTP Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ OTP sent successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to send OTP: $e');
      rethrow;
    }
  }

  /// Verify OTP for dhaba registration
  Future<Map<String, dynamic>> verifyDhabaRegistrationOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/verifyOtp');

      print('🔵 Verifying OTP...');
      print('   Mobile: $mobile');
      print('   OTP: $otp');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({'mobile': mobile, 'otp': otp}),
          )
          .timeout(_timeout);

      print('🔵 Verify OTP Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ OTP verified successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to verify OTP: $e');
      rethrow;
    }
  }

  // ==========================================
  // Dhaba Profile Completion APIs
  // ==========================================

  /// Save Business Info for Dhaba
  Future<Map<String, dynamic>> saveDhabaBusinessInfo({
    required int dhabaUserId,
    required String dhabaName,
    required String ownerName,
    required String mobile,
    String? email,
    String? yearEstablished,
    required String dhabaType,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaBusinessInfoApi);

      print('🔵 Saving dhaba business info...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              'dhaba_name': dhabaName,
              'owner_name': ownerName,
              'mobile': mobile,
              if (email != null) 'email': email,
              if (yearEstablished != null) 'year_established': yearEstablished,
              'dhaba_type': dhabaType,
            }),
          )
          .timeout(_timeout);

      print('🔵 Business Info Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Business info saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save business info: $e');
      rethrow;
    }
  }

  /// Save Location for Dhaba
  Future<Map<String, dynamic>> saveDhabaLocation({
    required int dhabaUserId,
    required String fullAddress,
    String? landmark,
    required int stateId,
    String? district,
    required String pincode,
    required double latitude,
    required double longitude,
    required String locationSource,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaLocationApi);

      print('🔵 Saving dhaba location...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              'full_address': fullAddress,
              if (landmark != null) 'landmark': landmark,
              'state_id': stateId,
              if (district != null) 'district': district,
              'pincode': pincode,
              'latitude': latitude,
              'longitude': longitude,
              'location_source': locationSource,
            }),
          )
          .timeout(_timeout);

      print('🔵 Location Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Location saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save location: $e');
      rethrow;
    }
  }

  /// Save Operation Details for Dhaba
  Future<Map<String, dynamic>> saveDhabaOperation({
    required int dhabaUserId,
    String? openingTime,
    String? closingTime,
    bool? is24x7,
    String? peakHours,
    String? avgWaitTime,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaOperationApi);

      print('🔵 Saving dhaba operation details...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              if (openingTime != null) 'opening_time': openingTime,
              if (closingTime != null) 'closing_time': closingTime,
              if (is24x7 != null) 'is_24x7': is24x7,
              if (peakHours != null) 'peak_hours': peakHours,
              if (avgWaitTime != null) 'avg_wait_time': avgWaitTime,
            }),
          )
          .timeout(_timeout);

      print('🔵 Operation Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Operation details saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save operation details: $e');
      rethrow;
    }
  }

  /// Save Facilities for Dhaba
  Future<Map<String, dynamic>> saveDhabaFacilities({
    required int dhabaUserId,
    bool? sittingFacility,
    bool? cleanRestrooms,
    bool? drinkingWater,
    bool? parkingSmall,
    bool? parkingLarge,
    bool? sleepingArea,
    bool? washingArea,
    bool? electricPoint,
    bool? cctv,
    bool? securityStaff,
    bool? wheelAlignment,
    bool? mechanic,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaFacilitiesApi);

      print('🔵 Saving dhaba facilities...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              if (sittingFacility != null) 'sitting_facility': sittingFacility,
              if (cleanRestrooms != null) 'clean_restrooms': cleanRestrooms,
              if (drinkingWater != null) 'drinking_water': drinkingWater,
              if (parkingSmall != null) 'parking_small': parkingSmall,
              if (parkingLarge != null) 'parking_large': parkingLarge,
              if (sleepingArea != null) 'sleeping_area': sleepingArea,
              if (washingArea != null) 'washing_area': washingArea,
              if (electricPoint != null) 'electric_point': electricPoint,
              if (cctv != null) 'cctv': cctv,
              if (securityStaff != null) 'security_staff': securityStaff,
              if (wheelAlignment != null) 'wheel_alignment': wheelAlignment,
              if (mechanic != null) 'mechanic': mechanic,
            }),
          )
          .timeout(_timeout);

      print('🔵 Facilities Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Facilities saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save facilities: $e');
      rethrow;
    }
  }

  /// Save Food Details for Dhaba
  Future<Map<String, dynamic>> saveDhabaFood({
    required int dhabaUserId,
    required List<String> foodType,
    String? specialDishes,
    bool? mealBreakfast,
    bool? mealLunch,
    bool? mealDinner,
    bool? mealNight,
    String? avgPriceRange,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaFoodApi);

      print('🔵 Saving dhaba food details...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              'food_type': foodType,
              if (specialDishes != null) 'special_dishes': specialDishes,
              if (mealBreakfast != null) 'meal_breakfast': mealBreakfast,
              if (mealLunch != null) 'meal_lunch': mealLunch,
              if (mealDinner != null) 'meal_dinner': mealDinner,
              if (mealNight != null) 'meal_night': mealNight,
              if (avgPriceRange != null) 'avg_price_range': avgPriceRange,
            }),
          )
          .timeout(_timeout);

      print('🔵 Food Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Food details saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save food details: $e');
      rethrow;
    }
  }

  /// Upload Photos for Dhaba
  Future<Map<String, dynamic>> uploadDhabaPhotos({
    required int dhabaUserId,
    required String category,
    required List<String> imagePaths,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaPhotosApi);

      print('🔵 Uploading dhaba photos...');
      print('   Category: $category');
      print('   Image count: ${imagePaths.length}');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_authService.getAuthHeaders());
      request.headers.remove('Content-Type'); // Let it be set automatically

      request.fields['dhaba_user_id'] = dhabaUserId.toString();
      request.fields['category'] = category;

      for (int i = 0; i < imagePaths.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('image_url[$i]', imagePaths[i]),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Photos Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Photos uploaded successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to upload photos: $e');
      rethrow;
    }
  }

  /// Save Banking Details for Dhaba
  Future<Map<String, dynamic>> saveDhabaBanking({
    required int dhabaUserId,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaBankingApi);

      print('🔵 Saving dhaba banking details...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              'account_holder_name': accountHolderName,
              'bank_name': bankName,
              'account_number': accountNumber,
              'ifsc_code': ifscCode,
            }),
          )
          .timeout(_timeout);

      print('🔵 Banking Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Banking details saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save banking details: $e');
      rethrow;
    }
  }

  /// Save Engagement Settings for Dhaba
  Future<Map<String, dynamic>> saveDhabaEngagement({
    required int dhabaUserId,
    bool? allowCall,
    bool? allowMessages,
    bool? allowPromotions,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.margdarshakDhabaEngagementApi);

      print('🔵 Saving dhaba engagement settings...');

      final response = await http
          .post(
            url,
            headers: _authService.getAuthHeaders(),
            body: json.encode({
              'dhaba_user_id': dhabaUserId,
              if (allowCall != null) 'allow_call': allowCall,
              if (allowMessages != null) 'allow_messages': allowMessages,
              if (allowPromotions != null) 'allow_promotions': allowPromotions,
            }),
          )
          .timeout(_timeout);

      print('🔵 Engagement Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Engagement settings saved successfully');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to save engagement settings: $e');
      rethrow;
    }
  }

  /// Get Dhaba Profile
  Future<Map<String, dynamic>> getDhabaProfile({
    required int dhabaUserId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.margdarshakDhabaProfileApi}?dhaba_user_id=$dhabaUserId',
      );

      print('🔵 Fetching dhaba profile...');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      print('🔵 Profile Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dhaba profile fetched successfully');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch dhaba profile: $e');
      rethrow;
    }
  }
}
