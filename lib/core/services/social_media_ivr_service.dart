import 'dart:convert';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';

import '../config/api_config.dart';

/// Social Media IVR Service for Live API Integration
/// Uses ${ApiConfig.laravelApiBase}/social-media-ivr-call
/// and ${ApiConfig.laravelApiBase}/social-media-ivr-call-update
class SocialMediaIVRService {
  // Live API Endpoints
  static String get _initiateCallUrl => '${ApiConfig.laravelApiBase}/social-media-ivr-call';
  static String get _updateCallUrl => '${ApiConfig.laravelApiBase}/social-media-ivr-call-update';

  static const Duration _timeout = Duration(seconds: 30);

  /// Initiate Social Media IVR call using Live API
  /// API Endpoint: POST ${ApiConfig.laravelApiBase}/social-media-ivr-call
  /// Request Body:
  /// {
  ///   "assigned_id": 12,
  ///   "lead_id": 345,
  ///   "name": "Rahul Sharma",
  ///   "mobile": "9876543210",
  ///   "source": "Facebook",
  ///   "role": "driver",
  ///   "lead_remarks": "Interested in truck booking",
  ///   "exten": "08383971722",
  ///   "number": "06394756798"
  /// }
  static Future<Map<String, dynamic>> initiateCall({
    required int assignedId,
    required int leadId,
    required String name,
    required String mobile,
    required String source,
    required String role,
    required String leadRemarks,
    required String exten, // Telecaller phone
    required String number, // Lead phone
  }) async {
    try {
      // Get Bearer Token
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      // Clean phone numbers
      final cleanExten = exten.replaceAll(RegExp(r'[^\d]'), '');
      final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');

      // Prepare request body
      final requestBody = {
        'assigned_id': assignedId,
        'lead_id': leadId,
        'name': name,
        'mobile': mobile,
        'source': source,
        'role': role,
        'lead_remarks': leadRemarks,
        'exten': cleanExten,
        'number': cleanNumber,
      };

      print('🚀 [Social Media IVR] Initiating Call...');
      print('   URL: $_initiateCallUrl');
      print('   Payload: ${json.encode(requestBody)}');
      print('   Token: Bearer ${token.substring(0, 10)}...');

      final response = await http
          .post(
            Uri.parse(_initiateCallUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print('🔵 [Social Media IVR] Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Log the complete response structure for debugging
        print('🔍 [Social Media IVR] Full Response Structure:');
        print('   data: $data');
        print('   data["success"]: ${data['success']}');
        print('   data["data"]: ${data['data']}');
        if (data['data'] != null) {
          print('   data["data"]["id"]: ${data['data']['id']}');
          print('   data["data"]["call_id"]: ${data['data']['call_id']}');
          print(
            '   data["data"]["call_history_id"]: ${data['data']['call_history_id']}',
          );
        }
        print('   data["id"]: ${data['id']}');

        // Check for success
        if (data['success'] == true) {
          // Extract call ID from response - prioritize call_history_id
          final callId =
              data['data']?['call_history_id'] ??
              data['data']?['id'] ??
              data['data']?['call_id'] ??
              data['id'];

          if (callId == null) {
            print(
              '⚠️ WARNING: API returned success but no call ID found in response!',
            );
            print('   Complete Response: ${json.encode(data)}');
          } else {
            print(
              '✅ Social Media IVR call initiated successfully. ID: $callId',
            );
          }

          return {
            'success': true,
            'call_id': callId,
            'call_log_id': callId,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Failed to initiate call',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in Social Media IVR initiateCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update Social Media IVR Call Feedback using Live API
  /// API Endpoint: POST ${ApiConfig.laravelApiBase}/social-media-ivr-call-update
  /// Request Body:
  /// {
  ///   "id": 1,
  ///   "call_status": "connected",
  ///   "call_feedbacks": "not interested",
  ///   "call_remarks": "Customer answered and requested callback tomorrow"
  /// }
  static Future<Map<String, dynamic>> updateCall({
    required int callId,
    required String callStatus,
    required String callFeedbacks,
    String? callRemarks,
  }) async {
    try {
      // Get token with detailed logging
      print('🔑 [Social Media IVR] Fetching auth token...');
      final token = await RealAuthService.instance.getAuthToken();

      if (token == null || token.isEmpty) {
        print('❌ [Social Media IVR] No auth token available');
        return {'success': false, 'error': 'No auth token'};
      }

      print('✅ [Social Media IVR] Token found: ${token.length} characters');
      print(
        '   Token prefix: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
      );

      // Verify token format (should be like "123|randomstring")
      if (!token.contains('|')) {
        print(
          '⚠️ [Social Media IVR] Token format might be invalid (no pipe character)',
        );
      }

      final requestBody = {
        'id': callId,
        'call_status': callStatus,
        'call_feedbacks': callFeedbacks,
        'call_remarks': callRemarks ?? '',
      };

      print('🔵 [Social Media IVR] Update Request:');
      print('   URL: $_updateCallUrl');
      print('   Call ID: $callId');
      print('   Status: "$callStatus"');
      print('   Feedback: "$callFeedbacks"');
      print('   Remarks: "${callRemarks ?? ''}"');
      print('   Token: Bearer ${token.substring(0, 20)}...');
      print('   Full Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(_updateCallUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print(
        '🔵 [Social Media IVR] Update Response: ${response.statusCode} - ${response.body}',
      );

      // Handle redirects
      if (response.statusCode == 302 || response.statusCode == 301) {
        print('❌ [Social Media IVR] Got redirect (${response.statusCode})');
        print('   This usually means authentication failed or route not found');
        print('   Location: ${response.headers['location']}');
        return {
          'success': false,
          'error':
              'Authentication failed or endpoint not found (${response.statusCode})',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Check if API actually reports success
        final isSuccess =
            data['success'] == true ||
            data['status'] == true ||
            data['updated'] == true ||
            data['message']?.toString().toLowerCase().contains('success') ==
                true ||
            data['message']?.toString().toLowerCase().contains('updated') ==
                true ||
            (data['error'] == null &&
                data['success'] != false &&
                data['status'] != false);

        if (isSuccess) {
          print('✅ Social Media call updated successfully');
          return {'success': true, 'data': data};
        } else {
          // API returned 200 but with error in body
          final errorMsg =
              data['message'] ?? data['error'] ?? 'Update rejected by server';
          print('❌ API rejected update: $errorMsg');
          return {'success': false, 'error': errorMsg, 'data': data};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Failed to update Social Media call: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch Social Media IVR Call History
  /// API Endpoint: GET ${ApiConfig.laravelApiBase}/social-media-ivr-calls?assigned_id={id}
  static Future<Map<String, dynamic>> fetchCallHistory({
    required int assignedId,
    int page = 1,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No auth token'};
      }

      final url =
          '${ApiConfig.laravelApiBase}/social-media-ivr-calls?assigned_id=$assignedId&page=$page';

      print('🔵 [Social Media IVR] Fetching History: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ [Social Media IVR] History fetched: ${data['data']?['data']?.length} records',
        );
        return {'success': true, 'data': data};
      } else {
        print(
          '❌ [Social Media IVR] History fetch failed: ${response.statusCode}',
        );
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ [Social Media IVR] History fetch error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
