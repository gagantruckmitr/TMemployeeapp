<?php
/**
 * Test script to check blank fields and verify lookups
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$results = [
    'blank_driver_names' => [],
    'blank_transporter_names' => [],
    'blank_job_ids' => [],
    'sample_lookups' => []
];

try {
    // Check records with blank driver names
    $query = "SELECT id, unique_id_driver, driver_name 
              FROM call_logs_match_making 
              WHERE (driver_name IS NULL OR driver_name = '') 
              AND unique_id_driver != ''
              LIMIT 5";
    
    $result = $conn->query($query);
    while ($row = $result->fetch_assoc()) {
        $driverTmid = $row['unique_id_driver'];
        
        // Try to look up the name
        $lookupQuery = "SELECT name, role FROM users WHERE unique_id = '$driverTmid' LIMIT 1";
        $lookupResult = $conn->query($lookupQuery);
        
        $lookup = null;
        if ($lookupResult && $lookupResult->num_rows > 0) {
            $lookup = $lookupResult->fetch_assoc();
        }
        
        $results['blank_driver_names'][] = [
            'id' => $row['id'],
            'tmid' => $driverTmid,
            'current_name' => $row['driver_name'],
            'lookup_result' => $lookup
        ];
    }
    
    // Check records with blank transporter names
    $query = "SELECT id, unique_id_transporter, transporter_name 
              FROM call_logs_match_making 
              WHERE (transporter_name IS NULL OR transporter_name = '') 
              AND unique_id_transporter != ''
              LIMIT 5";
    
    $result = $conn->query($query);
    while ($row = $result->fetch_assoc()) {
        $transporterTmid = $row['unique_id_transporter'];
        
        // Try to look up the name
        $lookupQuery = "SELECT name, role FROM users WHERE unique_id = '$transporterTmid' LIMIT 1";
        $lookupResult = $conn->query($lookupQuery);
        
        $lookup = null;
        if ($lookupResult && $lookupResult->num_rows > 0) {
            $lookup = $lookupResult->fetch_assoc();
        }
        
        $results['blank_transporter_names'][] = [
            'id' => $row['id'],
            'tmid' => $transporterTmid,
            'current_name' => $row['transporter_name'],
            'lookup_result' => $lookup
        ];
    }
    
    // Check records with blank job IDs
    $query = "SELECT id, unique_id_driver, unique_id_transporter, job_id 
              FROM call_logs_match_making 
              WHERE (job_id IS NULL OR job_id = '') 
              AND unique_id_driver != ''
              AND unique_id_transporter != ''
              LIMIT 5";
    
    $result = $conn->query($query);
    while ($row = $result->fetch_assoc()) {
        $driverTmid = $row['unique_id_driver'];
        $transporterTmid = $row['unique_id_transporter'];
        
        // Try to find a job
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
        
        $job = null;
        if ($jobResult && $jobResult->num_rows > 0) {
            $job = $jobResult->fetch_assoc();
        }
        
        $results['blank_job_ids'][] = [
            'id' => $row['id'],
            'driver_tmid' => $driverTmid,
            'transporter_tmid' => $transporterTmid,
            'current_job_id' => $row['job_id'],
            'lookup_result' => $job
        ];
    }
    
    // Get some sample TMIDs to verify they exist
    $query = "SELECT DISTINCT unique_id_driver FROM call_logs_match_making WHERE unique_id_driver != '' LIMIT 3";
    $result = $conn->query($query);
    while ($row = $result->fetch_assoc()) {
        $tmid = $row['unique_id_driver'];
        $userQuery = "SELECT id, name, role, unique_id FROM users WHERE unique_id = '$tmid' LIMIT 1";
        $userResult = $conn->query($userQuery);
        
        if ($userResult && $userResult->num_rows > 0) {
            $results['sample_lookups'][] = $userResult->fetch_assoc();
        } else {
            $results['sample_lookups'][] = ['tmid' => $tmid, 'found' => false];
        }
    }
    
    echo json_encode($results, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
