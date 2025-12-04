<?php
// Direct test of the analytics API
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Testing Analytics API Directly</h2>";

$callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 3;

echo "<p>Testing with Caller ID: <strong>$callerId</strong></p>";
echo "<p><a href='?caller_id=1'>Test Caller 1</a> | <a href='?caller_id=3'>Test Caller 3</a></p>";

// Make API call
$apiUrl = "http://" . $_SERVER['HTTP_HOST'] . "/api/telecaller_analytics_api.php?caller_id=$callerId&period=week";

echo "<h3>API URL:</h3>";
echo "<code>$apiUrl</code><br><br>";

$response = file_get_contents($apiUrl);
$data = json_decode($response, true);

echo "<h3>API Response:</h3>";
if ($data && isset($data['success']) && $data['success']) {
    echo "<p style='color: green;'>✅ API Success!</p>";
    
    $overview = $data['data']['overview'] ?? [];
    echo "<h4>Overview Stats:</h4>";
    echo "<table border='1' cellpadding='10'>";
    echo "<tr><th>Metric</th><th>Value</th></tr>";
    echo "<tr><td>Total Calls</td><td><strong>" . ($overview['total_calls'] ?? 0) . "</strong></td></tr>";
    echo "<tr><td>Connected Calls</td><td><strong>" . ($overview['connected_calls'] ?? 0) . "</strong></td></tr>";
    echo "<tr><td>Interested Count</td><td style='background: #d4edda;'><strong>" . ($overview['interested_count'] ?? 0) . "</strong></td></tr>";
    echo "<tr><td>Not Interested</td><td style='background: #f8d7da;'><strong>" . ($overview['not_interested'] ?? 0) . "</strong></td></tr>";
    echo "<tr><td>Callbacks</td><td><strong>" . ($overview['callbacks'] ?? 0) . "</strong></td></tr>";
    echo "</table>";
    
    $interestedCalls = $data['data']['interested_calls'] ?? [];
    $notInterestedCalls = $data['data']['not_interested_calls'] ?? [];
    
    echo "<h4>Interested Calls List:</h4>";
    if (empty($interestedCalls)) {
        echo "<p style='color: orange;'>⚠️ No interested calls found</p>";
    } else {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Driver</th><th>Feedback</th><th>Status</th><th>Time</th></tr>";
        foreach ($interestedCalls as $call) {
            echo "<tr>";
            echo "<td>" . ($call['driver_name'] ?? 'Unknown') . "</td>";
            echo "<td>" . ($call['feedback'] ?? '') . "</td>";
            echo "<td>" . ($call['call_status'] ?? '') . "</td>";
            echo "<td>" . ($call['time_ago'] ?? '') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    echo "<h4>Not Interested Calls List:</h4>";
    if (empty($notInterestedCalls)) {
        echo "<p style='color: orange;'>⚠️ No not interested calls found</p>";
    } else {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Driver</th><th>Feedback</th><th>Status</th><th>Time</th></tr>";
        foreach ($notInterestedCalls as $call) {
            echo "<tr>";
            echo "<td>" . ($call['driver_name'] ?? 'Unknown') . "</td>";
            echo "<td>" . ($call['feedback'] ?? '') . "</td>";
            echo "<td>" . ($call['call_status'] ?? '') . "</td>";
            echo "<td>" . ($call['time_ago'] ?? '') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    echo "<h4>Full JSON Response:</h4>";
    echo "<pre style='background: #f5f5f5; padding: 10px; overflow: auto;'>";
    echo json_encode($data, JSON_PRETTY_PRINT);
    echo "</pre>";
    
} else {
    echo "<p style='color: red;'>❌ API Error!</p>";
    echo "<pre style='background: #f8d7da; padding: 10px;'>";
    echo htmlspecialchars($response);
    echo "</pre>";
}

echo "<hr>";
echo "<h3>Next Steps:</h3>";
echo "<ol>";
echo "<li><a href='add_test_feedback_data.php?caller_id=$callerId'>Add Test Feedback Data for Caller $callerId</a></li>";
echo "<li><a href='test_analytics_feedback.php?caller_id=$callerId'>View Raw Feedback Data</a></li>";
echo "<li>Refresh this page to see updated counts</li>";
echo "</ol>";
?>
