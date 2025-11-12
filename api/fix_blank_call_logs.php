<?php
/**
 * Fix Blank Fields in call_logs_match_making Table
 * This script updates existing records that have missing transporter/driver names and job_ids
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$stats = [
    'total_records' => 0,
    'records_checked' => 0,
    'transporter_names_fixed' => 0,
    'driver_names_fixed' => 0,
    'job_ids_fixed' => 0,
    'errors' => []
];

try {
    // Get total count
    $countResult = $conn->query("SELECT COUNT(*) as total FROM call_logs_match_making");
    $stats['total_records'] = $countResult->fetch_assoc()['total'];
    
    // Get all records that need fixing
    $query = "SELECT id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, job_id, caller_id 
              FROM call_logs_match_making 
              WHERE (driver_name IS NULL OR driver_name = '') 
                 OR (transporter_name IS NULL OR transporter_name = '') 
                 OR (job_id IS NULL OR job_id = '')
              ORDER BY created_at DESC";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception('Query failed: ' . $conn->error);
    }
    
    $stats['records_checked'] = $result->num_rows;
    
    while ($row = $result->fetch_assoc()) {
        $id = $row['id'];
        $updates = [];
        $needsUpdate = false;
        
        // Fix driver name if missing
        if ((empty($row['driver_name']) || $row['driver_name'] === '') && !empty($row['unique_id_driver'])) {
            $driverTmid = $conn->real_escape_string($row['unique_id_driver']);
            $driverQuery = "SELECT name FROM users WHERE unique_id = '$driverTmid' AND role = 'driver' LIMIT 1";
            $driverResult = $conn->query($driverQuery);
            
            if ($driverResult && $driverResult->num_rows > 0) {
                $driverRow = $driverResult->fetch_assoc();
                $driverName = $conn->real_escape_string($driverRow['name']);
                $updates[] = "driver_name = '$driverName'";
                $stats['driver_names_fixed']++;
                $needsUpdate = true;
            }
        }
        
        // Fix transporter name if missing
        if ((empty($row['transporter_name']) || $row['transporter_name'] === '') && !empty($row['unique_id_transporter'])) {
            $transporterTmid = $conn->real_escape_string($row['unique_id_transporter']);
            $transporterQuery = "SELECT name FROM users WHERE unique_id = '$transporterTmid' AND role = 'transporter' LIMIT 1";
            $transporterResult = $conn->query($transporterQuery);
            
            if ($transporterResult && $transporterResult->num_rows > 0) {
                $transporterRow = $transporterResult->fetch_assoc();
                $transporterName = $conn->real_escape_string($transporterRow['name']);
                $updates[] = "transporter_name = '$transporterName'";
                $stats['transporter_names_fixed']++;
                $needsUpdate = true;
            }
        }
        
        // Try to find job_id if missing
        if ((empty($row['job_id']) || $row['job_id'] === '') && !empty($row['unique_id_driver']) && !empty($row['unique_id_transporter'])) {
            $driverTmid = $conn->real_escape_string($row['unique_id_driver']);
            $transporterTmid = $conn->real_escape_string($row['unique_id_transporter']);
            
            // Find the most recent job application for this driver-transporter pair
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
                $updates[] = "job_id = '$jobId'";
                $stats['job_ids_fixed']++;
                $needsUpdate = true;
            }
        }
        
        // Execute update if needed
        if ($needsUpdate && count($updates) > 0) {
            $updateSql = "UPDATE call_logs_match_making SET " . implode(', ', $updates) . " WHERE id = $id";
            
            if (!$conn->query($updateSql)) {
                $stats['errors'][] = "Failed to update record $id: " . $conn->error;
            }
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Blank fields fixed successfully',
        'stats' => $stats
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'stats' => $stats
    ]);
}

$conn->close();
?>
