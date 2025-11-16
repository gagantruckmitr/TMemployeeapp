<?php
/**
 * Test Telecaller Subscriptions API
 * Tests the new subscription logic based on call_logs and payments matching
 */

require_once 'config.php';

echo "<h2>Testing Telecaller Subscriptions API</h2>";
echo "<hr>";

// Test 1: Get all subscriptions for a telecaller
echo "<h3>Test 1: Get All Subscriptions for Telecaller</h3>";
$telecaller_id = 1; // Change this to test with different telecaller

$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscriptions_api.php?user_id=$telecaller_id&period=all";
echo "<p><strong>URL:</strong> $url</p>";

$response = file_get_contents($url);
$data = json_decode($response, true);

echo "<pre>";
print_r($data);
echo "</pre>";

if ($data['success']) {
    echo "<p style='color: green;'><strong>✓ Success!</strong></p>";
    echo "<p>Total Subscriptions: " . $data['data']['total_subscriptions'] . "</p>";
    echo "<p>Total Revenue: ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
    echo "<p>Average Subscription Value: ₹" . number_format($data['data']['avg_subscription_value'], 2) . "</p>";
} else {
    echo "<p style='color: red;'><strong>✗ Failed!</strong></p>";
    echo "<p>Error: " . ($data['error'] ?? 'Unknown error') . "</p>";
}

echo "<hr>";

// Test 2: Get today's subscriptions
echo "<h3>Test 2: Get Today's Subscriptions</h3>";
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscriptions_api.php?user_id=$telecaller_id&period=today";
echo "<p><strong>URL:</strong> $url</p>";

$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data['success']) {
    echo "<p style='color: green;'><strong>✓ Success!</strong></p>";
    echo "<p>Today's Subscriptions: " . $data['data']['total_subscriptions'] . "</p>";
    echo "<p>Today's Revenue: ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
} else {
    echo "<p style='color: red;'><strong>✗ Failed!</strong></p>";
}

echo "<hr>";

// Test 3: Get week's subscriptions
echo "<h3>Test 3: Get This Week's Subscriptions</h3>";
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscriptions_api.php?user_id=$telecaller_id&period=week";
echo "<p><strong>URL:</strong> $url</p>";

$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data['success']) {
    echo "<p style='color: green;'><strong>✓ Success!</strong></p>";
    echo "<p>Week's Subscriptions: " . $data['data']['total_subscriptions'] . "</p>";
    echo "<p>Week's Revenue: ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
} else {
    echo "<p style='color: red;'><strong>✗ Failed!</strong></p>";
}

echo "<hr>";

// Test 4: Get month's subscriptions
echo "<h3>Test 4: Get This Month's Subscriptions</h3>";
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscriptions_api.php?user_id=$telecaller_id&period=month";
echo "<p><strong>URL:</strong> $url</p>";

$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data['success']) {
    echo "<p style='color: green;'><strong>✓ Success!</strong></p>";
    echo "<p>Month's Subscriptions: " . $data['data']['total_subscriptions'] . "</p>";
    echo "<p>Month's Revenue: ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
} else {
    echo "<p style='color: red;'><strong>✗ Failed!</strong></p>";
}

echo "<hr>";

// Test 5: Check database for matching records
echo "<h3>Test 5: Database Check - Call Logs with Matching Payments</h3>";

$query = "
    SELECT 
        cl.id as call_log_id,
        cl.user_id as driver_id,
        cl.caller_id as telecaller_id,
        cl.call_time,
        p.id as payment_id,
        p.created_at as payment_created_at,
        p.amount,
        TIMESTAMPDIFF(MINUTE, cl.call_time, p.created_at) as minutes_after_call
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    AND cl.caller_id = $telecaller_id
    ORDER BY cl.call_time DESC
    LIMIT 5
";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<p style='color: green;'><strong>✓ Found matching records!</strong></p>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Call Log ID</th><th>Driver ID</th><th>Call Time</th><th>Payment ID</th><th>Payment Time</th><th>Amount</th><th>Minutes After Call</th></tr>";
    
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['call_log_id'] . "</td>";
        echo "<td>" . $row['driver_id'] . "</td>";
        echo "<td>" . $row['call_time'] . "</td>";
        echo "<td>" . $row['payment_id'] . "</td>";
        echo "<td>" . $row['payment_created_at'] . "</td>";
        echo "<td>₹" . number_format($row['amount'], 2) . "</td>";
        echo "<td>" . $row['minutes_after_call'] . " min</td>";
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<p style='color: orange;'><strong>⚠ No matching records found!</strong></p>";
    echo "<p>This could mean:</p>";
    echo "<ul>";
    echo "<li>No calls have been made by this telecaller</li>";
    echo "<li>No payments have been made after the calls</li>";
    echo "<li>The telecaller_id ($telecaller_id) doesn't exist</li>";
    echo "</ul>";
}

echo "<hr>";
echo "<p><em>Test completed at " . date('Y-m-d H:i:s') . "</em></p>";
