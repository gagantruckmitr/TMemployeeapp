<?php
require_once 'config.php';
header('Content-Type: text/plain');

echo "=== Testing Analytics for Caller ID 3 ===\n\n";

// Test 1: Check if call_logs_match_making table exists
$tableCheck = $conn->query("SHOW TABLES LIKE 'call_logs_match_making'");
echo "1. Table exists: " . ($tableCheck->num_rows > 0 ? "YES" : "NO") . "\n\n";

// Test 2: Count total rows
$totalQuery = "SELECT COUNT(*) as total FROM call_logs_match_making";
$totalResult = $conn->query($totalQuery);
$total = $totalResult->fetch_assoc()['total'];
echo "2. Total rows in table: $total\n\n";

// Test 3: Count rows for caller_id 3
$caller3Query = "SELECT COUNT(*) as total FROM call_logs_match_making WHERE caller_id = 3";
$caller3Result = $conn->query($caller3Query);
$caller3Total = $caller3Result->fetch_assoc()['total'];
echo "3. Rows for caller_id 3: $caller3Total\n\n";

// Test 4: Show sample data for caller_id 3
echo "4. Sample data for caller_id 3:\n";
$sampleQuery = "SELECT id, caller_id, feedback, match_status, created_at FROM call_logs_match_making WHERE caller_id = 3 LIMIT 5";
$sampleResult = $conn->query($sampleQuery);
while ($row = $sampleResult->fetch_assoc()) {
    print_r($row);
}

// Test 5: Test the analytics API endpoint
echo "\n5. Testing analytics API:\n";
$callerId = 3;
$whereClause = "WHERE caller_id = $callerId";

$totalCallsQuery = "SELECT COUNT(*) as total FROM call_logs_match_making $whereClause";
$totalResult = $conn->query($totalCallsQuery);
$totalCalls = $totalResult->fetch_assoc()['total'];
echo "Total calls: $totalCalls\n";

$matchQuery = "SELECT COUNT(*) as total FROM call_logs_match_making WHERE feedback = 'Match Making Done' AND caller_id = $callerId";
$matchResult = $conn->query($matchQuery);
$matches = $matchResult->fetch_assoc()['total'];
echo "Matches: $matches\n";

$selectedQuery = "SELECT COUNT(*) as total FROM call_logs_match_making WHERE match_status = 'Selected' AND caller_id = $callerId";
$selectedResult = $conn->query($selectedQuery);
$selected = $selectedResult->fetch_assoc()['total'];
echo "Selected: $selected\n";
?>
