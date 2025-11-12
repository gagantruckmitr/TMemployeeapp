<?php
/**
 * Test script to check what data is being returned by job applicants API
 */

require_once 'config.php';

header('Content-Type: application/json');

// Get a sample job ID that has applicants
$sampleJobQuery = "SELECT DISTINCT j.job_id 
                   FROM jobs j 
                   INNER JOIN applyjobs a ON j.id = a.job_id 
                   ORDER BY j.id DESC 
                   LIMIT 1";
$result = $conn->query($sampleJobQuery);

if (!$result || $result->num_rows === 0) {
    die(json_encode(['error' => 'No jobs found']));
}

$jobRow = $result->fetch_assoc();
$jobId = $jobRow['job_id'];

// Now test the actual query used by the API
$jobQuery = "SELECT id FROM jobs WHERE job_id = '$jobId' LIMIT 1";
$jobResult = $conn->query($jobQuery);

if (!$jobResult || $jobResult->num_rows === 0) {
    die(json_encode(['error' => 'Job not found']));
}

$jobRow = $jobResult->fetch_assoc();
$numericJobId = $jobRow['id'];

// Run the actual query
$query = "SELECT 
    j.id AS job_id,
    j.job_title,
    j.transporter_id AS contractor_id,
    t.unique_id AS transporter_tmid,
    t.name AS transporter_name,
    u.id AS driver_id,
    u.unique_id AS driver_tmid,
    u.name,
    u.mobile
FROM applyjobs a
INNER JOIN users u ON a.driver_id = u.id
INNER JOIN jobs j ON a.job_id = j.id
LEFT JOIN users t ON j.transporter_id = t.id AND t.role = 'transporter'
WHERE a.job_id = $numericJobId
LIMIT 3";

$result = $conn->query($query);

$applicants = [];
while ($row = $result->fetch_assoc()) {
    $applicants[] = $row;
}

echo json_encode([
    'test_job_id' => $jobId,
    'numeric_job_id' => $numericJobId,
    'query' => $query,
    'applicants_count' => count($applicants),
    'sample_applicants' => $applicants
], JSON_PRETTY_PRINT);

$conn->close();
?>
