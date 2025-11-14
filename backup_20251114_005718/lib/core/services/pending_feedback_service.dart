import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage pending call feedback across app lifecycle
/// Ensures feedback modal appears even after app goes to background or logout/login
class PendingFeedbackService {
  static PendingFeedbackService? _instance;
  PendingFeedbackService._();

  static PendingFeedbackService get instance {
    _instance ??= PendingFeedbackService._();
    return _instance!;
  }

  static const String _pendingFeedbackKey = 'pending_call_feedback';

  /// Save pending feedback data
  Future<void> savePendingFeedback({
    required String referenceId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String driverCompany,
    required int callerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
        'reference_id': referenceId,
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_company': driverCompany,
        'caller_id': callerId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_pendingFeedbackKey, json.encode(data));
      print('✅ Pending feedback saved: $referenceId');
    } catch (e) {
      print('❌ Error saving pending feedback: $e');
    }
  }

  /// Get pending feedback data
  Future<Map<String, dynamic>?> getPendingFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_pendingFeedbackKey);
      
      if (dataString == null) {
        return null;
      }
      
      final data = json.decode(dataString) as Map<String, dynamic>;
      print('📋 Pending feedback found: ${data['reference_id']}');
      return data;
    } catch (e) {
      print('❌ Error getting pending feedback: $e');
      return null;
    }
  }

  /// Check if there's pending feedback
  Future<bool> hasPendingFeedback() async {
    final data = await getPendingFeedback();
    return data != null;
  }

  /// Clear pending feedback after submission
  Future<void> clearPendingFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingFeedbackKey);
      print('✅ Pending feedback cleared');
    } catch (e) {
      print('❌ Error clearing pending feedback: $e');
    }
  }

  /// Get time since feedback was pending (in minutes)
  Future<int?> getTimeSincePending() async {
    final data = await getPendingFeedback();
    if (data == null) return null;
    
    try {
      final timestamp = DateTime.parse(data['timestamp'] as String);
      final now = DateTime.now();
      return now.difference(timestamp).inMinutes;
    } catch (e) {
      return null;
    }
  }
}
