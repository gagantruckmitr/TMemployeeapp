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
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/dashboard');

      print('🔵 Fetching dashboard stats...');

      final response = await http
          .get(url, headers: _authService.getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dashboard stats fetched successfully');
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

      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/shops')
          .replace(queryParameters: queryParams);

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
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/shops');

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

      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/drivers')
          .replace(queryParameters: queryParams);

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

  /// Get earnings summary
  Future<Map<String, dynamic>> getEarnings({
    String? period, // 'today', 'week', 'month'
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;

      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/earnings')
          .replace(queryParameters: queryParams);

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
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/duty-status');

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

  /// Get territory information
  Future<Map<String, dynamic>> getTerritoryInfo() async {
    try {
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/territory');

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
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/profile');

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
}
