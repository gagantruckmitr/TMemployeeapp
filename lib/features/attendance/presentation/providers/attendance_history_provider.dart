import 'package:flutter/foundation.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../../../core/services/tasksuite_auth_service.dart';

class AttendanceHistoryProvider extends ChangeNotifier {
  final AttendanceRepository _repository;
  
  AttendanceHistoryProvider(this._repository);

  List<AttendanceModel> _attendanceHistory = [];
  bool _isLoading = false;
  String? _error;

  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String?> _getToken() async {
    return TaskSuiteAuthService.instance.getToken();
  }

  Future<void> loadAttendanceHistory(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _repository.getAttendanceHistory(token, employeeId);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> attendanceData = response['data']['data'] ?? [];
        _attendanceHistory = attendanceData
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      } else {
        _error = response['message'] ?? 'Failed to load attendance history';
        _attendanceHistory = [];
      }
    } catch (e) {
      _error = e.toString();
      _attendanceHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _attendanceHistory = [];
    _error = null;
    notifyListeners();
  }
}