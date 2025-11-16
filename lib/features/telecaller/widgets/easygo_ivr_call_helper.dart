import 'package:flutter/material.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/phase2_auth_service.dart';
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
  /// - [onCallEnded]: Callback when call ends (for showing feedback modal)
  static Future<void> initiateCall({
    required BuildContext context,
    required String clientName,
    required String clientPhone,
    required String clientId,
    String contactType = 'driver',
    String? callSource,
    required VoidCallback onCallEnded,
  }) async {
    try {
      print('🔵 EasyGoIVRCallHelper.initiateCall() started');
      print('   Client: $clientName');
      print('   Phone: $clientPhone');
      print('   ID: $clientId');
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
      final cleanTelecallerPhone = telecallerPhone.replaceAll(RegExp(r'[^\d]'), '');
      final cleanClientPhone = clientPhone.replaceAll(RegExp(r'[^\d]'), '');

      print('📱 Cleaned phones: Telecaller=$cleanTelecallerPhone, Client=$cleanClientPhone');

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

      print('🔵 Calling SmartCallingService.initiateEasyGoIVR()...');
      
      // Initiate EasyGo IVR call
      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: cleanTelecallerPhone,
        clientPhone: cleanClientPhone,
        callerId: callerId.toString(),
        contactId: clientId,
        contactType: contactType,
        driverName: clientName,
        duration: '', // No duration limit
        callSource: callSource,
      );
      
      print('🔵 EasyGo IVR Result: $result');

      if (context.mounted) {
        if (result['success'] == true) {
          final referenceId = result['reference_id'] ?? 
                             result['data']?['call_id'] ?? 
                             DateTime.now().millisecondsSinceEpoch.toString();

          print('✅ Call initiated successfully! Reference: $referenceId');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ EasyGo IVR call initiated! Both phones will ring.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Show IVR call waiting overlay
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: clientName,
                  referenceId: referenceId,
                  onCallEnded: () {
                    Navigator.of(context).pop();
                    onCallEnded();
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
