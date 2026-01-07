import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../shared/widgets/attendance_history_skeleton.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/attendance_history_provider.dart';
import 'attendance_detail_page.dart';

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  final String? employeeId;
  final String? employeeName;

  const AttendanceHistoryPage({super.key, this.employeeId, this.employeeName});

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Get employee ID (prioritize passed ID, then fallback to current user)
      String? employeeId = widget.employeeId;

      if (employeeId == null) {
        employeeId = await _getEmployeeId();
      }

      if (employeeId != null && employeeId.isNotEmpty) {
        ref
            .read(attendanceHistoryProvider.notifier)
            .fetchAttendanceHistory(employeeId);
      }
    });
  }

  Future<String?> _getEmployeeId() async {
    // Try to get employee ID from current user
    final user = RealAuthService.instance.currentUser;
    if (user != null && user.employeeDetails?.empId != null) {
      return user.employeeDetails!.empId;
    }

    // Fallback to user id
    if (user != null) {
      return user.id;
    }

    // Try from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? prefs.getString('emp_id');
  }

  Future<void> _refreshData() async {
    String? employeeId = widget.employeeId;

    if (employeeId == null) {
      employeeId = await _getEmployeeId();
    }

    if (employeeId != null && employeeId.isNotEmpty) {
      await ref
          .read(attendanceHistoryProvider.notifier)
          .fetchAttendanceHistory(employeeId);
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accentBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryProvider);

    // Filter attendances by selected month
    List<AttendanceModel> filteredAttendances = [];
    if (historyState is AttendanceHistoryLoaded) {
      filteredAttendances = historyState.attendances.where((attendance) {
        try {
          final date = DateTime.parse(attendance.date);
          return date.year == _selectedMonth.year &&
              date.month == _selectedMonth.month;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Check for today's attendance from local state
    // ONLY if we are viewing the current user (no specific employeeId passed)
    if (widget.employeeId == null) {
      final todayState = ref.watch(attendanceStateProvider);
      final now = DateTime.now();

      // Only check if we are viewing the current month
      if (_selectedMonth.year == now.year &&
          _selectedMonth.month == now.month) {
        if (todayState.checkInTime != null) {
          // Check if today is already in the list
          final todayExists = filteredAttendances.any((attendance) {
            try {
              final date = DateTime.parse(attendance.date);
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            } catch (e) {
              return false;
            }
          });

          if (!todayExists) {
            // Calculate work hours for today if checked out
            String? calculatedWorkHours;
            if (todayState.checkOutTime != null) {
              final workDuration = todayState.checkOutTime!.difference(
                todayState.checkInTime!,
              );
              final totalHours = workDuration.inMinutes / 60.0;
              calculatedWorkHours = totalHours.toStringAsFixed(2);
            }

            final todayDateKey =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

            // Add today's attendance to the top of the list
            filteredAttendances.insert(
              0,
              AttendanceModel(
                id: 0, // Temporary ID
                employeeId: 'current',
                date: todayDateKey,
                checkinTime: todayState.checkInTime!.toIso8601String(),
                checkoutTime: todayState.checkOutTime?.toIso8601String(),
                workHours: calculatedWorkHours,
                attendanceStatus: 'Present',
                isManual: false,
                remark: null,
              ),
            );
          }
        }
      }
    }

    // Format month name
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName =
        '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.employeeName != null
                  ? '${widget.employeeName}'
                  : 'Attendance History',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              monthName,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: AppTheme.accentBlue),
            onPressed: () => _selectMonth(context),
            tooltip: 'Filter by Month',
          ),
        ],
      ),
      body: historyState is AttendanceHistoryLoading
          ? const AttendanceHistorySkeleton()
          : historyState is AttendanceHistoryLoaded
          ? filteredAttendances.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records for $monthName',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: AppTheme.accentBlue,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = filteredAttendances[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceDetailPage(
                                  attendanceId: attendance.id.toString(),
                                  employeeId: attendance.employeeId,
                                ),
                              ),
                            );
                          },
                          child: _AttendanceCard(attendance: attendance),
                        );
                      },
                    ),
                  )
          : historyState is AttendanceHistoryError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${historyState.message}',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      String? employeeId = widget.employeeId;
                      if (employeeId == null) {
                        employeeId = await _getEmployeeId();
                      }
                      if (employeeId != null && employeeId.isNotEmpty) {
                        ref
                            .read(attendanceHistoryProvider.notifier)
                            .fetchAttendanceHistory(employeeId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;

  const _AttendanceCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final status = attendance.attendanceStatus.toLowerCase();
    final isAbsent = status == 'absent';
    final isOnLeave = status == 'on_leave' || status == 'on leave';
    final isSimpleStatus = isAbsent || isOnLeave;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSimpleStatus
            ? Border.all(
                color: attendance.statusColor.withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                attendance.formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: attendance.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attendance.attendanceStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: attendance.statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (isSimpleStatus) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: attendance.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: attendance.statusColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOnLeave ? Icons.beach_access : Icons.event_busy,
                    color: attendance.statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isOnLeave ? 'On Leave' : 'Absent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: attendance.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeInfo(
                    icon: Icons.login_rounded,
                    label: 'Check In',
                    time: attendance.checkInTimeFormatted,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimeInfo(
                    icon: Icons.logout_rounded,
                    label: 'Check Out',
                    time: attendance.checkOutTimeFormatted,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            if (attendance.workHours != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Working: ${attendance.workHoursFormatted}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attendance.hasOvertime) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Overtime: ${attendance.overtimeFormatted}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
