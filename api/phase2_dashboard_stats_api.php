<?php
/**
 * Phase 2 Dashboard Stats API
 */

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    getDashboardStats();
} else {
    sendError('Method not allowed', 405);
}

function getDashboardStats() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
        return;
    }
    
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    if ($userId === 0) {
        sendError('user_id parameter is required', 400);
        return;
    }
    
    try {
        $stats = [];
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
        $stats['totalJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1'");
        $stats['approvedJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '0'");
        $stats['pendingJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND active_inactive = 0");
        $stats['inactiveJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs 
                                WHERE assigned_to = $userId
                                AND Application_Deadline IS NOT NULL 
                                AND Application_Deadline != '' 
                                AND Application_Deadline < CURDATE()");
        $stats['expiredJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(DISTINCT transporter_id) as count 
                                FROM jobs 
                                WHERE assigned_to = $userId
                                AND status = '1' AND active_inactive = 1 
                                AND transporter_id IS NOT NULL");
        $stats['activeTransporters'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $stats['driversApplied'] = 0;
        $stats['totalMatches'] = 0;
        
        $tableCheck = $conn->query("SHOW TABLES LIKE 'applyjobs'");
        if ($tableCheck && $tableCheck->num_rows > 0) {
            $result = $conn->query("SELECT COUNT(DISTINCT a.driver_id) as count 
                                    FROM applyjobs a
                                    INNER JOIN jobs j ON j.id = a.job_id 
                                    AND j.transporter_id = a.contractor_id
                                    WHERE j.assigned_to = $userId");
            if ($result) {
                $stats['driversApplied'] = (int)$result->fetch_assoc()['count'];
            }
            
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
