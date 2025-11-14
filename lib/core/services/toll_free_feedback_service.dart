import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/smart_calling_models.dart';
import '../../models/toll_free_lead_model.dart';
import 'real_auth_service.dart';

class TollFreeFeedbackService {
  TollFreeFeedbackService._();

  static final TollFreeFeedbackService instance = TollFreeFeedbackService._();

  Future<Map<String, dynamic>> submitFeedback({
    required TollFreeUser user,
    required CallFeedback feedback,
  }) async {
    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final callerId = int.tryParse(currentUser.id) ?? 0;

      final uri = Uri.parse('${ApiConfig.baseUrl}/toll_free_feedback_api.php');

      // Build feedback string based on status
      String feedbackString = '';
      switch (feedback.status) {
        case CallStatus.connected:
          feedbackString = feedback.connectedFeedback?.displayName ?? 'Connected';
          break;
        case CallStatus.callBack:
          feedbackString = feedback.callBackReason?.displayName ?? 'Call Back';
          break;
        case CallStatus.callBackLater:
          feedbackString = feedback.callBackTime?.displayName ?? 'Call Back Later';
          break;
        case CallStatus.notInterested:
          feedbackString = 'Not Interested';
          break;
        case CallStatus.notReachable:
          feedbackString = 'Not Reachable';
          break;
        case CallStatus.invalid:
          feedbackString = 'Invalid Number';
          break;
        case CallStatus.pending:
          feedbackString = 'Pending';
          break;
      }

      final body = {
        'caller_id': callerId,
        'user_id': user.id,
        'unique_id': user.uniqueId,
        'name': user.name,
        'mobile': user.mobile,
        'role': user.role,
        'feedback': feedbackString,
        'remarks': feedback.remarks ?? '',
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // Upload recording if provided
          if (data['success'] == true && feedback.recordingFile != null) {
            final callLogId = data['data']?['id'];
            if (callLogId != null) {
              await uploadRecording(
                recordingFile: feedback.recordingFile!,
                callLogId: callLogId.toString(),
                tmid: user.uniqueId,
                callerId: callerId.toString(),
              );
            }
          }
          
          return data;
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid response format',
            'raw_response': response.body.substring(0, 200),
            'error': e.toString(),
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'raw_response': response.body.substring(0, 200),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> uploadRecording({
    required File recordingFile,
    required String callLogId,
    required String tmid,
    required String callerId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload_recording_api.php');

      final request = http.MultipartRequest('POST', uri);
      request.fields['tmid'] = tmid;
      request.fields['caller_id'] = callerId;
      request.fields['call_log_id'] = callLogId;

      request.files.add(
        await http.MultipartFile.fromPath(
          'recording',
          recordingFile.path,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload error: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchCallHistory() async {
    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final callerId = int.tryParse(currentUser.id) ?? 0;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/toll_free_feedback_api.php',
      ).replace(
        queryParameters: {
          'action': 'get_history',
          'caller_id': callerId.toString(),
        },
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch call history: $e');
    }
  }
}
