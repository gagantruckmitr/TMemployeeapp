<?php
// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';
require_once 'phase2_job_brief_api.php';

// Mock data
$data = [
    'uniqueId' => 'TEST_TMID_123',
    'jobId' => 'TEST_JOB_123',
    'callerId' => 1,
    'name' => 'Test Transporter',
    'jobLocation' => 'Delhi',
    'requiredDrivers' => '5',
    'callStatusFeedback' => 'Connected: Details Received'
];

// Simulate POST request
$_SERVER['REQUEST_METHOD'] = 'POST';
// We can't easily mock php://input for the function, so we might need to modify the function or just test the query logic.
// Instead, let's try to construct the query and run it manually to see if it fails.

echo "Testing Database Connection...\n";
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "Connected.\n";

$uniqueId = 'TEST_TMID_123';
$jobId = 'TEST_JOB_123';
$callerId = 1;
$name = 'Test Transporter';
$requiredDrivers = '5';
$closedJob = 0;

$query = "INSERT INTO job_brief_table (
    unique_id, job_id, caller_id, name, required_drivers, closed_job, created_at, updated_at
) VALUES (
    '$uniqueId', '$jobId', $callerId, '$name', '$requiredDrivers', $closedJob, NOW(), NOW()
)";

echo "Testing Query: $query\n";

if ($conn->query($query)) {
    echo "Insert Successful! ID: " . $conn->insert_id . "\n";
    // Clean up
    $conn->query("DELETE FROM job_brief_table WHERE id = " . $conn->insert_id);
} else {
    echo "Insert Failed: " . $conn->error . "\n";
}

// Now let's try to call the actual API function by capturing output
// We need to mock file_get_contents('php://input') which is hard.
// But we can check if the columns exist.
$result = $conn->query("SHOW COLUMNS FROM job_brief_table");
echo "\nColumns:\n";
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}

?>
