import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../core/config/api_config.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/break_service.dart';
import '../../../models/leave_models.dart';
import '../../../routes/app_router.dart';
import '../widgets/break_status_popup.dart';
import '../widgets/apply_leave_dialog.dart';
import 'leave_requests_screen.dart';
import 'break_history_screen.dart';

/// Apple-style Leave & Break Management Screen
class LeaveBreakManagementScreen extends StatefulWidget {
  const LeaveBreakManagementScreen({super.key});

  @override
  State<LeaveBreakManagementScreen> createState() =>
      _LeaveBreakManagementScreenState();
}

class _LeaveBreakManagementScreenState
    extends State<LeaveBreakManagementScreen> {
  // iOS System Colors
  static const Color _systemBlue = Color(0xFF007AFF);
  static const Color _systemGreen = Color(0xFF34C759);
  static const Color _systemOrange = Color(0xFFFF9500);
  static const Color _systemRed = Color(0xFFFF3B30);
  static const Color _systemPurple = Color(0xFFAF52DE);
  static const Color _systemTeal = Color(0xFF5AC8FA);
  static const Color _systemGray = Color(0xFF8E8E93);
  static const Color _labelPrimary = Color(0xFF000000);
  static const Color _labelTertiary = Color(0xFF8E8E93);
  static const Color _separatorColor = Color(0xFFE5E5EA);
  static const Color _groupedBackground = Color(0xFFF2F2F7);

  bool _isLoading = true;
  bool _isOnBreak = false;
  BreakLog? _activeBreak;
  Map<String, dynamic>? _myStatus;
  Timer? _timer;
  int? _telecallerId;
  String? _telecallerName;

  @override
  void initState() {
    super.initState();
    _initTelecallerId();
  }

  void _initTelecallerId() {
    final user = RealAuthService.instance.currentUser;
    if (user != null) {
      _telecallerId = int.tryParse(user.id);
      _telecallerName = user.name; // Assuming user has a name field
      _loadData();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isOnBreak && mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_telecallerId == null) return;

    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadActiveBreak(), _loadMyStatus()]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadActiveBreak() async {
    if (_telecallerId == null) return;

    try {
      final logs = await BreakService.getBreakLogs(telecallerId: _telecallerId);

      // Sort logs by ID descending to get the latest first
      logs.sort((a, b) => b.id.compareTo(a.id));

      if (logs.isEmpty) {
        if (mounted) {
          setState(() {
            _activeBreak = null;
            _isOnBreak = false;
          });
        }
        return;
      }

      // Check the latest log
      final latestLog = logs.first;

      // If the latest log is NOT completed, we are on break.
      // If the latest log IS completed, we are NOT on break (even if older logs are pending).
      final isOnBreak = latestLog.status != 'completed';

      if (mounted) {
        setState(() {
          _activeBreak = isOnBreak ? latestLog : null;
          _isOnBreak = isOnBreak;
        });
      }
    } catch (e) {
      print('Error loading active break: $e');
      // Silent fail
    }
  }

  Future<void> _loadMyStatus() async {
    if (_telecallerId == null) return;

    try {
      final uri =
          Uri.parse(
            '${ApiConfig.baseUrl}/simple_leave_management_api.php',
          ).replace(
            queryParameters: {
              'action': 'get_my_status',
              'telecaller_id': _telecallerId.toString(),
            },
          );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _myStatus = data['data'];
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _navigateToSettings() {
    context.push(AppRouter.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavigationBar(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _separatorColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios,
                    color: _systemBlue,
                    size: 20,
                  ),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: _systemBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Title
          Expanded(
            child: Center(
              child: Text(
                'Leave & Break',
                style: TextStyle(
                  color: _labelPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          // Settings button
          GestureDetector(
            onTap: _navigateToSettings,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.settings_outlined,
                color: _systemBlue,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card Skeleton
            _ShimmerBox(height: 120, width: double.infinity, borderRadius: 16),
            const SizedBox(height: 32),

            // Quick Break Header Skeleton
            _ShimmerBox(height: 20, width: 100, borderRadius: 4),
            const SizedBox(height: 12),

            // Grid Skeleton
            Container(
              decoration: BoxDecoration(
                color: _groupedBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerBox(
                          height: 60,
                          width: double.infinity,
                          borderRadius: 0,
                          color: Colors.transparent,
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white),
                      Expanded(
                        child: _ShimmerBox(
                          height: 60,
                          width: double.infinity,
                          borderRadius: 0,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 1, color: Colors.white),
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerBox(
                          height: 60,
                          width: double.infinity,
                          borderRadius: 0,
                          color: Colors.transparent,
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white),
                      Expanded(
                        child: _ShimmerBox(
                          height: 60,
                          width: double.infinity,
                          borderRadius: 0,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 1, color: Colors.white),
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerBox(
                          height: 60,
                          width: double.infinity,
                          borderRadius: 0,
                          color: Colors.transparent,
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white),
                      Expanded(
                        child: _ShimmerBox(
                          height: 60,
                          width: double.infinity,
                          borderRadius: 0,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ShimmerBox(height: 50, width: double.infinity, borderRadius: 12),

            const SizedBox(height: 32),

            // Leave Management Header Skeleton
            _ShimmerBox(height: 20, width: 150, borderRadius: 4),
            const SizedBox(height: 12),

            // Leave Management Cells Skeleton
            Container(
              decoration: BoxDecoration(
                color: _groupedBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ShimmerBox(
                    height: 56,
                    width: double.infinity,
                    borderRadius: 0,
                    color: Colors.transparent,
                  ),
                  Container(height: 1, color: Colors.white),
                  _ShimmerBox(
                    height: 56,
                    width: double.infinity,
                    borderRadius: 0,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildStatusSection(),
          const SizedBox(height: 32),
          if (_isOnBreak && _activeBreak != null) ...[
            _buildActiveBreakSection(),
            const SizedBox(height: 32),
          ],
          _buildBreakSection(),
          const SizedBox(height: 32),
          _buildLeaveSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: _labelTertiary,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = _myStatus?['current_status'] ?? 'offline';
    final isOnline = status == 'online';
    final onlineDuration =
        _myStatus?['online_duration_formatted'] ?? '00:00:00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _groupedBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isOnline ? _systemGreen : _systemGray).withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: isOnline ? _systemGreen : _systemGray,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Expanded(
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         isOnline ? 'Online' : 'Offline',
            //         style: TextStyle(
            //           fontSize: 17,
            //           fontWeight: FontWeight.w600,
            //           color: _labelPrimary,
            //           letterSpacing: -0.4,
            //         ),
            //       ),
            //       const SizedBox(height: 2),
            //       Text(
            //         'Session: $onlineDuration',
            //         style: TextStyle(
            //           fontSize: 15,
            //           fontWeight: FontWeight.w400,
            //           color: _labelTertiary,
            //           letterSpacing: -0.2,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline ? _systemGreen : _systemGray,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBreakSection() {
    final breakType = _activeBreak!.breakType;
    final startTime = _activeBreak!.startTime;
    final duration = DateTime.now().difference(startTime);
    final durationStr = _formatDuration(duration);
    final breakInfo = _getBreakInfo(breakType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: breakInfo.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(breakInfo.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breakInfo.label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'In progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  durationStr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: _endBreak,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'End Break',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: breakInfo.color,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Break'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _groupedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildBreakRow(
                  _BreakType(
                    'Lunch Break',
                    'lunch_break',
                    Icons.restaurant_rounded,
                    _systemGreen,
                  ),
                  _BreakType(
                    'Tea Break',
                    'tea_break',
                    Icons.local_cafe_rounded,
                    _systemOrange,
                  ),
                ),
                Divider(
                  height: 1,
                  color: _separatorColor,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildBreakRow(
                  _BreakType(
                    'Rest Break',
                    'rest_break',
                    Icons.weekend_rounded,
                    _systemBlue,
                  ),
                  _BreakType(
                    'Training',
                    'training_break',
                    Icons.school_rounded,
                    _systemPurple,
                  ),
                ),
                Divider(
                  height: 1,
                  color: _separatorColor,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildBreakRow(
                  _BreakType(
                    'Meeting',
                    'meeting_break',
                    Icons.groups_rounded,
                    _systemRed,
                  ),
                  _BreakType(
                    'Personal',
                    'personal_break',
                    Icons.person_rounded,
                    _systemTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _groupedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildLeaveCell(
              icon: Icons.history_rounded,
              title: 'View Break History',
              color: _systemOrange,
              onTap: _navigateToBreakHistory,
              showChevron: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakRow(_BreakType left, _BreakType right) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _buildBreakCell(left)),
          VerticalDivider(width: 1, color: _separatorColor),
          Expanded(child: _buildBreakCell(right)),
        ],
      ),
    );
  }

  Widget _buildBreakCell(_BreakType breakType) {
    final isActive = _isOnBreak && _activeBreak?.breakType == breakType.type;
    final isDisabled = _isOnBreak && !isActive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => _startBreak(breakType.type),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: breakType.color.withValues(
                    alpha: isDisabled ? 0.08 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  breakType.icon,
                  color: isDisabled ? _labelTertiary : breakType.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  breakType.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDisabled ? _labelTertiary : _labelPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: breakType.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Leave Management'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _groupedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildLeaveCell(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Apply for Leave',
                  color: _systemBlue,
                  onTap: _showApplyLeaveDialog,
                ),
                Divider(height: 1, color: _separatorColor, indent: 56),
                _buildLeaveCell(
                  icon: Icons.history_rounded,
                  title: 'Leave History',
                  color: _systemPurple,
                  onTap: _navigateToLeaveRequests,
                  showChevron: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCell({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool showChevron = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: _labelPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: _labelTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  _BreakInfo _getBreakInfo(String breakType) {
    switch (breakType) {
      case 'lunch_break':
        return _BreakInfo(
          'Lunch Break',
          Icons.restaurant_rounded,
          _systemGreen,
        );
      case 'tea_break':
        return _BreakInfo('Tea Break', Icons.local_cafe_rounded, _systemOrange);
      case 'rest_break':
        return _BreakInfo('Rest Break', Icons.weekend_rounded, _systemBlue);
      case 'training_break':
        return _BreakInfo(
          'Training Break',
          Icons.school_rounded,
          _systemPurple,
        );
      case 'meeting_break':
        return _BreakInfo('Meeting Break', Icons.groups_rounded, _systemRed);
      default:
        return _BreakInfo('Personal Break', Icons.person_rounded, _systemTeal);
    }
  }

  Future<void> _startBreak(String breakType) async {
    if (_telecallerId == null || !mounted) return;

    HapticFeedback.mediumImpact();

    try {
      await BreakService.startBreak(
        callerId: _telecallerId!,
        telecallerName: _telecallerName ?? 'Unknown',
        breakType: breakType,
      );

      if (mounted) {
        await _loadData();
        _showBreakPopup(breakType);
      }
    } catch (e) {
      if (mounted) _showError('Error starting break: $e');
    }
  }

  void _showBreakPopup(String breakType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: BreakStatusPopup(
          breakType: breakType,
          startTime: DateTime.now(),
          onEndBreak: () {
            Navigator.of(ctx).pop();
            _endBreak();
          },
        ),
      ),
    );
  }

  Future<void> _endBreak() async {
    if (_activeBreak == null || !mounted) return;

    HapticFeedback.mediumImpact();

    try {
      await BreakService.endBreak(
        id: _activeBreak!.id,
        callerId: _activeBreak!.callerId,
        telecallerName: _activeBreak!.telecallerName,
        breakType: _activeBreak!.breakType,
      );

      if (mounted) {
        _showSuccess('Break ended');
        await _loadData();
      }
    } catch (e) {
      if (mounted) _showError('Error ending break: $e');
    }
  }

  void _showApplyLeaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ApplyLeaveDialog(
        onSubmit: (leaveType, startDate, endDate, reason) async {
          final currentUser = RealAuthService.instance.currentUser;
          if (currentUser == null) return;

          final totalDays = endDate.difference(startDate).inDays + 1;

          // Optimistic UI: Close dialog immediately and show success
          Navigator.pop(ctx);
          HapticFeedback.mediumImpact();
          _showSuccess('Leave request submitted!');

          // Fire-and-forget API call in background
          ApiService.applyLeave(
                telecallerId: currentUser.id,
                leaveType: leaveType.displayName,
                startDate: startDate,
                endDate: endDate,
                totalDays: totalDays,
                reason: reason,
              )
              .then((success) {
                if (!success && mounted) {
                  // Show error only if API fails
                  _showError('Failed to save leave request. Please try again.');
                }
              })
              .catchError((e) {
                if (mounted) {
                  _showError('Network error. Please check your connection.');
                }
              });
        },
      ),
    );
  }

  void _navigateToBreakHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BreakHistoryScreen()),
    );
  }

  void _navigateToLeaveRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaveRequestsScreen()),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _systemGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.color,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                0.0,
                0.5 + 0.5 * _animation.value,
                1.0,
              ].map((x) => x.clamp(0.0, 1.0)).toList(),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              transform: GradientRotation(_animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _BreakType {
  final String label;
  final String type;
  final IconData icon;
  final Color color;

  _BreakType(this.label, this.type, this.icon, this.color);
}

class _BreakInfo {
  final String label;
  final IconData icon;
  final Color color;

  _BreakInfo(this.label, this.icon, this.color);
}
