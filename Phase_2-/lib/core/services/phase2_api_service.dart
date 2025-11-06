import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/job_model.dart';
import '../../models/driver_applicant_model.dart';
import 'phase2_auth_service.dart';

class Phase2ApiService {
  // Update this to your actual API URL
  static const String baseUrl = 'https://truckmitr.com/truckmitr-app/api';

  // Fetch jobs with optional filter
  static Future<List<JobModel>> fetchJobs({String filter = 'all'}) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final uri =
          Uri.parse('$baseUrl/phase2_jobs_api.php').replace(queryParameters: {
        'filter': filter,
        'user_id': user.id.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> jobsJson = data['data'];
          return jobsJson.map((json) => JobModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch jobs');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  // Search jobs with live query
  static Future<List<JobModel>> searchJobs(
      {required String query, String filter = 'all'}) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$baseUrl/phase2_search_jobs_api.php')
          .replace(queryParameters: {
        'query': query,
        'filter': filter,
        'user_id': user.id.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> jobsJson = data['data'];
          return jobsJson.map((json) => JobModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to search jobs');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search jobs: $e');
    }
  }

  // Fetch dashboard statistics
  static Future<DashboardStats> fetchDashboardStats() async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$baseUrl/phase2_dashboard_stats_api.php')
          .replace(queryParameters: {'user_id': user.id.toString()});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return DashboardStats.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch stats');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  // Fetch recent activities
  static Future<List<RecentActivity>> fetchRecentActivities(
      {int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/phase2_recent_activities_api.php')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> activitiesJson = data['data'];
          return activitiesJson
              .map((json) => RecentActivity.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch activities');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch recent activities: $e');
    }
  }

  // Fetch job applicants
  static Future<List<DriverApplicant>> fetchJobApplicants(String jobId) async {
    try {
      final uri = Uri.parse('$baseUrl/phase2_job_applicants_api.php')
          .replace(queryParameters: {'job_id': jobId});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> applicantsJson = data['data'];
          return applicantsJson
              .map((json) => DriverApplicant.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch applicants');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch job applicants: $e');
    }
  }

  // Save call feedback
  static Future<void> saveCallFeedback({
    required int callerId,
    String? transporterTmid,
    String? driverTmid,
    int? driverId,
    String? driverName,
    String? transporterName,
    required String feedback,
    String? matchStatus,
    String? notes,
    String? jobId,
  }) async {
    try {
      // Always send all fields - let API handle empty values
      final requestBody = {
        'callerId': callerId,
        'uniqueIdTransporter': transporterTmid ?? '',
        'uniqueIdDriver': driverTmid ?? '',
        'driverId': driverId ?? 0,
        'driverName': driverName ?? '',
        'transporterName': transporterName ?? '',
        'feedback': feedback,
        'matchStatus': matchStatus ?? '',
        'additionalNotes': notes ?? '',
        'jobId': jobId ?? '',
      };

      print('SENDING TO API: $requestBody');

      // Use direct API endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/phase2_call_feedback_direct.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to save feedback');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save call feedback: $e');
    }
  }

  // Fetch call analytics
  static Future<Map<String, dynamic>> fetchCallAnalytics() async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      final response = await http.get(
        Uri.parse(
            '$baseUrl/phase2_call_analytics_api.php?action=stats&caller_id=$callerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch call analytics: $e');
    }
  }

  // Fetch call history with filters
  static Future<Map<String, dynamic>> fetchCallHistory({
    int limit = 50,
    int offset = 0,
    String period = 'all',
    String? feedbackFilter,
    String? search,
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      final queryParams = {
        'action': 'list',
        'caller_id': callerId.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
        'period': period,
      };

      if (feedbackFilter != null && feedbackFilter.isNotEmpty) {
        queryParams['feedback'] = feedbackFilter;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/phase2_call_history_api.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch call history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch call history: $e');
    }
  }

  // Update call log
  static Future<void> updateCallLog({
    required int id,
    String? feedback,
    String? matchStatus,
    String? remark,
  }) async {
    try {
      final requestBody = {
        'id': id,
        if (feedback != null) 'feedback': feedback,
        if (matchStatus != null) 'matchStatus': matchStatus,
        if (remark != null) 'remark': remark,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/phase2_call_history_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update call log');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update call log: $e');
    }
  }

  // Delete call log
  static Future<void> deleteCallLog(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/phase2_call_history_api.php?id=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete call log');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete call log: $e');
    }
  }

  // Save job brief
  static Future<void> saveJobBrief({
    required String uniqueId,
    required String jobId,
    int? callerId,
    String? name,
    String? jobLocation,
    String? route,
    String? vehicleType,
    String? licenseType,
    String? experience,
    double? salaryFixed,
    double? salaryVariable,
    String? esiPf,
    double? foodAllowance,
    double? tripIncentive,
    String? rehneKiSuvidha,
    String? mileage,
    String? fastTagRoadKharcha,
    String? callStatusFeedback,
  }) async {
    try {
      // Get caller ID from current user if not provided
      if (callerId == null) {
        final user = await Phase2AuthService.getCurrentUser();
        callerId = user?.id;
      }

      final requestBody = {
        'uniqueId': uniqueId,
        'jobId': jobId,
        if (callerId != null) 'callerId': callerId,
        if (name != null) 'name': name,
        if (jobLocation != null) 'jobLocation': jobLocation,
        if (route != null) 'route': route,
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (licenseType != null) 'licenseType': licenseType,
        if (experience != null) 'experience': experience,
        if (salaryFixed != null) 'salaryFixed': salaryFixed,
        if (salaryVariable != null) 'salaryVariable': salaryVariable,
        if (esiPf != null) 'esiPf': esiPf,
        if (foodAllowance != null) 'foodAllowance': foodAllowance,
        if (tripIncentive != null) 'tripIncentive': tripIncentive,
        if (rehneKiSuvidha != null) 'rehneKiSuvidha': rehneKiSuvidha,
        if (mileage != null) 'mileage': mileage,
        if (fastTagRoadKharcha != null)
          'fastTagRoadKharcha': fastTagRoadKharcha,
        if (callStatusFeedback != null)
          'callStatusFeedback': callStatusFeedback,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/phase2_job_brief_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to save job brief');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save job brief: $e');
    }
  }

  // Get call history for transporter (job briefs)
  static Future<List<Map<String, dynamic>>> getTransporterCallHistory(
      String uniqueId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/phase2_job_brief_api.php?action=history&unique_id=$uniqueId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch call history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch call history: $e');
    }
  }

  // Get list of transporters with call history
  static Future<List<Map<String, dynamic>>>
      getTransportersWithCallHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/phase2_job_brief_api.php?action=transporters_list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch transporters');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch transporters: $e');
    }
  }

  // Update job brief
  static Future<void> updateJobBrief({
    required int id,
    String? name,
    String? jobLocation,
    String? route,
    String? vehicleType,
    String? licenseType,
    String? experience,
    double? salaryFixed,
    double? salaryVariable,
    String? esiPf,
    double? foodAllowance,
    double? tripIncentive,
    String? rehneKiSuvidha,
    String? mileage,
    String? fastTagRoadKharcha,
    String? callStatusFeedback,
  }) async {
    try {
      final requestBody = {
        'id': id,
        if (name != null) 'name': name,
        if (jobLocation != null) 'jobLocation': jobLocation,
        if (route != null) 'route': route,
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (licenseType != null) 'licenseType': licenseType,
        if (experience != null) 'experience': experience,
        if (salaryFixed != null) 'salaryFixed': salaryFixed,
        if (salaryVariable != null) 'salaryVariable': salaryVariable,
        if (esiPf != null) 'esiPf': esiPf,
        if (foodAllowance != null) 'foodAllowance': foodAllowance,
        if (tripIncentive != null) 'tripIncentive': tripIncentive,
        if (rehneKiSuvidha != null) 'rehneKiSuvidha': rehneKiSuvidha,
        if (mileage != null) 'mileage': mileage,
        if (fastTagRoadKharcha != null)
          'fastTagRoadKharcha': fastTagRoadKharcha,
        if (callStatusFeedback != null)
          'callStatusFeedback': callStatusFeedback,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/phase2_job_brief_api.php?action=update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update job brief');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update job brief: $e');
    }
  }

  // Delete job brief
  static Future<void> deleteJobBrief(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/phase2_job_brief_api.php?action=delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete job brief');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete job brief: $e');
    }
  }

  // Fetch call logs (legacy method)
  static Future<List<Map<String, dynamic>>> fetchCallLogs(
      {int limit = 50, int offset = 0}) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      final uri = Uri.parse('$baseUrl/phase2_call_analytics_api.php')
          .replace(queryParameters: {
        'action': 'logs',
        'limit': limit.toString(),
        'offset': offset.toString(),
        'caller_id': callerId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch call logs');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch call logs: $e');
    }
  }

  // Upload driver call recording
  static Future<Map<String, dynamic>> uploadDriverCallRecording({
    required String filePath,
    required String jobId,
    required int callerId,
    required String driverTmid,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/phase2_upload_driver_recording_api.php');

      var request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'recording',
        filePath,
      ));

      // Add form fields
      request.fields['job_id'] = jobId;
      request.fields['caller_id'] = callerId.toString();
      request.fields['driver_tmid'] = driverTmid;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to upload recording');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload recording: $e');
    }
  }
}
