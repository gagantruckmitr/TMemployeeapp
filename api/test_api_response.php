<?php
/**
 * Test API Response for Telecallers with Subscriptions
 */

require_once 'config.php';

echo "<h2>Testing API Responses for Telecallers with Subscriptions</h2>";
echo "<hr>";

// Get telecallers with subscriptions
$query = "
    SELECT DISTINCT cl.caller_id, a.name, COUNT(DISTINCT p.id) as sub_count
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    LEFT JOIN admins a ON cl.caller_id = a.id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    GROUP BY cl.caller_id, a.name
    HAVING sub_count > 0
    ORDER BY sub_count DESC
";

$result = $conn->query($query);

echo "<h3>Telecallers with Subscriptions:</h3>";
echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Telecaller ID</th><th>Name</th><th>Subscriptions</th><th>Test Stats API</th><th>Test Subscriptions API</th></tr>";

while ($row = $result->fetch_assoc()) {
    $tc_id = $row['caller_id'];
    $tc_name = $row['name'] ?? 'Unknown';
    $sub_count = $row['sub_count'];
    
    $stats_url = "telecaller_subscription_stats_api.php?user_id=$tc_id";
    $subs_url = "telecaller_subscriptions_api.php?user_id=$tc_id&period=all";
    
    echo "<tr>";
    echo "<td><strong>$tc_id</strong></td>";
    echo "<td>$tc_name</td>";
    echo "<td><span style='background: #28a745; color: white; padding: 5px 10px; border-radius: 4px;'>$sub_count</span></td>";
    echo "<td><a href='$stats_url' target='_blank'>Test Stats API</a></td>";
    echo "<td><a href='$subs_url' target='_blank'>Test Subscriptions API</a></td>";
    echo "</tr>";
}

echo "</table>";

echo "<hr>";

// Test with telecaller ID 8 (has 44 subscriptions)
echo "<h3>Detailed Test: Telecaller ID 8 (Sonam - 44 subscriptions)</h3>";

$test_id = 8;
$stats_url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscription_stats_api.php?user_id=$test_id";

echo "<p><strong>Stats API URL:</strong> <a href='$stats_url' target='_blank'>$stats_url</a></p>";

$response = @file_get_contents($stats_url);
if ($response) {
    $data = json_decode($response, true);
    echo "<p><strong>API Response:</strong></p>";
    echo "<pre style='background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto;'>";
    echo json_encode($data, JSON_PRETTY_PRINT);
    echo "</pre>";
    
    if ($data['success']) {
        echo "<div style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0;'>";
        echo "<h4>✅ API is working correctly!</h4>";
        echo "<p><strong>Total Subscriptions:</strong> " . $data['data']['total_subscriptions'] . "</p>";
        echo "<p><strong>Total Revenue:</strong> ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
        echo "<p><strong>Today's Subscriptions:</strong> " . $data['data']['today_subscriptions'] . "</p>";
        echo "<p><strong>Week's Subscriptions:</strong> " . $data['data']['week_subscriptions'] . "</p>";
        echo "<p><strong>Month's Subscriptions:</strong> " . $data['data']['month_subscriptions'] . "</p>";
        echo "</div>";
    } else {
        echo "<div style='background: #f8d7da; padding: 15px; border-left: 4px solid #dc3545;'>";
        echo "<p><strong>❌ API Error:</strong> " . ($data['error'] ?? 'Unknown error') . "</p>";
        echo "</div>";
    }
} else {
    echo "<p style='color: red;'>Failed to call API</p>";
}

echo "<hr>";

// Check what user ID the app might be sending
echo "<h3>Debugging: Check User Login</h3>";
echo "<p>The app might be sending a different user_id. Common issues:</p>";
echo "<ul>";
echo "<li>App is sending user_id from 'users' table instead of 'admins' table</li>";
echo "<li>App is sending NULL or 0 as user_id</li>";
echo "<li>App is not authenticated properly</li>";
echo "</ul>";

echo "<p><strong>To fix in the app:</strong></p>";
echo "<ol>";
echo "<li>Check that RealAuthService.instance.currentUser.id returns the correct admin ID</li>";
echo "<li>Verify the user is logged in as an admin/telecaller, not a driver</li>";
echo "<li>Check the API URL being called in the app logs</li>";
echo "<li>Add debug logging in subscription_service.dart to see what user_id is being sent</li>";
echo "</ol>";

echo "<hr>";
echo "<p><em>Test completed at " . date('Y-m-d H:i:s') . "</em></p>";
