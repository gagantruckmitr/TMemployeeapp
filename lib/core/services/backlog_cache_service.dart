import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/smart_calling_models.dart';

/// Service to cache backlog leads data in memory and local storage
class BacklogCacheService {
  static final BacklogCacheService _instance = BacklogCacheService._internal();
  static BacklogCacheService get instance => _instance;
  BacklogCacheService._internal();

  // In-memory cache
  List<DriverContact>? _cachedLeads;
  DateTime? _lastFetchTime;
  int? _cachedCallerId;

  // Cache key for SharedPreferences
  static const String _cacheKey = 'backlog_leads_cache';
  static const String _cacheTimeKey = 'backlog_leads_cache_time';
  static const String _cacheCallerIdKey = 'backlog_leads_caller_id';

  /// Check if cache is valid (has data and belongs to same caller)
  bool hasCachedData(int callerId) {
    return _cachedLeads != null && 
           _cachedLeads!.isNotEmpty && 
           _cachedCallerId == callerId;
  }

  /// Get cached leads from memory
  List<DriverContact>? getCachedLeads(int callerId) {
    if (_cachedCallerId == callerId) {
      return _cachedLeads;
    }
    return null;
  }

  /// Get last fetch time
  DateTime? getLastFetchTime() => _lastFetchTime;

  /// Cache leads in memory and local storage
  Future<void> cacheLeads(List<DriverContact> leads, int callerId) async {
    _cachedLeads = leads;
    _lastFetchTime = DateTime.now();
    _cachedCallerId = callerId;

    // Also save to local storage for persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = leads.map((lead) => _leadToJson(lead)).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setString(_cacheTimeKey, _lastFetchTime!.toIso8601String());
      await prefs.setInt(_cacheCallerIdKey, callerId);
    } catch (e) {
      print('⚠️ Failed to save backlog cache to storage: $e');
    }
  }

  /// Load cache from local storage (call on app start)
  Future<List<DriverContact>?> loadFromStorage(int callerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCallerId = prefs.getInt(_cacheCallerIdKey);
      
      // Only load if same caller
      if (cachedCallerId != callerId) {
        return null;
      }

      final cachedJson = prefs.getString(_cacheKey);
      final cachedTimeStr = prefs.getString(_cacheTimeKey);

      if (cachedJson != null && cachedTimeStr != null) {
        _lastFetchTime = DateTime.tryParse(cachedTimeStr);
        _cachedCallerId = callerId;
        
        final List<dynamic> jsonList = json.decode(cachedJson);
        _cachedLeads = jsonList.map((j) => _jsonToLead(j)).toList();
        return _cachedLeads;
      }
    } catch (e) {
      print('⚠️ Failed to load backlog cache from storage: $e');
    }
    return null;
  }

  /// Remove a lead from cache (after feedback submitted)
  void removeLeadFromCache(String leadId) {
    _cachedLeads?.removeWhere((lead) => lead.id == leadId);
    // Update storage async
    if (_cachedLeads != null && _cachedCallerId != null) {
      cacheLeads(_cachedLeads!, _cachedCallerId!);
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _cachedLeads = null;
    _lastFetchTime = null;
    _cachedCallerId = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      await prefs.remove(_cacheCallerIdKey);
    } catch (e) {
      print('⚠️ Failed to clear backlog cache: $e');
    }
  }

  /// Convert DriverContact to JSON for storage
  Map<String, dynamic> _leadToJson(DriverContact lead) {
    return {
      'id': lead.id,
      'tmid': lead.tmid,
      'name': lead.name,
      'company': lead.company,
      'phoneNumber': lead.phoneNumber,
      'state': lead.state,
      'role': lead.role,
      'profilePicture': lead.profilePicture,
      'licenseType': lead.licenseType,
      'fleetSize': lead.fleetSize,
      'assignedTelecaller': lead.assignedTelecaller,
      'registrationDate': lead.registrationDate?.toIso8601String(),
      'profileCompletion': lead.profileCompletion?.percentage,
      'paymentInfo': lead.paymentInfo != null ? {
        'updatedAt': lead.paymentInfo!.updatedAt?.toIso8601String(),
        'paymentDate': lead.paymentInfo!.paymentDate?.toIso8601String(),
        'amount': lead.paymentInfo!.amount,
        'startAt': lead.paymentInfo!.startAt?.toIso8601String(),
        'endAt': lead.paymentInfo!.endAt?.toIso8601String(),
        'paymentId': lead.paymentInfo!.paymentId,
      } : null,
      'appliedJobsCount': lead.appliedJobs?.length ?? 0,
      'callHistoryCount': lead.callHistory?.length ?? 0,
      'trainingCompleted': lead.trainingInfo?.isCompleted ?? false,
    };
  }

  /// Convert JSON back to DriverContact
  DriverContact _jsonToLead(Map<String, dynamic> json) {
    PaymentInfo? paymentInfo;
    if (json['paymentInfo'] != null) {
      final pi = json['paymentInfo'];
      paymentInfo = PaymentInfo(
        paymentStatus: PaymentStatus.success,
        updatedAt: pi['updatedAt'] != null ? DateTime.tryParse(pi['updatedAt']) : null,
        paymentDate: pi['paymentDate'] != null ? DateTime.tryParse(pi['paymentDate']) : null,
        amount: pi['amount'],
        startAt: pi['startAt'] != null ? DateTime.tryParse(pi['startAt']) : null,
        endAt: pi['endAt'] != null ? DateTime.tryParse(pi['endAt']) : null,
        paymentId: pi['paymentId'],
      );
    }
    
    // Create placeholder applied jobs list based on count
    final appliedJobsCount = json['appliedJobsCount'] ?? 0;
    final appliedJobs = List<AppliedJob>.generate(
      appliedJobsCount,
      (i) => AppliedJob(jobId: '', jobCode: '', jobTitle: ''),
    );
    
    // Create placeholder call history list based on count
    final callHistoryCount = json['callHistoryCount'] ?? 0;
    final callHistory = List<CallHistoryEntry>.generate(
      callHistoryCount,
      (i) => CallHistoryEntry(id: '', callerId: '', callStatus: ''),
    );
    
    // Create training info
    TrainingInfo? trainingInfo;
    if (json['trainingCompleted'] != null) {
      trainingInfo = TrainingInfo(
        isCompleted: json['trainingCompleted'] ?? false,
        totalQuestions: 0,
        correctAnswers: 0,
        percentage: 0,
        rating: 0,
        rankingPercentage: 0,
        tier: 'N/A',
      );
    }

    return DriverContact(
      id: json['id'] ?? '',
      tmid: json['tmid'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      state: json['state'] ?? '',
      subscriptionStatus: paymentInfo != null 
          ? SubscriptionStatus.active 
          : SubscriptionStatus.inactive,
      status: CallStatus.callBackLater,
      role: json['role'],
      profilePicture: json['profilePicture'],
      licenseType: json['licenseType'],
      fleetSize: json['fleetSize'],
      assignedTelecaller: json['assignedTelecaller'],
      registrationDate: json['registrationDate'] != null 
          ? DateTime.tryParse(json['registrationDate']) 
          : null,
      profileCompletion: json['profileCompletion'] != null 
          ? ProfileCompletion(
              percentage: json['profileCompletion'],
              documentStatus: {},
            )
          : null,
      paymentInfo: paymentInfo,
      appliedJobs: appliedJobs,
      callHistory: callHistory,
      trainingInfo: trainingInfo,
    );
  }
}
