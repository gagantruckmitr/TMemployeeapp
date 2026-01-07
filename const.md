static const String checkIn = '$baseUrl/attendance/check-in';
  static const String checkOut = '$baseUrl/attendance/check-out';
  static String attendance(String employeeId) => '$baseUrl/attendance?employee_id=$employeeId';
  static String attendanceDetail(String attendanceId) => '$baseUrl/attendance/show/$attendanceId';
  static String attendanceEdit(String attendanceId) => '$baseUrl/attendance/edit/$attendanceId';
  static const String todayAttendanceSummary = '$baseUrl/attendance/today-summary';

BASE url 
  https://tasksuite.truckmitr.com/backend/public/api

