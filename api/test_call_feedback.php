<?php
/**
 * Test Call Feedback Submission
 * Simulates a feedback submission to debug the issue
 */

require_once 'config.php';

header('Content-Type: application/json');

// Simulate POST data
$testData = [
    'callerId' => 1,
    'uniqueIdDriver' => 'TMJD00419',
    'driverName' => 'Test Driver',
    'feedback' => 'Not Selected',
    'matchStatus' => 'Not Selected',
    'additionalNotes' => 'Test notes',
    'jobId' => 'TMJB00419'
];

try {
    $callerId = $testData['callerId'];
    $uniqueIdDriver = $conn->real_escape_string($testData['uniqueIdDriver']);
    $driverName = $conn->real_escape_string($testData['driverName']);
    $feedback = $conn->real_escape_string($testData['feedback']);
    $matchStatus = $conn->real_escape_string($testData['matchStatus']);
    $additionalNotes = $conn->real_escape_string($testData['additionalNotes']);
    $jobId = $conn->real_escape_string($testData['jobId']);
    
    // Build the query
    $query = "INSERT INTO call_logs_match_making 
              (caller_id, unique_id_driver, driver_name, feedback, match_status, transporter_job_remark, job_id, created_at, updated_at) 
              VALUES 
              ($callerId, '$uniqueIdDriver', '$driverName', '$feedback', '$matchStatus', '$additionalNotes', '$jobId', NOW(), NOW())";
    
    echo json_encode([
        'success' => true,
        'testData' => $testData,
        'query' => $query,
        'message' => 'Query prepared successfully. Execute to test.'
    ], JSON_PRETTY_PRINT);
    
    // Uncomment to actually execute:
    // if ($conn->query($query)) {
    //     echo json_encode(['success' => true, 'id' => $conn->insert_id]);
    // } else {
    //     throw new Exception('Query failed: ' . $conn->error);
    // }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

$conn->close();
