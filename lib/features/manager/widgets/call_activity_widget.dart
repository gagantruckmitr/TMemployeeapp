import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/manager_service.dart';

class CallActivityWidget extends StatefulWidget {
  final int managerId;

  const CallActivityWidget({super.key, required this.managerId});

  @override
  State<CallActivityWidget> createState() => _CallActivityWidgetState();
}

class _CallActivityWidgetState extends State<CallActivityWidget> {
  final ManagerService _managerService = ManagerService();
  List<dynamic> _timeline = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Modern teal green color scheme
  static const Color _tealPrimary = Color(0xFF14B8A6);
  static const Color _tealLight = Color(0xFF5EEAD4);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _loadTimeline(silent: true);
      }
    });
  }

  Future<void> _loadTimeline({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final timeline = await _managerService.getCallTimeline(limit: 30);
      if (mounted) {
        setState(() {
          _timeline = timeline;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _tealPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernHeader(),
          Divider(height: 1, color: _borderColor),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _timeline.isEmpty
                ? _buildEmptyState()
                : _buildTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _tealPrimary.withValues(alpha: 0.05),
            _white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_tealPrimary, _tealLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _tealPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.timeline_rounded, color: _white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Call Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Real-time call tracking',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _timeline.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final call = _timeline[index];
        return _buildModernCallCard(call);
      },
    );
  }

  Widget _buildModernCallCard(Map<String, dynamic> call) {
    final status = call['call_status'] ?? 'pending';
    final telecallerName = call['telecaller_name'] ?? 'Unknown';
    final driverName = call['driver_name'] ?? 'Unknown Driver';
    final driverMobile = call['driver_mobile'] ?? '';
    final driverState = call['driver_state'] ?? '';
    final duration = call['call_duration'] ?? 0;
    final callTime = call['call_time'] ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'connected':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Connected';
        break;
      case 'interested':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.star_rounded;
        statusLabel = 'Interested';
        break;
      case 'not_answered':
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.phone_missed_rounded;
        statusLabel = 'Not Answered';
        break;
      case 'busy':
        statusColor = const Color(0xFFFBBF24);
        statusIcon = Icons.phone_disabled_rounded;
        statusLabel = 'Busy';
        break;
      default:
        statusColor = _tealPrimary;
        statusIcon = Icons.phone_rounded;
        statusLabel = 'Calling';
    }

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        _formatTime(callTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (duration > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          '${duration}s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Call details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Telecaller to Driver flow
                Row(
                  children: [
                    // Telecaller
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _tealPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tealPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.headset_mic_rounded,
                                  size: 16,
                                  color: _tealPrimary,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Telecaller',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              telecallerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    // Driver
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_rounded,
                                  size: 16,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Driver contact info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 16,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        driverMobile,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (driverState.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            driverState,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: _tealPrimary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading call activity...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timeline_outlined,
              size: 64,
              color: _tealPrimary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No calls yet today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Call activity will appear here',
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timeStr;
    }
  }
}
