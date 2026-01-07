import 'package:flutter/material.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/phase2_auth_service.dart';
import '../../../core/services/phase2_api_service.dart';
import 'ivr_call_waiting_overlay.dart';

/// Helper class for initiating EasyGo IVR calls across all screens
class EasyGoIVRCallHelper {
  /// Initiate an EasyGo IVR call
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs and overlays
  /// - [clientName]: Name of the person being called (driver/transporter)
  /// - [clientPhone]: Phone number of the person being called
  /// - [clientId]: ID of the person being called (TMID)
  /// - [contactType]: Type of contact ('driver' or 'transporter')
  /// - [callSource]: Source of the call (e.g., 'job_posting', 'job_applicants')
  /// - [onCallEnded]: Callback when call ends (for showing feedback modal) - DEPRECATED
  /// - [onCallCompleted]: Callback when call ends, providing the callLogId (for showing feedback modal)
  /// - [transporterTmid]: TMID of transporter (for job matching IVR)
  /// - [transporterName]: Name of transporter (for job matching IVR)
  /// - [transporterUserId]: User ID of transporter (for job matching IVR)
  /// - [driverUserId]: User ID of driver (for job matching IVR)
  /// - [jobId]: Job ID (for job matching IVR)
  /// - [assignedTo]: User ID of person assigned to (for job matching IVR)
  /// - [jobBriefTransporterUserId]: Transporter's user ID for job brief IVR
  static Future<void> initiateCall({
    required BuildContext context,
    required String clientName,
    required String clientPhone,
    required String clientId,
    required String tmid, // Added TMID
    String contactType = 'driver',
    String? callSource,
    String process = 'Driver Onboarding', // Added process with new default
    VoidCallback? onCallEnded,
    Function(String? callLogId)? onCallCompleted,
    String? transporterTmid,
    String? transporterName,
    int? transporterUserId,
    int? driverUserId,
    String? jobId,
    int? assignedTo,
    int? jobBriefTransporterUserId,
  }) async {
    try {
      print('� [IVR DEBUG] EasyGoIVRCallHelper: initiateCall called');
      print(
        '🚀 [IVR DEBUG] Params: Name=$clientName, Phone=$clientPhone, TMID=$tmid, ClientID=$clientId',
      );

      print('�🔵 EasyGoIVRCallHelper.initiateCall() started');
      print('   Client: $clientName');
      print('   Phone: $clientPhone');
      print('   ID: $clientId');
      print('   TMID: $tmid');
      print('   Type: $contactType');

      // Get telecaller info from user profile
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        print('❌ User not logged in');
        _showError(context, 'User not logged in');
        return;
      }

      final telecallerPhone = user.mobile;
      final callerId = user.id;

      print('✅ User found: ID=$callerId, Phone=$telecallerPhone');

      if (telecallerPhone.isEmpty) {
        print('❌ Telecaller phone is empty');
        _showError(context, 'Telecaller phone number not found in profile');
        return;
      }

      // Clean phone numbers
      final cleanTelecallerPhone = telecallerPhone.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final cleanClientPhone = clientPhone.replaceAll(RegExp(r'[^\d]'), '');

      print(
        '📱 Cleaned phones: Telecaller=$cleanTelecallerPhone, Client=$cleanClientPhone',
      );

      // Validate phone numbers
      if (cleanClientPhone.isEmpty || cleanClientPhone.length < 10) {
        print('❌ Invalid client phone: $cleanClientPhone');
        _showError(context, 'Invalid phone number for $clientName');
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📞 Initiating EasyGo IVR call...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // For job applicants, use ONLY the job matching API (don't call generic IVR)
      // API: truckmitr.com/api/telehead/ivr-call-jobMatching
      String? matchId;
      Map<String, dynamic> result;

      if (callSource == 'job_applicants' &&
          transporterTmid != null &&
          transporterTmid.isNotEmpty &&
          transporterName != null &&
          transporterName.isNotEmpty &&
          transporterUserId != null &&
          driverUserId != null &&
          jobId != null &&
          jobId.isNotEmpty &&
          assignedTo != null) {
        try {
          print('🔵 Calling Job Matching IVR API (job_applicants)...');
          print('🔵 API: truckmitr.com/api/telehead/ivr-call-jobMatching');
          print('🔵 Request Data:');
          print('   unique_id_transporter: $transporterTmid');
          print('   unique_id_driver: $tmid');
          print('   user_id_transporter: $transporterUserId');
          print('   user_id_driver: $driverUserId');
          print('   assigned_to: $assignedTo');
          print('   job_id: $jobId');
          print('   transporter_name: $transporterName');
          print('   driver_name: $clientName');
          print('   exten (telecaller): $cleanTelecallerPhone');
          print('   number (driver): $cleanClientPhone');

          result = await SmartCallingService.instance.initiateJobMatchingCall(
            uniqueIdTransporter: transporterTmid,
            uniqueIdDriver: tmid,
            userIdTransporter: transporterUserId,
            userIdDriver: driverUserId,
            assignedTo: assignedTo,
            jobId: jobId,
            transporterName: transporterName,
            driverName: clientName,
            exten: cleanTelecallerPhone,
            number: cleanClientPhone,
          );
          print('✅ Job Matching IVR API called successfully');
          print('🔵 Response: $result');

          // Extract match_id from response
          matchId = result['match_id']?.toString();
          print('🔵 Match ID from API: $matchId');
        } catch (e) {
          print('⚠️ Job Matching IVR API error: $e');
          result = {'success': false, 'error': e.toString()};
        }
      } else if (callSource == 'job_posting' &&
          jobId != null &&
          assignedTo != null &&
          jobBriefTransporterUserId != null) {
        // For job posting, use ONLY the job brief API (don't call generic IVR)
        try {
          print('🔵 Calling Job Brief IVR API (job_posting)...');
          result = await Phase2ApiService.initiateIVRCallJobBrief(
            uniqueId: tmid,
            transporterUserId: jobBriefTransporterUserId,
            assignedTo: assignedTo,
            jobId: jobId,
            exten: cleanTelecallerPhone,
            number: cleanClientPhone,
          );
          print('✅ Job Brief IVR API called successfully');
          print('🔵 Job Brief Response: $result');
        } catch (e) {
          print('⚠️ Job Brief IVR API error: $e');
          result = {'success': false, 'error': e.toString()};
        }
      } else {
        // For other call sources, use generic IVR API
        print('🔵 Calling SmartCallingService.initiateEasyGoIVR()...');

        result = await SmartCallingService.instance.initiateEasyGoIVR(
          telecallerPhone: cleanTelecallerPhone,
          clientPhone: cleanClientPhone,
          callerId: callerId.toString(),
          contactId: clientId,
          tmid: tmid,
          contactType: contactType,
          driverName: clientName,
          duration: '',
          callSource: callSource,
          process: process,
        );

        print('🔵 EasyGo IVR Result: $result');
      }

      // Extract job_brief_id from result if job_posting
      String? jobBriefId;
      if (callSource == 'job_posting') {
        jobBriefId = result['data']?['job_brief_id']?.toString();
        print('🔵 Job Brief ID from API: $jobBriefId');
      }

      if (context.mounted) {
        if (result['success'] == true) {
          final referenceId =
              result['reference_id'] ??
              result['data']?['call_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString();

          // Robust ID extraction
          final callLogId =
              result['call_log_id']?.toString() ??
              result['call_id']?.toString() ??
              result['data']?['call_history_id']?.toString() ??
              ((result['reference_id'] != null &&
                      int.tryParse(result['reference_id'].toString()) != null)
                  ? result['reference_id'].toString()
                  : null);

          print(
            '✅ Call initiated successfully! Reference: $referenceId, Call Log ID: $callLogId',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ EasyGo IVR call initiated! Both phones will ring.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Show IVR call waiting overlay
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (overlayContext) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: clientName,
                  referenceId: referenceId,
                  onCallEnded: () {
                    // Navigator pop is handled inside the overlay widget
                    // Add a delay to ensure the pop animation completes before showing modal
                    Future.delayed(const Duration(milliseconds: 350), () {
                      print('🔵 IVR Call ended - triggering callbacks');
                      if (onCallEnded != null) onCallEnded();
                      if (onCallCompleted != null) {
                        // Use jobBriefId if available (for job posting calls)
                        // Use matchId if available (for job matching calls)
                        // Otherwise use callLogId
                        final idToPass = jobBriefId ?? matchId ?? callLogId;
                        print(
                          '🔵 Calling onCallCompleted with ID: $idToPass (jobBriefId: $jobBriefId, matchId: $matchId, callLogId: $callLogId)',
                        );
                        if (idToPass == null) {
                          print(
                            '⚠️ WARNING: No valid call ID found! Feedback update may fail.',
                          );
                        }
                        onCallCompleted(idToPass);
                      }
                    });
                  },
                ),
              ),
            ),
          );
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          print('❌ Call failed: $errorMsg');
          _showError(context, 'Failed to initiate IVR call: $errorMsg');
        }
      }
    } catch (e) {
      print('❌ Exception in initiateCall: $e');
      print('Stack trace: ${StackTrace.current}');
      if (context.mounted) {
        _showError(context, 'Error: $e');
      }
    }
  }

  /// Show error message
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
