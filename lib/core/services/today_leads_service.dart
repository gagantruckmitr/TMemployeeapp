import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'real_auth_service.dart';

class TodayLeadsService {
  static TodayLeadsService? _instance;
  TodayLeadsService._();
  
  // Store remaining fresh leads count (from API - total uncalled leads)
  int _remainingFreshLeads = 0;
  
  // Store total remaining from API (for KPI display - before filtering current page)
  int _totalRemainingFromApi = 0;
  
  int get remainingFreshLeads => _remainingFreshLeads;
  int get totalRemainingFromApi => _totalRemainingFromApi;
  
  // Pagination state
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMorePages = false;
  bool _isLoadingMore = false;
  
  bool get hasMorePages => _hasMorePages;
  bool get isLoadingMore => _isLoadingMore;

  // Track processed lead IDs (feedback submitted) - persists across refreshes
  // These leads should not appear again until app restart or explicit clear
  final Set<int> _processedLeadIds = {};
  
  /// Mark a lead as processed (feedback submitted)
  void markLeadAsProcessed(int leadId) {
    _processedLeadIds.add(leadId);
    debugPrint('✅ [TodayLeadsService] Marked lead $leadId as processed. Total processed: ${_processedLeadIds.length}');
  }
  
  /// Check if a lead has been processed
  bool isLeadProcessed(int leadId) => _processedLeadIds.contains(leadId);
  
  /// Clear processed leads (call on logout or explicit reset)
  void clearProcessedLeads() {
    _processedLeadIds.clear();
    debugPrint('🔄 [TodayLeadsService] Cleared all processed lead IDs');
  }
  
  /// Get count of processed leads
  int get processedLeadsCount => _processedLeadIds.length;

  // In-memory cache
  List<TodayLead>? _cachedLeads;
  DateTime? _lastFetchTime;
  int? _cachedUserId;

  // Cache keys for SharedPreferences
  static const String _cacheKey = 'fresh_leads_cache';
  static const String _cacheTimeKey = 'fresh_leads_cache_time';
  static const String _cacheUserIdKey = 'fresh_leads_user_id';
  static const String _remainingCountKey = 'fresh_leads_remaining';

  static TodayLeadsService get instance {
    _instance ??= TodayLeadsService._();
    return _instance!;
  }

  /// Check if cache is valid
  bool hasCachedData(int userId) {
    return _cachedLeads != null && 
           _cachedLeads!.isNotEmpty && 
           _cachedUserId == userId;
  }

  /// Get cached leads from memory
  List<TodayLead>? getCachedLeads(int userId) {
    if (_cachedUserId == userId) {
      return _cachedLeads;
    }
    return null;
  }

  /// Load cache from local storage
  Future<List<TodayLead>?> loadFromStorage(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getInt(_cacheUserIdKey);
      
      if (cachedUserId != userId) {
        return null;
      }

      final cachedJson = prefs.getString(_cacheKey);
      final cachedTimeStr = prefs.getString(_cacheTimeKey);
      final remainingCount = prefs.getInt(_remainingCountKey);

      if (cachedJson != null && cachedTimeStr != null) {
        _lastFetchTime = DateTime.tryParse(cachedTimeStr);
        _cachedUserId = userId;
        _remainingFreshLeads = remainingCount ?? 0;
        
        final List<dynamic> jsonList = json.decode(cachedJson);
        _cachedLeads = jsonList.map((j) => TodayLead.fromJson(j)).toList();
        return _cachedLeads;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load fresh leads cache: $e');
    }
    return null;
  }

  /// Save leads to cache
  Future<void> _cacheLeads(List<TodayLead> leads, int userId) async {
    _cachedLeads = leads;
    _lastFetchTime = DateTime.now();
    _cachedUserId = userId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = leads.map((lead) => _leadToJson(lead)).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setString(_cacheTimeKey, _lastFetchTime!.toIso8601String());
      await prefs.setInt(_cacheUserIdKey, userId);
      await prefs.setInt(_remainingCountKey, _remainingFreshLeads);
    } catch (e) {
      debugPrint('⚠️ Failed to save fresh leads cache: $e');
    }
  }

  /// Convert TodayLead to JSON for storage
  Map<String, dynamic> _leadToJson(TodayLead lead) {
    return {
      'id': lead.id,
      'assigned_to': lead.assignedTo,
      'unique_id': lead.uniqueId,
      'role': lead.role,
      'name': lead.name,
      'name_eng': lead.nameEng,
      'mobile': lead.mobile,
      'email': lead.email,
      'states': lead.states,
      'city': lead.city,
      'full_details': {'profile_completion': lead.driverCompletion},
      'user_lang': lead.userLang,
      'Created_at': lead.createdAt,
      'assigned_admin': lead.assignedAdmin != null ? {
        'id': lead.assignedAdmin!.id,
        'role': lead.assignedAdmin!.role,
        'name': lead.assignedAdmin!.name,
        'mobile': lead.assignedAdmin!.mobile,
        'email': lead.assignedAdmin!.email,
        'tc_for': lead.assignedAdmin!.tcFor,
      } : null,
      'call_logs': lead.callLogs,
    };
  }

  /// Remove a lead from cache and mark as processed
  void removeLeadFromCache(int leadId) {
    // Mark as processed so it won't appear again even after refresh
    markLeadAsProcessed(leadId);
    
    _cachedLeads?.removeWhere((lead) => lead.id == leadId);
    if (_cachedLeads != null && _cachedUserId != null) {
      _cacheLeads(_cachedLeads!, _cachedUserId!);
    }
    
    // Update remaining count
    if (_remainingFreshLeads > 0) {
      _remainingFreshLeads--;
    }
    if (_totalRemainingFromApi > 0) {
      _totalRemainingFromApi--;
    }
    debugPrint('🗑️ [TodayLeadsService] Removed lead $leadId from cache. Remaining: $_remainingFreshLeads');
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _cachedLeads = null;
    _lastFetchTime = null;
    _cachedUserId = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      await prefs.remove(_cacheUserIdKey);
      await prefs.remove(_remainingCountKey);
    } catch (e) {
      debugPrint('⚠️ Failed to clear fresh leads cache: $e');
    }
  }

  Future<Map<String, List<TodayLead>>> getTodayLeadsWithFilters() async {
    try {
      // Get auth token
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        debugPrint('❌ No auth token available');
        throw Exception('No auth token available');
      }

      // Get current user ID to filter leads
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user available');
        throw Exception('No current user available');
      }
      
      final currentUserId = int.tryParse(currentUser.id);
      debugPrint('👤 Current user ID: $currentUserId (${currentUser.name})');

      // Use the assigned leads endpoint with caller_id
      final uri = Uri.parse('https://truckmitr.com/api/telehead/today-leads/assigned/$currentUserId');

      debugPrint('📡 Fetching today leads from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('📊 Decoded data type: ${data.runtimeType}');
        
        List<TodayLead> freshLeads = [];
        List<TodayLead> connectedLeads = [];
        List<TodayLead> notConnectedLeads = [];
        List<TodayLead> callbackLaterLeads = [];
          
        // Check if response is a Map with status
        if (data is Map) {
          // Extract remaining_leads_count from API
          if (data.containsKey('remaining_leads_count')) {
            final remaining = data['remaining_leads_count'];
            _remainingFreshLeads = remaining is int 
                ? remaining 
                : int.tryParse(remaining.toString()) ?? 0;
            debugPrint('📊 Remaining fresh leads from API: $_remainingFreshLeads');
          } else if (data.containsKey('remaining_fresh')) {
            final remaining = data['remaining_fresh'];
            _remainingFreshLeads = remaining is int 
                ? remaining 
                : int.tryParse(remaining.toString()) ?? 0;
            debugPrint('📊 Remaining fresh leads: $_remainingFreshLeads');
          }
          
          // Parse fresh leads (data field) - filter out leads with call_logs
          if (data.containsKey('data') && data['data'] is List) {
            final allLeads = data['data'] as List;
            debugPrint('✅ Found ${allLeads.length} total leads in "data" field');
            
            final parsedLeads = allLeads
                .map((item) => TodayLead.fromJson(item))
                .toList();
            
            // Filter: Fresh leads = leads with empty call_logs
            freshLeads = parsedLeads
                .where((lead) => !lead.hasBeenCalled)
                .toList();
            
            debugPrint('✅ Filtered to ${freshLeads.length} fresh leads (without call_logs)');
            freshLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          
          // Parse connected leads
          if (data.containsKey('today_connected') && 
              data['today_connected'] is Map &&
              data['today_connected']['data'] is List) {
            final connectedData = data['today_connected']['data'] as List;
            debugPrint('✅ Found ${connectedData.length} connected leads');
            
            connectedLeads = connectedData
                .map((item) => TodayLead.fromJson(item))
                .toList();
            
            connectedLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          
          // Parse not connected leads
          if (data.containsKey('today_not_connected') && 
              data['today_not_connected'] is Map &&
              data['today_not_connected']['data'] is List) {
            final notConnectedData = data['today_not_connected']['data'] as List;
            debugPrint('✅ Found ${notConnectedData.length} not connected leads');
            
            notConnectedLeads = notConnectedData
                .map((item) => TodayLead.fromJson(item))
                .toList();
            
            notConnectedLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          
          // Parse callback later leads
          if (data.containsKey('today_callback') && 
              data['today_callback'] is Map &&
              data['today_callback']['data'] is List) {
            final callbackData = data['today_callback']['data'] as List;
            debugPrint('✅ Found ${callbackData.length} callback later leads');
            
            callbackLaterLeads = callbackData
                .map((item) => TodayLead.fromJson(item))
                .toList();
            
            callbackLaterLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
        }
        
        debugPrint('✅ Parsed leads successfully - Fresh: ${freshLeads.length}, Connected: ${connectedLeads.length}, Not Connected: ${notConnectedLeads.length}, Callback: ${callbackLaterLeads.length}');
        
        return {
          'fresh': freshLeads,
          'connected': connectedLeads,
          'not_connected': notConnectedLeads,
          'callback_later': callbackLaterLeads,
        };
      } else {
        debugPrint('❌ API returned error status: ${response.statusCode}');
        debugPrint('❌ Error body: ${response.body}');
        throw Exception('Failed to load today leads: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching today leads: $e');
      rethrow;
    }
  }

  /// Get today leads with caching support
  /// Set forceRefresh to true to bypass cache (e.g., on pull-to-refresh)
  Future<List<TodayLead>> getTodayLeads({bool forceRefresh = false}) async {
    try {
      // Get current user ID
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user available');
        throw Exception('No current user available');
      }
      
      final currentUserId = int.tryParse(currentUser.id) ?? 0;

      // If force refresh, clear all caches first and reset pagination
      if (forceRefresh) {
        debugPrint('🔄 Force refresh - clearing cache and fetching fresh data');
        _cachedLeads = null;
        _currentPage = 1;
        _lastPage = 1;
        _hasMorePages = false;
        await clearCache();
      } else {
        // Check cache first (unless force refresh)
        // Check memory cache
        if (hasCachedData(currentUserId)) {
          final cachedLeads = getCachedLeads(currentUserId);
          if (cachedLeads != null && cachedLeads.isNotEmpty) {
            debugPrint('� tReturning ${cachedLeads.length} leads from memory cache');
            return cachedLeads;
          }
        }

        // Check local storage
        final storedLeads = await loadFromStorage(currentUserId);
        if (storedLeads != null && storedLeads.isNotEmpty) {
          debugPrint('💾 Returning ${storedLeads.length} leads from local storage');
          return storedLeads;
        }
      }

      // Fetch first page only (10 leads) - load more on scroll
      final leads = await _fetchFromApi(currentUserId, page: 1);
      await _cacheLeads(leads, currentUserId);
      return leads;
    } catch (e) {
      debugPrint('❌ Error in getTodayLeads: $e');
      rethrow;
    }
  }

  /// Internal method to fetch from API with pagination support
  /// Uses the assigned leads endpoint: /api/telehead/today-leads/assigned/{caller_id}
  Future<List<TodayLead>> _fetchFromApi(int currentUserId, {int page = 1}) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        debugPrint('❌ No auth token available');
        throw Exception('No auth token available');
      }

      debugPrint('🌐 Fetching fresh leads from API for user $currentUserId (page $page)');

      // Use the assigned leads endpoint with caller_id and pagination
      final uri = Uri.parse('https://truckmitr.com/api/telehead/today-leads/assigned/$currentUserId?page=$page');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('📊 Decoded data type: ${data.runtimeType}');
        
        List<TodayLead> userLeads = [];
        
        // Check if response is a Map with status
        if (data is Map) {
          // Extract remaining_leads_count from API (total uncalled leads for KPI)
          if (data.containsKey('remaining_leads_count')) {
            final remaining = data['remaining_leads_count'];
            _totalRemainingFromApi = remaining is int 
                ? remaining 
                : int.tryParse(remaining.toString()) ?? 0;
            debugPrint('📊 Total remaining fresh leads from API: $_totalRemainingFromApi');
          }
          
          // Extract pagination info
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map;
            final currentPageVal = pagination['current_page'];
            final lastPageVal = pagination['last_page'];
            _currentPage = currentPageVal is int 
                ? currentPageVal 
                : int.tryParse(currentPageVal.toString()) ?? 1;
            _lastPage = lastPageVal is int 
                ? lastPageVal 
                : int.tryParse(lastPageVal.toString()) ?? 1;
            _hasMorePages = _currentPage < _lastPage;
            debugPrint('📄 Pagination: page $_currentPage of $_lastPage, hasMore: $_hasMorePages');
          }
          
          // Check for 'data' field
          if (data.containsKey('data') && data['data'] is List) {
            final allLeads = data['data'] as List;
            debugPrint('✅ Found ${allLeads.length} leads in current page');
            
            // Parse all leads first
            final parsedLeads = allLeads
                .map((item) => TodayLead.fromJson(item))
                .toList();
            
            // CRITICAL: Filter out leads that have been called (call_logs not empty)
            // AND filter out leads that have been processed (feedback submitted in this session)
            // Fresh leads = leads with empty call_logs array AND not processed
            userLeads = parsedLeads
                .where((lead) => !lead.hasBeenCalled && !_processedLeadIds.contains(lead.id))
                .toList();
            
            debugPrint('✅ Filtered to ${userLeads.length} fresh leads (without call_logs, excluding ${_processedLeadIds.length} processed)');
            
            // Sort by created_at descending (newest first)
            userLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            debugPrint('✅ Final count: ${userLeads.length} fresh leads');
          }
          
          // Check for 'leads' field
          else if (data.containsKey('leads') && data['leads'] is List) {
            final allLeads = data['leads'] as List;
            debugPrint('✅ Found ${allLeads.length} leads in "leads" field');
            
            final parsedLeads = allLeads
                .map((item) => TodayLead.fromJson(item))
                .toList();
            
            // Filter out leads that have been called AND processed leads
            userLeads = parsedLeads
                .where((lead) => !lead.hasBeenCalled && !_processedLeadIds.contains(lead.id))
                .toList();
            
            debugPrint('✅ Filtered to ${userLeads.length} fresh leads (without call_logs, excluding ${_processedLeadIds.length} processed)');
            
            // Sort by created_at descending (newest first)
            userLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            debugPrint('✅ Final count: ${userLeads.length} fresh leads');
          }
          
          else {
            debugPrint('⚠️ Response is a Map but no leads array found');
            debugPrint('📊 Available keys: ${data.keys.toList()}');
            return [];
          }
        }
        
        // The API returns an array directly
        else if (data is List) {
          debugPrint('✅ Found ${data.length} total leads in response');
          
          final parsedLeads = data.map((item) => TodayLead.fromJson(item)).toList();
          
          // Filter out leads that have been called AND processed leads
          userLeads = parsedLeads
              .where((lead) => !lead.hasBeenCalled && !_processedLeadIds.contains(lead.id))
              .toList();
          
          debugPrint('✅ Filtered to ${userLeads.length} fresh leads (without call_logs, excluding ${_processedLeadIds.length} processed)');
          
          // Sort by created_at descending (newest first)
          userLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          debugPrint('✅ Final count: ${userLeads.length} fresh leads');
        }
        
        else {
          debugPrint('⚠️ Response is neither List nor Map with leads, returning empty array');
          return [];
        }
        
        // Update remaining count - use API's total for display
        _remainingFreshLeads = _totalRemainingFromApi > 0 ? _totalRemainingFromApi : userLeads.length;
        
        return userLeads;
      } else {
        debugPrint('❌ API returned error status: ${response.statusCode}');
        debugPrint('❌ Error body: ${response.body}');
        throw Exception('Failed to load today leads: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching today leads: $e');
      rethrow;
    }
  }

  /// Load more leads (next page)
  Future<List<TodayLead>> loadMoreLeads() async {
    if (_isLoadingMore || !_hasMorePages) {
      return _cachedLeads ?? [];
    }
    
    try {
      _isLoadingMore = true;
      
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No current user available');
      }
      
      final currentUserId = int.tryParse(currentUser.id) ?? 0;
      final nextPage = _currentPage + 1;
      
      debugPrint('📄 Loading more leads, page $nextPage');
      
      final newLeads = await _fetchFromApi(currentUserId, page: nextPage);
      
      // Add to existing cache
      if (_cachedLeads != null) {
        // Remove duplicates
        final existingIds = _cachedLeads!.map((l) => l.id).toSet();
        final uniqueNewLeads = newLeads.where((l) => !existingIds.contains(l.id)).toList();
        _cachedLeads!.addAll(uniqueNewLeads);
        await _cacheLeads(_cachedLeads!, currentUserId);
      } else {
        _cachedLeads = newLeads;
        await _cacheLeads(newLeads, currentUserId);
      }
      
      return _cachedLeads!;
    } finally {
      _isLoadingMore = false;
    }
  }

}

class TodayLead {
  final int id;
  final int assignedTo;
  final String uniqueId;
  final String role;
  final String name;
  final String nameEng;
  final String mobile;
  final String? email;
  final String? states;
  final String? city;
  int driverCompletion; // Mutable to allow enrichment
  final String userLang;
  final String createdAt;
  final AssignedAdmin? assignedAdmin;
  final List<dynamic> callLogs;

  TodayLead({
    required this.id,
    required this.assignedTo,
    required this.uniqueId,
    required this.role,
    required this.name,
    required this.nameEng,
    required this.mobile,
    this.email,
    this.states,
    this.city,
    required this.driverCompletion,
    required this.userLang,
    required this.createdAt,
    this.assignedAdmin,
    this.callLogs = const [],
  });

  bool get hasBeenCalled => callLogs.isNotEmpty;

  factory TodayLead.fromJson(Map<String, dynamic> json) {
    // IMPORTANT: The API returns profile_completion in full_details object
    // full_details.profile_completion is the CORRECT value (e.g., 27)
    // driver_completion at root level is often 0 (outdated/incorrect)
    int completionInt = 0;
    
    if (json['full_details'] != null && json['full_details']['profile_completion'] != null) {
      // Use the accurate value from full_details
      final fullDetailsCompletion = json['full_details']['profile_completion'];
      completionInt = fullDetailsCompletion is int 
          ? fullDetailsCompletion 
          : int.tryParse(fullDetailsCompletion.toString()) ?? 0;
    } else {
      // Fallback to root level fields (usually 0)
      final profileCompletion = json['profile_completion'] ?? json['driver_completion'] ?? 0;
      completionInt = profileCompletion is int 
          ? profileCompletion 
          : int.tryParse(profileCompletion.toString()) ?? 0;
    }
    
    // Get call logs
    final callLogs = json['call_logs'] ?? [];
    
    // Debug log
    print('📊 Parsing lead ${json['id']} (${json['name']}): profile_completion = $completionInt%, call_logs = ${callLogs.length}');
    
    // Parse id safely (can be int or string)
    final idVal = json['id'];
    final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
    
    // Parse assigned_to safely (can be int or string)
    final assignedToVal = json['assigned_to'];
    final assignedTo = assignedToVal is int 
        ? assignedToVal 
        : int.tryParse(assignedToVal.toString()) ?? 0;
    
    return TodayLead(
      id: id,
      assignedTo: assignedTo,
      uniqueId: json['unique_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEng: json['name_eng']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      states: json['states']?.toString(),
      city: json['city']?.toString(),
      driverCompletion: completionInt,
      userLang: json['user_lang']?.toString() ?? 'en',
      createdAt: json['Created_at']?.toString() ?? '',
      assignedAdmin: json['assigned_admin'] != null
          ? AssignedAdmin.fromJson(json['assigned_admin'])
          : null,
      callLogs: callLogs is List ? callLogs : [],
    );
  }
}

class AssignedAdmin {
  final int id;
  final String role;
  final String name;
  final String mobile;
  final String email;
  final String tcFor;

  AssignedAdmin({
    required this.id,
    required this.role,
    required this.name,
    required this.mobile,
    required this.email,
    required this.tcFor,
  });

  factory AssignedAdmin.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
    
    return AssignedAdmin(
      id: id,
      role: json['role']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      tcFor: json['tc_for']?.toString() ?? '',
    );
  }
}

