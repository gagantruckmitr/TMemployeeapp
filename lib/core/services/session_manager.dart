import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user session with inactivity timeout
/// Prevents automatic logout unless user is inactive for more than 20 minutes
class SessionManager {
  static const String _lastActivityKey = 'last_activity_timestamp';
  // DISABLING TIMEOUT: Set to 365 days to effectively disable auto-logout
  static const Duration _inactivityTimeout = Duration(days: 365);
  static const Duration _checkInterval = Duration(minutes: 1);
  
  static SessionManager? _instance;
  Timer? _activityCheckTimer;
  DateTime _lastActivityTime = DateTime.now();
  
  // Callback when session expires
  Function()? onSessionExpired;
  
  SessionManager._();
  
  static SessionManager get instance {
    _instance ??= SessionManager._();
    return _instance!;
  }
  
  /// Initialize session manager and start monitoring
  Future<void> initialize({Function()? onExpired}) async {
    onSessionExpired = onExpired;
    await _loadLastActivity();
    _startActivityMonitoring();
    debugPrint('✅ Session Manager initialized with NO timeout (365 days)');
  }
  
  /// Record user activity to reset the inactivity timer
  Future<void> recordActivity() async {
    _lastActivityTime = DateTime.now();
    await _saveLastActivity();
  }
  
  /// Check if session is still valid
  Future<bool> isSessionValid() async {
    // ALWAYS RETURN TRUE to prevent auto-logout
    return true;
    
    /* 
    // Old logic disabled
    await _loadLastActivity();
    final now = DateTime.now();
    final difference = now.difference(_lastActivityTime);
    
    final isValid = difference < _inactivityTimeout;
    
    if (!isValid) {
      debugPrint('❌ Session expired due to inactivity: ${difference.inMinutes} minutes');
    }
    
    return isValid;
    */
  }
  
  /// Get remaining time before session expires
  Duration getRemainingTime() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastActivityTime);
    final remaining = _inactivityTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Start monitoring user activity
  void _startActivityMonitoring() {
    _activityCheckTimer?.cancel();
    
    _activityCheckTimer = Timer.periodic(_checkInterval, (timer) async {
      // Always valid now
      // final isValid = await isSessionValid();
      
      // if (!isValid) {
      //   debugPrint('⏰ Session timeout detected - logging out user');
      //   timer.cancel();
      //   onSessionExpired?.call();
      // } else {
      //   final remaining = getRemainingTime();
      //   debugPrint('✅ Session active - ${remaining.inMinutes} minutes remaining');
      // }
    });
  }
  
  /// Save last activity timestamp
  Future<void> _saveLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActivityKey, _lastActivityTime.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to save activity: $e');
    }
  }
  
  /// Load last activity timestamp
  Future<void> _loadLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastActivityKey);
      
      if (timestamp != null) {
        _lastActivityTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        _lastActivityTime = DateTime.now();
        await _saveLastActivity();
      }
    } catch (e) {
      debugPrint('Failed to load activity: $e');
      _lastActivityTime = DateTime.now();
    }
  }
  
  /// Reset session (call on login)
  Future<void> resetSession() async {
    _lastActivityTime = DateTime.now();
    await _saveLastActivity();
    _startActivityMonitoring();
    debugPrint('✅ Session reset - timer started');
  }
  
  /// Clear session (call on logout)
  Future<void> clearSession() async {
    _activityCheckTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
    debugPrint('✅ Session cleared');
  }
  
  /// Dispose resources
  void dispose() {
    _activityCheckTimer?.cancel();
  }
}
