// Production API Configuration for Plesk Deployment
// Replace 'yourdomain.com' with your actual domain

export const API_BASE_URL = 'https://yourdomain.com/api';

export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/auth_api.php',
  
  // Dashboard
  DASHBOARD_STATS: '/admin_dashboard_stats.php',
  
  // Telecallers
  TELECALLERS: '/admin_telecallers_api.php',
  TELECALLER_DETAILS: '/admin_telecallers_detailed_api.php',
  
  // Managers
  MANAGERS: '/admin_managers_api.php',
  MANAGER_DETAILS: '/admin_managers_detailed_api.php',
  
  // Leads
  LEADS: '/admin_leads_api.php',
  ASSIGN_LEADS: '/admin_assign_leads_api.php',
  
  // Call Monitoring
  CALL_LOGS: '/call_monitoring_api.php',
  LIVE_CALLS: '/admin_live_calls_api.php',
  
  // Analytics
  ANALYTICS: '/admin_analytics_api.php',
};

// API Configuration
export const API_CONFIG = {
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json',
  },
};

// Enable production mode
export const IS_PRODUCTION = true;
