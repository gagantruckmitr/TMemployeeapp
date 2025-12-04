import '../../models/smart_calling_models.dart';
import 'api_service.dart';
import 'easygo_ivr_service.dart';

class SmartCallingService {
  static SmartCallingService? _instance;
  SmartCallingService._();

  static SmartCallingService get instance {
    _instance ??= SmartCallingService._();
    return _instance!;
  }

  // Cache variables for drivers
  List<DriverContact>? _cachedDrivers;
  DateTime? _lastFetchTime;

  // Cache variables for transporters
  List<TransporterContact>? _cachedTransporters;
  DateTime? _lastTransporterFetchTime;

  // Cache timeout duration
  final Duration cacheTimeout = const Duration(minutes: 5);

  // Round robin pointer per telecaller
  static final Map<String, int> _telecallerPointer = {};
  static const int _leadsPerTelecaller = 10;

  /// Returns a subset of fresh leads assigned to the given telecaller using round robin.
  Future<List<DriverContact>> getLeadsForTelecaller(String telecallerId) async {
    // Fetch fresh leads (uncalled drivers) without using cache to ensure fairness.
    final allLeads = await getDrivers(forceRefresh: true);
    if (allLeads.isEmpty) return [];
    final start = _telecallerPointer[telecallerId] ?? 0;
    final end = (start + _leadsPerTelecaller).clamp(0, allLeads.length);
    final slice = allLeads.sublist(start, end);
    // Update pointer for next request
    _telecallerPointer[telecallerId] = end % allLeads.length;
    return slice;
  }

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

  // Initiate IVR call through Click2Call API (Production)
  Future<Map<String, dynamic>> initiateClick2CallIVR({
    required String driverMobile,
    required int callerId,
    required String driverId,
  }) async {
    try {
      return await ApiService.initiateClick2CallIVR(
        driverMobile: driverMobile,
        callerId: callerId,
        driverId: driverId,
      );
    } catch (e) {
      print('Failed to initiate Click2Call IVR: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Initiate EasyGo IVR call (New Integration)
  Future<Map<String, dynamic>> initiateEasyGoIVR({
    required String telecallerPhone,
    required String clientPhone,
    required String callerId,
    required String contactId,
    String contactType = 'driver',
    String? driverName,
    String duration = '',
    String? callSource,
  }) async {
    try {
      return await EasyGoIVRService.initiateCall(
        exten: telecallerPhone,
        number: clientPhone,
        callerId: callerId,
        contactId: contactId,
        contactType: contactType,
        driverName: driverName,
        duration: duration,
        callSource: callSource,
      );
    } catch (e) {
      print('Failed to initiate EasyGo IVR: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Initiate manual call (direct phone dialer)
  Future<Map<String, dynamic>> initiateManualCall({
    required String driverMobile,
    required int callerId,
    required String driverId,
    String contactType = 'driver', // 'driver' or 'transporter'
    String? callSource,
  }) async {
    try {
      return await ApiService.initiateManualCall(
        driverMobile: driverMobile,
        callerId: callerId,
        driverId: driverId,
        contactType: contactType,
        callSource: callSource,
      );
    } catch (e) {
      print('Failed to initiate manual call: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get call status by reference ID
  Future<Map<String, dynamic>> getCallStatus(String referenceId) async {
    try {
      return await ApiService.getCallStatus(referenceId);
    } catch (e) {
      print('Failed to get call status: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update call feedback after completion
  Future<bool> updateCallFeedback({
    required String referenceId,
    required String callStatus,
    String? feedback,
    String? remarks,
    int? callDuration,
    String? driverName,
  }) async {
    try {
      return await ApiService.updateCallFeedback(
        referenceId: referenceId,
        callStatus: callStatus,
        feedback: feedback,
        remarks: remarks,
        callDuration: callDuration,
        driverName: driverName,
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

  // Get transporters (uncalled transporters for welcome calls)
  Future<List<TransporterContact>> getTransporters({
    bool forceRefresh = false,
    int limit = 50,
  }) async {
    final now = DateTime.now();
    final shouldRefresh =
        forceRefresh ||
        _cachedTransporters == null ||
        _lastTransporterFetchTime == null ||
        now.difference(_lastTransporterFetchTime!) > cacheTimeout;

    if (shouldRefresh) {
      try {
        _cachedTransporters = await ApiService.getTransporters(limit: limit);
        _lastTransporterFetchTime = now;
      } catch (e) {
        print('Failed to fetch transporters: $e');
        _cachedTransporters = [];
      }
    }

    return _cachedTransporters ?? [];
  }

  // Update transporter call status
  Future<bool> updateTransporterCallStatus({
    required String transporterId,
    required CallStatus status,
    String? feedback,
    String? remarks,
  }) async {
    try {
      final success = await ApiService.updateTransporterCallStatus(
        transporterId: transporterId,
        status: status,
        feedback: feedback,
        remarks: remarks,
      );

      if (success) {
        if (_cachedTransporters != null) {
          final index = _cachedTransporters!.indexWhere(
            (t) => t.id == transporterId,
          );
          if (index != -1) {
            _cachedTransporters![index] = _cachedTransporters![index].copyWith(
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
      print('Failed to update transporter call status: $e');
      return false;
    }
  }

  // Clear cache
  void clearCache() {
    _cachedDrivers = null;
    _cachedTransporters = null;
    _lastFetchTime = null;
    _lastTransporterFetchTime = null;
  }

  // Refresh data
  Future<List<DriverContact>> refreshDrivers() async {
    return await getDrivers(forceRefresh: true);
  }

  Future<List<TransporterContact>> refreshTransporters() async {
    return await getTransporters(forceRefresh: true);
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
  Future<Map<String, dynamic>> getCallHistory({
    String? status,
    String? feedback,
    String? remarks,
    String? search,
    int limit = 1000,
  }) async {
    try {
      return await ApiService.getCallHistory(
        status: status,
        feedback: feedback,
        remarks: remarks,
        search: search,
        limit: limit,
      );
    } catch (e) {
      print('Failed to get call history: $e');
      return {'data': [], 'total': 0};
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
      return {'success': false, 'error': e.toString()};
    }
  }
}
