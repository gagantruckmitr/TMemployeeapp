<?php
/**
 * Test script to check if jobs have transporter_id set
 */

require_once 'config.php';

header('Content-Type: application/json');

$results = [
    'total_jobs' => 0,
    'jobs_with_transporter' => 0,
    'jobs_without_transporter' => 0,
    'sample_jobs' => []
];

// Count total jobs
$countQuery = "SELECT COUNT(*) as total FROM jobs";
$result = $conn->query($countQuery);
$results['total_jobs'] = $result->fetch_assoc()['total'];

// Count jobs with transporter_id
$withQuery = "SELECT COUNT(*) as total FROM jobs WHERE transporter_id IS NOT NULL AND transporter_id != 0";
$result = $conn->query($withQuery);
$results['jobs_with_transporter'] = $result->fetch_assoc()['total'];

// Count jobs without transporter_id
$withoutQuery = "SELECT COUNT(*) as total FROM jobs WHERE transporter_id IS NULL OR transporter_id = 0";
$result = $conn->query($withoutQuery);
$results['jobs_without_transporter'] = $result->fetch_assoc()['total'];

// Get sample jobs with their transporter info
$sampleQuery = "SELECT 
    j.id,
    j.job_id,
    j.job_title,
    j.transporter_id,
    t.unique_id as transporter_tmid,
    t.name as transporter_name,
    t.role as transporter_role
FROM jobs j
LEFT JOIN users t ON j.transporter_id = t.id
ORDER BY j.id DESC
LIMIT 10";

$result = $conn->query($sampleQuery);
while ($row = $result->fetch_assoc()) {
    $results['sample_jobs'][] = $row;
}

echo json_encode($results, JSON_PRETTY_PRINT);

$conn->close();
?>
