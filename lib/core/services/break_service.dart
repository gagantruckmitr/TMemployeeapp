import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/leave_models.dart';
import 'real_auth_service.dart';

import '../config/api_config.dart';

class BreakService {
  // Use the centralized API configuration
  static String get _baseUrl => '${ApiConfig.laravelApiBase}/break-logs';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await RealAuthService.instance.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<BreakLog>> getBreakLogs({int? telecallerId}) async {
    try {
      var uri = Uri.parse(_baseUrl);
      if (telecallerId != null) {
        uri = uri.replace(
          queryParameters: {'caller_id': telecallerId.toString()},
        );
      }

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => BreakLog.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          // Handle case where it might return a single object or wrapped list
          if (data.containsKey('data') && data['data'] is List) {
            return (data['data'] as List)
                .map((json) => BreakLog.fromJson(json))
                .toList();
          }
          // Fallback if it returns a single object (as in the user example?)
          return [BreakLog.fromJson(data)];
        }
        return [];
      } else {
        throw Exception('Failed to fetch break logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching break logs: $e');
      rethrow;
    }
  }

  static Future<BreakLog> getBreakLogById(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BreakLog.fromJson(data);
      } else {
        throw Exception('Failed to fetch break log: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching break log: $e');
      rethrow;
    }
  }

  static Future<BreakLog> startBreak({
    required int callerId,
    required String telecallerName,
    required String breakType,
    String notes = '',
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final body = {
        'caller_id': callerId,
        'telecaller_name': telecallerName,
        'break_type': breakType,
        'notes': notes,
      };

      final headers = await _getHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Handle wrapped response (e.g. { "success": true, "data": { ... } })
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return BreakLog.fromJson(data['data']);
        }
        return BreakLog.fromJson(data);
      } else {
        throw Exception(
          'Failed to start break: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error starting break: $e');
      rethrow;
    }
  }

  // Trying POST to base URL with full payload (including ID) to see if backend handles 'update' or 'close previous' logic.
  // We remove _method: PUT because it caused 405 on the base route.
  static Future<BreakLog> endBreak({
    required int id,
    required int callerId,
    required String telecallerName,
    required String breakType,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id/end');

      final headers = await _getHeaders();
      // Sending minimal or no body since the action is in the URL.
      // If the backend expects some data, we can add it back, but usually .../end endpoint just needs the event.
      // We will send the caller_id just in case validation needs it.
      final body = {
        'caller_id': callerId,
        'telecaller_name': telecallerName,
        'break_type': breakType,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return BreakLog.fromJson(data['data']);
        }
        return BreakLog.fromJson(data);
      } else {
        throw Exception(
          'Failed to end break: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error ending break: $e');
      rethrow;
    }
  }
}
