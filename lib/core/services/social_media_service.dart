import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/social_media_lead_model.dart';
import 'phase2_auth_service.dart';
import 'real_auth_service.dart';

class SocialMediaService {
  SocialMediaService._();

  static final SocialMediaService instance = SocialMediaService._();

  Future<Map<String, dynamic>> fetchSocialMediaLeads({int page = 1}) async {
    // Try to get user ID from Phase2Auth first, then fallback to RealAuth
    int userId = await Phase2AuthService.getUserId();
    print('🔍 Phase2Auth User ID: $userId');

    // If Phase2 user ID is 0, try to get from RealAuth
    if (userId == 0) {
      // Make sure user session is restored
      await RealAuthService.instance.isLoggedIn();

      final realAuthUser = RealAuthService.instance.currentUser;
      print('🔍 RealAuth Current User: $realAuthUser');

      if (realAuthUser != null) {
        userId = int.tryParse(realAuthUser.id) ?? 0;
        print('🔍 Using RealAuth User ID: $userId');
      } else {
        print('❌ RealAuth user is null');
      }
    } else {
      print('🔍 Using Phase2Auth User ID: $userId');
    }

    if (userId == 0) {
      throw Exception(
        'User not logged in. Please login again and try accessing Social Media screen.',
      );
    }

    // Get auth token from RealAuthService
    final token = await RealAuthService.instance.getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }

    // Use the new Laravel API endpoint
    final uri = Uri.parse(ApiConfig.socialMediaLeadsApi)
        .replace(
          queryParameters: {
            'assigned_id': userId.toString(),
            'page': page.toString(),
          },
        );

    print('🔍 Social Media Service - Request URL: $uri');
    print('🔍 Social Media Service - Token exists: ${token.isNotEmpty}');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

      print(
        '🔍 Social Media Service - Response Status: ${response.statusCode}',
      );
      print('🔍 Social Media Service - Response Body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        throw Exception(jsonBody['message'] ?? 'Access denied');
      }

      if (response.statusCode != 200) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final Map<String, dynamic> jsonBody = json.decode(response.body);

      final bool isSuccess = jsonBody['success'] == true;

      if (!isSuccess) {
        throw Exception(
          jsonBody['message'] ?? 'Failed to fetch social media leads',
        );
      }

      // Handle the new response structure with pagination
      final data = jsonBody['data'];
      
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        // New Laravel API structure with pagination
        final leadsData = data['data'];
        if (leadsData is List) {
          final leads = leadsData
              .whereType<Map<String, dynamic>>()
              .map(SocialMediaLead.fromJson)
              .toList();
          
          return {
            'leads': leads,
            'current_page': data['current_page'] ?? 1,
            'last_page': data['last_page'] ?? 1,
            'total': data['total'] ?? leads.length,
            'per_page': data['per_page'] ?? 15,
            'from': data['from'] ?? 1,
            'to': data['to'] ?? leads.length,
            'has_more_pages': (data['current_page'] ?? 1) < (data['last_page'] ?? 1),
          };
        }
      } else if (data is List) {
        // Fallback for old structure
        final leads = data
            .whereType<Map<String, dynamic>>()
            .map(SocialMediaLead.fromJson)
            .toList();
        
        return {
          'leads': leads,
          'current_page': 1,
          'last_page': 1,
          'total': leads.length,
          'per_page': leads.length,
          'from': 1,
          'to': leads.length,
          'has_more_pages': false,
        };
      }

      return {
        'leads': <SocialMediaLead>[],
        'current_page': 1,
        'last_page': 1,
        'total': 0,
        'per_page': 15,
        'from': 0,
        'to': 0,
        'has_more_pages': false,
      };
    } catch (error) {
      print('❌ Social Media Service Error: $error');
      throw Exception('Unable to load social media leads: $error');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSocialMediaCallHistory() async {
    // Try to get user ID from Phase2Auth first, then fallback to RealAuth
    int userId = await Phase2AuthService.getUserId();
    print('🔍 Phase2Auth User ID: $userId');

    // If Phase2 user ID is 0, try to get from RealAuth
    if (userId == 0) {
      // Make sure user session is restored
      await RealAuthService.instance.isLoggedIn();

      final realAuthUser = RealAuthService.instance.currentUser;
      print('🔍 RealAuth Current User: $realAuthUser');

      if (realAuthUser != null) {
        userId = int.tryParse(realAuthUser.id) ?? 0;
        print('🔍 Using RealAuth User ID: $userId');
      } else {
        print('❌ RealAuth user is null');
      }
    } else {
      print('🔍 Using Phase2Auth User ID: $userId');
    }

    if (userId == 0) {
      throw Exception(
        'User not logged in. Please login again and try accessing Social Media screen.',
      );
    }

    // Get auth token from RealAuthService
    final token = await RealAuthService.instance.getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }

    // Use the new Laravel API endpoint for call history
    final uri = Uri.parse('${ApiConfig.socialMediaCallHistoryApi}/$userId');

    print('🔍 Social Media Call History Service - Request URL: $uri');
    print('🔍 Social Media Call History Service - Token exists: ${token.isNotEmpty}');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(ApiConfig.timeout);

      print(
        '🔍 Social Media Call History Service - Response Status: ${response.statusCode}',
      );
      print('🔍 Social Media Call History Service - Response Body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final Map<String, dynamic> jsonBody = json.decode(response.body);
          throw Exception(jsonBody['message'] ?? 'Access denied');
        } catch (e) {
          throw Exception('Access denied');
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final dynamic jsonResponse = json.decode(response.body);
      print('🔍 Social Media Call History - JSON Response Type: ${jsonResponse.runtimeType}');
      print('🔍 Social Media Call History - JSON Response Keys: ${jsonResponse is Map ? jsonResponse.keys.toList() : 'Not a Map'}');

      // Handle different response structures
      if (jsonResponse is List) {
        // API returns array directly
        print('🔍 Response is direct array with ${jsonResponse.length} items');
        if (jsonResponse.isNotEmpty) {
          print('🔍 First item keys: ${jsonResponse[0] is Map ? (jsonResponse[0] as Map).keys.toList() : 'Not a Map'}');
        }
        return List<Map<String, dynamic>>.from(jsonResponse);
      } else if (jsonResponse is Map<String, dynamic>) {
        final jsonBody = jsonResponse;
        
        // Check if it has success field
        if (jsonBody.containsKey('success')) {
          final bool isSuccess = jsonBody['success'] == true;
          print('🔍 Success field: $isSuccess');

          if (!isSuccess) {
            throw Exception(
              jsonBody['message'] ?? 'Failed to fetch social media call history',
            );
          }
        }

        // Handle the response structure - API returns data directly as array
        final data = jsonBody['data'];
        print('🔍 Data field type: ${data.runtimeType}');
        print('🔍 Data field content: $data');
        
        if (data is List) {
          print('🔍 Data is array with ${data.length} items');
          if (data.isNotEmpty) {
            print('🔍 First data item keys: ${data[0] is Map ? (data[0] as Map).keys.toList() : 'Not a Map'}');
            print('🔍 First data item: ${data[0]}');
          }
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          print('🔍 Data is Map with keys: ${data.keys.toList()}');
          // If data is wrapped in another object, extract the array
          if (data.containsKey('data') && data['data'] is List) {
            final nestedData = data['data'] as List;
            print('🔍 Nested data is array with ${nestedData.length} items');
            return List<Map<String, dynamic>>.from(nestedData);
          }
        } else {
          print('🔍 Data field is neither List nor Map: ${data.runtimeType}');
        }
      } else {
        print('🔍 Response is neither List nor Map: ${jsonResponse.runtimeType}');
      }

      print('🔍 No valid data structure found, returning empty array');
      return [];
    } catch (error) {
      print('❌ Social Media Call History Service Error: $error');
      throw Exception('Unable to load social media call history: $error');
    }
  }
}