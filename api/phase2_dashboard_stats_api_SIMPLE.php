<?php
/**
 * Phase 2 Dashboard Stats API - Simple Version
 */

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    getDashboardStats();
} else {
    sendError('Method not allowed', 405);
}

function getDashboardStats() {
    try {
        $conn = getDBConnection();
        
        if (!$conn) {
            sendError('Database connection not available', 500);
            return;
        }
        
        $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
        
        if ($userId === 0) {
            sendError('user_id parameter is required', 400);
            return;
        }
        
        $stats = [];
        
        // Basic counts
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
        $stats['totalJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1'");
        $stats['approvedJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '0'");
        $stats['pendingJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND active_inactive = 0");
        $stats['inactiveJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Try expired jobs with error handling
        $expiredQuery = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND Application_Deadline < NOW() AND Application_Deadline IS NOT NULL AND Application_Deadline != ''";
        $result = $conn->query($expiredQuery);
        $stats['expiredJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Default values for other stats
        $stats['activeTransporters'] = 0;
        $stats['driversApplied'] = 0;
        $stats['totalMatches'] = 0;
        $stats['totalCalls'] = 0;
        
        sendSuccess($stats, 'Dashboard stats fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error fetching dashboard stats: ' . $e->getMessage(), 500);
    }
}
?>