/// Centralized API Configuration
/// Update the base domain here and it will reflect across all services
class ApiConfig {
  // ⚠️ DEPLOYMENT MODE: Switch between LOCAL and ONLINE
  // LOCAL DEVELOPMENT: (Removed)
  // static const String serverIp = '192.168.1.10';
  // static const String baseUrl = 'http://$serverIp/TMemployeeApp/api';
  // static const String publicUrl = 'http://$serverIp/TMemployeeApp/public';

  // PRODUCTION: Plesk Server (Active)
  // static const String domain = 'truckmitr.com';
  static const String domain = 'devtruckmitr.in';
  static const String baseUrl = 'https://$domain/truckmitr-app/api';
  static const String serverIp = domain;
  static const String publicUrl = 'https://$domain/public';

  // Laravel API Base URLs
  // static const String laravelApiBase = 'https://truckmitr.com/api';
  static const String laravelApiBase = 'https://$domain/api';
  static const String teleheadApiBase = 'https://$domain/api/telehead';
  static const String storageBase = 'https://$domain/storage/app/public';
  static const String publicStorageBase = 'https://$domain/public/storage';

  // Margdarshak uses laravelApiBase

  static String get margdarshakApiBase => laravelApiBase;

  // TaskSuite HRMS Base URL
  static const String taskSuiteBase =
      'https://tasksuite.$domain/backend/public/api';

  // Laravel API Endpoints (Telehead)
  static const String loginApi = '$teleheadApiBase/login';
  static const String getStates = '$laravelApiBase/states';
  static const String forgotPasswordApi = '$teleheadApiBase/forgot-password';
  static const String resetPasswordApi = '$teleheadApiBase/reset-password';
  static const String agentJobsApi = '$teleheadApiBase/agent-jobs';
  static const String driversApi = '$teleheadApiBase/drivers';
  static const String jobsApi = '$teleheadApiBase/jobs';
  static const String rejectedApplyJobsApi =
      '$teleheadApiBase/rejected-apply-jobs';
  static const String callLogsApi = '$teleheadApiBase/call-logs';
  static const String ivrCallJobMatchingApi =
      '$teleheadApiBase/ivr-call-jobMatching';
  static const String ivrCallUpdateJobMatchingApi =
      '$teleheadApiBase/ivr-call-update-jobMatching';
  static const String ivrCallJobBriefApi = '$teleheadApiBase/ivr-call-jobBrief';
  static const String ivrCallUpdateJobBriefApi =
      '$teleheadApiBase/ivr-call-update-jobBrief';
  static const String driverBucketApi = '$teleheadApiBase/driver-bucket';
  static const String driverBucketsApi = '$teleheadApiBase/driver-buckets';
  static const String paymentsSearchApi = '$teleheadApiBase/payments/search';
  static const String withoutCallHistoryApi =
      '$teleheadApiBase/withoutCallHistory';
  static const String reportsApi =
      '$teleheadApiBase/reports/assigned-to-wise-summary';
  static const String socialMediaLeadsApi =
      '$teleheadApiBase/social-media-leads';
  static const String socialMediaCallHistoryApi =
      '$teleheadApiBase/social-media-call-history';
  static const String todayLeadsApi = '$teleheadApiBase/today-leads';
  static const String callHistoryApi = '$teleheadApiBase/call-history';
  static const String matchMakingHistoryApi =
      '$teleheadApiBase/match-making-history';
  static const String socialMediaIvrCallsApi =
      '$teleheadApiBase/social-media-ivr-calls';
  static const String breakLogsApi = '$teleheadApiBase/break-logs';
  static const String analyticsApi = '$teleheadApiBase/analytics';
  static const String ivrCallUpdateApi = '$teleheadApiBase/ivr-call-update';
  static const String socialMediaIvrCallApi =
      '$teleheadApiBase/social-media-ivr-call';

  // Margdarshak API Endpoints
  static String get margdarshakDashboardApi =>
      '$margdarshakApiBase/margdarshak/dashboard';
  static String get margdarshakTerritoryDriversApi =>
      '$margdarshakApiBase/margdarshak/territory-drivers';
  static String get margdarshakTerritoryShopsApi =>
      '$margdarshakApiBase/margdarshak/territory-shops';
  static String get margdarshakTerritoryOverviewApi =>
      '$margdarshakApiBase/margdarshak/territory-overview';
  static String get margdarshakShopDriversApi =>
      '$margdarshakApiBase/margdarshak/shop-drivers';
  static String get margdarshakDutyStartStopApi =>
      '$margdarshakApiBase/margdarshak/duty/start-stop';
  static String get margdarshakLocationUpdateApi =>
      '$margdarshakApiBase/margdarshak/duty/update-location';

  // Margdarshak Dhaba Profile Completion APIs
  static String get margdarshakDhabaBusinessInfoApi =>
      '$margdarshakApiBase/margdarshak/dhaba/business-info';
  static String get margdarshakDhabaLocationApi =>
      '$margdarshakApiBase/margdarshak/dhaba/location';
  static String get margdarshakDhabaOperationApi =>
      '$margdarshakApiBase/margdarshak/dhaba/operation';
  static String get margdarshakDhabaFacilitiesApi =>
      '$margdarshakApiBase/margdarshak/dhaba/facilities';
  static String get margdarshakDhabaFoodApi =>
      '$margdarshakApiBase/margdarshak/dhaba/food';
  static String get margdarshakDhabaPhotosApi =>
      '$margdarshakApiBase/margdarshak/dhaba/photos';
  static String get margdarshakDhabaBankingApi =>
      '$margdarshakApiBase/margdarshak/dhaba/banking';
  static String get margdarshakDhabaEngagementApi =>
      '$margdarshakApiBase/margdarshak/dhaba/engagement';
  static String get margdarshakDhabaProfileApi =>
      '$margdarshakApiBase/margdarshak/dhaba/profile';
  static String get margdarshakDhabaDetailsApi =>
      '$margdarshakApiBase/margdarshak/dhaba/details';
  static String get margdarshakEarningsApi =>
      '$margdarshakApiBase/margdarshak/earnings';

  // Margdarshak Puncture Shop Profile Completion APIs
  static String get margdarshakPunctureBusinessInfoApi =>
      '$margdarshakApiBase/margdarshak/puncture/business-info';
  static String get margdarshakPunctureLocationApi =>
      '$margdarshakApiBase/margdarshak/puncture/location';
  static String get margdarshakPunctureOperationApi =>
      '$margdarshakApiBase/margdarshak/puncture/operation';
  static String get margdarshakPunctureServicesApi =>
      '$margdarshakApiBase/margdarshak/puncture/services';
  static String get margdarshakPuncturePhotosApi =>
      '$margdarshakApiBase/margdarshak/puncture/photos';
  static String get margdarshakPunctureDetailsApi =>
      '$margdarshakApiBase/margdarshak/puncture/details';

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

  // Privacy Policy & Terms and Conditions
  static String get privacyPolicyApi => '$laravelApiBase/privacy-policy';
  static String get termsAndConditionsApi =>
      '$laravelApiBase/terms-and-conditions';

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
