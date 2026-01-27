/// API Constants for the TMEmployee App
/// Based on TaskSuite HRMS Backend
class ApiConstants {
  // Base URL for TaskSuite HRMS Backend
  static const String baseUrl =
      'https://tasksuite.development.truckmitr.com/backend/public/api';

  // Attendance Endpoints
  static const String checkIn = '$baseUrl/attendance/check-in';
  static const String checkOut = '$baseUrl/attendance/check-out';
  static String attendance(String employeeId) =>
      '$baseUrl/attendance?employee_id=$employeeId';
  static String attendanceDetail(String attendanceId) =>
      '$baseUrl/attendance/show/$attendanceId';
  static String attendanceEdit(String attendanceId) =>
      '$baseUrl/attendance/edit/$attendanceId';
  static const String todayAttendanceSummary =
      '$baseUrl/attendance/today-summary';

  // Authentication
  static const String login = '$baseUrl/login';

  // Employees Endpoint
  static const String employees = '$baseUrl/employees';

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
