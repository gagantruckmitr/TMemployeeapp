import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/job_model.dart';
import '../../models/driver_applicant_model.dart';
import 'phase2_auth_service.dart';
import 'real_auth_service.dart';

class Phase2ApiService {
  // Update this to your actual API URL
  // For local development, use your machine's IP address
  // For production, use the domain
  static const String baseUrl = ApiConfig.baseUrl;

  // Fetch jobs with optional filter
  static Future<List<JobModel>> fetchJobs({String filter = 'all'}) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get auth token from RealAuthService
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Use Laravel API endpoint
      final uri = Uri.parse('${ApiConfig.agentJobsApi}/${user.id}');

      print('🔵 Fetching jobs from Laravel API: $uri');
      print('🔵 Filter: $filter');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔵 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Handle both array and object responses
        List<dynamic> jobsJson = [];
        if (data is List) {
          jobsJson = data;
        } else if (data is Map && data['data'] != null) {
          jobsJson = data['data'];
        } else if (data is Map && data['jobs'] != null) {
          jobsJson = data['jobs'];
        }

        print('✅ Fetched ${jobsJson.length} jobs from Laravel API');

        // Debug: Print first job to see structure
        if (jobsJson.isNotEmpty) {
          print('📋 Sample job data:');
          print('   transporter_name: ${jobsJson[0]['transporter_name']}');
          print(
            '   transporter_unique_id: ${jobsJson[0]['transporter_unique_id']}',
          );
          print('   transporter_mobile: ${jobsJson[0]['transporter_mobile']}');
          print('   profile_completion: ${jobsJson[0]['profile_completion']}%');
          print('   total_applicants: ${jobsJson[0]['total_applicants']}');
          print('   job_id: ${jobsJson[0]['job_id']}');
          print('   job_title: ${jobsJson[0]['job_title']}');
          print(
            '   status: ${jobsJson[0]['status']} (${jobsJson[0]['status'] == '1' ? 'Approved' : 'Pending'})',
          );
          print(
            '   active_inactive: ${jobsJson[0]['active_inactive']} (${jobsJson[0]['active_inactive'] == 1 ? 'Active' : 'Inactive'})',
          );
        }

        // Parse jobs and apply filter
        final allJobs = jobsJson
            .map((json) => JobModel.fromLaravelJson(json))
            .toList();

        // Apply filter
        List<JobModel> filteredJobs;
        switch (filter) {
          case 'approved':
            // Exclude expired and closed jobs from approved section
            filteredJobs = allJobs
                .where((job) => job.isApproved && !job.isExpiredByDeadline && !job.isClosed)
                .toList();
            break;
          case 'active':
            filteredJobs = allJobs
                .where((job) => job.isActive && !job.isExpiredByDeadline && !job.isClosed)
                .toList();
            break;
          case 'pending':
            // Exclude expired and closed jobs from pending section
            filteredJobs = allJobs
                .where((job) => !job.isApproved && !job.isExpiredByDeadline && !job.isClosed)
                .toList();
            break;
          case 'inactive':
            filteredJobs = allJobs.where((job) => !job.isActive).toList();
            break;
          case 'expired':
            filteredJobs = allJobs
                .where((job) => job.isExpiredByDeadline)
                .toList();
            break;
          case 'closed':
            filteredJobs = allJobs.where((job) => job.isClosed).toList();
            break;
          default: // 'all'
            filteredJobs = allJobs;
        }

        // Sort jobs: Fresh jobs (newest) at the top
        filteredJobs.sort((a, b) {
          try {
            final dateA = DateTime.parse(a.createdAt);
            final dateB = DateTime.parse(b.createdAt);
            return dateB.compareTo(dateA); // Newest first
          } catch (e) {
            return 0;
          }
        });

        print('✅ After filter "$filter": ${filteredJobs.length} jobs');
        return filteredJobs;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to fetch jobs: $e');
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  // Search jobs with live query
  static Future<List<JobModel>> searchJobs({
    required String query,
    String filter = 'all',
  }) async {
    try {
      // For now, fetch all jobs and filter locally
      // You can create a dedicated search endpoint later if needed
      final allJobs = await fetchJobs(filter: filter);

      if (query.isEmpty) {
        return allJobs;
      }

      // Search in multiple fields
      final searchLower = query.toLowerCase();
      return allJobs.where((job) {
        return job.jobId.toLowerCase().contains(searchLower) ||
            job.transporterTmid.toLowerCase().contains(searchLower) ||
            job.transporterName.toLowerCase().contains(searchLower) ||
            job.jobLocation.toLowerCase().contains(searchLower) ||
            job.jobTitle.toLowerCase().contains(searchLower) ||
            job.vehicleType.toLowerCase().contains(searchLower);
      }).toList();
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

      final uri = Uri.parse(
        '$baseUrl/phase2_dashboard_stats_api.php',
      ).replace(queryParameters: {'user_id': user.id.toString()});

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
  static Future<List<RecentActivity>> fetchRecentActivities({
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/phase2_recent_activities_api.php',
      ).replace(queryParameters: {'limit': limit.toString()});

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

  // Fetch driver detailed info with applied jobs
  static Future<Map<String, dynamic>> fetchDriverDetailedInfo(
    int driverId,
  ) async {
    try {
      // Get auth token
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse('${ApiConfig.driversApi}/$driverId/applied-jobs-with-assigned-to');

      print('=== FETCHING DRIVER DETAILED INFO ===');
      print('Driver ID: $driverId');
      print('URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Transform API response to expected format
        final driver = jsonResponse['driver'] ?? {};
        final appliedJobs = jsonResponse['applied_jobs'] as List? ?? [];

        return {
          'driver': {
            'id': driver['id'],
            'uniqueId': driver['unique_id'],
            'name': driver['name'],
            'mobile': driver['mobile'],
          },
          'totalJobsApplied': jsonResponse['total_jobs_applied'] ?? 0,
          'appliedJobs': appliedJobs
              .map(
                (job) => {
                  'jobId': job['job_unique_id'] ?? 'TMJB${job['job_id']}',
                  'jobTitle': job['job_title'] ?? '',
                  'transporterName': job['transporter_name'] ?? '',
                  'assignedTelecaller': job['assigned_agent_name'],
                  'assignedTo': job['assigned_to'],
                  'appliedDate': job['applied_at'],
                  'callStatus': job['call_status'],
                  'callFeedback': job['call_feedback'],
                  'callRemarks': job['call_remarks'],
                  'calledBy': job['called_by'],
                  'callUpdatedAt': job['call_updated_at'],
                  'feedback': job['call_feedback'] ?? job['call_status'],
                  'remarks': job['call_remarks'],
                  'matchStatus': null,
                  'notes': null,
                  'feedbackBy': job['called_by'] != null
                      ? 'Agent ${job['called_by']}'
                      : null,
                  'feedbackDate': job['call_updated_at'],
                },
              )
              .toList(),
          'callHistory': [], // Call history can be fetched separately if needed
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch driver details: $e');
    }
  }

  static Future<List<DriverApplicant>> fetchJobApplicants(String jobId) async {
    try {
      // Get auth token
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Extract numeric ID from jobId (e.g., "TMJB00512" -> "512")
      String numericJobId = jobId;
      if (jobId.startsWith('TMJB')) {
        // Remove "TMJB" prefix and leading zeros
        numericJobId = jobId
            .replaceFirst('TMJB', '')
            .replaceFirst(RegExp(r'^0+'), '');
        if (numericJobId.isEmpty) numericJobId = '0';
      }

      // Use Laravel API endpoint with numeric job ID (HTTPS required for auth)
      final uri = Uri.parse('${ApiConfig.jobsApi}/$numericJobId/applicants');

      print('=== FETCHING JOB APPLICANTS ===');
      print('Original Job ID: $jobId');
      print('Numeric Job ID: $numericJobId');
      print('URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('Data type: ${data.runtimeType}');
        print('Data: $data');

        // Laravel API returns array of applicants directly
        List<dynamic> applicantsJson;
        if (data is List) {
          applicantsJson = data;
          print('Data is List with ${applicantsJson.length} items');
        } else if (data is Map && data['applicants'] != null) {
          applicantsJson = data['applicants'];
          print('Data is Map with applicants: ${applicantsJson.length} items');
        } else {
          applicantsJson = [];
          print('Data format unknown, returning empty list');
        }

        print('=== LARAVEL JOB APPLICANTS API ===');
        print('Total applicants: ${applicantsJson.length}');
        print('==================================');

        // Map Laravel API response to DriverApplicant model
        return applicantsJson.map((json) {
          print('=== APPLICANT DEBUG ===');
          print('Driver: ${json['driver_name']}');
          print('Status: ${json['status']}');
          print('Images field: ${json['images']}');
          print('=======================');

          final transformedJson = {
            'jobId': int.tryParse(jobId) ?? 0,
            'jobTitle': '',
            'contractorId': 0,
            'transporterTmid': '',
            'transporterName': '',
            'driverId': json['driver_id'] ?? 0,
            'driverTmid': json['driver_unique_id'] ?? '',
            'name': json['driver_name'] ?? '',
            'mobile': json['mobile'] ?? '',
            'email': '',
            'city': '',
            'state': json['state_name'] ?? '',
            'gender': json['gender'],
            'profileImage': json['images'],
            'vehicleType': (json['vehicle_type'] ?? '')
                .toString()
                .replaceAll('\n', ' ')
                .trim(),
            'drivingExperience': json['Driving_Experience']?.toString() ?? '',
            'licenseType': json['Type_of_License'] ?? '',
            'licenseNumber': '',
            'preferredLocation': '',
            'aadharNumber': '',
            'panNumber': '',
            'gstNumber': '',
            'status': json['status'] ?? 'active', // Use actual status from API
            'createdAt': json['job_created_at'] ?? '',
            'updatedAt': json['job_updated_at'] ?? '',
            'appliedAt': json['applied_at'] ?? '',
            'profileCompletion': json['profile_completion'] ?? 0,
            'subscriptionAmount': json['subscription']?['amount']?.toString(),
            'subscriptionStartDate': json['subscription']?['start_at'],
            'subscriptionEndDate': null,
            'subscriptionStatus': json['subscription'] != null
                ? 'active'
                : 'inactive',
            'callStatus': json['call_status'],
            'callFeedback': json['call_feedback'],
            'callRemarks': json['call_remarks'],
            'matchStatus': json['match_status'],
            'matchMakerName': null,
            'feedbackNotes': null,
            'otherAppliedJobs': null,
            'totalJobsApplied':
                int.tryParse(json['total_jobs_applied']?.toString() ?? '0') ??
                0,
          };
          return DriverApplicant.fromJson(transformedJson);
        }).toList();
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
    String? callRecording,
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
        if (callRecording != null) 'callRecording': callRecording,
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

  // Reject job applicant - Using Laravel API
  static Future<void> rejectJobApplicant({
    required int callerId,
    required int driverId,
    required int jobId,
    required String driverTmid,
    required String jobIdString,
    String? reason,
    int? contractorId, // transporter_id from API response
  }) async {
    try {
      // Get auth token from RealAuthService
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Use Laravel API endpoint
      final requestBody = {
        'driver_id': driverId,
        'job_id': jobId,
        'contractor_id': contractorId ?? 0, // transporter_id
        'assigned_id': callerId, // telecaller ID
        'rejected_status': 'rejected',
      };

      print('🔴 SENDING REJECTION TO LARAVEL API:');
      print('   URL: ${ApiConfig.rejectedApplyJobsApi}');
      print('   Body: $requestBody');

      final response = await http.post(
        Uri.parse(ApiConfig.rejectedApplyJobsApi),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('🔴 Response status: ${response.statusCode}');
      print('🔴 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          print('✅ Applicant rejected successfully via Laravel API');
        } else {
          throw Exception(data['message'] ?? 'Failed to reject applicant');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reject applicant: $e');
    }
  }

  // Fetch call analytics
  static Future<Map<String, dynamic>> fetchCallAnalytics() async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      final response = await http.get(
        Uri.parse(
          '$baseUrl/phase2_call_analytics_api.php?action=stats&caller_id=$callerId',
        ),
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
    int limit = 1000, // Increased default to load more records
    int offset = 0,
    String period = 'all',
    String? feedbackFilter,
    String? search,
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      // Get auth token from RealAuthService
      final token = await RealAuthService.instance.getAuthToken();

      print('=== FETCHING DRIVER CALL HISTORY (LARAVEL API) ===');
      print('Caller ID: $callerId');
      print('Token exists: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        print(
          'Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        );
        print('Token length: ${token.length}');
      }

      if (token == null || token.isEmpty) {
        print('⚠️ No token available - user may need to re-login');
        throw Exception(
          'Authentication token not found. Please logout and login again.',
        );
      }

      print(
        'URL: https://truckmitr.com/api/telehead/jobs/assigned-to/$callerId',
      );

      final uri = Uri.parse(
        'https://truckmitr.com/api/telehead/jobs/assigned-to/$callerId',
      );

      // Use Bearer token
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('=== API RESPONSE ===');
        print('Response type: ${data.runtimeType}');

        // Laravel API returns jobs array
        List<dynamic> jobs = [];
        if (data is Map && data.containsKey('jobs')) {
          jobs = data['jobs'] is List ? data['jobs'] : [];
        } else if (data is List) {
          jobs = data;
        }

        print('Total jobs found: ${jobs.length}');

        // Debug: Print first job structure to see all available fields
        if (jobs.isNotEmpty) {
          print('📋 [DEBUG] First job keys: ${jobs[0].keys.toList()}');
          print('📋 [DEBUG] First job JSON: ${jobs[0]}');
        }

        // Transform Laravel job data to CallHistoryLog format
        List<Map<String, dynamic>> transformedLogs = jobs.map((job) {
          // Debug log ALL keys in the job to find where mobile is
          print('📋 [JOB KEYS] ${job.keys.toList()}');
          print(
            '📱 [DEBUG] Driver: ${job['driver_name']} - driver_mobile: "${job['driver_mobile']}" - mobile: "${job['mobile']}" - phone: "${job['phone']}"',
          );

          // Handle mobile numbers - they might be null, numeric, or string
          String driverMobile = '';
          if (job['driver_mobile'] != null) {
            driverMobile = job['driver_mobile'].toString().trim();
          }

          String transporterMobile = '';
          if (job['transporter_mobile'] != null) {
            transporterMobile = job['transporter_mobile'].toString().trim();
          }

          return {
            'id': job['id'] ?? 0,
            'callerId': job['assigned_to'] ?? callerId,
            'callerName': user?.name ?? '',
            'uniqueIdTransporter': job['unique_id_transporter'] ?? '',
            'uniqueIdDriver': job['unique_id_driver'] ?? '',
            'userIdTransporter': job['user_id_transporter'] ?? 0,
            'userIdDriver': job['user_id_driver'] ?? 0,
            'driverName': job['driver_name'] ?? '',
            'transporterName': job['transporter_name'] ?? '',
            'driverMobile': driverMobile,
            'transporterMobile': transporterMobile,
            'feedback': job['call_feedback'] ?? '',
            'matchStatus': _formatCallStatus(
              job['call_status']?.toString() ?? '',
            ),
            'remark': job['call_remarks'] ?? '',
            'jobId': job['job_id'] ?? '',
            'callRecording': job['call_recording'] ?? '',
            'createdAt': job['created_at'] ?? DateTime.now().toIso8601String(),
            'updatedAt': job['updated_at'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        // Apply filters
        List<Map<String, dynamic>> filteredLogs = transformedLogs;

        // Period filter
        if (period != 'all') {
          final now = DateTime.now();
          filteredLogs = filteredLogs.where((log) {
            final createdAt = log['createdAt']?.toString();
            if (createdAt == null) return false;

            try {
              final logDate = DateTime.parse(createdAt);

              if (period == 'today') {
                return logDate.year == now.year &&
                    logDate.month == now.month &&
                    logDate.day == now.day;
              } else if (period == 'yesterday') {
                final yesterday = now.subtract(const Duration(days: 1));
                return logDate.year == yesterday.year &&
                    logDate.month == yesterday.month &&
                    logDate.day == yesterday.day;
              } else if (period == 'week') {
                final weekAgo = now.subtract(const Duration(days: 7));
                return logDate.isAfter(weekAgo);
              } else if (period == 'month') {
                final monthAgo = now.subtract(const Duration(days: 30));
                return logDate.isAfter(monthAgo);
              }
            } catch (e) {
              return false;
            }
            return true;
          }).toList();
        }

        // Feedback filter - category based matching
        if (feedbackFilter != null && feedbackFilter.isNotEmpty) {
          filteredLogs = filteredLogs.where((log) {
            final feedback = (log['feedback']?.toString() ?? '').toLowerCase();
            final matchStatus = (log['matchStatus']?.toString() ?? '')
                .toLowerCase();

            // Determine the category of this log's feedback
            // IMPORTANT: Check Not Connected FIRST to avoid false matches
            String category;
            if (feedback.contains('ringing') ||
                feedback.contains('busy') ||
                feedback.contains('switched off') ||
                feedback.contains('not reachable') ||
                feedback.contains("didn't pick") ||
                feedback.contains("no answer") ||
                feedback.contains('not answered') ||
                feedback.contains('unreachable') ||
                feedback.contains('not available') ||
                matchStatus == 'not_connected' ||
                matchStatus == 'not connected') {
              category = 'not connected';
            } else if (feedback.contains('call back') ||
                feedback.contains('callback') ||
                feedback.contains('later') ||
                feedback.contains('tomorrow') ||
                feedback.contains('evening') ||
                feedback.contains('morning') ||
                feedback.contains('busy right now') ||
                matchStatus == 'callback' ||
                matchStatus == 'callback_later') {
              category = 'callback later';
            } else if (feedback.contains('interview') ||
                feedback.contains('selected') ||
                feedback.contains('interested') ||
                feedback.contains('done') ||
                feedback.contains('match making') ||
                feedback.contains('confirmed') ||
                matchStatus == 'connected') {
              category = 'connected';
            } else {
              category = 'other';
            }

            // Match against the filter
            final filterLower = feedbackFilter.toLowerCase();
            if (filterLower == 'connected') {
              return category == 'connected';
            } else if (filterLower == 'not connected') {
              return category == 'not connected';
            } else if (filterLower == 'callback later' ||
                filterLower == 'callback') {
              return category == 'callback later';
            }
            return true;
          }).toList();
        }

        // Search filter
        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          filteredLogs = filteredLogs.where((log) {
            final driverName =
                log['driverName']?.toString().toLowerCase() ?? '';
            final driverTmid =
                log['uniqueIdDriver']?.toString().toLowerCase() ?? '';
            final transporterName =
                log['transporterName']?.toString().toLowerCase() ?? '';
            final transporterTmid =
                log['uniqueIdTransporter']?.toString().toLowerCase() ?? '';
            return driverName.contains(searchLower) ||
                driverTmid.contains(searchLower) ||
                transporterName.contains(searchLower) ||
                transporterTmid.contains(searchLower);
          }).toList();
        }

        // Apply pagination
        final totalCount = filteredLogs.length;
        final paginatedLogs = filteredLogs.skip(offset).take(limit).toList();

        print('=== FINAL RESULTS ===');
        print('Total count: $totalCount');
        print('Paginated logs: ${paginatedLogs.length}');

        return {
          'logs': paginatedLogs,
          'total': totalCount,
          'hasMore': (offset + limit) < totalCount,
        };
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. The API endpoint may not exist or your session has expired. Please logout and login again.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. The URL may be incorrect.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('=== EXCEPTION IN fetchCallHistory ===');
      print('Error: $e');
      rethrow;
    }
  }

  // BACKUP: Original working implementation
  static Future<Map<String, dynamic>> _fetchCallHistoryBackup({
    int limit = 1000,
    int offset = 0,
    String period = 'all',
    String? feedbackFilter,
    String? search,
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      // Get auth token from RealAuthService
      final token = await RealAuthService.instance.getAuthToken();

      print('=== FETCHING DRIVER CALL HISTORY (LARAVEL API) ===');
      print('Caller ID: $callerId');
      print('Token exists: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        print(
          'Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        );
        print('Token length: ${token.length}');
      }

      if (token == null || token.isEmpty) {
        print('⚠️ No token available - user may need to re-login');
        throw Exception(
          'Authentication token not found. Please logout and login again.',
        );
      }

      print(
        'URL: https://truckmitr.com/api/telehead/jobs/assigned-to/$callerId',
      );

      final uri = Uri.parse(
        'https://truckmitr.com/api/telehead/jobs/assigned-to/$callerId',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('=== API RESPONSE ===');
        print('Response type: ${data.runtimeType}');

        // Laravel API returns jobs array
        List<dynamic> jobs = [];
        if (data is Map && data.containsKey('jobs')) {
          jobs = data['jobs'] is List ? data['jobs'] : [];
        } else if (data is List) {
          jobs = data;
        }

        print('Total jobs found: ${jobs.length}');

        // Transform Laravel job data to CallHistoryLog format
        List<Map<String, dynamic>> transformedLogs = jobs.map((job) {
          return {
            'id': job['id'] ?? 0,
            'callerId': job['assigned_to'] ?? callerId,
            'callerName': user?.name ?? '',
            'uniqueIdTransporter': job['unique_id_transporter'] ?? '',
            'uniqueIdDriver': job['unique_id_driver'] ?? '',
            'driverName': job['driver_name'] ?? '',
            'transporterName': job['transporter_name'] ?? '',
            'driverMobile': job['driver_mobile'] ?? '',
            'transporterMobile': job['transporter_mobile'] ?? '',
            'feedback': job['call_feedback'] ?? '',
            'matchStatus': _formatCallStatus(
              job['call_status']?.toString() ?? '',
            ),
            'remark': job['call_remarks'] ?? '',
            'jobId': job['job_id'] ?? '',
            'callRecording': job['call_recording'] ?? '',
            'createdAt': job['created_at'] ?? DateTime.now().toIso8601String(),
            'updatedAt': job['updated_at'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        // Apply filters
        List<Map<String, dynamic>> filteredLogs = transformedLogs;

        // Period filter
        if (period != 'all') {
          final now = DateTime.now();
          filteredLogs = filteredLogs.where((log) {
            final createdAt = log['createdAt']?.toString();
            if (createdAt == null) return false;

            try {
              final logDate = DateTime.parse(createdAt);

              if (period == 'today') {
                return logDate.year == now.year &&
                    logDate.month == now.month &&
                    logDate.day == now.day;
              } else if (period == 'yesterday') {
                final yesterday = now.subtract(const Duration(days: 1));
                return logDate.year == yesterday.year &&
                    logDate.month == yesterday.month &&
                    logDate.day == yesterday.day;
              } else if (period == 'week') {
                final weekAgo = now.subtract(const Duration(days: 7));
                return logDate.isAfter(weekAgo);
              } else if (period == 'month') {
                final monthAgo = now.subtract(const Duration(days: 30));
                return logDate.isAfter(monthAgo);
              }
            } catch (e) {
              return false;
            }
            return true;
          }).toList();
        }

        // Feedback filter - category based matching
        if (feedbackFilter != null && feedbackFilter.isNotEmpty) {
          filteredLogs = filteredLogs.where((log) {
            final feedback = (log['feedback']?.toString() ?? '').toLowerCase();
            final matchStatus = (log['matchStatus']?.toString() ?? '')
                .toLowerCase();

            // Determine the category of this log's feedback
            // IMPORTANT: Check Not Connected FIRST to avoid false matches
            String category;
            if (feedback.contains('ringing') ||
                feedback.contains('busy') ||
                feedback.contains('switched off') ||
                feedback.contains('not reachable') ||
                feedback.contains("didn't pick") ||
                feedback.contains("no answer") ||
                feedback.contains('not answered') ||
                feedback.contains('unreachable') ||
                feedback.contains('not available') ||
                matchStatus == 'not_connected' ||
                matchStatus == 'not connected') {
              category = 'not connected';
            } else if (feedback.contains('call back') ||
                feedback.contains('callback') ||
                feedback.contains('later') ||
                feedback.contains('tomorrow') ||
                feedback.contains('evening') ||
                feedback.contains('morning') ||
                feedback.contains('busy right now') ||
                matchStatus == 'callback' ||
                matchStatus == 'callback_later') {
              category = 'callback later';
            } else if (feedback.contains('interview') ||
                feedback.contains('selected') ||
                feedback.contains('interested') ||
                feedback.contains('done') ||
                feedback.contains('match making') ||
                feedback.contains('confirmed') ||
                matchStatus == 'connected') {
              category = 'connected';
            } else {
              category = 'other';
            }

            // Match against the filter
            final filterLower = feedbackFilter.toLowerCase();
            if (filterLower == 'connected') {
              return category == 'connected';
            } else if (filterLower == 'not connected') {
              return category == 'not connected';
            } else if (filterLower == 'callback later' ||
                filterLower == 'callback') {
              return category == 'callback later';
            }
            return true;
          }).toList();
        }

        // Search filter
        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          filteredLogs = filteredLogs.where((log) {
            final driverName =
                log['driverName']?.toString().toLowerCase() ?? '';
            final driverTmid =
                log['uniqueIdDriver']?.toString().toLowerCase() ?? '';
            final transporterName =
                log['transporterName']?.toString().toLowerCase() ?? '';
            final transporterTmid =
                log['uniqueIdTransporter']?.toString().toLowerCase() ?? '';
            return driverName.contains(searchLower) ||
                driverTmid.contains(searchLower) ||
                transporterName.contains(searchLower) ||
                transporterTmid.contains(searchLower);
          }).toList();
        }

        // Apply pagination
        final totalCount = filteredLogs.length;
        final paginatedLogs = filteredLogs.skip(offset).take(limit).toList();

        print('=== FINAL RESULTS ===');
        print('Total count: $totalCount');
        print('Paginated logs: ${paginatedLogs.length}');

        return {
          'logs': paginatedLogs,
          'total': totalCount,
          'hasMore': (offset + limit) < totalCount,
        };
      } else {
        print('=== API ERROR ===');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 401) {
          throw Exception(
            'Authentication failed. The API endpoint may not exist or your session has expired. Please logout and login again.',
          );
        } else if (response.statusCode == 404) {
          throw Exception('API endpoint not found. The URL may be incorrect.');
        }

        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('=== EXCEPTION IN fetchCallHistory ===');
      print('Error: $e');
      rethrow;
    }
  }

  // Update call log
  static Future<void> updateCallLog({
    required int id,
    String? feedback,
    String? matchStatus,
    String? remark,
    String? recordingFilePath,
    String? jobId,
    String? userTmid,
    String? userType,
  }) async {
    try {
      // If recording file is provided, upload it first
      String? recordingUrl;
      if (recordingFilePath != null && jobId != null && userTmid != null) {
        try {
          final user = await Phase2AuthService.getCurrentUser();
          final callerId = user?.id ?? 0;

          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/phase2_upload_driver_recording_api.php'),
          );

          request.files.add(
            await http.MultipartFile.fromPath('recording', recordingFilePath),
          );

          request.fields['job_id'] = jobId;
          request.fields['caller_id'] = callerId.toString();

          // Support both driver and transporter recordings
          if (userType == 'driver') {
            request.fields['driver_tmid'] = userTmid;
          } else if (userType == 'transporter') {
            request.fields['transporter_tmid'] = userTmid;
          }

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData['success'] == true) {
              recordingUrl = responseData['recording_url'];
            }
          }
        } catch (e) {
          print('Recording upload failed during update: $e');
          // Continue with update even if recording fails
        }
      }

      final requestBody = {
        'id': id,
        if (feedback != null) 'feedback': feedback,
        if (matchStatus != null) 'matchStatus': matchStatus,
        if (remark != null) 'remark': remark,
        if (recordingUrl != null) 'callRecording': recordingUrl,
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
    String? callRecording,
    String? requiredDrivers,
  }) async {
    try {
      print('=== SAVE JOB BRIEF API CALL ===');
      print('uniqueId: $uniqueId');
      print('jobId: $jobId');
      print('callerId (input): $callerId');

      // Get caller ID from current user if not provided
      if (callerId == null) {
        final user = await Phase2AuthService.getCurrentUser();
        callerId = user?.id;
        print('callerId (from user): $callerId');
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
        if (callRecording != null) 'callRecording': callRecording,
        if (requiredDrivers != null) 'requiredDrivers': requiredDrivers,
      };

      print('Request Body: ${json.encode(requestBody)}');
      print('API URL: $baseUrl/phase2_job_brief_api.php');

      final response = await http.post(
        Uri.parse('$baseUrl/phase2_job_brief_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response Data: $data');
        if (data['success'] != true) {
          print('API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to save job brief');
        }
        print('✓ Job brief saved successfully');
      } else {
        print('✗ Server error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('✗ Exception in saveJobBrief: $e');
      throw Exception('Failed to save job brief: $e');
    }
  }

  // Get call history for transporter (job briefs)
  static Future<List<Map<String, dynamic>>> getTransporterCallHistory(
    String uniqueId,
  ) async {
    try {
      // Get current user's caller_id
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      // Get auth token from RealAuthService
      final token = await RealAuthService.instance.getAuthToken();

      print('=== FETCHING TRANSPORTER CALL HISTORY (LARAVEL API) ===');
      print('Caller ID: $callerId');
      print('Transporter ID: $uniqueId');
      print('Token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        print('⚠️ No token available - user may need to re-login');
        throw Exception(
          'Authentication token not found. Please logout and login again.',
        );
      }

      print(
        'URL: https://truckmitr.com/api/telehead/call-logs/assigned-to/$callerId',
      );

      final response = await http.get(
        Uri.parse(
          'https://truckmitr.com/api/telehead/call-logs/assigned-to/$callerId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('=== TRANSPORTER CALL HISTORY RESPONSE ===');
        print('Response type: ${data.runtimeType}');
        print(
          'Response keys: ${data is Map ? data.keys.toList() : "Not a map"}',
        );

        // Laravel API returns call_logs array
        List<dynamic> callLogs = [];
        if (data is List) {
          callLogs = data;
        } else if (data is Map && data.containsKey('call_logs')) {
          callLogs = data['call_logs'] is List ? data['call_logs'] : [];
        } else if (data is Map && data.containsKey('data')) {
          callLogs = data['data'] is List ? data['data'] : [];
        }

        print('Total call logs found: ${callLogs.length}');

        // Filter call logs for the specific transporter (uniqueId is tmid)
        final filteredLogs = callLogs.where((log) {
          final transporterTmid = log['unique_id']?.toString() ?? '';
          return transporterTmid == uniqueId;
        }).toList();

        print('Filtered logs for $uniqueId: ${filteredLogs.length}');

        // Transform to expected format for TransporterCallHistoryScreen
        final transformedLogs = filteredLogs.map((log) {
          // Build job title from available data
          final jobId = log['job_id'] ?? '';
          final vehicleType = log['vehicle_type'] ?? '';
          final jobTitle = jobId.isNotEmpty
              ? 'Job: $jobId'
              : (vehicleType.isNotEmpty ? vehicleType : 'Call Log');

          return {
            'id': log['id'] ?? 0,
            'uniqueId': log['unique_id'] ?? '',
            'jobId': jobId,
            'jobTitle': jobTitle,
            'name': log['name'] ?? '',
            'companyName': log['name'] ?? '',
            'jobLocation': log['job_location'] ?? '',
            'route': log['route'] ?? '',
            'vehicleType': vehicleType,
            'licenseType': log['license_type'] ?? '',
            'experience': log['experience'] ?? '',
            'salaryFixed': log['salary_fixed'],
            'salaryVariable': log['salary_variable'],
            'esiPf': log['esi_pf'] ?? '',
            'foodAllowance': log['food_allowance'],
            'tripIncentive': log['trip_incentive'],
            'rehneKiSuvidha': log['rehne_ki_suvidha'] ?? '',
            'mileage': log['mileage'] ?? '',
            'fastTagRoadKharcha': log['fast_tag_road_kharcha'] ?? '',
            'callStatusFeedback': _formatCallStatus(
              log['call_status']?.toString() ?? '',
            ),
            'callFeedback': log['call_feedback'] ?? '',
            'callRemarks': log['call_remarks'] ?? '',
            'callRecording': log['call_recording'] ?? '',
            'callDuration': log['call_duration'] ?? '',
            'activeTime': log['active_time'] ?? '',
            'requiredDrivers': log['required_drivers'] ?? '',
            'createdAt': log['created_at'] ?? '',
            'updatedAt': log['updated_at'] ?? '',
            'callerName': user?.name ?? '',
          };
        }).toList();

        // Sort by created_at descending (latest feedback on top)
        transformedLogs.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? '';
          return dateB.compareTo(dateA); // Descending order (newest first)
        });

        print('=== FINAL TRANSFORMED LOGS ===');
        print('Count: ${transformedLogs.length}');

        return List<Map<String, dynamic>>.from(transformedLogs);
      } else if (response.statusCode == 401) {
        print('=== API ERROR ===');
        print('Status code: 401');
        print('Response body: ${response.body}');
        throw Exception(
          'Authentication failed. Please logout and login again.',
        );
      } else {
        print('=== API ERROR ===');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('=== EXCEPTION IN getTransporterCallHistory ===');
      print('Error: $e');
      throw Exception('Failed to fetch call history: $e');
    }
  }

  // Get list of transporters with call history
  static Future<List<Map<String, dynamic>>>
  getTransportersWithCallHistory() async {
    try {
      // Get current user's caller_id
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      // Get auth token from RealAuthService
      final token = await RealAuthService.instance.getAuthToken();

      print('=== FETCHING TRANSPORTERS LIST (LARAVEL API) ===');
      print('User: ${user?.name ?? "NULL"}');
      print('User ID: ${user?.id ?? "NULL"}');
      print('Caller ID: $callerId');
      print('Token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        print('⚠️ No token available - user may need to re-login');
        throw Exception(
          'Authentication token not found. Please logout and login again.',
        );
      }

      print(
        'URL: https://truckmitr.com/api/telehead/call-logs/assigned-to/$callerId',
      );

      final response = await http.get(
        Uri.parse(
          'https://truckmitr.com/api/telehead/call-logs/assigned-to/$callerId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('=== TRANSPORTERS API RESPONSE ===');
        print('Response type: ${data.runtimeType}');
        print(
          'Response keys: ${data is Map ? data.keys.toList() : "Not a map"}',
        );

        // Laravel API returns call_logs array
        List<dynamic> callLogs = [];
        if (data is List) {
          callLogs = data;
        } else if (data is Map && data.containsKey('call_logs')) {
          callLogs = data['call_logs'] is List ? data['call_logs'] : [];
        } else if (data is Map && data.containsKey('data')) {
          callLogs = data['data'] is List ? data['data'] : [];
        }

        print('Total call logs found: ${callLogs.length}');

        // Group by transporter unique_id and count calls
        Map<String, Map<String, dynamic>> transporterMap = {};

        // Debug: Print first few logs to see job_id values
        if (callLogs.isNotEmpty) {
          print('=== DEBUG: First 3 call logs job_id values ===');
          for (int i = 0; i < callLogs.length && i < 3; i++) {
            print(
              'Log $i: job_id = "${callLogs[i]['job_id']}", unique_id = "${callLogs[i]['unique_id']}"',
            );
          }
        }

        for (var log in callLogs) {
          final tmid = log['unique_id']?.toString() ?? '';
          if (tmid.isEmpty) continue;

          // Get job_id and validate it - filter out null, empty, 'null', 'N/A', and DIRECT_CALL prefixes
          final rawJobId = log['job_id'];
          String jobId = '';
          if (rawJobId != null) {
            final jobIdStr = rawJobId.toString().trim();
            final jobIdLower = jobIdStr.toLowerCase();
            if (jobIdStr.isNotEmpty &&
                jobIdLower != 'null' &&
                jobIdLower != 'n/a' &&
                !jobIdStr.startsWith('DIRECT_CALL')) {
              jobId = jobIdStr;
            }
          }

          print(
            '🔍 Processing log: tmid=$tmid, raw_job_id="$rawJobId", validated_jobId="$jobId"',
          );

          if (!transporterMap.containsKey(tmid)) {
            transporterMap[tmid] = {
              'tmid': tmid,
              'name': log['name'] ?? '',
              'phone': log['mobile'] ?? '',
              'company': '',
              'city': '',
              'state': '',
              'location': log['job_location'] ?? '',
              'id': log['user_id']?.toString() ?? '',
              'callCount': 0,
              'lastCallDate': null,
              'latestJobId': jobId, // Store the validated job_id
            };
          }

          // Increment call count
          transporterMap[tmid]!['callCount'] =
              (transporterMap[tmid]!['callCount'] ?? 0) + 1;

          // Update last call date and latest job_id
          final logDate = log['created_at'] ?? log['updated_at'];
          if (logDate != null) {
            final currentLast = transporterMap[tmid]!['lastCallDate'];
            if (currentLast == null ||
                logDate.toString().compareTo(currentLast.toString()) > 0) {
              transporterMap[tmid]!['lastCallDate'] = logDate;
              // Update latest job_id when we find a newer call with valid job_id
              if (jobId.isNotEmpty) {
                transporterMap[tmid]!['latestJobId'] = jobId;
              }
            }
          }

          // Also update latestJobId if current one is empty but this log has a valid one
          if ((transporterMap[tmid]!['latestJobId'] ?? '').toString().isEmpty &&
              jobId.isNotEmpty) {
            transporterMap[tmid]!['latestJobId'] = jobId;
          }
        }

        // Debug: Print transporter job IDs
        print('=== DEBUG: Transporter latestJobId values ===');
        transporterMap.forEach((tmid, data) {
          print('TMID: $tmid, latestJobId: "${data['latestJobId']}"');
        });

        print('Unique transporters found: ${transporterMap.length}');

        // Convert to list and sort by last call date
        final transportersList = transporterMap.values.toList();
        transportersList.sort((a, b) {
          final dateA = a['lastCallDate']?.toString() ?? '';
          final dateB = b['lastCallDate']?.toString() ?? '';
          return dateB.compareTo(dateA); // Most recent first
        });

        return transportersList;
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
    String? callRecording,
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
        if (callRecording != null) 'callRecording': callRecording,
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
  static Future<List<Map<String, dynamic>>> fetchCallLogs({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = await Phase2AuthService.getCurrentUser();
      final callerId = user?.id ?? 0;

      final uri = Uri.parse('$baseUrl/phase2_call_analytics_api.php').replace(
        queryParameters: {
          'action': 'logs',
          'limit': limit.toString(),
          'offset': offset.toString(),
          'caller_id': callerId.toString(),
        },
      );

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
      request.files.add(
        await http.MultipartFile.fromPath('recording', filePath),
      );

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

  // Upload transporter call recording
  static Future<Map<String, dynamic>> uploadTransporterCallRecording({
    required String filePath,
    required String jobId,
    required int callerId,
    required String transporterTmid,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/phase2_upload_driver_recording_api.php');

      var request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('recording', filePath),
      );

      // Add form fields
      request.fields['job_id'] = jobId;
      request.fields['caller_id'] = callerId.toString();
      request.fields['transporter_tmid'] = transporterTmid;

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

  // Upload call recording (generic - supports both driver and transporter)
  static Future<Map<String, dynamic>> uploadCallRecording({
    required String filePath,
    required String jobId,
    required int callerId,
    String? driverTmid,
    String? transporterTmid,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/phase2_upload_driver_recording_api.php');

      var request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('recording', filePath),
      );

      // Add form fields
      request.fields['job_id'] = jobId;
      request.fields['caller_id'] = callerId.toString();

      if (driverTmid != null) {
        request.fields['driver_tmid'] = driverTmid;
      }
      if (transporterTmid != null) {
        request.fields['transporter_tmid'] = transporterTmid;
      }

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

  // Initiate IVR call for job matching
  static Future<Map<String, dynamic>> initiateIVRCallJobMatching({
    required String uniqueIdTransporter,
    required String uniqueIdDriver,
    required int userIdTransporter,
    required int userIdDriver,
    required int assignedTo,
    required String jobId,
    required String transporterName,
    required String driverName,
    required String exten,
    required String number,
  }) async {
    try {
      // Get current user for logging
      final currentUser = await Phase2AuthService.getCurrentUser();
      print(
        '🔵 Current User: ID=${currentUser?.id}, Name=${currentUser?.name}',
      );
      print('🔵 assignedTo parameter: $assignedTo');

      final requestBody = {
        'unique_id_transporter': uniqueIdTransporter,
        'unique_id_driver': uniqueIdDriver,
        'user_id_transporter': userIdTransporter,
        'user_id_driver': userIdDriver,
        'assigned_to': assignedTo,
        'job_id': jobId,
        'transporter_name': transporterName,
        'driver_name': driverName,
        'exten': exten,
        'number': number,
      };

      print('=== IVR CALL JOB MATCHING API ===');
      print('URL: ${ApiConfig.ivrCallJobMatchingApi}');
      print('Request Body: ${json.encode(requestBody)}');

      // Get auth token from RealAuthService
      String? authToken;
      try {
        authToken = await RealAuthService.instance.getAuthToken();
        print(
          '✓ Auth token retrieved: ${authToken?.substring(0, authToken.length > 20 ? 20 : authToken.length)}...',
        );
      } catch (e) {
        print('⚠️ Could not get auth token: $e');
      }

      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      print(
        'Headers: Content-Type: application/json, Authorization: Bearer ${authToken != null ? '***' : 'NOT_SET'}',
      );

      final response = await http.post(
        Uri.parse(ApiConfig.ivrCallJobMatchingApi),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          print('✓ IVR call initiated successfully');
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to initiate IVR call');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('✗ Exception in initiateIVRCallJobMatching: $e');
      throw Exception('Failed to initiate IVR call: $e');
    }
  }

  // Update IVR call feedback for job matching
  static Future<Map<String, dynamic>> updateIVRCallJobMatchingFeedback({
    required String matchId,
    required String callStatus,
    required String callFeedback,
    String? callRemarks,
    String? callRecording,
    String? matchStatus,
  }) async {
    try {
      final requestBody = {
        'id': matchId,
        'call_status': callStatus,
        'call_feedback': callFeedback,
        'call_remarks': callRemarks ?? '',
        'call_recording': callRecording ?? '',
        if (matchStatus != null && matchStatus.isNotEmpty)
          'match_status': matchStatus.toLowerCase(),
      };

      print('=== UPDATE IVR CALL JOB MATCHING FEEDBACK API ===');
      print(
        'URL: ${ApiConfig.ivrCallUpdateJobMatchingApi}',
      );
      print('Request Body: ${json.encode(requestBody)}');

      // Get auth token from RealAuthService
      String? authToken;
      try {
        authToken = await RealAuthService.instance.getAuthToken();
        print(
          '✓ Auth token retrieved: ${authToken?.substring(0, authToken.length > 20 ? 20 : authToken.length)}...',
        );
      } catch (e) {
        print('⚠️ Could not get auth token: $e');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      print(
        'Headers: Content-Type: application/json, Authorization: Bearer ${authToken != null ? '***' : 'NOT_SET'}',
      );
      print('Auth token is set: ${authToken != null && authToken.isNotEmpty}');

      print('Auth Token :  $authToken');

      final response = await http.post(
        Uri.parse(ApiConfig.ivrCallUpdateJobMatchingApi),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print(
        'Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      // Handle redirects (301, 302, 303, 307, 308)
      if (response.statusCode >= 300 && response.statusCode < 400) {
        print('⚠️ Redirect detected (${response.statusCode})');
        print('Location header: ${response.headers['location']}');

        // Try to follow the redirect only if it's a valid API endpoint
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null && redirectUrl.contains('/api/')) {
          print('🔵 Following redirect to: $redirectUrl');

          final redirectResponse = await http.post(
            Uri.parse(redirectUrl),
            headers: headers,
            body: json.encode(requestBody),
          );

          print('Redirect Response Status: ${redirectResponse.statusCode}');
          print('Redirect Response Body: ${redirectResponse.body}');

          if (redirectResponse.statusCode == 200) {
            try {
              final data = json.decode(redirectResponse.body);
              print('✓ IVR call feedback updated successfully (via redirect)');
              return data;
            } catch (e) {
              print('✗ Error parsing redirect response: $e');
              throw Exception('Failed to parse redirect response: $e');
            }
          }
        } else {
          print(
            '⚠️ Redirect URL is invalid or not an API endpoint: $redirectUrl',
          );
        }

        throw Exception(
          'Server redirect: ${response.statusCode} - ${response.headers['location']}',
        );
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Parsed Response Data: $data');
          if (data['success'] == true || data['status'] == 'success') {
            print('✓ IVR call feedback updated successfully');
            return data;
          } else {
            print('⚠️ API returned success=false: ${data['message']}');
            throw Exception(
              data['message'] ?? 'Failed to update IVR call feedback',
            );
          }
        } catch (e) {
          print('✗ Error parsing response: $e');
          print('Raw response body: ${response.body}');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        print('✗ Server error: ${response.statusCode}');
        print('Error response body: ${response.body}');
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('✗ Exception in updateIVRCallJobMatchingFeedback: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to update IVR call feedback: $e');
    }
  }

  // Initiate IVR call for job brief
  static Future<Map<String, dynamic>> initiateIVRCallJobBrief({
    required String uniqueId,
    required int transporterUserId, // Transporter's user ID
    required int assignedTo,
    required String jobId,
    required String exten,
    required String number,
  }) async {
    try {
      final requestBody = {
        'unique_id': uniqueId,
        'user_id': transporterUserId, // Transporter's user ID
        'assigned_to': assignedTo,
        'job_id': jobId,
        'exten': exten,
        'number': number,
      };

      print('=== IVR CALL JOB BRIEF API ===');
      print('URL: ${ApiConfig.ivrCallJobBriefApi}');
      print('Request Body: ${json.encode(requestBody)}');

      // Get auth token from RealAuthService
      String? authToken;
      try {
        authToken = await RealAuthService.instance.getAuthToken();
        print(
          '✓ Auth token retrieved: ${authToken?.substring(0, authToken.length > 20 ? 20 : authToken.length)}...',
        );
      } catch (e) {
        print('⚠️ Could not get auth token: $e');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      print(
        'Headers: Content-Type: application/json, Authorization: Bearer ${authToken != null ? '***' : 'NOT_SET'}',
      );

      final response = await http.post(
        Uri.parse(ApiConfig.ivrCallJobBriefApi),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');

      // Handle redirects (301, 302, 303, 307, 308)
      if (response.statusCode >= 300 && response.statusCode < 400) {
        print('⚠️ Redirect detected (${response.statusCode})');
        print('Location header: ${response.headers['location']}');

        // Try to follow the redirect
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          print('🔵 Following redirect to: $redirectUrl');

          final redirectResponse = await http.post(
            Uri.parse(redirectUrl),
            headers: headers,
            body: json.encode(requestBody),
          );

          print('Redirect Response Status: ${redirectResponse.statusCode}');
          print('Redirect Response Body: ${redirectResponse.body}');

          if (redirectResponse.statusCode == 200) {
            try {
              final data = json.decode(redirectResponse.body);
              print('✓ IVR call initiated successfully (via redirect)');
              return data;
            } catch (e) {
              print('✗ Error parsing redirect response: $e');
              throw Exception('Failed to parse redirect response: $e');
            }
          }
        }

        throw Exception(
          'Server redirect: ${response.statusCode} - ${response.headers['location']}',
        );
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Parsed Response Data: $data');
          if (data['success'] == true || data['status'] == 'success') {
            print('✓ IVR call initiated successfully');
            return data;
          } else {
            print('⚠️ API returned success=false: ${data['message']}');
            throw Exception(data['message'] ?? 'Failed to initiate IVR call');
          }
        } catch (e) {
          print('✗ Error parsing response: $e');
          print('Raw response body: ${response.body}');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        print('✗ Server error: ${response.statusCode}');
        print('Error response body: ${response.body}');
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('✗ Exception in initiateIVRCallJobBrief: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to initiate IVR call: $e');
    }
  }

  // Update IVR call feedback for job brief
  static Future<Map<String, dynamic>> updateIVRCallJobBriefFeedback({
    required String jobBriefId,
    required String name,
    required String jobLocation,
    required String route,
    required String vehicleType,
    required String licenseType,
    required String experience,
    required String salaryFixed,
    required String salaryVariable,
    required String esiPf,
    required String foodAllowance,
    required String tripIncentive,
    required String rehneKiSuvidha,
    required String mileage,
    required String fastTagRoadKharcha,
    required String closedJob,
    required String callStatus,
    required String callFeedback,
    String? callRecording,
    String? callRemarks,
    String? requiredDrivers,
  }) async {
    try {
      final requestBody = {
        'id': jobBriefId,
        'name': name,
        'job_location': jobLocation,
        'route': route,
        'vehicle_type': vehicleType,
        'license_type': licenseType,
        'experience': experience,
        'salary_fixed': salaryFixed,
        'salary_variable': salaryVariable,
        'esi_pf': esiPf,
        'food_allowance': foodAllowance,
        'trip_incentive': tripIncentive,
        'rehne_ki_suvidha': rehneKiSuvidha,
        'mileage': mileage,
        'fast_tag_road_kharcha': fastTagRoadKharcha,
        'closed_job': closedJob,
        'call_status': callStatus,
        'call_feedback': callFeedback,
        'call_recording': callRecording ?? '',
        'call_remarks': callRemarks ?? '',
        'required_drivers': requiredDrivers ?? '',
      };

      print('=== UPDATE IVR CALL JOB BRIEF FEEDBACK API ===');
      print('URL: ${ApiConfig.ivrCallUpdateJobBriefApi}');
      print('Request Body: ${json.encode(requestBody)}');

      // Get auth token from RealAuthService
      String? authToken;
      try {
        authToken = await RealAuthService.instance.getAuthToken();
        print(
          '✓ Auth token retrieved: ${authToken?.substring(0, authToken.length > 20 ? 20 : authToken.length)}...',
        );
      } catch (e) {
        print('⚠️ Could not get auth token: $e');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      print(
        'Headers: Content-Type: application/json, Authorization: Bearer ${authToken != null ? '***' : 'NOT_SET'}',
      );
      print('Auth token is set: ${authToken != null && authToken.isNotEmpty}');

      final response = await http.post(
        Uri.parse(ApiConfig.ivrCallUpdateJobBriefApi),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print(
        'Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      // Handle redirects (301, 302, 303, 307, 308)
      if (response.statusCode >= 300 && response.statusCode < 400) {
        print('⚠️ Redirect detected (${response.statusCode})');
        print('Location header: ${response.headers['location']}');
        print('❌ Server returned redirect instead of processing the request');
        print(
          'This usually means: 1) Auth token is invalid, 2) Request format is wrong, 3) Server configuration issue',
        );

        throw Exception(
          'Server returned redirect (${response.statusCode}). Please check auth token and request format.',
        );
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Parsed Response Data: $data');
          if (data['success'] == true || data['status'] == 'success') {
            print('✓ Job brief feedback updated successfully');
            return data;
          } else {
            print('⚠️ API returned success=false: ${data['message']}');
            throw Exception(
              data['message'] ?? 'Failed to update job brief feedback',
            );
          }
        } catch (e) {
          print('✗ Error parsing response: $e');
          print('Raw response body: ${response.body}');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        print('✗ Server error: ${response.statusCode}');
        print('Error response body: ${response.body}');
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('✗ Exception in updateIVRCallJobBriefFeedback: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to update job brief feedback: $e');
    }
  }

  // Helper method to format call_status to display format
  static String _formatCallStatus(String callStatus) {
    switch (callStatus.toLowerCase()) {
      case 'connected':
        return 'Connected';
      case 'not_connected':
        return 'Not Connected';
      case 'callback_later':
        return 'Callback Later';
      default:
        return callStatus;
    }
  }

  // Add driver to bucket
  static Future<void> addToDriverBucket({
    required int userId,
    required String uniqueId,
    required int assignedTo,
    required String jobId,
  }) async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(ApiConfig.driverBucketApi);

      // Extract numeric job ID from string like "TMJB00593" -> "593"
      String numericJobId = jobId;
      if (jobId.startsWith('TMJB')) {
        numericJobId = jobId
            .replaceFirst('TMJB', '')
            .replaceFirst(RegExp(r'^0+'), '');
        if (numericJobId.isEmpty) numericJobId = '0';
      }

      final requestBody = {
        'user_id': userId,
        'unique_id': uniqueId,
        'assgined_to': assignedTo, // Backend typo 'assgined_to'
        'job_id': numericJobId, // Send numeric ID only (e.g., "593")
      };

      print('=== ADDING TO DRIVER BUCKET ===');
      print('URL: $uri');
      print('Body: $requestBody');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        return;
      } else {
        try {
          final body = json.decode(response.body);
          if (response.statusCode == 422 && body['errors'] != null) {
            if (body['errors']['unique_id'] != null) {
              final errors = body['errors']['unique_id'] as List;
              if (errors.any((e) => e.toString().contains('taken'))) {
                throw Exception('Driver is already in the bucket.');
              }
            }
            // Handle other validation errors similarly if needed
            throw Exception(body['message'] ?? 'Validation error');
          }
          throw Exception(
            body['message'] ??
                'Failed to add to bucket: ${response.statusCode}',
          );
        } catch (e) {
          if (e.toString().contains('already in the bucket')) rethrow;
          throw Exception(
            'Failed to add to bucket: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to add to driver bucket: $e');
    }
  }

  // Fetch driver buckets
  static Future<List<DriverApplicant>> fetchDriverBuckets() async {
    try {
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final uri = Uri.parse(
        'https://truckmitr.com/api/telehead/driver-buckets',
      );

      print('=== FETCHING DRIVER BUCKETS ===');
      print('URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> driversJson = data['drivers'] ?? [];

        return driversJson.map((json) {
          // Get the full job_id string (e.g., "TMJB00250")
          final jobIdStr = json['job_id']?.toString() ?? '';
          // Extract numeric part for jobId int field
          final numericJobId =
              int.tryParse(jobIdStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

          final transformedJson = {
            'jobId': numericJobId,
            'jobIdString': jobIdStr, // Full job ID like "TMJB00250"
            'jobTitle': '',
            'contractorId': 0,
            'transporterTmid': '',
            'transporterName': '',
            'driverId': json['driver_id'] ?? 0,
            'driverTmid':
                json['driver_unique_id'] ?? json['bucket_unique_id'] ?? '',
            'name': json['driver_name'] ?? '',
            'mobile': json['mobile'] ?? '',
            'email': '',
            'city': '', // Not in JSON, assume empty
            'state': json['state_name'] ?? '',
            'gender': null,
            'profileImage': json['images'],
            'vehicleType': (json['vehicle_type'] ?? '')
                .toString()
                .replaceAll('\n', ' ')
                .trim(),
            'drivingExperience': json['Driving_Experience']?.toString() ?? '',
            'licenseType': json['Type_of_License'] ?? '',
            'licenseNumber': '',
            'preferredLocation': '',
            'aadharNumber': '',
            'panNumber': '',
            'gstNumber': '',
            'status': 'active',
            'createdAt': json['bucket_created_at'] ?? '',
            'updatedAt': json['job_updated_at'] ?? '',
            'appliedAt': json['applied_at'] ?? '', // Might be null
            'profileCompletion': json['profile_completion'] ?? 0,
            'subscriptionAmount': json['subscription']?['amount']?.toString(),
            'subscriptionStartDate': json['subscription']?['start_at'],
            'subscriptionStatus': json['subscription'] != null
                ? 'active'
                : 'inactive',
            'callStatus': json['call_status'],
            'callFeedback': json['call_feedback'],
            'callRemarks': json['call_remarks'],
            'matchStatus': json['match_status'],
            // Use added_by field for the name of who added to bucket
            'matchMakerName': json['added_by'],
            'feedbackNotes': null,
            'otherAppliedJobs': null,
            'totalJobsApplied':
                int.tryParse(json['total_jobs_applied']?.toString() ?? '0') ??
                0,
          };
          return DriverApplicant.fromJson(transformedJson);
        }).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch driver buckets: $e');
    }
  }
}
