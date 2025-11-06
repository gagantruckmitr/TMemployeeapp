<?php
/**
 * Test script for Phase 2 call feedback submission
 */

require_once 'config.php';

header('Content-Type: application/json');

echo "<h2>Testing Phase 2 Call Feedback API</h2>";

// Test 1: Check table structure
echo "<h3>Test 1: Table Structure</h3>";
$query = "DESCRIBE call_logs_match_making";
$result = $conn->query($query);

if ($result) {
    echo "<table border='1'><tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td><td>{$row['Null']}</td><td>{$row['Key']}</td></tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color:red'>Error: " . $conn->error . "</p>";
}

// Test 2: Insert sample feedback
echo "<h3>Test 2: Insert Sample Feedback</h3>";

$testData = [
    'callerId' => 1,
    'uniqueIdDriver' => 'TMDR00419',
    'driverName' => 'Test Driver',
    'feedback' => 'Interview Done',
    'matchStatus' => 'Selected',
    'additionalNotes' => 'Test feedback from API',
    'jobId' => 'TMJB00419'
];

$callerId = $testData['callerId'];
$uniqueIdDriver = $conn->real_escape_string($testData['uniqueIdDriver']);
$driverName = $conn->real_escape_string($testData['driverName']);
$feedback = $conn->real_escape_string($testData['feedback']);
$matchStatus = $conn->real_escape_string($testData['matchStatus']);
$remark = $conn->real_escape_string($testData['additionalNotes']);
$jobId = $conn->real_escape_string($testData['jobId']);

$insertQuery = "INSERT INTO call_logs_match_making 
                (caller_id, unique_id_driver, driver_name, feedback, match_status, remark, job_id, created_at, updated_at) 
                VALUES 
                ($callerId, '$uniqueIdDriver', '$driverName', '$feedback', '$matchStatus', '$remark', '$jobId', NOW(), NOW())";

if ($conn->query($insertQuery)) {
    echo "<p style='color:green'>✓ Successfully inserted test feedback (ID: " . $conn->insert_id . ")</p>";
    echo "<pre>" . print_r($testData, true) . "</pre>";
} else {
    echo "<p style='color:red'>✗ Failed to insert: " . $conn->error . "</p>";
    echo "<p>Query: $insertQuery</p>";
}

// Test 3: Fetch statistics
echo "<h3>Test 3: Fetch Statistics</h3>";

$statsQuery = "SELECT 
    COUNT(*) as total_calls,
    SUM(CASE WHEN unique_id_driver IS NOT NULL THEN 1 ELSE 0 END) as driver_calls,
    SUM(CASE WHEN unique_id_transporter IS NOT NULL THEN 1 ELSE 0 END) as transporter_calls,
    SUM(CASE WHEN feedback = 'Interview Done' THEN 1 ELSE 0 END) as interview_done,
    SUM(CASE WHEN match_status = 'Selected' THEN 1 ELSE 0 END) as selected
FROM call_logs_match_making";

$result = $conn->query($statsQuery);
if ($result) {
    $stats = $result->fetch_assoc();
    echo "<pre>" . print_r($stats, true) . "</pre>";
} else {
    echo "<p style='color:red'>Error: " . $conn->error . "</p>";
}

// Test 4: Fetch recent logs
echo "<h3>Test 4: Recent Call Logs</h3>";

$logsQuery = "SELECT * FROM call_logs_match_making ORDER BY created_at DESC LIMIT 5";
$result = $conn->query($logsQuery);

if ($result) {
    echo "<table border='1'><tr><th>ID</th><th>Caller ID</th><th>Driver TMID</th><th>Feedback</th><th>Match Status</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['caller_id']}</td>";
        echo "<td>{$row['unique_id_driver']}</td>";
        echo "<td>{$row['feedback']}</td>";
        echo "<td>{$row['match_status']}</td>";
        echo "<td>{$row['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color:red'>Error: " . $conn->error . "</p>";
}

echo "<hr><p><strong>All tests completed!</strong></p>";
?>
