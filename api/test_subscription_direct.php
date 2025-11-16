<?php
/**
 * Direct test of subscription logic
 */

require_once 'config.php';

echo "<h2>Direct Subscription Test</h2>";
echo "<hr>";

// Get a telecaller ID to test with
echo "<h3>Step 1: Get Telecaller IDs</h3>";
$query = "SELECT DISTINCT caller_id FROM call_logs WHERE caller_id IS NOT NULL LIMIT 5";
$result = $conn->query($query);

$telecaller_ids = [];
if ($result && $result->num_rows > 0) {
    echo "<p>Found telecaller IDs:</p><ul>";
    while ($row = $result->fetch_assoc()) {
        $telecaller_ids[] = $row['caller_id'];
        echo "<li>Telecaller ID: " . $row['caller_id'] . "</li>";
    }
    echo "</ul>";
} else {
    echo "<p style='color: red;'>No telecaller IDs found in call_logs!</p>";
}

if (empty($telecaller_ids)) {
    echo "<p style='color: red;'><strong>Cannot proceed - no telecaller data!</strong></p>";
    exit;
}

$test_telecaller_id = $telecaller_ids[0];
echo "<p><strong>Testing with Telecaller ID: $test_telecaller_id</strong></p>";

echo "<hr>";

// Test the exact query from the API
echo "<h3>Step 2: Test Subscription Query</h3>";

$query = "
    SELECT 
        cl.id as call_log_id,
        cl.user_id as driver_id,
        COALESCE(cl.driver_name, u.name) as driver_name,
        COALESCE(cl.user_number, u.mobile) as driver_mobile,
        u.unique_id as driver_tmid,
        cl.caller_id as telecaller_id,
        a.name as telecaller_name,
        cl.call_time,
        cl.call_status,
        cl.call_duration,
        p.id as payment_id,
        p.created_at as payment_created_at,
        FROM_UNIXTIME(p.start_at) AS payment_start_time,
        FROM_UNIXTIME(p.end_at) AS payment_end_time,
        TIMESTAMPDIFF(MINUTE, cl.call_time, p.created_at) as minutes_after_call,
        p.amount,
        p.payment_id as razorpay_payment_id,
        p.payment_status,
        p.payment_type,
        p.plan_id,
        DATEDIFF(FROM_UNIXTIME(p.end_at), FROM_UNIXTIME(p.start_at)) as subscription_days
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    LEFT JOIN users u ON cl.user_id = u.id
    LEFT JOIN admins a ON cl.caller_id = a.id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    AND cl.caller_id = " . intval($test_telecaller_id) . "
    ORDER BY cl.call_time DESC
    LIMIT 5
";

echo "<p><strong>Query:</strong></p>";
echo "<pre style='background: #f5f5f5; padding: 10px; overflow-x: auto;'>" . htmlspecialchars($query) . "</pre>";

$result = $conn->query($query);

if (!$result) {
    echo "<p style='color: red;'><strong>Query Error:</strong> " . $conn->error . "</p>";
} else {
    $count = $result->num_rows;
    echo "<p style='color: " . ($count > 0 ? 'green' : 'orange') . ";'><strong>Found $count records</strong></p>";
    
    if ($count > 0) {
        echo "<table border='1' cellpadding='5' style='border-collapse: collapse; font-size: 12px;'>";
        echo "<tr>";
        echo "<th>Call Log ID</th>";
        echo "<th>Driver</th>";
        echo "<th>Telecaller</th>";
        echo "<th>Call Time</th>";
        echo "<th>Payment Time</th>";
        echo "<th>Minutes After</th>";
        echo "<th>Amount</th>";
        echo "</tr>";
        
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . $row['call_log_id'] . "</td>";
            echo "<td>" . $row['driver_name'] . "<br><small>" . $row['driver_mobile'] . "</small></td>";
            echo "<td>" . $row['telecaller_name'] . "</td>";
            echo "<td>" . $row['call_time'] . "</td>";
            echo "<td>" . $row['payment_created_at'] . "</td>";
            echo "<td>" . $row['minutes_after_call'] . " min</td>";
            echo "<td>₹" . number_format($row['amount'], 2) . "</td>";
            echo "</tr>";
        }
        
        echo "</table>";
    }
}

echo "<hr>";

// Test stats query
echo "<h3>Step 3: Test Stats Query</h3>";

$stats_query = "
    SELECT 
        COUNT(DISTINCT p.id) as total_subscriptions,
        SUM(p.amount) as total_revenue,
        COUNT(DISTINCT CASE WHEN DATE(cl.call_time) = CURDATE() THEN p.id END) as today_subscriptions,
        SUM(CASE WHEN DATE(cl.call_time) = CURDATE() THEN p.amount ELSE 0 END) as today_revenue
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    AND cl.caller_id = " . intval($test_telecaller_id) . "
";

$result = $conn->query($stats_query);

if (!$result) {
    echo "<p style='color: red;'><strong>Stats Query Error:</strong> " . $conn->error . "</p>";
} else {
    $stats = $result->fetch_assoc();
    echo "<div style='background: #e8f5e9; padding: 15px; border-radius: 8px;'>";
    echo "<h4>Statistics for Telecaller ID: $test_telecaller_id</h4>";
    echo "<p><strong>Total Subscriptions:</strong> " . ($stats['total_subscriptions'] ?? 0) . "</p>";
    echo "<p><strong>Total Revenue:</strong> ₹" . number_format($stats['total_revenue'] ?? 0, 2) . "</p>";
    echo "<p><strong>Today's Subscriptions:</strong> " . ($stats['today_subscriptions'] ?? 0) . "</p>";
    echo "<p><strong>Today's Revenue:</strong> ₹" . number_format($stats['today_revenue'] ?? 0, 2) . "</p>";
    echo "</div>";
}

echo "<hr>";

// Test API endpoint
echo "<h3>Step 4: Test API Endpoint</h3>";
$api_url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscription_stats_api.php?user_id=$test_telecaller_id";
echo "<p><strong>API URL:</strong> <a href='$api_url' target='_blank'>$api_url</a></p>";

$response = @file_get_contents($api_url);
if ($response === false) {
    echo "<p style='color: red;'>Failed to call API</p>";
} else {
    $data = json_decode($response, true);
    echo "<p><strong>API Response:</strong></p>";
    echo "<pre style='background: #f5f5f5; padding: 10px; overflow-x: auto;'>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
}

echo "<hr>";
echo "<p><em>Test completed at " . date('Y-m-d H:i:s') . "</em></p>";
