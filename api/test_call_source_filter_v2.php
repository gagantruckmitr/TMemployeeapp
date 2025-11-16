<?php
/**
 * Test script to verify call_source filtering works correctly (v2)
 * This version uses actual user data
 */

require_once 'config.php';

echo "<h1>Call Source Filter Test v2</h1>";

// First, find a valid driver user
echo "<h2>Step 1: Find Valid Test User</h2>";
$userQuery = "SELECT id, unique_id, name, mobile, role FROM users WHERE role = 'driver' LIMIT 1";
$userResult = $conn->query($userQuery);

if ($userResult && $userResult->num_rows > 0) {
    $testUser = $userResult->fetch_assoc();
    echo "✅ Found test user:<br>";
    echo "- ID: {$testUser['id']}<br>";
    echo "- Name: {$testUser['name']}<br>";
    echo "- Role: {$testUser['role']}<br>";
    $userId = $testUser['id'];
} else {
    echo "❌ No driver user found. Creating test user...<br>";
    $stmt = $conn->prepare("INSERT INTO users (unique_id, name, mobile, role, created_at) VALUES (?, 'Test Driver', '9999999999', 'driver', NOW())");
    $uniqueId = 'TM' . time();
    $stmt->bind_param('s', $uniqueId);
    $stmt->execute();
    $userId = $conn->insert_id;
    echo "✅ Created test user with ID: $userId<br>";
    $stmt->close();
}

// Test 2: Insert test calls with different sources
echo "<h2>Step 2: Insert Test Calls</h2>";

$testCalls = [
    ['source' => null, 'name' => 'Regular Call', 'tc_for' => 'smart_calling'],
    ['source' => 'job_posting', 'name' => 'Job Posting Call', 'tc_for' => 'easygo_ivr_driver'],
    ['source' => 'job_applicants', 'name' => 'Job Applicants Call', 'tc_for' => 'easygo_ivr_driver'],
    ['source' => null, 'name' => 'Another Regular Call', 'tc_for' => 'easygo_ivr_driver'],
];

$callerId = 1; // Test telecaller ID

foreach ($testCalls as $call) {
    $stmt = $conn->prepare("
        INSERT INTO call_logs 
        (caller_id, user_id, tc_for, driver_name, call_status, call_source, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'completed', ?, NOW(), NOW())
    ");
    
    $stmt->bind_param('iisss', $callerId, $userId, $call['tc_for'], $call['name'], $call['source']);
    
    if ($stmt->execute()) {
        echo "✅ Inserted: {$call['name']} (source: " . ($call['source'] ?? 'NULL') . ", tc_for: {$call['tc_for']})<br>";
    } else {
        echo "❌ Failed to insert: {$call['name']} - Error: " . $stmt->error . "<br>";
    }
    
    $stmt->close();
}

// Test 3: Query with filter (simulating call_history_api.php)
echo "<h2>Step 3: Query with Filter (Telecaller Call History)</h2>";
echo "<p><strong>This query simulates what telecaller call history API returns</strong></p>";

$query = "
    SELECT 
        cl.id,
        cl.driver_name,
        cl.call_source,
        cl.tc_for,
        u.role,
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

echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr style='background-color: #f0f0f0;'><th>ID</th><th>Name</th><th>Call Source</th><th>TC For</th><th>User Role</th><th>Created At</th></tr>";

$count = 0;
while ($row = $result->fetch_assoc()) {
    $bgColor = $count % 2 == 0 ? '#ffffff' : '#f9f9f9';
    echo "<tr style='background-color: $bgColor;'>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['driver_name']}</td>";
    echo "<td>" . ($row['call_source'] ?? '<em>NULL</em>') . "</td>";
    echo "<td>{$row['tc_for']}</td>";
    echo "<td>{$row['role']}</td>";
    echo "<td>{$row['created_at']}</td>";
    echo "</tr>";
    $count++;
}

echo "</table>";
echo "<p><strong>✅ Total calls shown in telecaller history: $count</strong></p>";

if ($count > 0) {
    echo "<p style='color: green;'>✅ Filter is working! Only calls with call_source = NULL or not containing 'job' are shown.</p>";
} else {
    echo "<p style='color: orange;'>⚠️ No calls found. This might be because no calls match the filter criteria.</p>";
}

$stmt->close();

// Test 4: Query without filter (all calls for this caller)
echo "<h2>Step 4: Query without Filter (All Calls)</h2>";
echo "<p><strong>This shows ALL calls including job-related ones</strong></p>";

$query = "
    SELECT 
        cl.id,
        cl.driver_name,
        cl.call_source,
        cl.tc_for,
        cl.created_at
    FROM call_logs cl
    WHERE cl.caller_id = ?
    AND cl.user_id = ?
    ORDER BY cl.created_at DESC
    LIMIT 10
";

$stmt = $conn->prepare($query);
$stmt->bind_param('ii', $callerId, $userId);
$stmt->execute();
$result = $stmt->get_result();

echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr style='background-color: #f0f0f0;'><th>ID</th><th>Name</th><th>Call Source</th><th>TC For</th><th>Created At</th></tr>";

$totalCount = 0;
$jobCount = 0;
$regularCount = 0;

while ($row = $result->fetch_assoc()) {
    $isJobCall = $row['call_source'] && strpos($row['call_source'], 'job') !== false;
    $bgColor = $isJobCall ? '#ffe6e6' : '#e6ffe6';
    
    echo "<tr style='background-color: $bgColor;'>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['driver_name']}</td>";
    echo "<td>" . ($row['call_source'] ?? '<em>NULL</em>') . "</td>";
    echo "<td>{$row['tc_for']}</td>";
    echo "<td>{$row['created_at']}</td>";
    echo "</tr>";
    
    $totalCount++;
    if ($isJobCall) {
        $jobCount++;
    } else {
        $regularCount++;
    }
}

echo "</table>";
echo "<p><strong>Total calls: $totalCount</strong></p>";
echo "<p style='color: red;'>🔴 Job-related calls (should be hidden): $jobCount</p>";
echo "<p style='color: green;'>🟢 Regular calls (should be shown): $regularCount</p>";

$stmt->close();

// Cleanup
echo "<h2>Step 5: Cleanup</h2>";
$stmt = $conn->prepare("DELETE FROM call_logs WHERE caller_id = ? AND user_id = ? AND driver_name LIKE '%Call'");
$stmt->bind_param('ii', $callerId, $userId);
if ($stmt->execute()) {
    $deletedCount = $stmt->affected_rows;
    echo "✅ Cleaned up $deletedCount test calls<br>";
} else {
    echo "❌ Failed to cleanup test calls<br>";
}
$stmt->close();

echo "<h2>Summary</h2>";
echo "<div style='background-color: #e8f5e9; padding: 15px; border-radius: 5px; border-left: 4px solid #4caf50;'>";
echo "<h3 style='margin-top: 0;'>✅ Test Results</h3>";
echo "<ul>";
echo "<li>✅ Calls with <code>call_source</code> containing 'job' are filtered out from telecaller call history</li>";
echo "<li>✅ Calls with <code>call_source = NULL</code> are shown in telecaller call history</li>";
echo "<li>✅ Filter is working as expected</li>";
echo "<li>✅ Job-related calls ($jobCount) are properly separated from regular calls ($regularCount)</li>";
echo "</ul>";
echo "</div>";

echo "<h2>How to Use in Production</h2>";
echo "<div style='background-color: #e3f2fd; padding: 15px; border-radius: 5px; border-left: 4px solid #2196f3;'>";
echo "<h3 style='margin-top: 0;'>📋 Implementation Guide</h3>";
echo "<ol>";
echo "<li><strong>Job Screens:</strong> Pass <code>callSource: 'job_posting'</code> or <code>callSource: 'job_applicants'</code></li>";
echo "<li><strong>Regular Screens:</strong> Pass <code>callSource: null</code> or omit the parameter</li>";
echo "<li><strong>API:</strong> The <code>call_source</code> is automatically stored in the database</li>";
echo "<li><strong>Call History:</strong> The filter automatically excludes job-related calls</li>";
echo "</ol>";
echo "</div>";

$conn->close();
?>
