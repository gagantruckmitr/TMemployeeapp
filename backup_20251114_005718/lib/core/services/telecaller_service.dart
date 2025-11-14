import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_service.dart';
import '../../models/database_models.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'real_auth_service.dart';

class TelecallerService {
  static TelecallerService? _instance;
  TelecallerService._();

  static TelecallerService get instance {
    _instance ??= TelecallerService._();
    return _instance!;
  }

  final DatabaseService _db = DatabaseService.instance;

  // Get dashboard statistics for current telecaller
  Future<Map<String, int>> getDashboardStats() async {
    try {
      // Use RealAuthService to get current user
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        return _getDefaultStats();
      }
      
      final callerId = int.tryParse(currentUser.id) ?? 1;
      
      // Call the dashboard stats API
      final response = await http.get(
        Uri.parse('${ApiConfig.dashboardStatsApi}?caller_id=$callerId'),
      ).timeout(ApiConfig.shortTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final stats = data['data'];
          return {
            'total_calls': stats['total_calls'] ?? 0,
            'connected_calls': stats['connected_calls'] ?? 0,
            'pending_calls': stats['pending_calls'] ?? 0,
            'fresh_leads': stats['fresh_leads'] ?? 0,
            'callbacks_scheduled': stats['callbacks_scheduled'] ?? 0,
            'interested_count': stats['interested_count'] ?? 0,
          };
        }
      }
      
      return _getDefaultStats();
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return _getDefaultStats();
    }
  }
  
  Future<dynamic> _getCurrentUser() async {
    try {
      // Try to import RealAuthService
      final authService = RealAuthService.instance;
      return authService.currentUser;
    } catch (e) {
      // Fallback to AuthService
      return AuthService.instance.currentUser;
    }
  }
  
  Map<String, int> _getDefaultStats() {
    return {
      'total_calls': 0,
      'connected_calls': 0,
      'pending_calls': 0,
      'fresh_leads': 0,
      'callbacks_scheduled': 0,
      'interested_count': 0,
    };
  }

  // Get callback requests assigned to current telecaller
  Future<List<CallbackRequest>> getMyCallbackRequests({
    CallbackStatus? status,
    AppType? appType,
    int limit = 50,
    int offset = 0,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    final telecallerId = currentUser?.role == 'telecaller' ? currentUser?.id : null;
    
    return await _db.getCallbackRequests(
      assignedTo: telecallerId,
      status: status,
      appType: appType,
      limit: limit,
      offset: offset,
    );
  }

  // Get all callback requests (for admin/manager)
  Future<List<CallbackRequest>> getAllCallbackRequests({
    CallbackStatus? status,
    AppType? appType,
    int limit = 50,
    int offset = 0,
  }) async {
    return await _db.getCallbackRequests(
      status: status,
      appType: appType,
      limit: limit,
      offset: offset,
    );
  }

  // Update callback request status
  Future<bool> updateCallbackStatus(
    int requestId,
    CallbackStatus status, {
    String? notes,
  }) async {
    return await _db.updateCallbackStatus(requestId, status, notes: notes);
  }

  // Assign callback request to telecaller
  Future<bool> assignCallbackRequest(int requestId, int telecallerId) async {
    return await _db.assignCallbackRequest(requestId, telecallerId);
  }

  // Get drivers
  Future<List<User>> getDrivers({int limit = 50, int offset = 0}) async {
    return await _db.getDrivers(limit: limit, offset: offset);
  }

  // Get transporters
  Future<List<User>> getTransporters({int limit = 50, int offset = 0}) async {
    return await _db.getTransporters(limit: limit, offset: offset);
  }

  // Search users
  Future<List<User>> searchUsers(String query, {String? role}) async {
    return await _db.searchUsers(query, role: role);
  }

  // Add call log
  Future<bool> logCall({
    required int userId,
    required String userNumber,
    String? referenceId,
    String? apiResponse,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return false;

    return await _db.addCallLog(
      callerId: currentUser.id,
      userId: userId,
      callerNumber: currentUser.mobile,
      userNumber: userNumber,
      referenceId: referenceId,
      apiResponse: apiResponse,
    );
  }

  // Get call logs for current telecaller
  Future<List<CallLog>> getMyCallLogs({int limit = 50, int offset = 0}) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return [];

    return await _db.getCallLogs(
      callerId: currentUser.id,
      limit: limit,
      offset: offset,
    );
  }

  // Get all telecallers (for admin/manager)
  Future<List<Admin>> getTelecallers() async {
    return await _db.getTelecallers();
  }

  // Get callback requests by status for charts
  Future<Map<CallbackStatus, int>> getCallbacksByStatus() async {
    final currentUser = AuthService.instance.currentUser;
    final telecallerId = currentUser?.role == 'telecaller' ? currentUser?.id : null;
    
    final requests = await _db.getCallbackRequests(
      assignedTo: telecallerId,
      limit: 1000, // Get all for statistics
    );

    Map<CallbackStatus, int> statusCounts = {};
    for (var status in CallbackStatus.values) {
      statusCounts[status] = 0;
    }

    for (var request in requests) {
      statusCounts[request.status] = (statusCounts[request.status] ?? 0) + 1;
    }

    return statusCounts;
  }

  // Get recent activity (recent callback requests and calls)
  Future<List<ActivityItem>> getRecentActivity({int limit = 20}) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return [];

    List<ActivityItem> activities = [];

    // Get recent callback requests
    final callbacks = await getMyCallbackRequests(limit: limit ~/ 2);
    for (var callback in callbacks) {
      activities.add(ActivityItem(
        type: ActivityType.callback,
        title: 'Callback: ${callback.userName}',
        subtitle: callback.contactReason,
        timestamp: callback.requestDateTime,
        status: callback.status.value,
        phoneNumber: callback.mobileNumber,
      ));
    }

    // Get recent call logs
    final calls = await getMyCallLogs(limit: limit ~/ 2);
    for (var call in calls) {
      activities.add(ActivityItem(
        type: ActivityType.call,
        title: 'Call: ${call.userNumber}',
        subtitle: 'Call logged',
        timestamp: call.callTime,
        status: 'Completed',
        phoneNumber: call.userNumber,
      ));
    }

    // Sort by timestamp (most recent first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(limit).toList();
  }

  // Get performance analytics
  Future<Map<String, dynamic>> getPerformanceAnalytics({String period = 'week'}) async {
    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'error': 'No user logged in'};
      }
      
      final callerId = int.tryParse(currentUser.id) ?? 1;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.telecallerAnalyticsApi}?caller_id=$callerId&period=$period'),
      ).timeout(ApiConfig.shortTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      
      return {'success': false, 'error': 'Failed to fetch analytics'};
    } catch (e) {
      print('Error fetching performance analytics: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

enum ActivityType {
  callback,
  call,
}

class ActivityItem {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String status;
  final String? phoneNumber;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.status,
    this.phoneNumber,
  });
}