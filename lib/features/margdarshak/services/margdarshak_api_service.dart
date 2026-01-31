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
}
