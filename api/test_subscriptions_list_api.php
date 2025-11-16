<?php
/**
 * Test Subscriptions List API
 */

require_once 'config.php';

$telecaller_id = 14; // Pallvi - has 17 subscriptions

echo "<h2>Testing Subscriptions List API for Telecaller ID: $telecaller_id</h2>";
echo "<hr>";

$api_url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecaller_subscriptions_api.php?user_id=$telecaller_id&period=all";

echo "<p><strong>API URL:</strong> <a href='$api_url' target='_blank'>$api_url</a></p>";

$response = @file_get_contents($api_url);

if ($response === false) {
    echo "<p style='color: red;'>Failed to call API</p>";
    exit;
}

$data = json_decode($response, true);

echo "<h3>API Response:</h3>";
echo "<pre style='background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto;'>";
echo json_encode($data, JSON_PRETTY_PRINT);
echo "</pre>";

if ($data['success']) {
    echo "<div style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745;'>";
    echo "<h4>✅ API Success!</h4>";
    echo "<p><strong>Total Subscriptions:</strong> " . $data['data']['total_subscriptions'] . "</p>";
    echo "<p><strong>Total Revenue:</strong> ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
    echo "<p><strong>Subscriptions Returned:</strong> " . count($data['data']['subscriptions']) . "</p>";
    echo "</div>";
    
    if (count($data['data']['subscriptions']) > 0) {
        echo "<h3>Sample Subscriptions:</h3>";
        echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
        echo "<tr><th>Payment ID</th><th>Driver</th><th>Amount</th><th>Call Time</th><th>Payment Time</th><th>Minutes After</th></tr>";
        
        foreach (array_slice($data['data']['subscriptions'], 0, 5) as $sub) {
            echo "<tr>";
            echo "<td>" . $sub['payment_id'] . "</td>";
            echo "<td>" . $sub['driver_name'] . "<br><small>" . $sub['driver_tmid'] . "</small></td>";
            echo "<td>₹" . $sub['amount'] . "</td>";
            echo "<td>" . ($sub['call_time'] ?? 'N/A') . "</td>";
            echo "<td>" . $sub['payment_created_at'] . "</td>";
            echo "<td>" . ($sub['minutes_after_call'] ?? 'N/A') . " min</td>";
            echo "</tr>";
        }
        
        echo "</table>";
    }
} else {
    echo "<div style='background: #f8d7da; padding: 15px; border-left: 4px solid #dc3545;'>";
    echo "<h4>❌ API Error!</h4>";
    echo "<p><strong>Error:</strong> " . ($data['error'] ?? 'Unknown error') . "</p>";
    echo "</div>";
}

echo "<hr>";
echo "<p><em>Test completed at " . date('Y-m-d H:i:s') . "</em></p>";
