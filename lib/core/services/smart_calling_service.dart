import '../../models/smart_calling_models.dart';
import 'api_service.dart';
import 'easygo_ivr_service.dart';
import 'today_leads_service.dart';

class SmartCallingService {
  static SmartCallingService? _instance;
  SmartCallingService._();

  static SmartCallingService get instance {
    _instance ??= SmartCallingService._();
    return _instance!;
  }

  // Cache variables for drivers
  List<DriverContact>? _cachedDrivers;
  String? _cachedUserType;
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
    String? userType, // 'driver' or 'transporter' for match-making
    bool useElechamps = false, // Use elechamps API
    String? adminId, // Admin ID for elechamps API
  }) async {
    // Check if we need to refresh cache
    final targetUserType = userType ?? 'driver';
    final now = DateTime.now();
    final shouldRefresh =
        forceRefresh ||
        _cachedDrivers == null ||
        _lastFetchTime == null ||
        _cachedUserType != targetUserType ||
        now.difference(_lastFetchTime!) > cacheTimeout;

    if (shouldRefresh) {
      // NOTE: ApiService.getFreshLeads has been removed (API deleted)
      // Now using TodayLeadsService as the primary data source

      // Get today's leads from new API (primary source)
      final todayLeads = await _getTodayLeadsAsDriverContacts(targetUserType);

      // Get elechamps leads if requested
      List<DriverContact> elechampsLeads = [];
      if (useElechamps && adminId != null) {
        try {
          elechampsLeads = await ApiService.getElechampsLeads(
            adminId: adminId,
            limit: limit,
          );
          print('📊 Fetched ${elechampsLeads.length} leads from elechamps API');
        } catch (e) {
          print('⚠️ Failed to fetch elechamps leads: $e');
        }
      }

      // Merge all lists, removing duplicates by ID
      final allLeads = <String, DriverContact>{};

      // Add today's leads first (primary source)
      for (final lead in todayLeads) {
        allLeads[lead.id] = lead;
      }

      // Add elechamps leads (will override if same ID)
      for (final lead in elechampsLeads) {
        allLeads[lead.id] = lead;
      }

      _cachedDrivers = allLeads.values.toList();
      _cachedUserType = targetUserType;
      _lastFetchTime = now;

      print(
        '📊 Merged leads: ${todayLeads.length} from today + ${elechampsLeads.length} from elechamps = ${_cachedDrivers!.length} total',
      );
    }

    // Apply local filters if needed
    var filteredDrivers = _cachedDrivers ?? [];

    // Extra safety: Filter out transporters from driver list based on TMID
    // This catches any that might have slipped through API service filtering
    filteredDrivers = filteredDrivers.where((d) {
      final tmid = d.tmid.toUpperCase();
      return !(tmid.contains('TR') && !tmid.contains('DR'));
    }).toList();

    if (search != null && search.isNotEmpty) {
      filteredDrivers = filteredDrivers.where((driver) {
        return driver.name.toLowerCase().contains(search.toLowerCase()) ||
            driver.company.toLowerCase().contains(search.toLowerCase()) ||
            driver.phoneNumber.contains(search);
      }).toList();
    }

    return filteredDrivers;
  }

  // Get elechamps leads directly (convenience method)
  Future<List<DriverContact>> getElechampsLeads({
    required String adminId,
    int limit = 50,
  }) async {
    try {
      return await ApiService.getElechampsLeads(adminId: adminId, limit: limit);
    } catch (e) {
      print('Failed to fetch elechamps leads: $e');
      return [];
    }
  }

  // Helper method to get today's leads as DriverContact objects
  Future<List<DriverContact>> _getTodayLeadsAsDriverContacts(
    String userType,
  ) async {
    try {
      final todayLeadsService = TodayLeadsService.instance;
      final leads = await todayLeadsService.getTodayLeads();

      // Filter by user type (driver or transporter)
      final filteredLeads = leads
          .where((lead) => lead.role == userType)
          .toList();

      // Convert to DriverContact
      return filteredLeads.map((lead) {
        // Convert UTC to IST (UTC+5:30)
        DateTime? registrationDate;
        if (lead.createdAt.isNotEmpty) {
          final utcDate = DateTime.tryParse(lead.createdAt);
          if (utcDate != null) {
            // Convert to IST by adding 5 hours and 30 minutes
            registrationDate = utcDate.add(
              const Duration(hours: 5, minutes: 30),
            );
          }
        }

        return DriverContact(
          id: lead.id.toString(),
          tmid: lead.uniqueId,
          name: lead.nameEng,
          company: lead.role == 'driver' ? 'Driver' : 'Transporter',
          phoneNumber: lead.mobile,
          state: lead.states ?? '0',
          subscriptionStatus: SubscriptionStatus.inactive,
          status: CallStatus.pending,
          role: lead.role,
          registrationDate: registrationDate,
          profileCompletion: ProfileCompletion(
            percentage: lead.driverCompletion,
            documentStatus: {},
          ),
          assignedTelecaller: lead.assignedAdmin?.name,
        );
      }).toList();
    } catch (e) {
      print('⚠️ Error fetching today\'s leads: $e');
      return [];
    }
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
      case NavigationSection.welcomeCall:
      case NavigationSection.tollFree:
      case NavigationSection.jobMatching:
      case NavigationSection.callbackRequest:
      case NavigationSection.socialMediaLeads:
      case NavigationSection.settings:
        // These are navigation-only sections, no driver data
        return [];
    }
  }

  // Get contact counts by category
  Future<Map<NavigationSection, int>> getContactCounts() async {
    final allDrivers = await getDrivers();
    final counts = <NavigationSection, int>{};

    // Only count for sections that have driver data
    final countableSections = [
      NavigationSection.home,
      NavigationSection.interested,
      NavigationSection.connectedCalls,
      NavigationSection.callBacks,
      NavigationSection.callBackLater,
      NavigationSection.pendingCalls,
    ];

    for (final section in NavigationSection.values) {
      if (countableSections.contains(section)) {
        counts[section] = allDrivers.where((contact) {
          return ContactCategorizer.getCategoryForContact(contact) == section;
        }).length;
      } else {
        counts[section] = 0; // Navigation-only sections have no count
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

  // Initiate EasyGo IVR call (New Integration - Live API)
  Future<Map<String, dynamic>> initiateEasyGoIVR({
    required String telecallerPhone,
    required String clientPhone,
    required String callerId,
    required String contactId,
    required String tmid, // Added TMID requirement
    String contactType =
        'driver', // Kept for backward compat in signature, but unused in new service if not needed
    String? driverName,
    String duration = '',
    String? callSource,
    String process =
        'welcome', // Process type: 'welcome', 'tollfree', 'transporter', etc.
  }) async {
    try {
      return await EasyGoIVRService.initiateCall(
        exten: telecallerPhone,
        number: clientPhone,
        callerId: callerId,
        contactId: contactId,
        tmid: tmid,
        driverName: driverName,
        callSource: callSource,
        process: process,
      );
    } catch (e) {
      print('Failed to initiate EasyGo IVR: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Initiate Job Matching IVR call (for job applicants)
  Future<Map<String, dynamic>> initiateJobMatchingCall({
    required String uniqueIdTransporter,
    required String uniqueIdDriver,
    required int userIdTransporter,
    required int userIdDriver,
    required int assignedTo,
    required String jobId,
    required String transporterName,
    required String driverName,
    required String exten,
    required String number,
  }) async {
    try {
      return await EasyGoIVRService.initiateJobMatchingCall(
        uniqueIdTransporter: uniqueIdTransporter,
        uniqueIdDriver: uniqueIdDriver,
        userIdTransporter: userIdTransporter,
        userIdDriver: userIdDriver,
        assignedTo: assignedTo,
        jobId: jobId,
        transporterName: transporterName,
        driverName: driverName,
        exten: exten,
        number: number,
      );
    } catch (e) {
      print('Failed to initiate job matching call: $e');
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

  // Update EasyGo Call Feedback (New Live API)
  Future<bool> updateEasyGoCallFeedback({
    required int callId,
    required String status,
    required String feedback,
    String? remarks,
    String? recordingFile,
  }) async {
    try {
      final result = await EasyGoIVRService.updateCall(
        callId: callId,
        status: status,
        feedback: feedback,
        remarks: remarks,
        recordingFile: recordingFile,
      );
      return result['success'] == true;
    } catch (e) {
      print('Failed to update EasyGo call feedback: $e');
      return false;
    }
  }

  // Update call feedback after completion (Legacy/Click2Call)
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
    String? userType, // 'transporter' for match-making
  }) async {
    final now = DateTime.now();
    final shouldRefresh =
        forceRefresh ||
        _cachedTransporters == null ||
        _lastTransporterFetchTime == null ||
        now.difference(_lastTransporterFetchTime!) > cacheTimeout;

    if (shouldRefresh) {
      try {
        final apiTransporters = await ApiService.getTransporters(
          limit: limit,
          userType: userType,
        );

        // Get today's transporter leads
        final todayTransporters = await _getTodayLeadsAsTransporterContacts();

        // Merge both lists, removing duplicates by ID
        final allTransporters = <String, TransporterContact>{};

        // Add API transporters first
        for (final transporter in apiTransporters) {
          allTransporters[transporter.id] = transporter;
        }

        // Add today's transporters (will override if same ID)
        for (final transporter in todayTransporters) {
          allTransporters[transporter.id] = transporter;
        }

        _cachedTransporters = allTransporters.values.toList();

        // Extra safety: Filter out drivers from transporter list based on TMID
        _cachedTransporters = _cachedTransporters?.where((t) {
          final tmid = t.tmid.toUpperCase();
          return !(tmid.contains('DR') && !tmid.contains('TR'));
        }).toList();

        _lastTransporterFetchTime = now;

        print(
          '📊 Merged transporters: ${apiTransporters.length} from API + ${todayTransporters.length} from today = ${_cachedTransporters!.length} total',
        );
      } catch (e) {
        print('Failed to fetch transporters: $e');
        _cachedTransporters = [];
      }
    }

    return _cachedTransporters ?? [];
  }

  // Helper method to get today's transporter leads as TransporterContact objects
  Future<List<TransporterContact>> _getTodayLeadsAsTransporterContacts() async {
    try {
      final todayLeadsService = TodayLeadsService.instance;
      final leads = await todayLeadsService.getTodayLeads();

      // Filter only transporters
      final transporterLeads = leads
          .where((lead) => lead.role == 'transporter')
          .toList();

      // Convert to TransporterContact
      return transporterLeads.map((lead) {
        // Convert UTC to IST (UTC+5:30)
        DateTime? registrationDate;
        if (lead.createdAt.isNotEmpty) {
          final utcDate = DateTime.tryParse(lead.createdAt);
          if (utcDate != null) {
            // Convert to IST by adding 5 hours and 30 minutes
            registrationDate = utcDate.add(
              const Duration(hours: 5, minutes: 30),
            );
          }
        }

        return TransporterContact(
          id: lead.id.toString(),
          tmid: lead.uniqueId,
          name: lead.nameEng,
          company: 'Transporter',
          phoneNumber: lead.mobile,
          state: lead.states ?? '0',
          subscriptionStatus: SubscriptionStatus.inactive,
          status: CallStatus.pending,
          registrationDate: registrationDate,
          profileCompletion: ProfileCompletion(
            percentage: lead.driverCompletion,
            documentStatus: {},
          ),
        );
      }).toList();
    } catch (e) {
      print('⚠️ Error fetching today\'s transporter leads: $e');
      return [];
    }
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
    _cachedUserType = null;
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
        return 'callback_later';
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_connected';
      case CallStatus.notInterested:
        return 'connected';
      case CallStatus.invalid:
        return 'not_connected';
      case CallStatus.pending:
        return 'not_connected';
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
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 1000,
  }) async {
    try {
      return await ApiService.getCallHistory(
        status: status,
        feedback: feedback,
        remarks: remarks,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
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

  // Update call history feedback by user ID (finds most recent call log)
  Future<bool> updateCallHistoryFeedbackByUserId({
    required String userId,
    required String callerId,
    required CallStatus status,
    String? feedback,
    String? remarks,
  }) async {
    try {
      final statusString = _mapCallStatusToString(status);
      return await ApiService.updateCallHistoryFeedbackByUserId(
        userId: userId,
        callerId: callerId,
        callStatus: statusString,
        feedback: feedback,
        remarks: remarks,
      );
    } catch (e) {
      print('Failed to update call history feedback by user ID: $e');
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
