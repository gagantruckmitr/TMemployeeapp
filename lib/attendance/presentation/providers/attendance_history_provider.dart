import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import 'attendance_provider.dart';

final attendanceHistoryProvider =
    StateNotifierProvider<AttendanceHistoryNotifier, AttendanceHistoryState>((
      ref,
    ) {
      return AttendanceHistoryNotifier(ref.read(attendanceRepositoryProvider));
    });

class AttendanceHistoryNotifier extends StateNotifier<AttendanceHistoryState> {
  final AttendanceRepository _repository;

  AttendanceHistoryNotifier(this._repository)
    : super(const AttendanceHistoryState.initial());

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchAttendanceHistory(String employeeId) async {
    state = const AttendanceHistoryState.loading();

    try {
      final token = await _getToken();
      if (token == null) {
        state = const AttendanceHistoryState.error(
          'No authentication token found',
        );
        return;
      }

      final response = await _repository.getAttendanceHistory(
        token,
        employeeId,
      );

      List<AttendanceModel> markedAttendances = [];
      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['data'] != null) {
        final List<dynamic> attendancesJson = response['data']['data'];
        markedAttendances = attendancesJson
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      }

      // Generate complete attendance history with smart Sunday handling
      final completeAttendances = _generateSmartAttendanceHistory(
        markedAttendances,
      );

      state = AttendanceHistoryState.loaded(attendances: completeAttendances);
    } catch (e) {
      print('Error fetching attendance history: $e');
      state = AttendanceHistoryState.error(e.toString());
    }
  }

  List<AttendanceModel> _generateSmartAttendanceHistory(
    List<AttendanceModel> markedAttendances,
  ) {
    final now = DateTime.now();
    final List<AttendanceModel> completeHistory = [];

    // Create a map of marked attendance dates for quick lookup
    final Map<String, AttendanceModel> markedDatesMap = {};
    for (var attendance in markedAttendances) {
      final dateKey = attendance.date.split(' ')[0]; // Get YYYY-MM-DD part
      markedDatesMap[dateKey] = attendance;
    }

    print(
      'DEBUG ATTENDANCE: Generating smart attendance history for last 30 days',
    );
    print(
      'DEBUG ATTENDANCE: Marked attendance dates: ${markedDatesMap.keys.toList()}',
    );

    // Generate last 30 days with smart Sunday logic
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayName = _getDayName(date.weekday);

      if (markedDatesMap.containsKey(dateKey)) {
        // User marked attendance - always show it (including Sunday)
        print(
          'DEBUG ATTENDANCE: Adding marked attendance for: $dateKey ($dayName) - ${markedDatesMap[dateKey]!.attendanceStatus}',
        );
        completeHistory.add(markedDatesMap[dateKey]!);
      } else if (date.weekday == 7) {
        // Sunday with no marked attendance - skip it completely
        print(
          'DEBUG ATTENDANCE: Skipping Sunday (no attendance marked): $dateKey',
        );
        continue;
      } else {
        // Monday-Saturday with no marked attendance - show as absent
        print(
          'DEBUG ATTENDANCE: Creating absent record for: $dateKey ($dayName)',
        );
        completeHistory.add(AttendanceModel.createAbsentRecord(dateKey));
      }
    }

    // Sort by date (newest first)
    completeHistory.sort((a, b) {
      final dateA = DateTime.parse(a.date.split(' ')[0]);
      final dateB = DateTime.parse(b.date.split(' ')[0]);
      return dateB.compareTo(dateA);
    });

    final presentCount = completeHistory
        .where((a) => a.attendanceStatus != 'Absent')
        .length;
    final absentCount = completeHistory
        .where((a) => a.attendanceStatus == 'Absent')
        .length;

    print(
      'DEBUG ATTENDANCE: Generated ${completeHistory.length} total records',
    );
    print('DEBUG ATTENDANCE: Present: $presentCount, Absent: $absentCount');

    return completeHistory;
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}

sealed class AttendanceHistoryState {
  const AttendanceHistoryState();
  const factory AttendanceHistoryState.initial() = AttendanceHistoryInitial;
  const factory AttendanceHistoryState.loading() = AttendanceHistoryLoading;
  const factory AttendanceHistoryState.loaded({
    required List<AttendanceModel> attendances,
  }) = AttendanceHistoryLoaded;
  const factory AttendanceHistoryState.error(String message) =
      AttendanceHistoryError;
}

class AttendanceHistoryInitial extends AttendanceHistoryState {
  const AttendanceHistoryInitial();
}

class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading();
}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceModel> attendances;
  const AttendanceHistoryLoaded({required this.attendances});
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;
  const AttendanceHistoryError(this.message);
}
