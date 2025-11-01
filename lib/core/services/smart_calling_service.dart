import '../../models/smart_calling_models.dart';
import 'api_service.dart';

class SmartCallingService {
  static SmartCallingService? _instance;
  SmartCallingService._();

  static SmartCallingService get instance {
    _instance ??= SmartCallingService._();
    return _instance!;
  }

  // Cache for drivers to avoid frequent API calls
  List<DriverContact>? _cachedDrivers;
  DateTime? _lastFetchTime;
  static const Duration cacheTimeout = Duration(minutes: 5);

  // Get fresh leads (uncalled drivers) - REAL DATA ONLY
  Future<List<DriverContact>> getDrivers({
    bool forceRefresh = false,
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
  }) async {
    // Check if we need to refresh cache
    final now = DateTime.now();
    final shouldRefresh =
        forceRefresh ||
        _cachedDrivers == null ||
        _lastFetchTime == null ||
        now.difference(_lastFetchTime!) > cacheTimeout;

    if (shouldRefresh) {
      // Get fresh leads (uncalled drivers only)
      _cachedDrivers = await ApiService.getFreshLeads(limit: limit);
      _lastFetchTime = now;
    }

    // Apply local filters if needed
    var filteredDrivers = _cachedDrivers ?? [];

    if (search != null && search.isNotEmpty) {
      filteredDrivers = filteredDrivers.where((driver) {
        return driver.name.toLowerCase().contains(search.toLowerCase()) ||
            driver.company.toLowerCase().contains(search.toLowerCase()) ||
            driver.phoneNumber.contains(search);
      }).toList();
    }

    return filteredDrivers;
  }

  // Get drivers by category
  Future<List<DriverContact>> getDriversByCategory(
    NavigationSection category,
  ) async {
    // For categories other than home (fresh leads), fetch by status from API
    switch (category) {
      case NavigationSection.home:
        // Fresh leads - uncalled drivers
        return await getDrivers();

      case NavigationSection.pendingCalls:
        // Pending calls - same as fresh leads (uncalled drivers)
        return await getDrivers();

      case NavigationSection.connectedCalls:
        // Get drivers with connected status
        return await getDriversByStatus(CallStatus.connected);

      case NavigationSection.callBacks:
        // Get drivers with callback status
        return await getDriversByStatus(CallStatus.callBack);

      case NavigationSection.callBackLater:
        // Get drivers with callback_later status
        return await getDriversByStatus(CallStatus.callBackLater);

      case NavigationSection.interested:
        // Get connected drivers and filter by interested feedback
        final connectedDrivers = await getDriversByStatus(CallStatus.connected);
        return connectedDrivers.where((contact) {
          return ContactCategorizer.isInterestedFeedback(contact.lastFeedback);
        }).toList();

      case NavigationSection.callHistory:
        // Call history doesn't return drivers
        return [];

      case NavigationSection.profile:
        return [];
    }
  }

  // Get contact counts by category
  Future<Map<NavigationSection, int>> getContactCounts() async {
    final allDrivers = await getDrivers();
    final counts = <NavigationSection, int>{};

    for (final section in NavigationSection.values) {
      if (section == NavigationSection.profile) {
        counts[section] = 0; // Profile has no count
      } else {
        counts[section] = allDrivers.where((contact) {
          return ContactCategorizer.getCategoryForContact(contact) == section;
        }).length;
      }
    }

    return counts;
  }

  // Get single driver - REAL DATA ONLY
  Future<DriverContact> getDriver(String driverId) async {
    // Try to get from API first
    try {
      return await ApiService.getDriver(driverId);
    } catch (e) {
      // Fallback to cached data if available
      final cachedDriver = _cachedDrivers?.firstWhere(
        (driver) => driver.id == driverId,
        orElse: () => throw Exception('Driver not found'),
      );
      if (cachedDriver != null) {
        return cachedDriver;
      }
      throw Exception('Driver not found: $driverId');
    }
  }

  // Update call status
  Future<bool> updateCallStatus({
    required String driverId,
    required CallStatus status,
    String? feedback,
    String? remarks,
  }) async {
    try {
      final success = await ApiService.updateCallStatus(
        driverId: driverId,
        status: status,
        feedback: feedback,
        remarks: remarks,
      );

      if (success) {
        // Update cached data if available
        if (_cachedDrivers != null) {
          final index = _cachedDrivers!.indexWhere((d) => d.id == driverId);
          if (index != -1) {
            _cachedDrivers![index] = _cachedDrivers![index].copyWith(
              status: status,
              lastFeedback: feedback,
              lastCallTime: DateTime.now(),
              remarks: remarks,
            );
          }
        }
      }

      return success;
    } catch (e) {
      print('Failed to update call status: $e');
      return false;
    }
  }

  // Log a call
  Future<bool> logCall({
    required String driverId,
    String? referenceId,
    String? apiResponse,
  }) async {
    try {
      return await ApiService.logCall(
        driverId: driverId,
        referenceId: referenceId,
        apiResponse: apiResponse,
      );
    } catch (e) {
      print('Failed to log call: $e');
      return false;
    }
  }

  // Initiate IVR call through MyOperator
  Future<Map<String, dynamic>> initiateIVRCall({
    required String driverMobile,
    required int callerId,
    required String driverId,
  }) async {
    try {
      return await ApiService.initiateIVRCall(
        driverMobile: driverMobile,
        callerId: callerId,
        driverId: driverId,
      );
    } catch (e) {
      print('Failed to initiate IVR call: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Initiate manual call (direct phone dialer)
  Future<Map<String, dynamic>> initiateManualCall({
    required String driverMobile,
    required int callerId,
    required String driverId,
  }) async {
    try {
      return await ApiService.initiateManualCall(
        driverMobile: driverMobile,
        callerId: callerId,
        driverId: driverId,
      );
    } catch (e) {
      print('Failed to initiate manual call: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get call status by reference ID
  Future<Map<String, dynamic>> getCallStatus(String referenceId) async {
    try {
      return await ApiService.getCallStatus(referenceId);
    } catch (e) {
      print('Failed to get call status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update call feedback after completion
  Future<bool> updateCallFeedback({
    required String referenceId,
    required String callStatus,
    String? feedback,
    String? remarks,
    int? callDuration,
  }) async {
    try {
      return await ApiService.updateCallFeedback(
        referenceId: referenceId,
        callStatus: callStatus,
        feedback: feedback,
        remarks: remarks,
        callDuration: callDuration,
      );
    } catch (e) {
      print('Failed to update call feedback: $e');
      return false;
    }
  }

  // Search drivers - REAL DATA ONLY
  Future<List<DriverContact>> searchDrivers(String query) async {
    return await ApiService.getDrivers(search: query);
  }

  // Get drivers by status - REAL DATA ONLY
  Future<List<DriverContact>> getDriversByStatus(CallStatus status) async {
    final statusString = _mapCallStatusToString(status);
    return await ApiService.getDrivers(status: statusString);
  }

  // Clear cache
  void clearCache() {
    _cachedDrivers = null;
    _lastFetchTime = null;
  }

  // Refresh data
  Future<List<DriverContact>> refreshDrivers() async {
    return await getDrivers(forceRefresh: true);
  }

  // Helper method to map CallStatus to string
  String _mapCallStatusToString(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return 'connected';
      case CallStatus.callBack:
        return 'callback';
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_reachable';
      case CallStatus.notInterested:
        return 'not_interested';
      case CallStatus.invalid:
        return 'invalid';
      case CallStatus.pending:
        return 'pending';
    }
  }

  // Get dashboard statistics
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final counts = await getContactCounts();
      return {
        'totalDrivers': counts.values.fold(0, (sum, count) => sum + count),
        'pendingCalls': counts[NavigationSection.home] ?? 0,
        'connectedCalls': counts[NavigationSection.connectedCalls] ?? 0,
        'interestedDrivers': counts[NavigationSection.interested] ?? 0,
        'callBacks': counts[NavigationSection.callBacks] ?? 0,
        'callBackLater': counts[NavigationSection.callBackLater] ?? 0,
      };
    } catch (e) {
      print('Failed to get dashboard stats: $e');
      return {
        'totalDrivers': 0,
        'pendingCalls': 0,
        'connectedCalls': 0,
        'interestedDrivers': 0,
        'callBacks': 0,
        'callBackLater': 0,
      };
    }
  }

  // Get call history
  Future<List<dynamic>> getCallHistory({String? status}) async {
    try {
      return await ApiService.getCallHistory(status: status);
    } catch (e) {
      print('Failed to get call history: $e');
      return [];
    }
  }

  // Update call history feedback
  Future<bool> updateCallHistoryFeedback({
    required String callLogId,
    required CallStatus status,
    String? feedback,
    String? remarks,
  }) async {
    try {
      final statusString = _mapCallStatusToString(status);
      return await ApiService.updateCallHistoryFeedback(
        callLogId: callLogId,
        callStatus: statusString,
        feedback: feedback,
        remarks: remarks,
      );
    } catch (e) {
      print('Failed to update call history feedback: $e');
      return false;
    }
  }

  // Upload call recording
  Future<Map<String, dynamic>> uploadCallRecording({
    required dynamic recordingFile,
    required String tmid,
    required String callerId,
    String? callLogId,
  }) async {
    try {
      return await ApiService.uploadCallRecording(
        recordingFile: recordingFile,
        tmid: tmid,
        callerId: callerId,
        callLogId: callLogId,
      );
    } catch (e) {
      print('Failed to upload call recording: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
