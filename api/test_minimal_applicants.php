<?php
header('Content-Type: application/json');
require_once 'config.php';

$jobIdString = 'TMJB00466';

try {
    // Get numeric ID
    $jobQuery = "SELECT id FROM jobs WHERE job_id = '$jobIdString' LIMIT 1";
    $jobResult = $conn->query($jobQuery);
    
    if (!$jobResult || $jobResult->num_rows === 0) {
        throw new Exception('Job not found');
    }
    
    $jobRow = $jobResult->fetch_assoc();
    $numericJobId = $jobRow['id'];
    
    // Minimal query - just get basic applicant data
    $query = "SELECT 
        u.id AS driver_id,
        u.name,
        u.unique_id AS driver_tmid,
        u.mobile,
        u.city
    FROM applyjobs a
    INNER JOIN users u ON a.driver_id = u.id
    WHERE a.job_id = $numericJobId
    LIMIT 5";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception('Query failed: ' . $conn->error);
    }
    
    $applicants = [];
    while ($row = $result->fetch_assoc()) {
        $applicants[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'count' => count($applicants),
        'applicants' => $applicants
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
