import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../models/database_models.dart';
import 'real_auth_service.dart';

class CallbackRequestsService {
  CallbackRequestsService._();

  static final CallbackRequestsService instance = CallbackRequestsService._();

  Future<List<CallbackRequest>> fetchCallbackRequests() async {
    final userId = RealAuthService.instance.currentUser?.id;
    final token = await RealAuthService.instance.getAuthToken();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/callback_requests_api.php',
    ).replace(
      queryParameters: {
        'action': 'index',
        if (userId != null) 'auth_admin_id': userId,
      },
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);

      print(
        '📞 CallbackRequestsService: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final Map<String, dynamic> jsonBody = json.decode(response.body);

      final dynamic successValue = jsonBody['success'];
      final dynamic statusValue = jsonBody['status'];
      final bool isSuccess =
          (successValue is bool && successValue) ||
          (statusValue is bool && statusValue);

      if (!isSuccess) {
        throw Exception(jsonBody['message'] ?? 'Failed to fetch requests');
      }

      final data = jsonBody['data'];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(CallbackRequest.fromJson)
            .toList();
      }

      return [];
    } catch (error) {
      throw Exception('Unable to load callback requests: $error');
    }
  }
}
