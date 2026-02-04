import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../core/services/manual_call_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../app/theme/app_theme.dart';

/// Helper class for manual call operations in job matching
/// Handles initiation and feedback collection for job matching manual calls
class ManualCallJobMatchingHelper {
  /// Initiate a manual call for job matching
  ///
  /// Flow:
  /// 1. Call the API FIRST to register the call
  /// 2. If API succeeds with match_id -> launch dialer and show feedback modal
  /// 3. If API returns pending_match_id -> show feedback modal for pending call (no dialer)
  /// 4. If API fails -> show error message (no dialer)
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

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Step 1: Checking API... (Run 5)'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // STEP 1: Call API FIRST to register the call
      print('🔄 Initiating API call FIRST...');
      final initiateResult = await ManualCallService.initiateJobMatchingCall(
        uniqueIdTransporter: uniqueIdTransporter,
        uniqueIdDriver: uniqueIdDriver,
        userIdTransporter: userIdTransporter,
        userIdDriver: userIdDriver,
        assignedTo: assignedTo,
        jobId: jobId,
        driverName: driverName,
        transporterName: transporterName,
      );

      print('🔵 API Response: ${initiateResult['success']}');
      print('🔵 Full API Response: $initiateResult');

      if (!context.mounted) return;

      // STEP 2: Handle API response
      if (initiateResult['success'] == true) {
        // SUCCESS: Extract match_id and launch dialer
        final dynamic rawId =
            initiateResult['id'] ??
            initiateResult['match_id'] ??
            initiateResult['data']?['match_id'] ??
            initiateResult['data']?['id'];

        print('🔵 rawId extracted: $rawId (type: ${rawId?.runtimeType})');

        int callId = 0;
        if (rawId is int) {
          callId = rawId;
        } else if (rawId != null) {
          callId = int.tryParse(rawId.toString()) ?? 0;
        }

        if (callId == 0) {
          throw Exception('Failed to get call ID from API response');
        }

        print('✅ Got call ID: $callId');

        // Launch dialer only on success
        print('📱 Opening phone dialer for: $cleanMobile');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling $driverName...'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        FlutterPhoneDirectCaller.callNumber(cleanMobile)
            .then((_) => print('✅ Phone dialer launched successfully'))
            .onError(
              (error, stackTrace) => print('⚠️ Phone dialer error: $error'),
            );

        // Small delay to let dialer open
        await Future.delayed(const Duration(milliseconds: 500));

        // Show feedback modal with the call ID
        print('📋 Opening feedback modal with ID: $callId');
        if (context.mounted) {
          onCallInitiated(callId);
        }
      } else {
        // FAILED: Check if there's a pending call
        final errorStr = initiateResult['error']?.toString() ?? '';
        String displayError = 'Failed to initiate call';
        int? pendingMatchId;

        // Clean up error message for display and extract pending_match_id
        try {
          // Remove HTTP prefix if present to parse JSON
          final jsonString = errorStr.replaceAll(RegExp(r'HTTP \d+: '), '');

          if (jsonString.startsWith('{')) {
            final errorData = json.decode(jsonString);
            displayError = errorData['message'] ?? displayError;

            // Check for pending match ID in nested data
            if (errorData['data'] != null &&
                errorData['data']['pending_match_id'] != null) {
              pendingMatchId = int.tryParse(
                errorData['data']['pending_match_id'].toString(),
              );
              print('🔵 Found pending_match_id: $pendingMatchId');
            }
          } else {
            displayError = errorStr;
          }
        } catch (e) {
          // Fallback if parsing fails
          if (errorStr.contains('Please submit feedback')) {
            displayError = 'Please submit feedback for previous call first';
          } else {
            displayError = errorStr;
          }
        }

        print('❌ API Error: $displayError');

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).hideCurrentSnackBar(); // Hide loading snackbar
        }

        Fluttertoast.showToast(
          msg: "⚠️ $displayError",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
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
    File? callRecording,
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
      print('   Recording: ${callRecording?.path ?? "none"}');

      final updateResult = await ManualCallService.updateJobMatchingCall(
        id: id,
        callStatus: normalizedCallStatus,
        callFeedback: callFeedback,
        callRemarks: callRemarks,
        matchStatus: matchStatus,
        driverName: driverName,
        transporterName: transporterName,
        callRecording: callRecording,
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
