import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tasksuite_auth_service.dart';
import '../../data/repositories/attendance_repository.dart';

// Sentinel value for copyWith to distinguish between null and not provided
const _undefined = Object();

// Attendance Repository Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

// Attendance State Provider
final attendanceStateProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
      return AttendanceNotifier(ref.read(attendanceRepositoryProvider));
    });

// Today's Attendance Summary Provider (for HR)
final todayAttendanceSummaryProvider =
    StateNotifierProvider<
      TodayAttendanceSummaryNotifier,
      TodayAttendanceSummaryState
    >((ref) {
      return TodayAttendanceSummaryNotifier(
        ref.read(attendanceRepositoryProvider),
      );
    });

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceNotifier(this._repository)
    : super(
        AttendanceState(
          checkInTime: null,
          checkOutTime: null,
          isCheckedIn: false,
          avgCheckInTime: '--:--',
          totalDaysAttended: 0,
          isLoading: false,
          errorMessage: null,
        ),
      );

  Future<String?> _getToken() async {
    return TaskSuiteAuthService.instance.getToken();
  }

  Future<void> checkIn(
    String employeeId, {
    String? selfiePath,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _repository.checkIn(
        token,
        employeeId,
        selfiePath: selfiePath,
        latitude: latitude,
        longitude: longitude,
        locationAccuracy: locationAccuracy,
        address: address,
        remark: remark,
      );

      print('Check-in response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        final checkInTime = DateTime.parse(data['checkin_time']);

        state = state.copyWith(
          checkInTime: checkInTime,
          isCheckedIn: true,
          isLoading: false,
          successMessage: 'Punch In Successfully',
        );

        await fetchAttendanceStats(employeeId);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message'] ?? 'Punch in failed',
        );
      }
    } catch (e) {
      print('Check-in error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> checkOut(
    String employeeId, {
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _repository.checkOut(
        token,
        employeeId,
        latitude: latitude,
        longitude: longitude,
        locationAccuracy: locationAccuracy,
        address: address,
        remark: remark,
      );

      print('Check-out response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        final checkOutTime = DateTime.parse(data['checkout_time']);

        state = state.copyWith(
          checkOutTime: checkOutTime,
          isCheckedIn: false,
          isLoading: false,
          successMessage: 'Punch Out Successfully',
        );

        // Refresh attendance stats after punch-out
        await fetchAttendanceStats(employeeId);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message'] ?? 'Punch out failed',
        );
      }
    } catch (e) {
      print('Check-out error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  Future<void> fetchTodayAttendance(String employeeId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('No token found for fetching attendance');
        return;
      }

      print('Fetching today attendance for: $employeeId');
      final response = await _repository.getTodayAttendance(token, employeeId);
      print('Today attendance response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        DateTime? checkInTime;
        DateTime? checkOutTime;
        bool isCheckedIn = false;
        final now = DateTime.now();

        if (data['checkin_time'] != null) {
          checkInTime = DateTime.parse(data['checkin_time']);

          // Only consider user as checked in if:
          // 1. There's no checkout time AND
          // 2. The check-in is from today (same day)
          final isCheckInToday =
              checkInTime.year == now.year &&
              checkInTime.month == now.month &&
              checkInTime.day == now.day;

          isCheckedIn = data['checkout_time'] == null && isCheckInToday;
          print(
            'Check-in time: $checkInTime, Is from today: $isCheckInToday, Is checked in: $isCheckedIn',
          );

          // If check-in is not from today, reset the times
          if (!isCheckInToday) {
            print(
              'Check-in is from a previous day, resetting state for new day',
            );
            checkInTime = null;
            checkOutTime = null;
          }
        }

        if (data['checkout_time'] != null && checkInTime != null) {
          checkOutTime = DateTime.parse(data['checkout_time']);
          print('Check-out time: $checkOutTime');
        }

        state = state.copyWith(
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
          isCheckedIn: isCheckedIn,
        );

        print(
          'Updated state - CheckIn: ${state.checkInTimeFormatted}, CheckOut: ${state.checkOutTimeFormatted}, IsCheckedIn: ${state.isCheckedIn}',
        );
      } else {
        print('No attendance data found for today');
      }
    } catch (e) {
      // Silently fail - no attendance for today
      print('Error fetching today attendance: $e');
    }
  }

  Future<void> fetchAttendanceStats(String employeeId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return;
      }

      final response = await _repository.getAttendanceHistory(
        token,
        employeeId,
      );

      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['data'] != null) {
        final List<dynamic> attendancesJson = response['data']['data'];

        if (attendancesJson.isEmpty) {
          return;
        }

        // Calculate average check-in time and current month attendance
        int totalMinutes = 0;
        int validCount = 0;
        int currentMonthCount = 0;
        final now = DateTime.now();

        for (var record in attendancesJson) {
          final checkinTime = record['checkin_time'];
          if (checkinTime != null) {
            try {
              final dateTime = DateTime.parse(checkinTime);

              // Count for current month
              if (dateTime.year == now.year && dateTime.month == now.month) {
                currentMonthCount++;
              }

              // Convert to minutes since midnight for average calculation
              final minutesSinceMidnight = dateTime.hour * 60 + dateTime.minute;
              totalMinutes += minutesSinceMidnight;
              validCount++;
            } catch (e) {
              print('Error parsing check-in time: $e');
            }
          }
        }

        String avgCheckInTime = '--:--';
        if (validCount > 0) {
          final avgMinutes = (totalMinutes / validCount).round();
          final avgHour = avgMinutes ~/ 60;
          final avgMinute = avgMinutes % 60;

          // Format to 12-hour time
          final displayHour = avgHour > 12
              ? avgHour - 12
              : (avgHour == 0 ? 12 : avgHour);
          final period = avgHour >= 12 ? 'PM' : 'AM';
          avgCheckInTime =
              '${displayHour.toString().padLeft(2, '0')}:${avgMinute.toString().padLeft(2, '0')} $period';
        }

        state = state.copyWith(
          avgCheckInTime: avgCheckInTime,
          totalDaysAttended: currentMonthCount,
        );
      }
    } catch (e) {
      print('Error fetching attendance stats: $e');
    }
  }

  void reset() {
    state = AttendanceState(
      checkInTime: null,
      checkOutTime: null,
      isCheckedIn: false,
      avgCheckInTime: state.avgCheckInTime,
      totalDaysAttended: state.totalDaysAttended,
      isLoading: false,
      errorMessage: null,
    );
  }
}

// Attendance State
class AttendanceState {
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isCheckedIn;
  final String avgCheckInTime;
  final int totalDaysAttended;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AttendanceState({
    required this.checkInTime,
    required this.checkOutTime,
    required this.isCheckedIn,
    required this.avgCheckInTime,
    required this.totalDaysAttended,
    required this.isLoading,
    this.errorMessage,
    this.successMessage,
  });

  AttendanceState copyWith({
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isCheckedIn,
    String? avgCheckInTime,
    int? totalDaysAttended,
    bool? isLoading,
    Object? errorMessage = _undefined,
    Object? successMessage = _undefined,
  }) {
    return AttendanceState(
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      avgCheckInTime: avgCheckInTime ?? this.avgCheckInTime,
      totalDaysAttended: totalDaysAttended ?? this.totalDaysAttended,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _undefined
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: successMessage == _undefined
          ? this.successMessage
          : successMessage as String?,
    );
  }

  String get checkInTimeFormatted {
    if (checkInTime == null) return '--:--';
    final hour = checkInTime!.hour > 12
        ? checkInTime!.hour - 12
        : checkInTime!.hour;
    final period = checkInTime!.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')} $period';
  }

  String get checkOutTimeFormatted {
    if (checkOutTime == null) return '--:--';
    final hour = checkOutTime!.hour > 12
        ? checkOutTime!.hour - 12
        : checkOutTime!.hour;
    final period = checkOutTime!.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')} $period';
  }
}

// Today's Attendance Summary Notifier (for HR)
class TodayAttendanceSummaryNotifier
    extends StateNotifier<TodayAttendanceSummaryState> {
  final AttendanceRepository _repository;

  TodayAttendanceSummaryNotifier(this._repository)
    : super(
        TodayAttendanceSummaryState(
          totalEmployees: 0,
          presentCount: 0,
          absentCount: 0,
          isLoading: false,
        ),
      );

  Future<String?> _getToken() async {
    return TaskSuiteAuthService.instance.getToken();
  }

  Future<void> fetchTodaySummary() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('Fetching today attendance summary...');
      final response = await _repository.getTodayAttendanceSummary(token);
      print('Summary response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final totalEmployees = data['total_employees'] ?? 0;
        final presentCount = data['present_count'] ?? 0;
        final absentCount = data['absent_count'] ?? 0;

        print(
          'Parsed data - Total: $totalEmployees, Present: $presentCount, Absent: $absentCount',
        );

        state = state.copyWith(
          totalEmployees: totalEmployees,
          presentCount: presentCount,
          absentCount: absentCount,
          isLoading: false,
        );
      } else {
        print('API returned success: false or no data');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error fetching today summary: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

// Today's Attendance Summary State
class TodayAttendanceSummaryState {
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final bool isLoading;

  TodayAttendanceSummaryState({
    required this.totalEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.isLoading,
  });

  TodayAttendanceSummaryState copyWith({
    int? totalEmployees,
    int? presentCount,
    int? absentCount,
    bool? isLoading,
  }) {
    return TodayAttendanceSummaryState(
      totalEmployees: totalEmployees ?? this.totalEmployees,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
