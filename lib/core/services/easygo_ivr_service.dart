import 'dart:convert';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';

/// EasyGo IVR Service for Live API Integration
/// Uses https://development.truckmitr.com/api/telehead/ivr-call
class EasyGoIVRService {
  // Live API Endpoints
  static const String _initiateCallUrl =
      'https://development.truckmitr.com/api/telehead/ivr-call';
  static const String _updateCallUrl =
      'https://development.truckmitr.com/api/telehead/ivr-call-update';
  static const String _userDetailsUrl =
      'https://development.truckmitr.com/api/telehead/user-details';

  static const Duration _timeout = Duration(seconds: 30);
  static const String _defaultDID = '8062982912';

  /// Fetch user mobile by user ID
  static Future<String?> getUserMobile(String userId) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('$_userDetailsUrl/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          // Try different field names
          return data['mobile']?.toString() ??
              data['phone']?.toString() ??
              data['phone_number']?.toString() ??
              data['data']?['mobile']?.toString();
        } else if (data is List && data.isNotEmpty) {
          return data[0]['mobile']?.toString() ?? data[0]['phone']?.toString();
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user mobile: $e');
      return null;
    }
  }

  /// Initiate IVR call using Live API
  static Future<Map<String, dynamic>> initiateCall({
    required String exten, // Telecaller phone
    required String number, // Driver phone
    required String callerId, // Telecaller ID (assigned_to)
    required String contactId, // Driver ID (user_id)
    required String tmid, // Driver TMID (unique_id)
    String process = 'welcome',
    String? driverName,
    String? callSource,
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
        'unique_id': tmid,
        'user_id': contactId,
        'assigned_to': callerId,
        'process': process,
        'exten': cleanExten,
        'number': cleanNumber,
        'did': _defaultDID,
      };

      print('🚀 [IVR DEBUG] EasyGoIVRService: Preparing API Request...');
      print('🚀 [IVR DEBUG] URL: $_initiateCallUrl');
      print('🚀 [IVR DEBUG] Payload: ${json.encode(requestBody)}');

      print('🔵 Live IVR API Request:');
      print('   URL: $_initiateCallUrl');
      print('   Headers: {Authorization: Bearer ${token.substring(0, 10)}...}');
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

      print('🔵 Live IVR API Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Check for success and extracted call_history_id
        if (data['success'] == true && data['data'] != null) {
          final callData = data['data'];

          // Extract call_history_id from response
          final callId = callData['call_history_id'];

          if (callId == null) {
            print(
              '⚠️ WARNING: API returned success but no call_history_id found in response!',
            );
            print('   Response data: $data');
          }

          print('✅ Live IVR call initiated successfully. ID: $callId');

          return {
            'success': true,
            'call_id': callId,
            'call_log_id': callId,
            'data': data,
            'reference_id': callId?.toString(),
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
      print('❌ Exception in Live IVR initiateCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Initiate Job Matching IVR call - for job applicants only
  static Future<Map<String, dynamic>> initiateJobMatchingCall({
    required String uniqueIdTransporter,
    required String uniqueIdDriver,
    required int userIdTransporter,
    required int userIdDriver,
    required int assignedTo,
    required String jobId,
    required String transporterName,
    required String driverName,
    required String exten,
    required String number,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final cleanExten = exten.replaceAll(RegExp(r'[^\d]'), '');
      final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');

      final requestBody = {
        'unique_id_transporter': uniqueIdTransporter,
        'unique_id_driver': uniqueIdDriver,
        'user_id_transporter': userIdTransporter,
        'user_id_driver': userIdDriver,
        'assigned_to': assignedTo,
        'job_id': jobId,
        'transporter_name': transporterName,
        'driver_name': driverName,
        'exten': cleanExten,
        'number': cleanNumber,
      };

      print('=== JOB MATCHING IVR CALL API ===');
      print('URL: https://development.truckmitr.com/api/telehead/ivr-call-jobMatching');
      print('Request Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(
              'https://development.truckmitr.com/api/telehead/ivr-call-jobMatching',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final matchId = data['data']?['match_id'];
          print('✅ Job matching call initiated. Match ID: $matchId');
          return {'success': true, 'match_id': matchId, 'data': data};
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Failed to initiate job matching call',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in initiateJobMatchingCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update Call Feedback using Live API
  static Future<Map<String, dynamic>> updateCall({
    required int callId,
    required String status,
    required String feedback,
    String? remarks,
    String? recordingFile,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No auth token'};
      }

      final requestBody = <String, dynamic>{
        'id': callId,
        'status': status, // Some APIs expect 'status'
        'call_status': status, // Some APIs expect 'call_status'
        'feedback': feedback, // Some APIs expect 'feedback'
        'call_feedback': feedback, // Some APIs expect 'call_feedback'
        'remarks': remarks ?? '', // Some APIs expect 'remarks'
        'call_remarks': remarks ?? '', // Some APIs expect 'call_remarks'
      };

      // Only include recording if provided
      if (recordingFile != null && recordingFile.isNotEmpty) {
        requestBody['call_recording'] = recordingFile;
      }

      print('🔵 Live IVR Update Request:');
      print('   URL: $_updateCallUrl');
      print('   Call ID: $callId');
      print('   Status: "$status"');
      print('   Feedback: "$feedback"');
      print('   Remarks: "${remarks ?? ''}"');
      print('   Recording: ${recordingFile ?? "none"}');
      print('   Full Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(_updateCallUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print(
        '🔵 Live IVR Update Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Check if API actually reports success - handle various response patterns
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
          print('✅ Call updated successfully');
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
      print('❌ Failed to update call: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
