import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'real_auth_service.dart';

/// Service to check for pending call feedback before allowing new calls
/// Ensures telecallers submit feedback for previous calls before making new ones
/// Now checks last 10 calls for pending feedback
class CallFeedbackGuardService {
  static CallFeedbackGuardService? _instance;
  CallFeedbackGuardService._();

  static CallFeedbackGuardService get instance {
    _instance ??= CallFeedbackGuardService._();
    return _instance!;
  }

  // Cache for pending feedback check
  List<PendingCallEntry> _cachedPendingCalls = [];
  DateTime? _lastCheckTime;
  static const Duration _cacheExpiry = Duration(seconds: 30);
  static const int _maxCallsToCheck = 10;

  /// ValueNotifier to notify UI when pending feedback status changes
  /// UI can listen to this to show/hide call buttons
  final ValueNotifier<bool> hasPendingFeedbackNotifier = ValueNotifier<bool>(false);

  /// Check if call button should be visible (no pending feedback)
  bool get canShowCallButton => !hasPendingFeedbackNotifier.value;

  /// Get all pending calls from last 10 calls
  /// Returns list of calls that need feedback
  Future<List<PendingCallEntry>> getPendingCalls({bool forceRefresh = false}) async {
    // Return cached data if still valid
    if (!forceRefresh &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _cacheExpiry) {
      return _cachedPendingCalls;
    }

    try {
      final currentUser = RealAuthService.instance.currentUser;
      final token = await RealAuthService.instance.getAuthToken();

      if (currentUser == null || token == null) {
        return [];
      }

      final assignedToId = currentUser.id;
      final url = ApiConfig.getLaravelApiUrl('call-history/$assignedToId');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        List<dynamic> historyList = [];

        if (decodedResponse is List) {
          historyList = decodedResponse;
        } else if (decodedResponse is Map) {
          if (decodedResponse['status'] == true ||
              decodedResponse['success'] == true) {
            final data = decodedResponse['data'];
            if (data is List) {
              historyList = data;
            }
          }
        }

        if (historyList.isEmpty) {
          _cachedPendingCalls = [];
          _lastCheckTime = DateTime.now();
          return [];
        }

        // Check last 10 calls for pending feedback
        final callsToCheck = historyList.take(_maxCallsToCheck).toList();
        final List<PendingCallEntry> pendingCalls = [];

        for (final call in callsToCheck) {
          if (call is! Map) continue;

          final feedback =
              call['feedback']?.toString() ??
              call['call_feedback']?.toString();

          // Check if feedback is missing or empty
          final hasFeedback =
              feedback != null &&
              feedback.isNotEmpty &&
              feedback.toLowerCase() != 'null' &&
              feedback.toLowerCase() != 'pending';

          if (!hasFeedback) {
            DateTime callTime;
            try {
              if (call['call_time'] != null) {
                callTime = DateTime.parse(call['call_time'].toString());
              } else if (call['created_at'] != null) {
                callTime = DateTime.parse(call['created_at'].toString());
              } else {
                callTime = DateTime.now();
              }
            } catch (e) {
              callTime = DateTime.now();
            }

            pendingCalls.add(PendingCallEntry(
              id: (call['id'] ?? call['call_id'] ?? '').toString(),
              driverId:
                  (call['driver_id'] ?? call['user_id'] ?? '').toString(),
              driverName:
                  (call['driver_name'] ??
                          call['user_name'] ??
                          call['name'] ??
                          'Unknown')
                      .toString(),
              phoneNumber:
                  (call['phone_number'] ??
                          call['mobile'] ??
                          call['phone'] ??
                          '')
                      .toString(),
              callTime: callTime,
              process: call['process']?.toString(),
            ));
          }
        }

        if (pendingCalls.isNotEmpty) {
          debugPrint(
            '⚠️ Found ${pendingCalls.length} calls needing feedback in last $_maxCallsToCheck calls',
          );
        }

        _cachedPendingCalls = pendingCalls;
        _lastCheckTime = DateTime.now();
        
        // Update the notifier for UI reactivity
        hasPendingFeedbackNotifier.value = pendingCalls.isNotEmpty;
        
        return pendingCalls;
      }

      // No pending calls
      hasPendingFeedbackNotifier.value = false;
      return [];
    } catch (e) {
      debugPrint('❌ Error checking pending calls: $e');
      return [];
    }
  }

  /// Get the first (most recent) pending call - for backward compatibility
  Future<PendingCallEntry?> getLastPendingCall({bool forceRefresh = false}) async {
    final pendingCalls = await getPendingCalls(forceRefresh: forceRefresh);
    return pendingCalls.isNotEmpty ? pendingCalls.first : null;
  }

  /// Check if any of the last 10 calls need feedback
  Future<bool> hasPendingFeedback({bool forceRefresh = false}) async {
    final pendingCalls = await getPendingCalls(forceRefresh: forceRefresh);
    return pendingCalls.isNotEmpty;
  }

  /// Get count of pending feedback calls
  Future<int> getPendingFeedbackCount({bool forceRefresh = false}) async {
    final pendingCalls = await getPendingCalls(forceRefresh: forceRefresh);
    return pendingCalls.length;
  }

  /// Check if the last call needs feedback (backward compatibility)
  Future<bool> hasLastCallPendingFeedback({bool forceRefresh = false}) async {
    final pendingCalls = await getPendingCalls(forceRefresh: forceRefresh);
    return pendingCalls.isNotEmpty;
  }

  /// Clear the cache (call after feedback is submitted)
  void clearCache() {
    _cachedPendingCalls = [];
    _lastCheckTime = null;
    // Reset the notifier - will be updated on next check
    hasPendingFeedbackNotifier.value = false;
  }

  /// Remove a specific call from pending list after feedback submitted
  void removePendingCall(String callId) {
    _cachedPendingCalls.removeWhere((call) => call.id == callId);
    // Update notifier based on remaining pending calls
    hasPendingFeedbackNotifier.value = _cachedPendingCalls.isNotEmpty;
  }

  /// Show toast message for pending feedback
  static void showPendingFeedbackToast(BuildContext context, {int pendingCount = 1}) {
    final message = pendingCount > 1
        ? 'Please submit feedback for $pendingCount pending calls'
        : 'Please submit previous feedback';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (pendingCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Model for a pending call entry
class PendingCallEntry {
  final String id;
  final String driverId;
  final String driverName;
  final String phoneNumber;
  final DateTime callTime;
  final String? process;

  PendingCallEntry({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.phoneNumber,
    required this.callTime,
    this.process,
  });
}
