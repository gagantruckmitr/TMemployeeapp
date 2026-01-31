import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';
import '../config/api_config.dart';

/// Manual Call Service for initiating and updating manual calls
/// Uses the telehead manual call API endpoints
class ManualCallService {
  static const String _initiateCallUrl =
      '${ApiConfig.laravelApiBase}/manual-call';
  static const String _updateCallUrl =
      '${ApiConfig.laravelApiBase}/manual-call-update';
  static const Duration _timeout = Duration(seconds: 30);

  /// Initiate manual call
  /// Returns call_history_id on success
  static Future<Map<String, dynamic>> initiateCall({
    required String uniqueId,
    required String userId,
    required String assignedTo,
    required String process,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final requestBody = {
        'unique_id': uniqueId,
        'user_id': userId,
        'assigned_to': assignedTo,
        'process': process,
      };

      print('🔵 Manual Call Initiate Request:');
      print('   URL: $_initiateCallUrl');
      print('   Body: ${json.encode(requestBody)}');

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

      print('🔵 Manual Call Initiate Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final callHistoryId = data['data']['call_history_id'];
          print('✅ Manual call initiated successfully. ID: $callHistoryId');

          return {
            'success': true,
            'call_history_id': callHistoryId,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Failed to initiate manual call',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in Manual Call initiateCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update manual call with feedback
  /// Uses multipart form data for file upload
  static Future<Map<String, dynamic>> updateCall({
    required int callHistoryId,
    required String callStatus,
    required String callFeedback,
    String? callRemarks,
    File? callRecording,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No auth token'};
      }

      print('🔵 Manual Call Update Request:');
      print('   URL: $_updateCallUrl');
      print('   Call History ID: $callHistoryId');
      print('   Status: "$callStatus"');
      print('   Feedback: "$callFeedback"');
      print('   Remarks: "${callRemarks ?? ''}"');
      print(
        '   Recording: ${callRecording != null ? callRecording.path : "none"}',
      );

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_updateCallUrl));

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['id'] = callHistoryId.toString();
      request.fields['call_status'] = callStatus;
      request.fields['call_feedback'] = callFeedback;
      if (callRemarks != null && callRemarks.isNotEmpty) {
        request.fields['call_remarks'] = callRemarks;
      }

      // Add file if provided
      if (callRecording != null) {
        final fileStream = http.ByteStream(callRecording.openRead());
        final fileLength = await callRecording.length();
        final multipartFile = http.MultipartFile(
          'call_recording',
          fileStream,
          fileLength,
          filename: callRecording.path.split('/').last,
        );
        request.files.add(multipartFile);
        print('   📎 Attached recording: ${multipartFile.filename}');
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Manual Call Update Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        final isSuccess =
            data['success'] == true ||
            data['status'] == true ||
            data['message']?.toString().toLowerCase().contains('success') ==
                true ||
            data['message']?.toString().toLowerCase().contains('updated') ==
                true;

        if (isSuccess) {
          print('✅ Manual call updated successfully');
          return {'success': true, 'data': data};
        } else {
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
      print('❌ Failed to update manual call: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
