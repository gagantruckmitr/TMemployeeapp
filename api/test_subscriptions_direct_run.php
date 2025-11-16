<?php
/**
 * Direct test - Run the API code directly without HTTP call
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

// Display formatted
echo "<h2>Direct API Test for Telecaller ID: 14</h2>";
echo "<hr>";

echo "<h3>Raw Output:</h3>";
echo "<pre style='background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto;'>";
echo htmlspecialchars($output);
echo "</pre>";

echo "<h3>Parsed JSON:</h3>";
$data = json_decode($output, true);

if ($data) {
    echo "<pre style='background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto;'>";
    echo json_encode($data, JSON_PRETTY_PRINT);
    echo "</pre>";
    
    if ($data['success']) {
        echo "<div style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745;'>";
        echo "<h4>✅ Success!</h4>";
        echo "<p><strong>Total Subscriptions:</strong> " . $data['data']['total_subscriptions'] . "</p>";
        echo "<p><strong>Subscriptions Returned:</strong> " . count($data['data']['subscriptions']) . "</p>";
        echo "</div>";
    } else {
        echo "<div style='background: #f8d7da; padding: 15px; border-left: 4px solid #dc3545;'>";
        echo "<h4>❌ Error!</h4>";
        echo "<p>" . $data['error'] . "</p>";
        echo "</div>";
    }
} else {
    echo "<p style='color: red;'>Failed to parse JSON</p>";
    echo "<p>JSON Error: " . json_last_error_msg() . "</p>";
}
