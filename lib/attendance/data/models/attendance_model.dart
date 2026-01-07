import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_utils.dart';

class AttendanceModel {
  final int id;
  final String employeeId;
  final String date;
  final String? checkinTime;
  final String? checkoutTime;
  final String? workHours;
  final String attendanceStatus;
  final bool isManual;
  final String? remark;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    this.checkinTime,
    this.checkoutTime,
    this.workHours,
    required this.attendanceStatus,
    required this.isManual,
    this.remark,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      employeeId: json['employee_id']?.toString() ?? '',
      date: json['date'] ?? '',
      checkinTime: json['checkin_time'],
      checkoutTime: json['checkout_time'],
      workHours: json['work_hours']?.toString(),
      attendanceStatus: json['attendance_status'] ?? 'Present',
      isManual: json['is_manual'] == true || json['is_manual'] == 1,
      remark: json['remark'],
    );
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String get checkInTimeFormatted {
    if (checkinTime == null || checkinTime!.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(checkinTime!);
      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '--:--';
    }
  }

  String get checkOutTimeFormatted {
    if (checkoutTime == null) return '--:--';
    try {
      final dateTime = DateTime.parse(checkoutTime!);
      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '--:--';
    }
  }

  /// Formats work hours from decimal (e.g., 8.43) to HH:MM:SS format
  String get workHoursFormatted {
    return TimeUtils.formatWorkHours(workHours);
  }

  /// Calculates overtime based on office hours (9:30 AM to 6:30 PM = 9 hours)
  /// Returns overtime in hours as double, 0 if no overtime
  double get overtimeHours {
    if (checkoutTime == null || checkinTime == null || checkinTime!.isEmpty)
      return 0.0;

    try {
      final checkIn = DateTime.parse(checkinTime!);
      final checkOut = DateTime.parse(checkoutTime!);

      // Calculate total work duration
      final workDuration = checkOut.difference(checkIn);
      final totalHours = workDuration.inMinutes / 60.0;

      // Standard office hours: 9 hours (9:30 AM to 6:30 PM)
      const standardHours = 9.0;

      // Calculate overtime (anything beyond 9 hours)
      final overtime = totalHours - standardHours;
      return overtime > 0 ? overtime : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Formats overtime hours to HH:MM format
  String get overtimeFormatted {
    final overtime = overtimeHours;
    if (overtime <= 0) return "0:00";

    final hours = overtime.floor();
    final minutes = ((overtime % 1) * 60).round();

    return "${hours}:${minutes.toString().padLeft(2, '0')}";
  }

  /// Checks if employee worked overtime
  bool get hasOvertime {
    return overtimeHours > 0;
  }

  Color get statusColor {
    final status = attendanceStatus.toLowerCase();
    switch (status) {
      case 'present':
        return AppTheme.primaryGreen;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'half day':
        return Colors.amber;
      case 'on_leave':
      case 'on leave':
        return Colors.blue;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// Creates an absent record for a given date
  static AttendanceModel createAbsentRecord(String dateKey) {
    return AttendanceModel(
      id: -1, // Negative ID to indicate it's a generated record
      employeeId: '',
      date: dateKey,
      checkinTime: null,
      checkoutTime: null,
      workHours: null,
      attendanceStatus: 'Absent',
      isManual: false,
      remark: 'No attendance marked',
    );
  }
}
