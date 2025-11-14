import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'real_auth_service.dart';

class ActivityTrackerService {
  static final ActivityTrackerService instance = ActivityTrackerService._();
  ActivityTrackerService._();

  Timer? _activityTimer;
  Timer? _heartbeatTimer;
  DateTime _lastActivity = DateTime.now();
  bool _isTracking = false;
  
  static const Duration _inactivityTimeout = Duration(minutes: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  void startTracking() {
    if (_isTracking) return;
    
    _isTracking = true;
    _lastActivity = DateTime.now();
    
    // Set status to active immediately
    _setActiveStatus();
    
    // Check for inactivity every 30 seconds
    _activityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkInactivity();
    });
    
    // Send heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
    
    debugPrint('✅ Activity tracking started');
  }

  void stopTracking() {
    _activityTimer?.cancel();
    _heartbeatTimer?.cancel();
    _isTracking = false;
    debugPrint('❌ Activity tracking stopped');
  }

  void recordActivity() {
    final wasInactive = isInactive;
    _lastActivity = DateTime.now();
    
    // If was inactive, set back to active
    if (wasInactive) {
      _setActiveStatus();
    }
  }

  Future<void> _checkInactivity() async {
    final inactiveDuration = DateTime.now().difference(_lastActivity);
    
    if (inactiveDuration >= _inactivityTimeout) {
      debugPrint('🔴 User inactive for ${inactiveDuration.inMinutes} minutes - auto logout');
      await _autoLogout();
    }
  }

  Future<void> _setActiveStatus() async {
    final user = RealAuthService.instance.currentUser;
    if (user == null) return;

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php?action=update_status',
      );
      
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'telecaller_id': int.parse(user.id),
          'status': 'online',
        }),
      ).timeout(const Duration(seconds: 5));
      debugPrint('✅ Status set to online');
    } catch (e) {
      debugPrint('Failed to set online status: $e');
    }
  }

  Future<void> _autoLogout() async {
    debugPrint('🔴 Auto-logout triggered due to inactivity');
    
    stopTracking();
    
    // Call logout but keep credentials saved
    await RealAuthService.instance.logout(keepCredentials: true);
    
    // The app will automatically navigate to login screen
    // because RealAuthService will clear the user session
  }

  Future<void> _sendHeartbeat() async {
    final user = RealAuthService.instance.currentUser;
    if (user == null) return;

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php?action=heartbeat',
      );
      
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'telecaller_id': int.parse(user.id),
          'last_activity': _lastActivity.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Heartbeat failed: $e');
    }
  }

  Duration get timeSinceLastActivity => DateTime.now().difference(_lastActivity);
  bool get isInactive => timeSinceLastActivity >= _inactivityTimeout;
}
