import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/smart_calling_models.dart';
import '../../models/leave_models.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static Duration get timeout => ApiConfig.timeout;

  // Store current caller ID
  static String? _currentCallerId;

  static void setCallerId(String callerId) {
    _currentCallerId = callerId;
  }

  // Get fresh leads (uncalled drivers) for telecaller
  static Future<List<DriverContact>> getFreshLeads({
    int limit = 50,
    String? callerId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/fresh_leads_api.php').replace(
        queryParameters: {
          'action': 'fresh_leads',
          'limit': limit.toString(),
          'caller_id': callerId ?? _currentCallerId ?? '1',
        },
      );

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> driversJson = data['data'];
          return driversJson
              .map((json) => _mapJsonToDriverContact(json))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch fresh leads');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch fresh leads: $e');
    }
  }

  // Get all drivers for smart calling
  static Future<List<DriverContact>> getDrivers({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
    String? callerId,
  }) async {
    try {
      // Use fresh_leads_api for status-based queries
      final apiEndpoint = status != null
          ? 'fresh_leads_api.php'
          : 'simple_drivers_api.php';
      final action = status != null ? 'fresh_leads' : 'drivers';

      final queryParams = <String, String>{
        'action': action,
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
        queryParams['caller_id'] = callerId ?? _currentCallerId ?? '1';
      } else {
        queryParams['offset'] = offset.toString();
        if (search != null && search.isNotEmpty) queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/$apiEndpoint',
      ).replace(queryParameters: queryParams);

      print('🔵 Fetching drivers from: $uri');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> driversJson = data['data'];
          print('✅ Fetched ${driversJson.length} drivers with status: $status');
          return driversJson
              .map((json) => _mapJsonToDriverContact(json))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch drivers');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch drivers: $e');
      throw Exception('Failed to fetch drivers: $e');
    }
  }

  // Get single driver by ID
  static Future<DriverContact> getDriver(String driverId) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/simple_drivers_api.php',
      ).replace(queryParameters: {'action': 'driver', 'id': driverId});

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _mapJsonToDriverContact(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch driver');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch driver: $e');
    }
  }

  // Update call status for a driver
  static Future<bool> updateCallStatus({
    required String driverId,
    required CallStatus status,
    String? feedback,
    String? remarks,
    String? callerId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/fresh_leads_api.php',
      ).replace(queryParameters: {'action': 'mark_called'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'driver_id': driverId,
              'status': _mapCallStatusToString(status),
              'feedback': feedback,
              'remarks': remarks,
              'caller_id': callerId ?? _currentCallerId ?? '1',
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update call status: $e');
    }
  }

  // Log a call
  static Future<bool> logCall({
    required String driverId,
    String? callerId,
    String? referenceId,
    String? apiResponse,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/simple_drivers_api.php',
      ).replace(queryParameters: {'action': 'log_call'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'driver_id': driverId,
              'caller_id': callerId ?? '1',
              'reference_id': referenceId,
              'api_response': apiResponse,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to log call: $e');
    }
  }

  // Update telecaller status (online, offline, on_call, break, busy)
  static Future<bool> updateTelecallerStatus({
    required String telecallerId,
    required String status,
    String? currentCallId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/manager_dashboard_api.php',
      ).replace(queryParameters: {'action': 'update_telecaller_status'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'telecaller_id': int.parse(telecallerId),
              'status': status,
              'current_call_id': currentCallId,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Telecaller status updated to: $status');
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to update telecaller status: $e');
      return false;
    }
  }

  // Get telecaller analytics data
  static Future<Map<String, dynamic>> getTelecallerAnalytics({
    String? period = 'week',
    String? callerId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/telecaller_analytics_api.php').replace(
        queryParameters: {
          'action': 'analytics',
          'period': period ?? 'week',
          'caller_id': callerId ?? _currentCallerId ?? '1',
        },
      );

      print('🔵 Fetching analytics from: $uri');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final dynamic rawData = json.decode(response.body);
        // Convert to Map<String, dynamic> explicitly
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          rawData as Map,
        );

        if (data['success'] == true) {
          print('✅ Analytics data fetched successfully');
          return data;
        } else {
          print('❌ Analytics API error: ${data['error']}');
          throw Exception(data['error'] ?? 'Failed to fetch analytics');
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch analytics: $e');
      // Return empty data structure instead of throwing
      return {
        'success': false,
        'error': e.toString(),
        'data': {
          'overview': {},
          'recent_calls': [],
          'call_trends': [],
          'performance_metrics': {},
          'hourly_activity': [],
        },
      };
    }
  }

  // Helper method to map JSON to DriverContact
  static DriverContact _mapJsonToDriverContact(Map<String, dynamic> json) {
    // Parse registration date from either registrationDate or createdAt field
    DateTime? regDate;
    if (json['registrationDate'] != null) {
      regDate = DateTime.tryParse(json['registrationDate']);
    } else if (json['createdAt'] != null) {
      regDate = DateTime.tryParse(json['createdAt']);
    }

    return DriverContact(
      id: json['id']?.toString() ?? '',
      tmid: json['tmid'] ?? 'TM000000',
      name: json['name'] ?? 'Unknown Driver',
      company: json['company'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      state: json['state'] ?? 'Unknown',
      subscriptionStatus: _mapStringToSubscriptionStatus(
        json['subscriptionStatus'],
      ),
      status: _mapStringToCallStatus(json['callStatus']),
      lastFeedback: json['lastFeedback'],
      lastCallTime: json['lastCallTime'] != null
          ? DateTime.tryParse(json['lastCallTime'])
          : null,
      remarks: json['remarks'],
      paymentInfo: _mapJsonToPaymentInfo(json['paymentInfo']),
      registrationDate: regDate,
      profileCompletion: _mapJsonToProfileCompletion(
        json['profile_completion'],
      ),
    );
  }

  // Helper method to map JSON to ProfileCompletion
  static ProfileCompletion? _mapJsonToProfileCompletion(dynamic json) {
    if (json == null) return null;

    // If it's a string like "75%", parse it
    if (json is String) {
      return ProfileCompletion.fromPercentageString(json);
    }

    // If it's a number, use it directly
    if (json is int) {
      return ProfileCompletion(percentage: json, documentStatus: {});
    }

    return null;
  }

  // Helper method to map JSON to PaymentInfo
  static PaymentInfo? _mapJsonToPaymentInfo(dynamic json) {
    if (json == null) return PaymentInfo.none();

    if (json is Map<String, dynamic>) {
      return PaymentInfo(
        subscriptionType: json['subscriptionType'],
        paymentStatus: _mapStringToPaymentStatus(json['paymentStatus']),
        paymentDate: json['paymentDate'] != null
            ? DateTime.tryParse(json['paymentDate'])
            : null,
        amount: json['amount']?.toString(),
        expiryDate: json['expiryDate'] != null
            ? DateTime.tryParse(json['expiryDate'])
            : null,
      );
    }

    return PaymentInfo.none();
  }

  // Helper method to map string to PaymentStatus enum
  static PaymentStatus _mapStringToPaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'paid':
        return PaymentStatus.success;
      case 'pending':
      case 'processing':
        return PaymentStatus.pending;
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.none;
    }
  }

  // Helper method to map string to CallStatus enum
  static CallStatus _mapStringToCallStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'connected':
        return CallStatus.connected;
      case 'callback':
        return CallStatus.callBack;
      case 'callbacklater':
      case 'callback_later':
        return CallStatus.callBackLater;
      case 'notreachable':
      case 'not_reachable':
        return CallStatus.notReachable;
      case 'notinterested':
      case 'not_interested':
        return CallStatus.notInterested;
      case 'invalid':
        return CallStatus.invalid;
      case 'pending':
      default:
        return CallStatus.pending;
    }
  }

  // Helper method to map CallStatus enum to string
  static String _mapCallStatusToString(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return 'connected';
      case CallStatus.callBack:
        return 'callback';
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_reachable';
      case CallStatus.notInterested:
        return 'not_interested';
      case CallStatus.invalid:
        return 'invalid';
      case CallStatus.pending:
        return 'pending';
    }
  }

  // Helper method to map string to SubscriptionStatus enum
  static SubscriptionStatus _mapStringToSubscriptionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'inactive':
      default:
        return SubscriptionStatus.inactive;
    }
  }

  // ============================================
  // IVR CALLING API METHODS
  // ============================================

  // Initiate IVR call through MyOperator
  static Future<Map<String, dynamic>> initiateIVRCall({
    required String driverMobile,
    required int callerId,
    required String driverId,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConfig.ivrCallApi,
      ).replace(queryParameters: {'action': 'initiate_call'});

      final requestBody = {
        'driver_mobile': driverMobile,
        'caller_id': callerId,
        'driver_id': driverId,
      };

      print('🔵 IVR Call API Request:');
      print('   URL: $uri');
      print('   Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(timeout);

      print('🔵 IVR Call API Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ IVR call initiated successfully');
          print('   Reference ID: ${data['data']?['reference_id']}');
          print('   Simulation Mode: ${data['simulation_mode']}');
          return data;
        } else {
          print('❌ IVR call failed: ${data['error']}');
          return data;
        }
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        print('❌ HTTP Error: $errorMsg');
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      print('❌ Exception in initiateIVRCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Initiate manual call (direct phone dialer)
  static Future<Map<String, dynamic>> initiateManualCall({
    required String driverMobile,
    required int callerId,
    required String driverId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/manual_call_api.php',
      ).replace(queryParameters: {'action': 'initiate_call'});

      final requestBody = {
        'driver_mobile': driverMobile,
        'caller_id': callerId,
        'driver_id': driverId,
      };

      print('🔵 Manual Call API Request:');
      print('   URL: $uri');
      print('   Body: ${json.encode(requestBody)}');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(timeout);

      print('🔵 Manual Call API Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Manual call logged successfully');
          print('   Reference ID: ${data['data']?['reference_id']}');
          return data;
        } else {
          print('❌ Manual call failed: ${data['error']}');
          return data;
        }
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        print('❌ HTTP Error: $errorMsg');
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      print('❌ Exception in initiateManualCall: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Get call status by reference ID
  static Future<Map<String, dynamic>> getCallStatus(String referenceId) async {
    try {
      final uri = Uri.parse(ApiConfig.ivrCallApi).replace(
        queryParameters: {'action': 'call_status', 'reference_id': referenceId},
      );

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to get call status: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update call feedback after completion
  static Future<bool> updateCallFeedback({
    required String referenceId,
    required String callStatus,
    String? feedback,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConfig.ivrCallApi,
      ).replace(queryParameters: {'action': 'update_feedback'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'reference_id': referenceId,
              'call_status': callStatus,
              'feedback': feedback,
              'remarks': remarks,
              'call_duration': callDuration,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to update call feedback: $e');
      return false;
    }
  }

  // Get detailed profile completion data
  static Future<ProfileCompletion?> getProfileCompletionDetails(
    String userId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/profile_completion_api.php').replace(
        queryParameters: {'action': 'get_profile_details', 'user_id': userId},
      );

      print('🔵 Fetching profile completion details for user: $userId');
      print('🔵 URL: $uri');

      final response = await http.get(uri).timeout(timeout);

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final profileData = data['data']['profile_completion'];
          final docStatus = profileData['document_status'] ?? {};
          final docValues = profileData['document_values'] ?? {};

          print('✅ Profile completion: ${profileData['percentage']}%');
          print('✅ Document status count: ${docStatus.length}');
          print('✅ Document values count: ${docValues.length}');

          // Convert all values to strings, handling different types
          final Map<String, String?> convertedValues = {};
          docValues.forEach((key, value) {
            if (value == null) {
              convertedValues[key] = null;
            } else if (value is String) {
              convertedValues[key] = value;
            } else if (value is int || value is double || value is bool) {
              convertedValues[key] = value.toString();
            } else {
              convertedValues[key] = value.toString();
            }
          });

          return ProfileCompletion(
            percentage: profileData['percentage'] ?? 0,
            documentStatus: Map<String, bool>.from(docStatus),
            documentValues: convertedValues,
          );
        } else {
          print('❌ API returned error: ${data['error']}');
        }
      }
      return null;
    } catch (e) {
      print('❌ Failed to fetch profile completion details: $e');
      return null;
    }
  }

  // Get call history
  static Future<List<dynamic>> getCallHistory({String? status}) async {
    try {
      final queryParams = <String, String>{
        'action': 'call_history',
        'caller_id': _currentCallerId ?? '1',
        'limit': '100',
      };

      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(
        '$baseUrl/call_history_api.php',
      ).replace(queryParameters: queryParams);

      print('🔵 Fetching call history from: $uri');
      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> historyJson = data['data'] ?? [];
          print('✅ Fetched ${historyJson.length} call history entries');
          return historyJson;
        } else {
          print('⚠️ API returned success=false: ${data['error']}');
          return [];
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Failed to fetch call history: $e');
      return [];
    }
  }

  // Update call history feedback
  static Future<bool> updateCallHistoryFeedback({
    required String callLogId,
    required String callStatus,
    String? feedback,
    String? remarks,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/call_history_api.php',
      ).replace(queryParameters: {'action': 'update_feedback'});

      final requestBody = {
        'call_log_id': callLogId,
        'call_status': callStatus,
        if (feedback != null) 'feedback': feedback,
        if (remarks != null) 'remarks': remarks,
      };

      print('🔵 Update Feedback Request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(timeout);

      print('🔵 Update Feedback Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to update feedback: $e');
      return false;
    }
  }

  // Upload call recording
  static Future<Map<String, dynamic>> uploadCallRecording({
    required dynamic recordingFile,
    required String tmid,
    required String callerId,
    String? callLogId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload_recording_api.php');

      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['tmid'] = tmid;
      request.fields['caller_id'] = callerId;
      if (callLogId != null) {
        request.fields['call_log_id'] = callLogId;
      }

      // Add file
      if (recordingFile != null) {
        final file = recordingFile as dynamic;
        request.files.add(
          await http.MultipartFile.fromPath('recording', file.path),
        );
      }

      print('🔵 Uploading recording: $tmid\_$callerId');

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // Longer timeout for file upload
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Upload Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Recording uploaded: ${data['url']}');
        }
        return data;
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Failed to upload recording: $e');
      return {'success': false, 'error': 'Upload error: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE MANAGEMENT METHODS
  // ═══════════════════════════════════════════════════════════════

  // Apply for leave
  static Future<bool> applyLeave({
    required String telecallerId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required String reason,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/enhanced_leave_management_api.php',
      ).replace(queryParameters: {'action': 'apply_leave'});

      final requestBody = {
        'telecaller_id': telecallerId,
        'leave_type': leaveType,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'total_days': totalDays,
        'reason': reason,
      };

      print('🔵 Apply Leave Request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(timeout);

      print('🔵 Apply Leave Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to apply leave: $e');
      return false;
    }
  }

  // Get leave requests for telecaller
  static Future<List<LeaveRequest>> getLeaveRequests({
    required String telecallerId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/enhanced_leave_management_api.php')
          .replace(
            queryParameters: {
              'action': 'get_my_leaves',
              'telecaller_id': telecallerId,
            },
          );

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> leaveData = data['data'] ?? [];
          return leaveData.map((json) => LeaveRequest.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Failed to get leave requests: $e');
      return [];
    }
  }

  // Get all leave requests (for managers)
  static Future<List<LeaveRequest>> getAllLeaveRequests({
    String? managerId,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'action': 'get_leave_requests_for_approval',
      };

      if (managerId != null) queryParams['manager_id'] = managerId;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$baseUrl/enhanced_leave_management_api.php',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> leaveData = data['data'] ?? [];
          return leaveData.map((json) => LeaveRequest.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Failed to get all leave requests: $e');
      return [];
    }
  }

  // Update leave status (approve/reject)
  static Future<bool> updateLeaveStatus({
    required String leaveId,
    required String status,
    required String managerId,
    String? managerRemarks,
  }) async {
    try {
      final action = status == 'approved'
          ? 'manager_approve_leave'
          : 'reject_leave';

      final uri = Uri.parse(
        '$baseUrl/enhanced_leave_management_api.php',
      ).replace(queryParameters: {'action': action});

      final requestBody = {
        'leave_request_id': leaveId,
        'manager_id': managerId,
        if (managerRemarks != null && managerRemarks.isNotEmpty)
          'manager_remarks': managerRemarks,
        if (status == 'rejected') 'rejected_by': managerId,
      };

      print('🔵 Update Leave Status Request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(timeout);

      print('🔵 Update Leave Status Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to update leave status: $e');
      return false;
    }
  }
}
