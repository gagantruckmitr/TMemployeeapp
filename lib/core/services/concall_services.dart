import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../features/telecaller/widgets/ivr_call_waiting_overlay.dart';
import '../../models/concall_history_model.dart';
import '../config/api_config.dart';
import 'phase2_api_service.dart';
import 'real_auth_service.dart';

class ConCallService {
  static final ConCallService instance = ConCallService._internal();
  ConCallService._internal();

  int? activeMatchId;
  String? activeJobId;

  void clearActiveCall() {
    activeMatchId = null;
    activeJobId = null;
    IVRCallWaitingOverlay.removeMiniOverlay();
  }

  /// Fetch con call history for a specific assigned user
  Future<List<ConCallHistoryModel>> fetchConCallHistory(int assignedTo) async {
    try {
      // Get auth token
      final token = await RealAuthService.instance.getAuthToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = ApiConfig.getConCallHistoryUrl(assignedTo);
      
      print('🔵 Fetching Con Call History:');
      print('   URL: $url');
      print('   Assigned To: $assignedTo');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('   Response Status: ${response.statusCode}');
      print('   Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['jobs'] != null && data['jobs'] is List) {
          final jobs = (data['jobs'] as List)
              .map((job) => ConCallHistoryModel.fromJson(job))
              .toList();
          print('✅ Loaded ${jobs.length} con calls');
          return jobs;
        }
        print('⚠️ No jobs found in response');
        return [];
      } else {
        throw Exception('Failed to load con call history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching con call history: $e');
      rethrow;
    }
  }

  Future<void> handleConCallTap({
    required BuildContext context,
    required String jobId,
    required String phoneExten,
    required String targetPhone,
    required int assignedTo,
    bool isDriverCall = false,
    String? driverTmid,
    int? driverUserId,
    String? driverName,
    String? transporterTmid,
    int? transporterUserId,
    String? transporterName,
    required Function(String? matchId) onShowFeedback,
  }) async {
    try {
      final cleanExtenPhone = phoneExten.replaceAll(RegExp(r'[^\d]'), '');
      final cleanTargetPhone = targetPhone.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanTargetPhone.isEmpty) {
        throw Exception('Target phone number not found');
      }

      if (activeMatchId == null) {
        // INITIATE FIRST LEG
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📞 Initiating ConCall First Leg...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }

        final res = await Phase2ApiService.initiateConCallFirst(
          jobId: jobId,
          assignedTo: assignedTo,
          exten: cleanExtenPhone,
          number: cleanTargetPhone,
          isDriverCall: isDriverCall,
          driverTmid: driverTmid,
          driverUserId: driverUserId,
          driverName: driverName,
          transporterTmid: transporterTmid,
          transporterUserId: transporterUserId,
          transporterName: transporterName,
        );

        if (res['success'] != true) {
          throw Exception(res['message'] ?? 'Failed to initiate first leg');
        }

        activeMatchId = int.tryParse(res['match_id']?.toString() ?? '0');
        activeJobId = jobId;

        if (activeMatchId == 0) {
          activeMatchId = null;
          throw Exception('Invalid match_id received');
        }

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: isDriverCall
                      ? (driverName ?? 'Driver')
                      : (transporterName ?? 'Transporter'),
                  referenceId: jobId,
                  allowMinimize: true,
                  onCallEnded: () {
                    final endedMatchId = activeMatchId?.toString();
                    clearActiveCall();
                    onShowFeedback(endedMatchId);
                  },
                ),
              ),
            ),
          );
        }
      } else {
        // INITIATE SECOND LEG
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📞 Initiating ConCall Second Leg...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }

        final res = await Phase2ApiService.initiateConCallSecond(
          matchId: activeMatchId!,
          jobId: jobId,
          assignedTo: assignedTo,
          exten: cleanExtenPhone,
          number: cleanTargetPhone,
          isTransporterCall: !isDriverCall,
          driverTmid: driverTmid,
          driverUserId: driverUserId,
          driverName: driverName,
          transporterTmid: transporterTmid,
          transporterUserId: transporterUserId,
          transporterName: transporterName,
        );

        if (res['success'] != true) {
          throw Exception(res['message'] ?? 'Failed to initiate second leg');
        }

        final currentMatchId = activeMatchId?.toString();

        // After second call initiates, remove mini overlay (or update it) and show a new overlay?
        // "if it is in mini mode and second call is iniated and after second call insiated and call ended then feedback box will open"
        IVRCallWaitingOverlay.removeMiniOverlay();

        if (context.mounted) {
          // Push new overlay for the second person
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName:
                      'ConCall: ${(isDriverCall ? driverName : transporterName) ?? 'Participant'}',
                  referenceId: jobId,
                  allowMinimize:
                      false, // Wait until call is done, then feedback
                  onCallEnded: () {
                    clearActiveCall();
                    onShowFeedback(currentMatchId);
                  },
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
