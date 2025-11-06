<?php
/**
 * Phase 2 Dashboard Stats API - FIXED VERSION
 * Fetches real-time statistics from database
 */

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Clean any output buffer
if (ob_get_level()) {
    ob_end_clean();
}
ob_start();

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    getDashboardStats();
} else {
    sendError('Method not allowed', 405);
}

function getDashboardStats() {
    global $conn;
    
    // Check if connection exists
    if (!$conn || $conn->connect_error) {
        sendError('Database connection failed', 500);
        return;
    }
    
    // Get user_id from request
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    if ($userId === 0) {
        sendError('user_id parameter is required', 400);
        return;
    }
    
    try {
        $stats = [];
        
        // Get total jobs assigned to this user
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
        $stats['totalJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Get approved jobs (status = '1')
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1'");
        $stats['approvedJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Get pending jobs (status = '0')
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '0'");
        $stats['pendingJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Get inactive jobs (active_inactive = 0)
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND active_inactive = 0");
        $stats['inactiveJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Get expired jobs
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs 
                                WHERE assigned_to = $userId
                                AND Application_Deadline IS NOT NULL 
                                AND Application_Deadline != '' 
                                AND Application_Deadline < CURDATE()");
        $stats['expiredJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Get active transporters
        $result = $conn->query("SELECT COUNT(DISTINCT transporter_id) as count 
                                FROM jobs 
                                WHERE assigned_to = $userId
                                AND status = '1' AND active_inactive = 1 
                                AND transporter_id IS NOT NULL");
        $stats['activeTransporters'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        // Get driver applications
        $stats['driversApplied'] = 0;
        $stats['totalMatches'] = 0;
        
        $tableCheck = $conn->query("SHOW TABLES LIKE 'applyjobs'");
        if ($tableCheck && $tableCheck->num_rows > 0) {
            // Count total unique driver applications
            $result = $conn->query("SELECT COUNT(DISTINCT a.driver_id) as count 
                                    FROM applyjobs a
                                    INNER JOIN jobs j ON j.id = a.job_id 
                                    AND j.transporter_id = a.contractor_id
                                    WHERE j.assigned_to = $userId");
            if ($result) {
                $stats['driversApplied'] = (int)$result->fetch_assoc()['count'];
            }
            
            // Count interested/matched applications
            $result = $conn->query("SELECT COUNT(*) as count 
                                    FROM applyjobs a
                                    INNER JOIN jobs j ON j.id = a.job_id 
                                    AND j.transporter_id = a.contractor_id
                                    WHERE j.assigned_to = $userId
                                    AND a.status = 'Interested'");
            if ($result) {
                $stats['totalMatches'] = (int)$result->fetch_assoc()['count'];
            }
        }
        
        // Get total calls
        $stats['totalCalls'] = 0;
        $callTableCheck = $conn->query("SHOW TABLES LIKE 'call_logs'");
        if ($callTableCheck && $callTableCheck->num_rows > 0) {
            $result = $conn->query("SELECT COUNT(*) as count FROM call_logs WHERE caller_id = $userId");
            if ($result) {
                $stats['totalCalls'] = (int)$result->fetch_assoc()['count'];
            }
        }
        
        sendSuccess($stats, 'Dashboard stats fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error fetching dashboard stats: ' . $e->getMessage(), 500);
    }
}

function sendSuccess($data, $message = 'Success') {
    ob_clean();
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

function sendError($message, $code = 400) {
    ob_clean();
    http_response_code($code);
    echo json_encode([
        'success' => false,
        'message' => $message
    ]);
    exit;
}
