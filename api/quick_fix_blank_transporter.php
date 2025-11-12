<?php
/**
 * Quick fix for blank transporter fields
 * Simple script that can be run directly
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$results = [
    'transporter_tmid_fixed' => 0,
    'transporter_name_fixed' => 0,
    'driver_name_fixed' => 0,
    'errors' => []
];

try {
    // Fix blank transporter TMIDs and names using job_id
    $query = "UPDATE call_logs_match_making clm
              INNER JOIN jobs j ON clm.job_id = j.job_id
              INNER JOIN users u ON j.transporter_id = u.id
              SET clm.unique_id_transporter = u.unique_id,
                  clm.transporter_name = u.name
              WHERE (clm.unique_id_transporter IS NULL OR clm.unique_id_transporter = '')
              AND clm.job_id IS NOT NULL AND clm.job_id != ''";
    
    if ($conn->query($query)) {
        $results['transporter_tmid_fixed'] = $conn->affected_rows;
    } else {
        $results['errors'][] = 'Transporter fix failed: ' . $conn->error;
    }
    
    // Fix blank driver names
    $query = "UPDATE call_logs_match_making clm
              INNER JOIN users u ON clm.unique_id_driver = u.unique_id
              SET clm.driver_name = u.name
              WHERE (clm.driver_name IS NULL OR clm.driver_name = '')
              AND clm.unique_id_driver != ''";
    
    if ($conn->query($query)) {
        $results['driver_name_fixed'] = $conn->affected_rows;
    } else {
        $results['errors'][] = 'Driver name fix failed: ' . $conn->error;
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Cleanup completed',
        'results' => $results
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
