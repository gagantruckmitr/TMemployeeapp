<?php
// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

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

// Check columns
$result = $conn->query("SHOW COLUMNS FROM job_brief_table");
echo "\nColumns:\n";
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
?>
