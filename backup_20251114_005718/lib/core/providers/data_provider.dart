import 'package:flutter/foundation.dart';
import '../services/telecaller_service.dart';
import '../../models/database_models.dart';

class DataProvider extends ChangeNotifier {
  final TelecallerService _telecallerService = TelecallerService.instance;

  // Dashboard stats
  Map<String, int> _dashboardStats = {};
  Map<String, int> get dashboardStats => _dashboardStats;

  // Callback requests
  List<CallbackRequest> _callbackRequests = [];
  List<CallbackRequest> get callbackRequests => _callbackRequests;

  // Users (drivers and transporters)
  List<User> _drivers = [];
  List<User> _transporters = [];
  List<User> get drivers => _drivers;
  List<User> get transporters => _transporters;

  // Loading states
  bool _isLoadingStats = false;
  bool _isLoadingCallbacks = false;
  bool _isLoadingUsers = false;

  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingCallbacks => _isLoadingCallbacks;
  bool get isLoadingUsers => _isLoadingUsers;

  // Error states
  String? _error;
  String? get error => _error;

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    _isLoadingStats = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await _telecallerService.getDashboardStats();
    } catch (e) {
      _error = 'Failed to load dashboard stats: ${e.toString()}';
      print(_error);
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // Load callback requests
  Future<void> loadCallbackRequests({
    CallbackStatus? status,
    AppType? appType,
  }) async {
    _isLoadingCallbacks = true;
    _error = null;
    notifyListeners();

    try {
      _callbackRequests = await _telecallerService.getMyCallbackRequests(
        status: status,
        appType: appType,
      );
    } catch (e) {
      _error = 'Failed to load callback requests: ${e.toString()}';
      print(_error);
    } finally {
      _isLoadingCallbacks = false;
      notifyListeners();
    }
  }

  // Load users (drivers and transporters)
  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _telecallerService.getDrivers(limit: 100),
        _telecallerService.getTransporters(limit: 100),
      ]);

      _drivers = futures[0];
      _transporters = futures[1];
    } catch (e) {
      _error = 'Failed to load users: ${e.toString()}';
      print(_error);
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  // Update callback status
  Future<bool> updateCallbackStatus(
    int requestId,
    CallbackStatus status, {
    String? notes,
  }) async {
    try {
      final success = await _telecallerService.updateCallbackStatus(
        requestId,
        status,
        notes: notes,
      );

      if (success) {
        // Update local data
        final index = _callbackRequests.indexWhere((req) => req.id == requestId);
        if (index != -1) {
          _callbackRequests[index] = CallbackRequest(
            id: _callbackRequests[index].id,
            uniqueId: _callbackRequests[index].uniqueId,
            assignedTo: _callbackRequests[index].assignedTo,
            userName: _callbackRequests[index].userName,
            mobileNumber: _callbackRequests[index].mobileNumber,
            requestDateTime: _callbackRequests[index].requestDateTime,
            contactReason: _callbackRequests[index].contactReason,
            appType: _callbackRequests[index].appType,
            status: status,
            notes: notes ?? _callbackRequests[index].notes,
            createdAt: _callbackRequests[index].createdAt,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _error = 'Failed to update callback status: ${e.toString()}';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query, {String? role}) async {
    try {
      return await _telecallerService.searchUsers(query, role: role);
    } catch (e) {
      _error = 'Failed to search users: ${e.toString()}';
      print(_error);
      notifyListeners();
      return [];
    }
  }

  // Log a call
  Future<bool> logCall({
    required int userId,
    required String userNumber,
    String? referenceId,
    String? apiResponse,
  }) async {
    try {
      return await _telecallerService.logCall(
        userId: userId,
        userNumber: userNumber,
        referenceId: referenceId,
        apiResponse: apiResponse,
      );
    } catch (e) {
      _error = 'Failed to log call: ${e.toString()}';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadDashboardStats(),
      loadCallbackRequests(),
      loadUsers(),
    ]);
  }
}