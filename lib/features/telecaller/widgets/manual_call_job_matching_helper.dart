import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../core/services/manual_call_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../app/theme/app_theme.dart';

/// Helper class for manual call operations in job matching
/// Handles initiation and feedback collection for job matching manual calls
class ManualCallJobMatchingHelper {
  /// Initiate a manual call for job matching
  ///
  /// Parameters:
  /// - context: BuildContext for showing dialogs
  /// - uniqueIdTransporter: Transporter TMID
  /// - uniqueIdDriver: Driver TMID
  /// - userIdTransporter: Transporter user ID
  /// - userIdDriver: Driver user ID
  /// - jobId: Job ID
  /// - driverName: Driver name
  /// - transporterName: Transporter name
  /// - phoneNumber: Phone number to call
  /// - onCallInitiated: Callback when call is initiated with the ID
  static Future<void> initiateJobMatchingCall({
    required BuildContext context,
    required String uniqueIdTransporter,
    required String uniqueIdDriver,
    required String userIdTransporter,
    required String userIdDriver,
    required String jobId,
    required String driverName,
    required String transporterName,
    required String phoneNumber,
    required Function(int id) onCallInitiated,
  }) async {
    try {
      // Get current user
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final String assignedTo = currentUser.id.toString();
      final cleanMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // STEP 1: Open phone dialer IMMEDIATELY (don't wait for API)
      print('📱 Opening phone dialer immediately for: $cleanMobile');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Calling $driverName...'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Launch dialer without waiting - fire and forget
      FlutterPhoneDirectCaller.callNumber(cleanMobile)
          .then((_) {
            print('✅ Phone dialer launched successfully');
          })
          .onError((error, stackTrace) {
            print('⚠️ Phone dialer error: $error');
          });

      // STEP 2: Start API call (runs in parallel with showing modal)
      print('🔄 Initiating API call...');
      final apiFuture = ManualCallService.initiateJobMatchingCall(
        uniqueIdTransporter: uniqueIdTransporter,
        uniqueIdDriver: uniqueIdDriver,
        userIdTransporter: userIdTransporter,
        userIdDriver: userIdDriver,
        assignedTo: assignedTo,
        jobId: jobId,
        driverName: driverName,
        transporterName: transporterName,
      );

      // STEP 3: Small delay to let dialer open first, then show modal
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;

      // Wait for API with short timeout to get real ID
      int callId = 0;
      try {
        final initiateResult = await apiFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⏰ API timeout, will use fallback');
            return {'success': false, 'error': 'timeout'};
          },
        );

        print('🔵 API Response: ${initiateResult['success']}');

        if (initiateResult['success'] == true) {
          final dynamic rawId =
              initiateResult['id'] ?? initiateResult['match_id'];
          if (rawId is int) {
            callId = rawId;
          } else if (rawId != null) {
            callId = int.tryParse(rawId.toString()) ?? 0;
          }
          print('✅ Got call ID: $callId');
        } else {
          print('⚠️ API failed: ${initiateResult['error']}');
        }
      } catch (e) {
        print('❌ API error: $e');
      }

      // STEP 4: Show feedback modal with the ID
      print('📋 Opening feedback modal with ID: $callId');
      if (!context.mounted) return;
      onCallInitiated(callId);
    } catch (e) {
      print('❌ Error in manual job matching call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Update manual call for job matching with feedback
  static Future<void> updateJobMatchingCall({
    required BuildContext context,
    required int id,
    required String callStatus,
    required String callFeedback,
    String? callRemarks,
    String? matchStatus,
    required String driverName,
    required String transporterName,
  }) async {
    try {
      // Normalize call status for API (modal uses 'call_back', API expects 'callback_later')
      String normalizedCallStatus = callStatus;
      if (callStatus == 'call_back') {
        normalizedCallStatus = 'callback_later';
      }

      print('🔄 Updating manual job matching call feedback:');
      print('   ID: $id');
      print('   Status: $callStatus -> $normalizedCallStatus');
      print('   Feedback: $callFeedback');
      print('   Remarks: ${callRemarks ?? "none"}');
      print('   Match Status: ${matchStatus ?? "none"}');

      final updateResult = await ManualCallService.updateJobMatchingCall(
        id: id,
        callStatus: normalizedCallStatus,
        callFeedback: callFeedback,
        callRemarks: callRemarks,
        matchStatus: matchStatus,
        driverName: driverName,
        transporterName: transporterName,
      );

      if (context.mounted) {
        if (updateResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Feedback saved for job matching'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final errorMsg = updateResult['error'] ?? 'Failed to save feedback';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $errorMsg'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error updating manual job matching call feedback: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feedback: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
