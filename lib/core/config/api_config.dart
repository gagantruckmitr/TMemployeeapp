/// Centralized API Configuration
/// Update the base domain here and it will reflect across all services
class ApiConfig {
  // ⚠️ DEPLOYMENT MODE: Switch between LOCAL and ONLINE
  // LOCAL DEVELOPMENT: (Removed)
  // static const String serverIp = '192.168.1.10';
  // static const String baseUrl = 'http://$serverIp/TMemployeeApp/api';
  // static const String publicUrl = 'http://$serverIp/TMemployeeApp/public';

  // PRODUCTION: Plesk Server (Active)
  static const String domain = 'development.truckmitr.com';
  static const String baseUrl = 'https://$domain/truckmitr-app/api';
  static const String serverIp = domain;
  static const String publicUrl = 'https://$domain/public';

  // Laravel API Base URLs
  static const String laravelApiBase = 'https://$domain/api/telehead';
  static const String storageBase = 'https://$domain/storage/app/public';

  // TaskSuite HRMS Base URL
  static const String taskSuiteBase =
      'https://tasksuite.$domain/backend/public/api';

  // Laravel API Endpoints
  static const String loginApi = '$laravelApiBase/login';
  static const String forgotPasswordApi = '$laravelApiBase/forgot-password';
  static const String resetPasswordApi = '$laravelApiBase/reset-password';
  static const String agentJobsApi = '$laravelApiBase/agent-jobs';
  static const String driversApi = '$laravelApiBase/drivers';
  static const String jobsApi = '$laravelApiBase/jobs';
  static const String rejectedApplyJobsApi =
      '$laravelApiBase/rejected-apply-jobs';
  static const String callLogsApi = '$laravelApiBase/call-logs';
  static const String ivrCallJobMatchingApi =
      '$laravelApiBase/ivr-call-jobMatching';
  static const String ivrCallUpdateJobMatchingApi =
      '$laravelApiBase/ivr-call-update-jobMatching';
  static const String ivrCallJobBriefApi = '$laravelApiBase/ivr-call-jobBrief';
  static const String ivrCallUpdateJobBriefApi =
      '$laravelApiBase/ivr-call-update-jobBrief';
  static const String driverBucketApi = '$laravelApiBase/driver-bucket';
  static const String driverBucketsApi = '$laravelApiBase/driver-buckets';
  static const String paymentsSearchApi = '$laravelApiBase/payments/search';
  static const String withoutCallHistoryApi =
      '$laravelApiBase/withoutCallHistory';
  static const String reportsApi =
      '$laravelApiBase/reports/assigned-to-wise-summary';
  static const String socialMediaLeadsApi =
      '$laravelApiBase/social-media-leads';
  static const String socialMediaCallHistoryApi =
      '$laravelApiBase/social-media-call-history';
  static const String todayLeadsApi = '$laravelApiBase/today-leads';
  static const String callHistoryApi = '$laravelApiBase/call-history';
  static const String matchMakingHistoryApi =
      '$laravelApiBase/match-making-history';
  static const String socialMediaIvrCallsApi =
      '$laravelApiBase/social-media-ivr-calls';
  static const String breakLogsApi = '$laravelApiBase/break-logs';
  static const String analyticsApi = '$laravelApiBase/analytics';
  static const String ivrCallUpdateApi = '$laravelApiBase/ivr-call-update';
  static const String socialMediaIvrCallApi =
      '$laravelApiBase/social-media-ivr-call';

  // Email Configuration
  static const String hrEmail = 'hr@$domain';
  static const String commandCentreEmail = 'harneet.kaur@$domain';

  // ONLINE PRODUCTION: InfinityFree hosting (Commented out)
  // static const String baseUrl = 'https://truckmitr.gt.tc/api';
  // static const String serverIp = 'truckmitr.gt.tc'; // For display only

  // Specific API Endpoints
  static const String authApi = '$baseUrl/auth_api.php';
  static const String dashboardStatsApi =
      '$baseUrl/telecaller_dashboard_stats.php';
  // REMOVED: fresh_leads_api.php has been deleted from server\n  // static const String freshLeadsApi = '$baseUrl/fresh_leads_api.php';
  static const String backlogLeadsApi = '$baseUrl/backlog_leads_api.php';
  static const String legacyDriversApi = '$baseUrl/simple_drivers_api.php';
  static const String managerDashboardApi =
      '$baseUrl/manager_dashboard_api.php';
  static const String telecallerAnalyticsApi =
      '$baseUrl/telecaller_analytics_api.php';
  // Production IVR API - Click2Call
  static const String click2CallIvrApi = '$baseUrl/click2call_ivr_api.php';

  // Timeout Configuration
  static const Duration timeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);

  // Helper method to get storage URL for images
  static String getStorageUrl(String path) {
    if (path.isEmpty) return '';
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$storageBase/$cleanPath';
  }

  // Helper method to get public URL for assets
  static String getPublicUrl(String path) {
    if (path.isEmpty) return '';
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$publicUrl/$cleanPath';
  }

  // Helper method to get Laravel API URL with endpoint and query parameters
  static String getLaravelApiUrl(String endpoint) {
    return '$laravelApiBase/$endpoint';
  }

  // Helper method to get call history URL for assigned user
  static String getCallHistoryUrl(int assignedToId) {
    return '$laravelApiBase/call-history/$assignedToId';
  }

  // Helper method to get jobs assigned to URL
  static String getJobsAssignedToUrl(int callerId) {
    return '$laravelApiBase/jobs/assigned-to/$callerId';
  }

  // Helper method to get call logs assigned to URL
  static String getCallLogsAssignedToUrl(int callerId) {
    return '$laravelApiBase/call-logs/assigned-to/$callerId';
  }

  // Helper method to get TaskSuite API URL with endpoint
  static String getTaskSuiteUrl(String endpoint) {
    return '$taskSuiteBase/$endpoint';
  }

  // Helper method to check if using localhost
  static bool get isLocalhost =>
      serverIp == 'localhost' || serverIp == '127.0.0.1';

  // Helper method to get current configuration info
  static Map<String, String> get configInfo => {
    'Server IP': serverIp,
    'Base URL': baseUrl,
    'Is Localhost': isLocalhost.toString(),
  };
}
