import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/social_media_lead_model.dart';

class SocialMediaService {
  SocialMediaService._();

  static final SocialMediaService instance = SocialMediaService._();

  Future<List<SocialMediaLead>> fetchSocialMediaLeads() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/social-media-leads.php',
    ).replace(
      queryParameters: {
        'action': 'get_social_media_leads',
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final Map<String, dynamic> jsonBody = json.decode(response.body);

      final bool isSuccess = jsonBody['success'] == true;

      if (!isSuccess) {
        throw Exception(jsonBody['message'] ?? 'Failed to fetch social media leads');
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
      throw Exception('Unable to load social media leads: $error');
    }
  }
}
