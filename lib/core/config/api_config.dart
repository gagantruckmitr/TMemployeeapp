/// Centralized API Configuration
/// Update the IP address here and it will reflect across all services
class ApiConfig {
  // ⚠️ DEPLOYMENT MODE: Switch between LOCAL and ONLINE
  // LOCAL DEVELOPMENT: (Commented out)
  // static const String serverIp = '192.168.29.149';
  // static const String baseUrl = 'http://$serverIp/truckmitr-app/api';

  // PRODUCTION: Plesk Server (Active)
  static const String baseUrl = 'https://truckmitr.com/truckmitr-app/api';
  static const String serverIp = 'truckmitr.com';

  // ONLINE PRODUCTION: InfinityFree hosting (Commented out)
  // static const String baseUrl = 'https://truckmitr.gt.tc/api';
  // static const String serverIp = 'truckmitr.gt.tc'; // For display only

  // Specific API Endpoints
  static const String authApi = '$baseUrl/auth_api.php';
  static const String dashboardStatsApi =
      '$baseUrl/telecaller_dashboard_stats.php';
  static const String freshLeadsApi = '$baseUrl/fresh_leads_api.php';
  static const String driversApi = '$baseUrl/simple_drivers_api.php';
  static const String managerDashboardApi =
      '$baseUrl/manager_dashboard_api.php';
  static const String telecallerAnalyticsApi =
      '$baseUrl/telecaller_analytics_api.php';
  // Production IVR API - Click2Call
  static const String click2CallIvrApi = '$baseUrl/click2call_ivr_api.php';

  // Timeout Configuration
  static const Duration timeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);

  // Helper method to get full API URL
  static String getApiUrl(String endpoint) {
    return '$baseUrl/$endpoint';
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
