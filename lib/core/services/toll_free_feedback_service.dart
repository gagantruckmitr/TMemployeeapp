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

      // Determine which API to use based on applied jobs
      final hasAppliedJobs = user.appliedJobs.isNotEmpty;
      
      if (hasAppliedJobs) {
        // Use matchmaking API for users with applied jobs
        return await _submitMatchmakingFeedback(
          user: user,
          feedback: feedback,
          callerId: callerId,
        );
      } else {
        // Use welcome call API for users without applied jobs
        return await _submitWelcomeCallFeedback(
          user: user,
          feedback: feedback,
          callerId: callerId,
        );
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _submitMatchmakingFeedback({
    required TollFreeUser user,
    required CallFeedback feedback,
    required int callerId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/phase2_call_feedback_direct.php');

      // Build feedback string based on status
      String feedbackString = '';
      String matchStatus = '';
      
      switch (feedback.status) {
        case CallStatus.connected:
          feedbackString = feedback.connectedFeedback?.displayName ?? 'Connected';
          matchStatus = 'connected';
          break;
        case CallStatus.callBack:
          feedbackString = feedback.callBackReason?.displayName ?? 'Call Back';
          matchStatus = 'callback';
          break;
        case CallStatus.callBackLater:
          feedbackString = feedback.callBackTime?.displayName ?? 'Call Back Later';
          matchStatus = 'callback_later';
          break;
        case CallStatus.notInterested:
          feedbackString = 'Not Interested';
          matchStatus = 'not_interested';
          break;
        case CallStatus.notReachable:
          feedbackString = 'Not Reachable';
          matchStatus = 'not_reachable';
          break;
        case CallStatus.invalid:
          feedbackString = 'Invalid Number';
          matchStatus = 'invalid';
          break;
        case CallStatus.pending:
          feedbackString = 'Pending';
          matchStatus = 'pending';
          break;
      }

      // Get first applied job for matchmaking context
      final firstJob = user.appliedJobs.isNotEmpty ? user.appliedJobs[0] : null;
      final jobDetails = firstJob?['job_details'] as Map<String, dynamic>?;
      final jobId = jobDetails?['job_id'] ?? '';

      final body = {
        'callerId': callerId,
        'uniqueIdDriver': user.isDriver ? user.uniqueId : '',
        'uniqueIdTransporter': user.isTransporter ? user.uniqueId : '',
        'driverName': user.isDriver ? user.name : '',
        'transporterName': user.isTransporter ? user.name : '',
        'feedback': feedbackString,
        'matchStatus': matchStatus,
        'additionalNotes': feedback.remarks ?? '',
        'jobId': jobId,
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
            print('🎙️ Uploading recording for matchmaking...');
            print('Driver TMID: ${user.isDriver ? user.uniqueId : ""}');
            print('Transporter TMID: ${user.isTransporter ? user.uniqueId : ""}');
            print('Job ID: $jobId');
            print('Recording file: ${feedback.recordingFile!.path}');
            
            final uploadResult = await _uploadMatchmakingRecording(
              recordingFile: feedback.recordingFile!,
              driverTmid: user.isDriver ? user.uniqueId : '',
              transporterTmid: user.isTransporter ? user.uniqueId : '',
              jobId: jobId,
              callerId: callerId.toString(),
            );
            
            print('📤 Recording upload result: $uploadResult');
          } else {
            print('⚠️ Recording not uploaded - Success: ${data['success']}, Has file: ${feedback.recordingFile != null}');
          }
          
          return data;
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid response format',
            'raw_response': response.body.length > 200 ? response.body.substring(0, 200) : response.body,
            'error': e.toString(),
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'raw_response': response.body.length > 200 ? response.body.substring(0, 200) : response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Matchmaking feedback error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _submitWelcomeCallFeedback({
    required TollFreeUser user,
    required CallFeedback feedback,
    required int callerId,
  }) async {
    try {
      print('📞 Submitting welcome call feedback...');
      // TODO: Upload toll_free_feedback_api.php to server, then change back to toll_free_feedback_api.php
      final uri = Uri.parse('${ApiConfig.baseUrl}/social_media_feedback_api.php');
      print('API URL: $uri');

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
        'lead_id': user.id,
        'name': user.name,
        'mobile': user.mobile,
        'feedback': feedbackString,
        'remarks': feedback.remarks ?? '',
      };

      print('📤 Request body: $body');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(ApiConfig.timeout);

      print('📡 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // Upload recording if provided
          if (data['success'] == true && feedback.recordingFile != null) {
            print('🎙️ Uploading recording for welcome call...');
            final callLogId = data['data']?['id'];
            print('Call log ID: $callLogId');
            if (callLogId != null) {
              final uploadResult = await uploadRecording(
                recordingFile: feedback.recordingFile!,
                callLogId: callLogId.toString(),
                tmid: user.uniqueId,
                callerId: callerId.toString(),
              );
              print('📤 Recording upload result: $uploadResult');
            }
          } else {
            print('⚠️ Recording not uploaded - Success: ${data['success']}, Has file: ${feedback.recordingFile != null}');
          }
          
          return data;
        } catch (e) {
          print('❌ JSON decode error: $e');
          return {
            'success': false,
            'message': 'Invalid response format',
            'raw_response': response.body.length > 200 ? response.body.substring(0, 200) : response.body,
            'error': e.toString(),
          };
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'raw_response': response.body.length > 200 ? response.body.substring(0, 200) : response.body,
        };
      }
    } catch (e) {
      print('💥 Welcome call feedback error: $e');
      return {
        'success': false,
        'message': 'Welcome call feedback error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _uploadMatchmakingRecording({
    required File recordingFile,
    required String driverTmid,
    required String transporterTmid,
    required String jobId,
    required String callerId,
  }) async {
    try {
      print('🔄 Starting matchmaking recording upload...');
      print('API URL: ${ApiConfig.baseUrl}/phase2_upload_driver_recording_api.php');
      print('Job ID: $jobId');
      print('Caller ID: $callerId');
      print('Driver TMID: $driverTmid');
      print('Transporter TMID: $transporterTmid');
      print('File path: ${recordingFile.path}');
      print('File exists: ${await recordingFile.exists()}');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/phase2_upload_driver_recording_api.php');

      final request = http.MultipartRequest('POST', uri);
      request.fields['job_id'] = jobId;
      request.fields['caller_id'] = callerId;
      
      if (driverTmid.isNotEmpty) {
        request.fields['driver_tmid'] = driverTmid;
      }
      
      if (transporterTmid.isNotEmpty) {
        request.fields['transporter_tmid'] = transporterTmid;
      }

      print('📋 Request fields: ${request.fields}');

      request.files.add(
        await http.MultipartFile.fromPath(
          'recording',
          recordingFile.path,
        ),
      );

      print('📁 File added to request');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      print('📡 Response status: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Upload successful: $result');
        return result;
      } else {
        print('❌ Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
          'response': response.body,
        };
      }
    } catch (e) {
      print('💥 Upload error: $e');
      return {
        'success': false,
        'message': 'Upload error: $e',
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
