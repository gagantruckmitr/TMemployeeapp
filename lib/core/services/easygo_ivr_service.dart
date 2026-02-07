import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';

import '../config/api_config.dart';

/// EasyGo IVR Service for Live API Integration
/// Uses centralized API configuration
class EasyGoIVRService {
  // Live API Endpoints using centralized config
  static String get _initiateCallUrl => ApiConfig.getLaravelApiUrl('ivr-call');
  static String get _updateCallUrl => ApiConfig.getLaravelApiUrl('ivr-call-update');
  static String get _userDetailsUrl => ApiConfig.getLaravelApiUrl('user-details');

  static const Duration _timeout = Duration(seconds: 30);
  static const String _defaultDID = '8062982912';

  /// Parse JSON error response body into message and optional data.
  static Map<String, dynamic>? _parseErrorBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = json.decode(body);
      if (decoded is! Map) return null;
      final message = decoded['message']?.toString();
      if (message == null || message.isEmpty) return null;
      return {
        'message': message,
        'data': decoded['data'],
      };
    } catch (_) {
      return null;
    }
  }

  /// Build user-friendly error map for IVR failures.
  static Map<String, dynamic> _errorResult(
    String error, {
    String? errorCode,
    int? pendingCallHistoryId,
  }) {
    final result = <String, dynamic>{'success': false, 'error': error};
    if (errorCode != null) result['error_code'] = errorCode;
    if (pendingCallHistoryId != null) {
      result['pending_call_history_id'] = pendingCallHistoryId;
    }
    return result;
  }

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
          final msg = data['message']?.toString() ?? 'Failed to initiate call';
          return _errorResult(msg);
        }
      }

      // Non-success HTTP: parse body for user-friendly message
      final parsed = _parseErrorBody(response.body);
      final apiMessage = parsed?['message'];
      final apiData = parsed?['data'];

      if (response.statusCode == 422 && apiMessage != null) {
        // Pending feedback: "Please submit feedback for the previous call before initiating a new call."
        final pendingId = apiData is Map
            ? (apiData['pending_call_history_id'] as num?)?.toInt()
            : null;
        print(
          '❌ IVR 422: Pending feedback required. pending_call_history_id: $pendingId',
        );
        return _errorResult(
          apiMessage.trim().isEmpty
              ? 'Please submit feedback for the previous call before initiating a new call.'
              : apiMessage,
          errorCode: 'PENDING_FEEDBACK',
          pendingCallHistoryId: pendingId,
        );
      }

      if (parsed != null && apiMessage != null && apiMessage.isNotEmpty) {
        return _errorResult(apiMessage);
      }

      // Fallback by status code
      final fallback = response.statusCode >= 500
          ? 'Server error. Please try again later.'
          : response.statusCode == 408
              ? 'Request timed out. Please try again.'
              : response.statusCode == 401
                  ? 'Session expired. Please log in again.'
                  : 'Request failed (${response.statusCode}). Please try again.';
      return _errorResult(fallback);
    } on TimeoutException catch (e) {
      print('❌ IVR initiateCall timeout: $e');
      return _errorResult(
        'Request timed out. Please check your connection and try again.',
        errorCode: 'TIMEOUT',
      );
    } on SocketException catch (e) {
      print('❌ IVR initiateCall network: $e');
      return _errorResult(
        'No internet connection. Please check your network and try again.',
        errorCode: 'NETWORK',
      );
    } catch (e, stack) {
      print('❌ Exception in Live IVR initiateCall: $e');
      print('Stack: $stack');
      final msg = e.toString();
      return _errorResult(
        msg.contains('SocketException') || msg.contains('Failed host lookup')
            ? 'No internet connection. Please try again.'
            : msg.contains('TimeoutException') || msg.contains('timed out')
                ? 'Request timed out. Please try again.'
                : 'Something went wrong. Please try again.',
      );
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
      print('URL: ${ApiConfig.ivrCallJobMatchingApi}');
      print('Request Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(ApiConfig.ivrCallJobMatchingApi),
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
          final msg = data['message']?.toString() ??
              'Failed to initiate job matching call';
          return _errorResult(msg);
        }
      }

      // Parse error body for user-friendly message
      Map<String, dynamic>? decoded;
      try {
        decoded = json.decode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        decoded = null;
      }

      final apiMessage = decoded?['message']?.toString();
      final easygoErrorRaw = decoded?['easygo_error']?.toString();

      // 500 with "Job saved but IVR failed" and easygo "Token Expired"
      if (response.statusCode == 500 &&
          (apiMessage != null || easygoErrorRaw != null)) {
        String? easygoMsg;
        int? easygoCode;
        if (easygoErrorRaw != null && easygoErrorRaw.isNotEmpty) {
          try {
            final easygo = json.decode(easygoErrorRaw) as Map?;
            if (easygo != null) {
              easygoMsg = easygo['msg']?.toString();
              easygoCode = (easygo['code'] as num?)?.toInt();
            }
          } catch (_) {}
        }

        final isTokenExpired = easygoCode == 408 ||
            (easygoMsg?.toLowerCase().contains('token expired') ?? false);
        final jobSaved = apiMessage?.toLowerCase().contains('job saved') ?? false;

        if (isTokenExpired) {
          print('❌ Job Matching IVR: EasyGo token expired (408)');
          final userMsg = jobSaved
              ? 'IVR session expired. Your job was saved. Please try again in a moment or log in again.'
              : 'IVR session expired. Please try again or log in again.';
          return _errorResult(userMsg, errorCode: 'EASYGO_TOKEN_EXPIRED');
        }

        if (apiMessage != null && apiMessage.isNotEmpty) {
          return _errorResult(apiMessage);
        }
      }

      if (apiMessage != null && apiMessage.isNotEmpty) {
        return _errorResult(apiMessage);
      }

      final fallback = response.statusCode >= 500
          ? 'Server error. Please try again later.'
          : response.statusCode == 408
              ? 'Request timed out. Please try again.'
              : response.statusCode == 401
                  ? 'Session expired. Please log in again.'
                  : 'Request failed (${response.statusCode}). Please try again.';
      return _errorResult(fallback);
    } on TimeoutException catch (e) {
      print('❌ Job Matching IVR timeout: $e');
      return _errorResult(
        'Request timed out. Please check your connection and try again.',
        errorCode: 'TIMEOUT',
      );
    } on SocketException catch (e) {
      print('❌ Job Matching IVR network: $e');
      return _errorResult(
        'No internet connection. Please check your network and try again.',
        errorCode: 'NETWORK',
      );
    } catch (e, stack) {
      print('❌ Exception in initiateJobMatchingCall: $e');
      print('Stack: $stack');
      final msg = e.toString();
      return _errorResult(
        msg.contains('SocketException') || msg.contains('Failed host lookup')
            ? 'No internet connection. Please try again.'
            : msg.contains('TimeoutException') || msg.contains('timed out')
                ? 'Request timed out. Please try again.'
                : 'Something went wrong. Please try again.',
      );
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
        return _errorResult('Session expired. Please log in again.');
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
      }

      final parsed = _parseErrorBody(response.body);
      final apiMessage = parsed?['message'];
      final errorMsg = apiMessage != null && apiMessage.isNotEmpty
          ? apiMessage
          : 'Request failed (${response.statusCode}). Please try again.';
      print('❌ HTTP Error: ${response.statusCode} - $errorMsg');
      return _errorResult(errorMsg);
    } on TimeoutException catch (e) {
      print('❌ Update call timeout: $e');
      return _errorResult(
        'Request timed out. Please try again.',
        errorCode: 'TIMEOUT',
      );
    } on SocketException catch (e) {
      print('❌ Update call network: $e');
      return _errorResult(
        'No internet connection. Please try again.',
        errorCode: 'NETWORK',
      );
    } catch (e, stack) {
      print('❌ Failed to update call: $e');
      print('Stack: $stack');
      final msg = e.toString();
      return _errorResult(
        msg.contains('SocketException') || msg.contains('Failed host lookup')
            ? 'No internet connection. Please try again.'
            : msg.contains('TimeoutException') || msg.contains('timed out')
                ? 'Request timed out. Please try again.'
                : msg,
      );
    }
  }
}
