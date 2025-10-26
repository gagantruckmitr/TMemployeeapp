import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/manager_models.dart';
import '../config/api_config.dart';

class ManagerService {
  static String get baseUrl => ApiConfig.managerDashboardApi;

  // Get manager details from admins table
  Future<Map<String, dynamic>> getManagerDetails(int managerId) async {
    try {
      final url = '$baseUrl?action=manager_details&manager_id=$managerId';
      print('🔵 Fetching manager details from: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 30));

      print('🔵 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Successfully fetched manager details');
          return data;
        }
      }
      throw Exception('Failed to load manager details - Status: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching manager details: $e');
      throw Exception('Error fetching manager details: $e');
    }
  }

  // Get manager dashboard overview
  Future<Map<String, dynamic>> getOverview(int managerId) async {
    try {
      final url = '$baseUrl?action=overview&manager_id=$managerId';
      print('🔵 Fetching manager overview from: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 30));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Successfully parsed manager overview data');
          return {
            'overview': ManagerOverview.fromJson(data['overview']),
            'today': TodayStats.fromJson(data['today']),
            'weekTrend': (data['weekTrend'] as List).map((e) => WeekTrend.fromJson(e)).toList(),
            'topPerformers': (data['topPerformers'] as List).map((e) => TopPerformer.fromJson(e)).toList(),
          };
        }
      }
      throw Exception('Failed to load overview - Status: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching overview: $e');
      throw Exception('Error fetching overview: $e');
    }
  }

  // Get list of all telecallers
  Future<List<TelecallerInfo>> getTelecallers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=telecallers'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['telecallers'] as List)
              .map((e) => TelecallerInfo.fromJson(e))
              .toList();
        }
      }
      throw Exception('Failed to load telecallers');
    } catch (e) {
      throw Exception('Error fetching telecallers: $e');
    }
  }

  // Get detailed information about a telecaller
  Future<TelecallerDetails> getTelecallerDetails(int telecallerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=telecaller_details&telecaller_id=$telecallerId'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TelecallerDetails(
            telecaller: TelecallerInfo.fromJson(data['telecaller']),
            todayStats: TodayStats.fromJson(data['todayStats']),
            recentCalls: (data['recentCalls'] as List)
                .map((e) => CallLogEntry.fromJson(e))
                .toList(),
            assignments: (data['assignments'] as List)
                .map((e) => DriverAssignment.fromJson(e))
                .toList(),
          );
        }
      }
      throw Exception('Failed to load telecaller details');
    } catch (e) {
      throw Exception('Error fetching telecaller details: $e');
    }
  }

  // Get telecaller performance over time
  Future<Map<String, dynamic>> getTelecallerPerformance(
    int telecallerId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30)).toString().split(' ')[0];
      final end = endDate ?? DateTime.now().toString().split(' ')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=telecaller_performance&telecaller_id=$telecallerId&start_date=$start&end_date=$end'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'performance': (data['performance'] as List)
                .map((e) => PerformanceData.fromJson(e))
                .toList(),
            'summary': data['summary'],
            'period': data['period'],
          };
        }
      }
      throw Exception('Failed to load performance data');
    } catch (e) {
      throw Exception('Error fetching performance: $e');
    }
  }

  // Get call logs with filters
  Future<Map<String, dynamic>> getCallLogs({
    int? telecallerId,
    int? driverId,
    String? status,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'action': 'call_logs',
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (telecallerId != null) params['telecaller_id'] = telecallerId.toString();
      if (driverId != null) params['driver_id'] = driverId.toString();
      if (status != null) params['status'] = status;
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'callLogs': (data['callLogs'] as List)
                .map((e) => CallLogEntry.fromJson(e))
                .toList(),
            'total': data['total'],
            'limit': data['limit'],
            'offset': data['offset'],
          };
        }
      }
      throw Exception('Failed to load call logs');
    } catch (e) {
      throw Exception('Error fetching call logs: $e');
    }
  }

  // Get real-time status of all telecallers
  Future<Map<String, dynamic>> getRealTimeStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=real_time_status'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'statuses': (data['statuses'] as List)
                .map((e) => RealTimeStatus.fromJson(e))
                .toList(),
            'counts': data['counts'],
            'timestamp': data['timestamp'],
          };
        }
      }
      throw Exception('Failed to load real-time status');
    } catch (e) {
      throw Exception('Error fetching real-time status: $e');
    }
  }

  // Assign driver to telecaller
  Future<bool> assignDriver({
    required int telecallerId,
    required int driverId,
    required int managerId,
    String priority = 'medium',
    String notes = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=assign_driver'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'telecaller_id': telecallerId,
          'driver_id': driverId,
          'manager_id': managerId,
          'priority': priority,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error assigning driver: $e');
    }
  }

  // Reassign driver to different telecaller
  Future<bool> reassignDriver({
    required int assignmentId,
    required int newTelecallerId,
    required int managerId,
    String reason = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=reassign_driver'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assignment_id': assignmentId,
          'new_telecaller_id': newTelecallerId,
          'manager_id': managerId,
          'reason': reason,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error reassigning driver: $e');
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics({
    String period = 'week',
    int? telecallerId,
  }) async {
    try {
      final params = <String, String>{
        'action': 'analytics',
        'period': period,
      };
      
      if (telecallerId != null) params['telecaller_id'] = telecallerId.toString();
      
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      throw Exception('Failed to load analytics');
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    String period = 'today',
    String metric = 'conversions',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=leaderboard&period=$period&metric=$metric'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['leaderboard'] as List)
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
        }
      }
      throw Exception('Failed to load leaderboard');
    } catch (e) {
      throw Exception('Error fetching leaderboard: $e');
    }
  }

  // Update telecaller status
  Future<bool> updateTelecallerStatus({
    required int telecallerId,
    required String status,
    int? currentCallId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_telecaller_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'telecaller_id': telecallerId,
          'status': status,
          'current_call_id': currentCallId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  // Get telecaller call details - which driver they called
  Future<Map<String, dynamic>> getTelecallerCallDetails({
    required int telecallerId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().toString().split(' ')[0];
      final end = endDate ?? DateTime.now().toString().split(' ')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=telecaller_call_details&telecaller_id=$telecallerId&start_date=$start&end_date=$end'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      throw Exception('Failed to load call details');
    } catch (e) {
      throw Exception('Error fetching call details: $e');
    }
  }

  // Get driver assignments - which leads assigned to which telecaller
  Future<Map<String, dynamic>> getDriverAssignments({int? telecallerId}) async {
    try {
      final url = telecallerId != null
          ? '$baseUrl?action=driver_assignments&telecaller_id=$telecallerId'
          : '$baseUrl?action=driver_assignments';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      throw Exception('Failed to load assignments');
    } catch (e) {
      throw Exception('Error fetching assignments: $e');
    }
  }

  // Get call timeline - real-time activity feed
  Future<List<dynamic>> getCallTimeline({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=call_timeline&limit=$limit'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['timeline'] as List;
        }
      }
      throw Exception('Failed to load timeline');
    } catch (e) {
      throw Exception('Error fetching timeline: $e');
    }
  }
}
