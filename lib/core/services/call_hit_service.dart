import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'real_auth_service.dart';

/// Service to log call button hits
class CallHitService {
  static final CallHitService instance = CallHitService._internal();
  CallHitService._internal();

  /// Log a call hit whenever telecaller presses call button
  /// Only uses existing columns: user_id, call_time, assigned_to
  Future<Map<String, dynamic>> logCallHit({
    required String contactId,
    required String contactName,
    required String contactType,
    required String callType,
    required String sourceScreen,
    String? jobId,
    String? phoneNumber,
    String? assignedTo,
  }) async {
    try {
      print('🔵 CallHitService: Starting to log call hit');
      print('   Source: $sourceScreen');
      print('   Contact: $contactName ($contactId)');
      print('   Call Type: $callType');
      
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        print('❌ CallHitService: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('✅ CallHitService: User authenticated - Telecaller ID: ${user.id}');

      final url = Uri.parse('${ApiConfig.baseUrl}/call_hit_api.php');
      print('🌐 CallHitService: API URL: $url');
      
      // user_id = driver/transporter being called (contactId)
      // assigned_to = telecaller making the call (current user)
      // Use local time (IST) instead of UTC
      final now = DateTime.now();
      final formattedTime = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      final body = {
        'user_id': contactId, // Driver/Transporter TMID or ID
        'call_time': formattedTime, // Local IST time
        'assigned_to': user.id.toString(), // Telecaller ID
      };

      print('📤 CallHitService: Sending request with body: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('📥 CallHitService: Response status: ${response.statusCode}');
      print('📥 CallHitService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ CallHitService: Call hit logged successfully');
        return data;
      } else {
        print('❌ CallHitService: Failed with status ${response.statusCode}');
        throw Exception('Failed to log call hit: ${response.statusCode}');
      }
    } catch (e) {
      // Log error but don't throw - we don't want to block the call
      print('❌ CallHitService ERROR: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetch call hit statistics for a telecaller
  Future<Map<String, dynamic>> getCallHitStats({
    String? period, // 'today', 'week', 'month', 'all'
  }) async {
    try {
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = {
        'telecaller_id': user.id.toString(), // Use telecaller_id instead of user_id
        if (period != null) 'period': period,
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/call_hit_stats_api.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch call hit stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching call hit stats: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
