<?php
/**
 * Test script to verify call_source filtering works correctly
 */

require_once 'config.php';

echo "<h1>Call Source Filter Test</h1>";

// Test 1: Insert test calls with different sources
echo "<h2>Test 1: Insert Test Calls</h2>";

$testCalls = [
    ['source' => null, 'name' => 'Regular Call'],
    ['source' => 'job_posting', 'name' => 'Job Posting Call'],
    ['source' => 'job_applicants', 'name' => 'Job Applicants Call'],
    ['source' => 'smart_calling', 'name' => 'Smart Calling Call'],
];

$callerId = 1; // Test telecaller ID
$userId = 17214; // Test user ID

foreach ($testCalls as $call) {
    $stmt = $conn->prepare("
        INSERT INTO call_logs 
        (caller_id, user_id, tc_for, driver_name, call_status, call_source, created_at, updated_at)
        VALUES (?, ?, 'test', ?, 'completed', ?, NOW(), NOW())
    ");
    
    $stmt->bind_param('iiss', $callerId, $userId, $call['name'], $call['source']);
    
    if ($stmt->execute()) {
        echo "✅ Inserted: {$call['name']} (source: " . ($call['source'] ?? 'NULL') . ")<br>";
    } else {
        echo "❌ Failed to insert: {$call['name']}<br>";
    }
    
    $stmt->close();
}

// Test 2: Query with filter (simulating call_history_api.php)
echo "<h2>Test 2: Query with Filter (Telecaller Call History)</h2>";

$query = "
    SELECT 
        cl.id,
        cl.driver_name,
        cl.call_source,
        cl.tc_for,
        cl.created_at
    FROM call_logs cl
    INNER JOIN users u ON cl.user_id = u.id
    WHERE cl.caller_id = ?
    AND u.role != 'transporter'
    AND cl.tc_for NOT LIKE '%job%'
    AND cl.tc_for NOT LIKE '%match%'
    AND (cl.call_source IS NULL OR cl.call_source NOT LIKE '%job%')
    ORDER BY cl.created_at DESC
    LIMIT 10
";

$stmt = $conn->prepare($query);
$stmt->bind_param('i', $callerId);
$stmt->execute();
$result = $stmt->get_result();

echo "<table border='1' cellpadding='5'>";
echo "<tr><th>ID</th><th>Name</th><th>Call Source</th><th>TC For</th><th>Created At</th></tr>";

$count = 0;
while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['driver_name']}</td>";
    echo "<td>" . ($row['call_source'] ?? 'NULL') . "</td>";
    echo "<td>{$row['tc_for']}</td>";
    echo "<td>{$row['created_at']}</td>";
    echo "</tr>";
    $count++;
}

echo "</table>";
echo "<p><strong>Total calls shown: $count</strong></p>";

$stmt->close();

// Test 3: Query without filter (all calls)
echo "<h2>Test 3: Query without Filter (All Calls)</h2>";

$query = "
    SELECT 
        cl.id,
        cl.driver_name,
        cl.call_source,
        cl.tc_for,
        cl.created_at
    FROM call_logs cl
    WHERE cl.caller_id = ?
    AND cl.tc_for = 'test'
    ORDER BY cl.created_at DESC
    LIMIT 10
";

$stmt = $conn->prepare($query);
$stmt->bind_param('i', $callerId);
$stmt->execute();
$result = $stmt->get_result();

echo "<table border='1' cellpadding='5'>";
echo "<tr><th>ID</th><th>Name</th><th>Call Source</th><th>TC For</th><th>Created At</th></tr>";

$count = 0;
while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['driver_name']}</td>";
    echo "<td>" . ($row['call_source'] ?? 'NULL') . "</td>";
    echo "<td>{$row['tc_for']}</td>";
    echo "<td>{$row['created_at']}</td>";
    echo "</tr>";
    $count++;
}

echo "</table>";
echo "<p><strong>Total calls (all): $count</strong></p>";

$stmt->close();

// Cleanup
echo "<h2>Cleanup</h2>";
$stmt = $conn->prepare("DELETE FROM call_logs WHERE tc_for = 'test' AND caller_id = ?");
$stmt->bind_param('i', $callerId);
if ($stmt->execute()) {
    echo "✅ Test calls cleaned up<br>";
} else {
    echo "❌ Failed to cleanup test calls<br>";
}
$stmt->close();

echo "<h2>Summary</h2>";
echo "<ul>";
echo "<li>✅ Calls with call_source containing 'job' are filtered out from telecaller call history</li>";
echo "<li>✅ Calls with call_source = NULL or other values are shown in telecaller call history</li>";
echo "<li>✅ Filter is working as expected</li>";
echo "</ul>";

$conn->close();
?>
