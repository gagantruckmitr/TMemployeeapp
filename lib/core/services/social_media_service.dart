import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/social_media_lead_model.dart';
import 'phase2_auth_service.dart';
import 'real_auth_service.dart';

class SocialMediaService {
  SocialMediaService._();

  static final SocialMediaService instance = SocialMediaService._();

  Future<List<SocialMediaLead>> fetchSocialMediaLeads() async {
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

    final uri = Uri.parse('${ApiConfig.baseUrl}/social-media-leads.php')
        .replace(
          queryParameters: {
            'action': 'get_social_media_leads',
            'user_id': userId.toString(),
          },
        );

    print('🔍 Social Media Service - Request URL: $uri');

    try {
      final response = await http.get(uri).timeout(ApiConfig.timeout);

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

      final data = jsonBody['data'];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SocialMediaLead.fromJson)
            .toList();
      }

      return [];
    } catch (error) {
      print('❌ Social Media Service Error: $error');
      throw Exception('Unable to load social media leads: $error');
    }
  }
}
