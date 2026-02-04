import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../../core/services/manual_call_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../models/smart_calling_models.dart';
import '../../../app/theme/app_theme.dart';
import 'call_feedback_modal.dart';

/// Helper class for manual call operations
/// Handles initiation and feedback collection for manual calls
class ManualCallHelper {
  /// Initiate a manual call and show feedback modal
  /// 
  /// Parameters:
  /// - context: BuildContext for showing dialogs
  /// - contact: DriverContact or TransporterContact
  /// - process: Process type based on screen ('Driver Onboarding', 'Transporter Onboarding', etc.)
  /// - onFeedbackSubmitted: Callback when feedback is submitted
  /// - showRecordingUpload: Whether to show recording upload (default: true for welcome calling)
  static Future<void> initiateManualCall({
    required BuildContext context,
    required dynamic contact, // DriverContact or TransporterContact
    required String process,
    required Future<void> Function(CallFeedback) onFeedbackSubmitted,
    bool showRecordingUpload = true,
  }) async {
    try {
      // Get current user
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Extract contact details
      final String uniqueId = contact.tmid;
      final String userId = contact.id;
      final String assignedTo = currentUser.id.toString();
      final String phoneNumber = contact.phoneNumber;
      final String contactName = contact.name;

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Initiating call to $contactName...'),
              ],
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Step 1: Initiate manual call via API
      final initiateResult = await ManualCallService.initiateCall(
        uniqueId: uniqueId,
        userId: userId,
        assignedTo: assignedTo,
        process: process,
      );

      if (!context.mounted) return;

      if (initiateResult['success'] != true) {
        final errorMsg = initiateResult['error'] ?? 'Failed to initiate call';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Extract call_history_id
      final callHistoryId = initiateResult['call_history_id'] as int?;
      if (callHistoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to get call history ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('✅ Manual call initiated. Call History ID: $callHistoryId');

      // Step 2: Make the actual phone call
      final cleanMobile = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Calling $contactName...'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      try {
        await FlutterPhoneDirectCaller.callNumber(cleanMobile);
      } catch (callError) {
        print('⚠️ Phone dialer error: $callError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open dialer: $callError'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Step 3: Wait a moment then show feedback modal
      await Future.delayed(const Duration(milliseconds: 500));

      if (!context.mounted) return;

      // Convert contact to DriverContact if needed
      final DriverContact driverContact = contact is DriverContact
          ? contact
          : DriverContact(
              id: contact.id,
              tmid: contact.tmid,
              name: contact.name,
              company: contact.company ?? '',
              phoneNumber: contact.phoneNumber,
              state: contact.state ?? '0',
              subscriptionStatus: contact.subscriptionStatus ?? SubscriptionStatus.inactive,
              status: contact.status ?? CallStatus.pending,
            );

      // Show feedback modal
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => CallFeedbackModal(
          contact: driverContact,
          referenceId: callHistoryId.toString(),
          allowDismiss: false,
          requireRecording: false,
          showRecordingUpload: showRecordingUpload,
          onFeedbackSubmitted: (feedback) async {
            // Update manual call with feedback
            await _updateManualCallFeedback(
              context: context,
              callHistoryId: callHistoryId,
              feedback: feedback,
              contactName: contactName,
            );

            // Call the original callback
            await onFeedbackSubmitted(feedback);

            // Close the modal
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    } catch (e) {
      print('❌ Error in manual call: $e');
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

  /// Update manual call with feedback
  static Future<void> _updateManualCallFeedback({
    required BuildContext context,
    required int callHistoryId,
    required CallFeedback feedback,
    required String contactName,
  }) async {
    try {
      // Map CallStatus to API status string
      String callStatus;
      switch (feedback.status) {
        case CallStatus.connected:
          callStatus = 'connected';
          break;
        case CallStatus.callBack:
          callStatus = 'not_connected';
          break;
        case CallStatus.callBackLater:
          callStatus = 'call_back';
          break;
        default:
          callStatus = 'not_connected';
      }

      // Get feedback string
      String callFeedback = '';
      if (feedback.connectedFeedback != null) {
        callFeedback = feedback.connectedFeedback!.displayName;
      } else if (feedback.callBackReason != null) {
        callFeedback = feedback.callBackReason!.displayName;
      } else if (feedback.callBackTime != null) {
        callFeedback = feedback.callBackTime!.displayName;
      } else {
        callFeedback = 'No feedback';
      }

      print('🔄 Updating manual call feedback:');
      print('   Call History ID: $callHistoryId');
      print('   Status: $callStatus');
      print('   Feedback: $callFeedback');
      print('   Remarks: ${feedback.remarks ?? "none"}');
      print('   Recording: ${feedback.recordingFile != null ? "attached" : "none"}');

      final updateResult = await ManualCallService.updateCall(
        callHistoryId: callHistoryId,
        callStatus: callStatus,
        callFeedback: callFeedback,
        callRemarks: feedback.remarks,
        callRecording: feedback.recordingFile,
      );

      if (context.mounted) {
        if (updateResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Feedback saved for $contactName'),
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
      print('❌ Error updating manual call feedback: $e');
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
