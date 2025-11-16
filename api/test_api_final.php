<?php
/**
 * Final API Test - Check if data is being returned
 */

// Simulate GET parameters
$_GET['user_id'] = 14;
$_GET['period'] = 'all';

// Capture output
ob_start();

// Include the API file
include 'telecaller_subscriptions_api.php';

// Get the output
$output = ob_get_clean();

echo "<h2>Final API Test for Telecaller ID: 14</h2>";
echo "<hr>";

$data = json_decode($output, true);

if ($data && $data['success']) {
    echo "<div style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0;'>";
    echo "<h3>✅ API is working!</h3>";
    echo "<p><strong>Total Subscriptions:</strong> " . $data['data']['total_subscriptions'] . "</p>";
    echo "<p><strong>Total Revenue:</strong> ₹" . number_format($data['data']['total_revenue'], 2) . "</p>";
    echo "<p><strong>Subscriptions in Response:</strong> " . count($data['data']['subscriptions']) . "</p>";
    echo "</div>";
    
    if (count($data['data']['subscriptions']) > 0) {
        echo "<h3>Sample Subscriptions (First 3):</h3>";
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #f8f9fa;'>";
        echo "<th>Driver Name</th>";
        echo "<th>TMID</th>";
        echo "<th>Mobile</th>";
        echo "<th>Amount</th>";
        echo "<th>Payment Date</th>";
        echo "</tr>";
        
        foreach (array_slice($data['data']['subscriptions'], 0, 3) as $sub) {
            echo "<tr>";
            echo "<td><strong>" . ($sub['driver_name'] ?? 'N/A') . "</strong></td>";
            echo "<td>" . ($sub['driver_tmid'] ?? 'N/A') . "</td>";
            echo "<td>" . ($sub['driver_mobile'] ?? 'N/A') . "</td>";
            echo "<td style='color: green; font-weight: bold;'>₹" . number_format($sub['amount'], 2) . "</td>";
            echo "<td>" . ($sub['payment_created_at'] ?? 'N/A') . "</td>";
            echo "</tr>";
        }
        
        echo "</table>";
        
        echo "<h3>Full JSON Response (First Subscription):</h3>";
        echo "<pre style='background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto;'>";
        echo json_encode($data['data']['subscriptions'][0], JSON_PRETTY_PRINT);
        echo "</pre>";
    } else {
        echo "<div style='background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107;'>";
        echo "<p><strong>⚠️ Warning:</strong> API returned success but subscriptions array is empty!</p>";
        echo "</div>";
    }
} else {
    echo "<div style='background: #f8d7da; padding: 15px; border-left: 4px solid #dc3545;'>";
    echo "<h3>❌ API Error!</h3>";
    echo "<p><strong>Error:</strong> " . ($data['error'] ?? 'Unknown error') . "</p>";
    echo "</div>";
}

echo "<hr>";
echo "<h3>Raw JSON Response:</h3>";
echo "<pre style='background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto; max-height: 400px;'>";
echo htmlspecialchars($output);
echo "</pre>";
