import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';

/// Service to check for pending match-making feedback before allowing new calls
/// Ensures telecallers submit feedback for previous match-making calls before making new ones
class MatchMakingFeedbackGuardService {
  static MatchMakingFeedbackGuardService? _instance;
  MatchMakingFeedbackGuardService._();

  static MatchMakingFeedbackGuardService get instance {
    _instance ??= MatchMakingFeedbackGuardService._();
    return _instance!;
  }

  // Cache for pending feedback check
  PendingMatchMakingEntry? _cachedLastPendingCall;
  DateTime? _lastCheckTime;
  static const Duration _cacheExpiry = Duration(seconds: 30);

  /// Check if the last match-making call has pending feedback
  /// Returns the last match-making entry if it needs feedback, null otherwise
  Future<PendingMatchMakingEntry?> getLastPendingMatchMakingCall({
    bool forceRefresh = false,
  }) async {
    // Return cached data if still valid
    if (!forceRefresh &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _cacheExpiry) {
      return _cachedLastPendingCall;
    }

    try {
      final currentUser = RealAuthService.instance.currentUser;
      final token = await RealAuthService.instance.getAuthToken();

      if (currentUser == null || token == null) {
        return null;
      }

      final assignedToId = currentUser.id;
      final url =
          'https://truckmitr.com/api/telehead/match-making-history/$assignedToId';

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
          _cachedLastPendingCall = null;
          _lastCheckTime = DateTime.now();
          return null;
        }

        // Get the most recent call (first item - API returns sorted by newest)
        final lastCall = historyList.first;
        if (lastCall is! Map) {
          _cachedLastPendingCall = null;
          _lastCheckTime = DateTime.now();
          return null;
        }

        final feedback =
            lastCall['feedback']?.toString() ??
            lastCall['call_feedback']?.toString();

        // Check if feedback is missing or empty
        final hasFeedback =
            feedback != null &&
            feedback.isNotEmpty &&
            feedback.toLowerCase() != 'null' &&
            feedback.toLowerCase() != 'pending';

        if (!hasFeedback) {
          DateTime callTime;
          try {
            if (lastCall['call_time'] != null) {
              callTime = DateTime.parse(lastCall['call_time'].toString());
            } else if (lastCall['created_at'] != null) {
              callTime = DateTime.parse(lastCall['created_at'].toString());
            } else {
              callTime = DateTime.now();
            }
          } catch (e) {
            callTime = DateTime.now();
          }

          debugPrint(
            '⚠️ Last match-making call needs feedback: id=${lastCall['match_id']}, feedback=$feedback',
          );

          _cachedLastPendingCall = PendingMatchMakingEntry(
            matchId: (lastCall['match_id'] ?? lastCall['id'] ?? '').toString(),
            driverId:
                (lastCall['driver_id'] ??
                        lastCall['user_id_driver'] ??
                        lastCall['user_id'] ??
                        '')
                    .toString(),
            driverName:
                (lastCall['driver_name'] ??
                        lastCall['name'] ??
                        'Unknown Driver')
                    .toString(),
            driverPhone:
                (lastCall['driver_phone'] ??
                        lastCall['number'] ??
                        lastCall['phone'] ??
                        '')
                    .toString(),
            transporterId:
                (lastCall['transporter_id'] ??
                        lastCall['user_id_transporter'] ??
                        '')
                    .toString(),
            transporterName:
                (lastCall['transporter_name'] ??
                        'Unknown Transporter')
                    .toString(),
            transporterPhone:
                (lastCall['transporter_phone'] ??
                        lastCall['exten'] ??
                        '')
                    .toString(),
            jobId: lastCall['job_id']?.toString(),
            callTime: callTime,
          );
          _lastCheckTime = DateTime.now();
          return _cachedLastPendingCall;
        }

        _cachedLastPendingCall = null;
        _lastCheckTime = DateTime.now();
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking pending match-making calls: $e');
      return null;
    }
  }

  /// Check if the last match-making call needs feedback
  Future<bool> hasLastMatchMakingCallPendingFeedback({
    bool forceRefresh = false,
  }) async {
    final lastPending =
        await getLastPendingMatchMakingCall(forceRefresh: forceRefresh);
    return lastPending != null;
  }

  /// Clear the cache (call after feedback is submitted)
  void clearCache() {
    _cachedLastPendingCall = null;
    _lastCheckTime = null;
  }

  /// Show toast message for pending match-making feedback
  static void showPendingMatchMakingFeedbackToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please submit match-making feedback',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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

/// Model for a pending match-making entry
class PendingMatchMakingEntry {
  final String matchId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String transporterId;
  final String transporterName;
  final String transporterPhone;
  final String? jobId;
  final DateTime callTime;

  PendingMatchMakingEntry({
    required this.matchId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.transporterId,
    required this.transporterName,
    required this.transporterPhone,
    this.jobId,
    required this.callTime,
  });
}
