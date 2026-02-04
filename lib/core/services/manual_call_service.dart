import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';
import '../config/api_config.dart';

/// Manual Call Service for initiating and updating manual calls
/// Uses the telehead manual call API endpoints
class ManualCallService {
  static String get _initiateCallUrl =>
      ApiConfig.getLaravelApiUrl('manual-call');
  static String get _updateCallUrl =>
      ApiConfig.getLaravelApiUrl('manual-call-update');
  static String get _initiateJobMatchingCallUrl =>
      ApiConfig.getLaravelApiUrl('manual-call-jobMatching');
  static String get _updateJobMatchingCallUrl =>
      ApiConfig.getLaravelApiUrl('manual-call-update-jobMatching');
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

  /// Initiate manual call for job matching
  /// Returns id on success
  static Future<Map<String, dynamic>> initiateJobMatchingCall({
    required String uniqueIdTransporter,
    required String uniqueIdDriver,
    required String userIdTransporter,
    required String userIdDriver,
    required String assignedTo,
    required String jobId,
    required String driverName,
    required String transporterName,
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
        'unique_id_transporter': uniqueIdTransporter,
        'unique_id_driver': uniqueIdDriver,
        'user_id_transporter': userIdTransporter,
        'user_id_driver': userIdDriver,
        'assigned_to': assignedTo,
        'job_id': jobId,
        'driver_name': driverName,
        'transporter_name': transporterName,
      };

      print('🔵 Manual Call Job Matching Initiate Request:');
      print('   URL: $_initiateJobMatchingCallUrl');
      print('   Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(_initiateJobMatchingCallUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print('🔵 Manual Call Job Matching Initiate Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          // API returns 'match_id' instead of 'id'
          final id = data['data']['match_id'] ?? data['data']['id'];
          print('✅ Manual job matching call initiated successfully. ID: $id');

          return {'success': true, 'id': id, 'match_id': id, 'data': data};
        } else {
          return {
            'success': false,
            'error':
                data['message'] ??
                'Failed to initiate manual job matching call',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in Manual Call initiateJobMatchingCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update manual call for job matching with feedback
  /// Uses multipart form data for file upload
  static Future<Map<String, dynamic>> updateJobMatchingCall({
    required int id,
    required String callStatus,
    required String callFeedback,
    String? callRemarks,
    String? matchStatus,
    required String driverName,
    required String transporterName,
    File? callRecording,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No auth token'};
      }

      print('🔵 Manual Call Job Matching Update Request:');
      print('   URL: $_updateJobMatchingCallUrl');
      print('   ID: $id');
      print('   Status: "$callStatus"');
      print('   Feedback: "$callFeedback"');
      print('   Remarks: "${callRemarks ?? ''}"');
      print('   Match Status: "${matchStatus ?? ''}"');
      print(
        '   Recording: ${callRecording != null ? callRecording.path : "none"}',
      );
      print(
        '   Token: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
      );

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_updateJobMatchingCallUrl),
      );

      // Add headers - same as Postman
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['id'] = id.toString();
      request.fields['call_status'] = callStatus;
      request.fields['call_feedback'] = callFeedback;
      request.fields['driver_name'] = driverName;
      request.fields['transporter_name'] = transporterName;

      if (callRemarks != null && callRemarks.isNotEmpty) {
        request.fields['call_remarks'] = callRemarks;
      }

      if (matchStatus != null && matchStatus.isNotEmpty) {
        request.fields['match_status'] = matchStatus;
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

      print('🔵 Manual Call Job Matching Update Response:');
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
          print('✅ Manual job matching call updated successfully');
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
      print('❌ Failed to update manual job matching call: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static String get _initiateJobBriefCallUrl =>
      ApiConfig.getLaravelApiUrl('manual-call-jobBrief');
  static String get _updateJobBriefCallUrl =>
      ApiConfig.getLaravelApiUrl('manual-call-update-jobBrief');

  /// Initiate manual call for Job Brief
  static Future<Map<String, dynamic>> initiateJobBriefCall({
    required String uniqueId, // unique_id of transporter/job
    required String userId,
    required String assignedTo,
    required String jobId,
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

      final requestBody = {
        'unique_id': uniqueId,
        'user_id': userId,
        'assigned_to': assignedTo,
        'job_id': jobId,
        'exten': exten,
        'number': number,
      };

      print('🔵 Manual Call Job Brief Initiate Request:');
      print('   URL: $_initiateJobBriefCallUrl');
      print('   Body: $requestBody');

      final response = await http
          .post(
            Uri.parse(_initiateJobBriefCallUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print('🔵 Manual Call Job Brief Initiate Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data; // Should return {success: true, data: {id: ...}}
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in Manual Call initiateJobBriefCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Update manual call for Job Brief with feedback
  static Future<Map<String, dynamic>> updateJobBriefCall({
    required int id,
    required String name,
    required String jobLocation,
    required String route,
    required String vehicleType,
    required String licenseType,
    required String experience,
    required String salaryFixed,
    required String salaryVariable,
    required String esiPf,
    required int foodAllowance,
    required int tripIncentive,
    required String rehneKiSuvidha,
    required String mileage,
    required int fastTagRoadKharcha,
    required int closedJob,
    required String callStatus,
    required String callFeedback,
    String? callRemarks,
    required String requiredDrivers,
    File? callRecording,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No auth token'};
      }

      print('🔵 Manual Call Job Brief Update Request:');
      print('   URL: $_updateJobBriefCallUrl');
      print('   ID: $id');
      print('   Status: $callStatus');
      print('   Feedback: $callFeedback');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_updateJobBriefCallUrl),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['id'] = id.toString();
      request.fields['name'] = name;
      request.fields['job_location'] = jobLocation;
      request.fields['route'] = route;
      request.fields['vehicle_type'] = vehicleType;
      request.fields['license_type'] = licenseType;
      request.fields['experience'] = experience;
      request.fields['salary_fixed'] = salaryFixed;
      request.fields['salary_variable'] = salaryVariable;
      request.fields['esi_pf'] = esiPf;
      request.fields['food_allowance'] = foodAllowance.toString();
      request.fields['trip_incentive'] = tripIncentive.toString();
      request.fields['rehne_ki_suvidha'] = rehneKiSuvidha;
      request.fields['mileage'] = mileage;
      request.fields['fast_tag_road_kharcha'] = fastTagRoadKharcha.toString();
      request.fields['closed_job'] = closedJob.toString();
      request.fields['call_status'] = callStatus;
      request.fields['call_feedback'] = callFeedback;
      request.fields['call_remarks'] = callRemarks ?? '';
      request.fields['required_drivers'] = requiredDrivers;

      if (callRecording == null) {
        request.fields['call_recording'] = ''; // Default empty if no file
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
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Manual Call Job Brief Update Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // Expected {success: true, ...}
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in updateJobBriefCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
