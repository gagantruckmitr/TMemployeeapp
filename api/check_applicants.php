<?php
header('Content-Type: text/plain');
require_once 'config.php';

$jobId = 'TMJB00466';

echo "=== CHECKING APPLICANTS FOR JOB {$jobId} ===\n\n";

// Get numeric ID
$jobQuery = "SELECT id FROM jobs WHERE job_id = '{$jobId}'";
$result = $conn->query($jobQuery);
$job = $result->fetch_assoc();
$numericJobId = $job['id'];

echo "Numeric Job ID: {$numericJobId}\n\n";

// Check if there are applicants
$countQuery = "SELECT COUNT(*) as count FROM applyjobs WHERE job_id = {$numericJobId}";
$countResult = $conn->query($countQuery);
$count = $countResult->fetch_assoc()['count'];

echo "Number of applicants: {$count}\n\n";

if ($count == 0) {
    echo "No applicants found for this job.\n";
    exit;
}

// Get simple applicant data
echo "Applicants:\n";
echo str_repeat("=", 80) . "\n";

$simpleQuery = "SELECT 
    a.id as apply_id,
    a.driver_id,
    u.name,
    u.unique_id
FROM applyjobs a
INNER JOIN users u ON a.driver_id = u.id
WHERE a.job_id = {$numericJobId}
LIMIT 10";

$simpleResult = $conn->query($simpleQuery);

if (!$simpleResult) {
    echo "ERROR: " . $conn->error . "\n";
} else {
    while ($row = $simpleResult->fetch_assoc()) {
        echo "Apply ID: {$row['apply_id']} | Driver ID: {$row['driver_id']} | Name: {$row['name']} | TMID: {$row['unique_id']}\n";
    }
}
?>
