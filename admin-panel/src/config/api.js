// API Configuration
// LOCAL DEVELOPMENT
export const API_BASE_URL = 'http://192.168.29.149/api';

// PRODUCTION (Commented out)
// export const API_BASE_URL = 'https://truckmitr.com/truckmitr-app/api';

export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/auth_api.php',
  
  // Dashboard
  DASHBOARD_STATS: '/dashboard_stats_api.php',
  
  // Telecallers
  TELECALLERS: '/admin_telecallers_api.php',
  TELECALLER_DETAILS: '/telecaller_details_api.php',
  
  // Managers
  MANAGERS: '/admin_managers_api.php',
  
  // Leads
  LEADS: '/admin_leads_api.php',
  ASSIGN_LEADS: '/admin_assign_leads_api.php',
  
  // Call Monitoring
  CALL_LOGS: '/call_monitoring_api.php',
  LIVE_CALLS: '/admin_live_calls_api.php',
  
  // Analytics
  ANALYTICS: '/admin_analytics_api.php',
};
