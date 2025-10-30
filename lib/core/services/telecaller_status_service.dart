import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TelecallerStatusService {
  static TelecallerStatusService? _instance;
  TelecallerStatusService._();

  static TelecallerStatusService get instance {
    _instance ??= TelecallerStatusService._();
    return _instance!;
  }

  Timer? _heartbeatTimer;
  String? _currentTelecallerId;
  String _currentStatus = 'offline';
  DateTime? _breakStartTime;

  // Initialize status tracking for telecaller
  Future<void> initialize(String telecallerId) async {
    _currentTelecallerId = telecallerId;
    await recordLogin(telecallerId);
    _startHeartbeat();
  }

  // Record login
  Future<bool> recordLogin(String telecallerId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'login'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentStatus = 'online';
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Failed to record login: $e');
      return false;
    }
  }

  // Record logout
  Future<bool> recordLogout(String telecallerId) async {
    try {
      _stopHeartbeat();

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'logout'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentStatus = 'offline';
          _currentTelecallerId = null;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Failed to record logout: $e');
      return false;
    }
  }

  // Update status (online, offline, on_call, break, busy)
  Future<bool> updateStatus(
    String telecallerId,
    String status, {
    String? currentCallId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'update_status'});

      final body = {'telecaller_id': int.parse(telecallerId), 'status': status};

      if (currentCallId != null) {
        body['current_call_id'] = int.parse(currentCallId);
      }

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentStatus = status;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Failed to update status: $e');
      return false;
    }
  }

  // Start break
  Future<bool> startBreak(String telecallerId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'start_break'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentStatus = 'break';
          _breakStartTime = DateTime.now();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Failed to start break: $e');
      return false;
    }
  }

  // End break
  Future<bool> endBreak(String telecallerId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'end_break'});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentStatus = 'online';
          _breakStartTime = null;
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Failed to end break: $e');
      return false;
    }
  }

  // Get telecaller status
  Future<Map<String, dynamic>?> getStatus(String telecallerId) async {
    try {
      final uri =
          Uri.parse(
            '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
          ).replace(
            queryParameters: {
              'action': 'get_status',
              'telecaller_id': telecallerId,
            },
          );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Failed to get status: $e');
      return null;
    }
  }

  // Get all telecaller statuses (for manager)
  Future<List<Map<String, dynamic>>> getAllStatuses() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'get_all_status'});

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Failed to get all statuses: $e');
      return [];
    }
  }

  // Start heartbeat (updates every 30 seconds)
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentTelecallerId != null) {
        _sendHeartbeat(_currentTelecallerId!);
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send heartbeat
  Future<void> _sendHeartbeat(String telecallerId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_status_tracking_api.php',
      ).replace(queryParameters: {'action': 'heartbeat'});

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Heartbeat failed: $e');
    }
  }

  // Get current status
  String get currentStatus => _currentStatus;

  // Get break duration
  Duration? get currentBreakDuration {
    if (_breakStartTime != null) {
      return DateTime.now().difference(_breakStartTime!);
    }
    return null;
  }

  // Dispose
  void dispose() {
    _stopHeartbeat();
  }
}
