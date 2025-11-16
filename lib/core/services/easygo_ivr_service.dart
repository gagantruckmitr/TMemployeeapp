import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// EasyGo IVR Service for Click2Call Integration
/// Uses backend API for token management and call initiation
class EasyGoIVRService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/easygo_ivr_api.php';
  static const Duration _timeout = Duration(seconds: 30);

  /// Initiate IVR call using EasyGo API (via backend)
  /// 
  /// Parameters:
  /// - [exten]: Telecaller phone number (without country code)
  /// - [number]: Client/Driver/Transporter phone number (without country code)
  /// - [callerId]: Telecaller user ID
  /// - [contactId]: Contact TMID
  /// - [contactType]: Type of contact ('driver' or 'transporter')
  /// - [driverName]: Name of the driver/contact
  /// - [duration]: Optional call duration limit (empty string for unlimited)
  /// 
  /// Returns:
  /// - Map with 'success' boolean and 'data' or 'error' fields
  static Future<Map<String, dynamic>> initiateCall({
    required String exten,
    required String number,
    required String callerId,
    required String contactId,
    String contactType = 'driver',
    String? driverName,
    String duration = '',
    String? callSource,
  }) async {
    try {
      // Clean phone numbers (remove any non-digit characters)
      final cleanExten = exten.replaceAll(RegExp(r'[^\d]'), '');
      final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');

      // Validate phone numbers
      if (cleanExten.isEmpty || cleanExten.length < 10) {
        return {
          'success': false,
          'error': 'Invalid telecaller phone number',
        };
      }

      if (cleanNumber.isEmpty || cleanNumber.length < 10) {
        return {
          'success': false,
          'error': 'Invalid client phone number',
        };
      }

      final requestBody = {
        'exten': cleanExten,
        'number': cleanNumber,
        'caller_id': callerId,
        'contact_id': contactId,
        'contact_type': contactType,
        'driver_name': driverName,
        'duration': duration,
        if (callSource != null) 'call_source': callSource,
      };

      print('🔵 EasyGo IVR API Request (via backend):');
      print('   URL: $_baseUrl?action=initiate_call');
      print('   Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl?action=initiate_call'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(_timeout);

      print('🔵 EasyGo IVR API Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ EasyGo IVR call initiated successfully');
          print('   Call Log ID: ${data['call_log_id']}');
          return {
            'success': true,
            'data': data['data'],
            'reference_id': data['reference_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'call_log_id': data['call_log_id'],
          };
        } else {
          print('❌ EasyGo IVR call failed: ${data['error']}');
          return {
            'success': false,
            'error': data['error'] ?? 'Unknown error',
          };
        }
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        print('❌ HTTP Error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      print('❌ Exception in EasyGo IVR initiateCall: $e');
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  /// Get call logs from backend
  static Future<List<dynamic>> getCallLogs({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_call_logs&limit=$limit'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('❌ Failed to get call logs: $e');
      return [];
    }
  }

  /// Generate new token (admin function)
  static Future<String?> generateToken() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=generate_token'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['token'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Failed to generate token: $e');
      return null;
    }
  }
}
