/// API Constants for the TMEmployee App
/// Based on TaskSuite HRMS Backend
library;

import '../config/api_config.dart';

class ApiConstants {
  // Base URL for TaskSuite HRMS Backend
  static String get baseUrl => ApiConfig.taskSuiteBase;

  // Attendance Endpoints
  static String get checkIn => '$baseUrl/attendance/check-in';
  static String get checkOut => '$baseUrl/attendance/check-out';
  static String attendance(String employeeId) =>
      '$baseUrl/attendance?employee_id=$employeeId';
  static String attendanceDetail(String attendanceId) =>
      '$baseUrl/attendance/show/$attendanceId';
  static String attendanceEdit(String attendanceId) =>
      '$baseUrl/attendance/edit/$attendanceId';
  static String get todayAttendanceSummary =>
      '$baseUrl/attendance/today-summary';

  // Authentication
  static String get login => '$baseUrl/login';

  // Employees Endpoint
  static String get employees => '$baseUrl/employees';

  // Helper method to get headers with token
  static Map<String, String> headersWithToken(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Helper method to get basic headers
  static Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
