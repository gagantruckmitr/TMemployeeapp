<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once 'config.php';

if (!$conn || $conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error']);
    exit;
}

try {
    $stats = [];
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs");
    $stats['totalJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE status = '1'");
    $stats['approvedJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE status = '0'");
    $stats['pendingJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE active_inactive = 0");
    $stats['inactiveJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE Application_Deadline IS NOT NULL AND Application_Deadline != '' AND Application_Deadline < CURDATE()");
    $stats['expiredJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(DISTINCT transporter_id) as count FROM jobs WHERE status = '1' AND active_inactive = 1 AND transporter_id IS NOT NULL");
    $stats['activeTransporters'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $stats['driversApplied'] = 0;
    $stats['totalMatches'] = 0;
    
    $tableCheck = $conn->query("SHOW TABLES LIKE 'applyjobs'");
    if ($tableCheck && $tableCheck->num_rows > 0) {
        // Count total unique drivers who applied (simplified - just check job_id exists)
        $result = $conn->query("SELECT COUNT(DISTINCT driver_id) as count FROM applyjobs WHERE job_id IN (SELECT id FROM jobs)");
        if ($result) {
            $stats['driversApplied'] = (int)$result->fetch_assoc()['count'];
        }
        
        // totalMatches = same as driversApplied
        $stats['totalMatches'] = $stats['driversApplied'];
    }
    
    $stats['totalCalls'] = 0;
    $callTableCheck = $conn->query("SHOW TABLES LIKE 'call_logs'");
    if ($callTableCheck && $callTableCheck->num_rows > 0) {
        $result = $conn->query("SELECT COUNT(*) as count FROM call_logs");
        if ($result) {
            $stats['totalCalls'] = (int)$result->fetch_assoc()['count'];
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Dashboard stats fetched successfully',
        'data' => $stats
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
