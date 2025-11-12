<?php
/**
 * Test if caller_id filtering is working
 */

require_once 'config.php';

header('Content-Type: application/json');

echo "Testing caller_id filtering...\n\n";

// Test 1: Get transporters list without caller_id
echo "Test 1: Transporters list WITHOUT caller_id\n";
echo "URL: phase2_job_brief_api.php?action=transporters_list\n";
$response1 = file_get_contents('http://localhost/truckmitr-app/api/phase2_job_brief_api.php?action=transporters_list');
$data1 = json_decode($response1, true);
echo "Result: " . ($data1['success'] ? 'Success' : 'Failed') . "\n";
echo "Count: " . count($data1['data'] ?? []) . " transporters\n\n";

// Test 2: Get transporters list WITH caller_id = 3
echo "Test 2: Transporters list WITH caller_id=3\n";
echo "URL: phase2_job_brief_api.php?action=transporters_list&caller_id=3\n";
$response2 = file_get_contents('http://localhost/truckmitr-app/api/phase2_job_brief_api.php?action=transporters_list&caller_id=3');
$data2 = json_decode($response2, true);
echo "Result: " . ($data2['success'] ? 'Success' : 'Failed') . "\n";
echo "Count: " . count($data2['data'] ?? []) . " transporters\n\n";

// Test 3: Get transporters list WITH caller_id = 4
echo "Test 3: Transporters list WITH caller_id=4\n";
echo "URL: phase2_job_brief_api.php?action=transporters_list&caller_id=4\n";
$response3 = file_get_contents('http://localhost/truckmitr-app/api/phase2_job_brief_api.php?action=transporters_list&caller_id=4');
$data3 = json_decode($response3, true);
echo "Result: " . ($data3['success'] ? 'Success' : 'Failed') . "\n";
echo "Count: " . count($data3['data'] ?? []) . " transporters\n\n";

// Test 4: Check actual data in database
echo "Test 4: Database check - caller_id distribution\n";
$query = "SELECT caller_id, COUNT(*) as count FROM job_brief_table GROUP BY caller_id";
$result = $conn->query($query);
echo "Caller ID distribution:\n";
while ($row = $result->fetch_assoc()) {
    echo "  Caller ID " . ($row['caller_id'] ?? 'NULL') . ": " . $row['count'] . " records\n";
}

echo "\n\nTest 5: Sample records\n";
$query = "SELECT id, caller_id, unique_id, job_id, created_at FROM job_brief_table ORDER BY created_at DESC LIMIT 5";
$result = $conn->query($query);
echo "Recent records:\n";
while ($row = $result->fetch_assoc()) {
    echo "  ID: {$row['id']}, Caller: {$row['caller_id']}, Transporter: {$row['unique_id']}, Job: {$row['job_id']}\n";
}

$conn->close();
?>
