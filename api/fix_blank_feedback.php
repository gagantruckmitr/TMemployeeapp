<?php
/**
 * Fix blank feedback column
 * Removes records with NULL feedback or deletes duplicate pending records
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$results = [
    'pending_records_deleted' => 0,
    'null_feedback_deleted' => 0,
    'total_before' => 0,
    'total_after' => 0,
    'details' => []
];

try {
    // Get total count before
    $countQuery = "SELECT COUNT(*) as total FROM call_logs_match_making";
    $result = $conn->query($countQuery);
    $results['total_before'] = $result->fetch_assoc()['total'];
    
    // Strategy 1: Delete records where feedback is NULL and there's a duplicate with actual feedback
    // This handles the case where a "pending" record was created, then a real feedback was submitted
    $deleteQuery = "DELETE clm1 FROM call_logs_match_making clm1
                    INNER JOIN call_logs_match_making clm2 
                    ON clm1.caller_id = clm2.caller_id
                    AND clm1.unique_id_driver = clm2.unique_id_driver
                    AND clm1.job_id = clm2.job_id
                    AND DATE(clm1.created_at) = DATE(clm2.created_at)
                    WHERE clm1.feedback IS NULL
                    AND clm2.feedback IS NOT NULL
                    AND clm1.id < clm2.id";
    
    if ($conn->query($deleteQuery)) {
        $results['pending_records_deleted'] = $conn->affected_rows;
        $results['details'][] = "Deleted {$conn->affected_rows} pending records that have corresponding feedback records";
    } else {
        $results['details'][] = 'Error deleting pending records: ' . $conn->error;
    }
    
    // Strategy 2: Delete very old records with NULL feedback (older than 7 days)
    // These are likely abandoned/incomplete submissions
    $deleteOldQuery = "DELETE FROM call_logs_match_making 
                       WHERE feedback IS NULL 
                       AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)";
    
    if ($conn->query($deleteOldQuery)) {
        $results['null_feedback_deleted'] = $conn->affected_rows;
        $results['details'][] = "Deleted {$conn->affected_rows} old records with NULL feedback (>7 days old)";
    } else {
        $results['details'][] = 'Error deleting old NULL feedback: ' . $conn->error;
    }
    
    // Get total count after
    $result = $conn->query($countQuery);
    $results['total_after'] = $result->fetch_assoc()['total'];
    
    // Get remaining NULL feedback count
    $nullCountQuery = "SELECT COUNT(*) as null_count FROM call_logs_match_making WHERE feedback IS NULL";
    $result = $conn->query($nullCountQuery);
    $results['remaining_null_feedback'] = $result->fetch_assoc()['null_count'];
    
    echo json_encode([
        'success' => true,
        'message' => 'Blank feedback cleanup completed',
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
