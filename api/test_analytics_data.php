<?php
// Test Analytics Data API
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$callerId = (int)($_GET['caller_id'] ?? 1);
$period = $_GET['period'] ?? 'today';

echo "=== Testing telecaller_analytics_api.php ===\n";
echo "Caller ID: $callerId\n";
echo "Period: $period\n\n";

// Make request to the actual API
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . "/telecaller_analytics_api.php?caller_id=$callerId&period=$period";
echo "API URL: $url\n\n";

$response = file_get_contents($url);
$data = json_decode($response, true);

echo "=== API Response ===\n";
echo json_encode($data, JSON_PRETTY_PRINT);
echo "\n\n";

if ($data['success']) {
    echo "=== ✅ API Success ===\n";
    $overview = $data['data']['overview'] ?? [];
    echo "Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
    echo "Connected Calls: " . ($overview['connected_calls'] ?? 0) . "\n";
    echo "Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
    echo "Callbacks Scheduled: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
    echo "Success Rate: " . ($overview['success_rate'] ?? 0) . "%\n";
    echo "Interested Count: " . ($overview['interested_count'] ?? 0) . "\n";
    echo "Not Interested: " . ($overview['not_interested'] ?? 0) . "\n";
    
    echo "\n=== Recent Calls ===\n";
    $recentCalls = $data['data']['recent_calls'] ?? [];
    echo "Count: " . count($recentCalls) . "\n";
    
    echo "\n=== Call Trends ===\n";
    $trends = $data['data']['call_trends'] ?? [];
    echo "Count: " . count($trends) . "\n";
} else {
    echo "=== ❌ API Failed ===\n";
    echo "Error: " . ($data['error'] ?? 'Unknown error') . "\n";
}
?>
