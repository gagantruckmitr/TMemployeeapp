import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../models/attendance_detail_model.dart';
import '../../../../core/config/api_config.dart';

abstract class AttendanceRepository {
  Future<Map<String, dynamic>> getAttendanceHistory(String token, String employeeId);
  Future<AttendanceDetailModel?> getAttendanceDetail(String id);
  Future<Map<String, dynamic>> checkIn(
    String token,
    String employeeId, {
    String? selfiePath,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  });
  Future<Map<String, dynamic>> checkOut(
    String token,
    String employeeId, {
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  });
  Future<Map<String, dynamic>> getTodayAttendance(String token, String employeeId);
  Future<Map<String, dynamic>> getTodayAttendanceSummary(String token);
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  @override
  Future<Map<String, dynamic>> getAttendanceHistory(String token, String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/history/$employeeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch attendance history'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<AttendanceDetailModel?> getAttendanceDetail(String id) async {
    // Implementation for fetching attendance detail
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> checkIn(
    String token,
    String employeeId, {
    String? selfiePath,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  }) async {
    try {
      final body = {
        'employee_id': employeeId,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (locationAccuracy != null) 'location_accuracy': locationAccuracy.toString(),
        if (address != null) 'address': address,
        if (remark != null) 'remark': remark,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/checkin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Check-in failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> checkOut(
    String token,
    String employeeId, {
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  }) async {
    try {
      final body = {
        'employee_id': employeeId,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (locationAccuracy != null) 'location_accuracy': locationAccuracy.toString(),
        if (address != null) 'address': address,
        if (remark != null) 'remark': remark,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/attendance/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Check-out failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayAttendance(String token, String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/today/$employeeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch today attendance'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayAttendanceSummary(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/summary/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch attendance summary'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}