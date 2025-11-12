<?php
/**
 * Cleanup and Fix Call Logs - Cron Job Script
 * This script should be run periodically (e.g., every hour) to:
 * 1. Fill in missing driver/transporter names
 * 2. Fill in missing job_ids
 * 3. Remove duplicate entries
 * 4. Update outdated information
 */

require_once 'config.php';

// Only allow execution from command line or with secret key
$secretKey = 'truckmitr_cleanup_2024';
$isCommandLine = php_sapi_name() === 'cli';
$hasValidKey = isset($_GET['key']) && $_GET['key'] === $secretKey;

if (!$isCommandLine && !$hasValidKey) {
    http_response_code(403);
    die(json_encode(['success' => false, 'message' => 'Unauthorized']));
}

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$stats = [
    'timestamp' => date('Y-m-d H:i:s'),
    'total_records' => 0,
    'blank_fields_fixed' => 0,
    'duplicates_removed' => 0,
    'details' => [
        'driver_names_fixed' => 0,
        'transporter_names_fixed' => 0,
        'job_ids_fixed' => 0,
    ],
    'errors' => []
];

try {
    // Start transaction
    $conn->begin_transaction();
    
    // Get total count
    $countResult = $conn->query("SELECT COUNT(*) as total FROM call_logs_match_making");
    $stats['total_records'] = $countResult->fetch_assoc()['total'];
    
    // ===== STEP 1: Fix blank driver names =====
    $query = "UPDATE call_logs_match_making clm
              INNER JOIN users u ON clm.unique_id_driver = u.unique_id AND u.role = 'driver'
              SET clm.driver_name = u.name
              WHERE (clm.driver_name IS NULL OR clm.driver_name = '')
              AND clm.unique_id_driver != ''";
    
    if ($conn->query($query)) {
        $stats['details']['driver_names_fixed'] = $conn->affected_rows;
        $stats['blank_fields_fixed'] += $conn->affected_rows;
    }
    
    // ===== STEP 2: Fix blank transporter names =====
    $query = "UPDATE call_logs_match_making clm
              INNER JOIN users u ON clm.unique_id_transporter = u.unique_id AND u.role = 'transporter'
              SET clm.transporter_name = u.name
              WHERE (clm.transporter_name IS NULL OR clm.transporter_name = '')
              AND clm.unique_id_transporter != ''";
    
    if ($conn->query($query)) {
        $stats['details']['transporter_names_fixed'] = $conn->affected_rows;
        $stats['blank_fields_fixed'] += $conn->affected_rows;
    }
    
    // ===== STEP 3: Fix blank job_ids =====
    // This is more complex - we need to find the most recent job for each driver-transporter pair
    $blankJobsQuery = "SELECT id, unique_id_driver, unique_id_transporter 
                       FROM call_logs_match_making 
                       WHERE (job_id IS NULL OR job_id = '')
                       AND unique_id_driver != ''
                       AND unique_id_transporter != ''";
    
    $blankJobsResult = $conn->query($blankJobsQuery);
    
    if ($blankJobsResult) {
        while ($row = $blankJobsResult->fetch_assoc()) {
            $id = $row['id'];
            $driverTmid = $conn->real_escape_string($row['unique_id_driver']);
            $transporterTmid = $conn->real_escape_string($row['unique_id_transporter']);
            
            $jobQuery = "SELECT j.job_id 
                        FROM applyjobs a
                        INNER JOIN jobs j ON a.job_id = j.id
                        INNER JOIN users d ON a.driver_id = d.id
                        INNER JOIN users t ON j.transporter_id = t.id
                        WHERE d.unique_id = '$driverTmid' 
                        AND t.unique_id = '$transporterTmid'
                        ORDER BY a.created_at DESC
                        LIMIT 1";
            
            $jobResult = $conn->query($jobQuery);
            
            if ($jobResult && $jobResult->num_rows > 0) {
                $jobRow = $jobResult->fetch_assoc();
                $jobId = $conn->real_escape_string($jobRow['job_id']);
                
                $updateQuery = "UPDATE call_logs_match_making SET job_id = '$jobId' WHERE id = $id";
                if ($conn->query($updateQuery)) {
                    $stats['details']['job_ids_fixed']++;
                    $stats['blank_fields_fixed']++;
                }
            }
        }
    }
    
    // ===== STEP 4: Remove duplicate entries =====
    // Keep the most recent entry for each caller_id + driver_tmid + transporter_tmid + created_at (same minute)
    $duplicateQuery = "DELETE clm1 FROM call_logs_match_making clm1
                       INNER JOIN call_logs_match_making clm2 
                       WHERE clm1.id < clm2.id
                       AND clm1.caller_id = clm2.caller_id
                       AND clm1.unique_id_driver = clm2.unique_id_driver
                       AND clm1.unique_id_transporter = clm2.unique_id_transporter
                       AND DATE_FORMAT(clm1.created_at, '%Y-%m-%d %H:%i') = DATE_FORMAT(clm2.created_at, '%Y-%m-%d %H:%i')";
    
    if ($conn->query($duplicateQuery)) {
        $stats['duplicates_removed'] = $conn->affected_rows;
    }
    
    // Commit transaction
    $conn->commit();
    
    $response = [
        'success' => true,
        'message' => 'Cleanup completed successfully',
        'stats' => $stats
    ];
    
    // Log the results
    $logFile = __DIR__ . '/cleanup_logs.txt';
    file_put_contents($logFile, json_encode($response, JSON_PRETTY_PRINT) . "\n\n", FILE_APPEND);
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    
    $stats['errors'][] = $e->getMessage();
    
    $response = [
        'success' => false,
        'message' => 'Cleanup failed: ' . $e->getMessage(),
        'stats' => $stats
    ];
    
    http_response_code(500);
    echo json_encode($response, JSON_PRETTY_PRINT);
}

$conn->close();
?>
