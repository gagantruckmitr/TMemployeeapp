import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/analytics_kpi_model.dart';
import 'phase2_auth_service.dart';
import 'real_auth_service.dart';

class AnalyticsService {
  static const String baseUrl = 'https://development.truckmitr.com/api/telehead';

  static Future<AnalyticsKPIResponse> fetchAnalytics({
    String filter = 'today',
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final token = await RealAuthService.instance.getAuthToken();

      // Map display filters to API filters if necessary,
      // but assuming the caller passes the correct API filter string.
      // API expects: today, yesterday, this_week, this_month, all

      final uri = Uri.parse('$baseUrl/analytics/assigned-wise').replace(
        queryParameters: {'assigned_to': user.id.toString(), 'filter': filter},
      );

      print('Fetching Analytics KPI: $uri');

      final response = await http.get(
        uri,
        headers: token != null
            ? {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              }
            : {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
      );

      print('Analytics Response Code: ${response.statusCode}');
      print('Analytics Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AnalyticsKPIResponse.fromJson(data);
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching analytics: $e');
      throw Exception('Error fetching analytics: $e');
    }
  }
}
