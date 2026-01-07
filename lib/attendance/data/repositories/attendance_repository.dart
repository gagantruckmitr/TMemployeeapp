import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class AttendanceRepository {
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
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.checkIn),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Add required fields
    request.fields['employee_id'] = employeeId;

    // Add location fields if provided
    if (latitude != null) {
      request.fields['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      request.fields['longitude'] = longitude.toString();
    }

    // Add optional fields
    if (locationAccuracy != null) {
      request.fields['location_accuracy'] = locationAccuracy.toString();
    }
    if (address != null && address.isNotEmpty) {
      request.fields['address'] = address;
    }
    if (remark != null && remark.isNotEmpty) {
      request.fields['remark'] = remark;
    }

    // Add selfie if provided
    if (selfiePath != null && selfiePath.isNotEmpty) {
      final file = File(selfiePath);
      if (await file.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('selfie', selfiePath),
        );
      }
    }

    // Log check-in details
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Log successful response
      print('✅ CHECK-IN SUCCESSFUL');
      print('Response: ${json.encode(responseData)}');

      return responseData;
    } else {
      final errorData = json.decode(response.body);

      // Log error response
      print('❌ CHECK-IN FAILED');
      print('Status Code: ${response.statusCode}');
      print('Error: ${json.encode(errorData)}');

      throw Exception(errorData['message'] ?? 'Failed to check in');
    }
  }

  Future<Map<String, dynamic>> checkOut(
    String token,
    String employeeId, {
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? address,
    String? remark,
  }) async {
    // Log check-out details
    print('═══════════════════════════════════════════════════════════');
    print('🔴 CHECK-OUT DETAILS');
    print('═══════════════════════════════════════════════════════════');
    print('Employee ID: $employeeId');
    print('Latitude: $latitude');
    print('Longitude: $longitude');
    print(
      'Location Accuracy: ${locationAccuracy != null ? '±${locationAccuracy.toStringAsFixed(2)}m' : 'N/A'}',
    );
    print('Address: ${address ?? 'N/A'}');
    print('Remark: ${remark ?? 'N/A'}');
    print('Check-out Time: ${DateTime.now().toString()}');
    print('═══════════════════════════════════════════════════════════');

    final response = await http.post(
      Uri.parse(ApiConstants.checkOut),
      headers: ApiConstants.headersWithToken(token),
      body: json.encode({
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        if (locationAccuracy != null) 'location_accuracy': locationAccuracy,
        if (address != null && address.isNotEmpty) 'address': address,
        if (remark != null && remark.isNotEmpty) 'remark': remark,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Log successful response
      print('✅ CHECK-OUT SUCCESSFUL');
      print('Response: ${json.encode(responseData)}');

      return responseData;
    } else {
      final errorData = json.decode(response.body);

      // Log error response
      print('❌ CHECK-OUT FAILED');
      print('Status Code: ${response.statusCode}');
      print('Error: ${json.encode(errorData)}');

      throw Exception(errorData['message'] ?? 'Failed to check out');
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance(
    String token,
    String employeeId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.attendance(employeeId)),
      headers: ApiConstants.headersWithToken(token),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract the attendance record for today from paginated data
      if (data['success'] == true &&
          data['data'] != null &&
          data['data']['data'] != null) {
        final List<dynamic> records = data['data']['data'];
        if (records.isNotEmpty) {
          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          // Find record for today
          try {
            final todayRecord = records.firstWhere((record) {
              final recordDate = record['date']?.toString() ?? '';
              final checkInTime = record['checkin_time']?.toString() ?? '';
              return recordDate == todayStr || checkInTime.startsWith(todayStr);
            });

            return {'success': true, 'data': todayRecord};
          } catch (e) {
            // No record found for today
            return {'success': true, 'data': null};
          }
        }
      }

      return {'success': true, 'data': null};
    } else {
      // If no attendance found, return empty data
      return {'success': true, 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAttendanceHistory(
    String token,
    String employeeId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.attendance(employeeId)),
      headers: ApiConstants.headersWithToken(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load attendance history');
    }
  }

  Future<Map<String, dynamic>> getTodayAttendanceSummary(String token) async {
    try {
      // Get all employees first
      final employeesResponse = await http.get(
        Uri.parse(ApiConstants.employees),
        headers: ApiConstants.headersWithToken(token),
      );

      if (employeesResponse.statusCode != 200) {
        throw Exception('Failed to load employees');
      }

      final employeesData = json.decode(employeesResponse.body);
      final List<dynamic> employees =
          employeesData['employees'] ?? employeesData['data'] ?? [];
      final int totalEmployees = employees.length;

      print('Total employees: $totalEmployees');

      // Count present employees by checking attendance for each
      int presentCount = 0;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      for (var employee in employees) {
        final empId =
            employee['emp_id']?.toString() ?? employee['id']?.toString();
        if (empId != null && empId.isNotEmpty) {
          try {
            final attendanceData = await getAttendanceHistory(token, empId);

            if (attendanceData['success'] == true &&
                attendanceData['data'] != null &&
                attendanceData['data']['data'] != null) {
              final List<dynamic> records = attendanceData['data']['data'];

              // Check if employee has attendance record for today
              final hasTodayAttendance = records.any((record) {
                final checkinTime = record['checkin_time']?.toString() ?? '';
                return checkinTime.startsWith(todayStr);
              });

              if (hasTodayAttendance) {
                presentCount++;
              }
            }
          } catch (e) {
            print('Error checking attendance for employee $empId: $e');
          }
        }
      }

      print('Present count: $presentCount');

      return {
        'success': true,
        'data': {
          'total_employees': totalEmployees,
          'present_count': presentCount,
          'absent_count': totalEmployees - presentCount,
        },
      };
    } catch (e) {
      print('Error in getTodayAttendanceSummary: $e');
      return {
        'success': false,
        'data': {'total_employees': 0, 'present_count': 0, 'absent_count': 0},
      };
    }
  }
}
