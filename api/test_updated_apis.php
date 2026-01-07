<?php
header('Content-Type: application/json');

echo "Testing Updated APIs with call_history table\n\n";

// Test 1: Dashboard Stats API
echo "=== Test 1: Dashboard Stats API ===\n";
$dashboardUrl = "http://localhost/api/dashboard_stats_api.php";
$ch = curl_init($dashboardUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$dashboardResponse = curl_exec($ch);
$dashboardData = json_decode($dashboardResponse, true);
curl_close($ch);

if ($dashboardData && isset($dashboardData['success'])) {
    echo "✓ Dashboard Stats API working\n";
    echo "  Total Calls: " . ($dashboardData['data']['total_calls'] ?? 0) . "\n";
    echo "  Connected: " . ($dashboardData['data']['connected_calls'] ?? 0) . "\n";
    echo "  Calls Today: " . ($dashboardData['data']['calls_today'] ?? 0) . "\n";
} else {
    echo "✗ Dashboard Stats API failed\n";
    echo "  Error: " . ($dashboardData['error'] ?? 'Unknown error') . "\n";
}

echo "\n";

// Test 2: Telecaller Analytics API (using telecaller ID 3 from sample data)
echo "=== Test 2: Telecaller Analytics API ===\n";
$analyticsUrl = "http://localhost/api/telecaller_analytics_api.php?caller_id=3&period=week";
$ch = curl_init($analyticsUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$analyticsResponse = curl_exec($ch);
$analyticsData = json_decode($analyticsResponse, true);
curl_close($ch);

if ($analyticsData && isset($analyticsData['success'])) {
    echo "✓ Telecaller Analytics API working\n";
    $overview = $analyticsData['data']['overview'] ?? [];
    echo "  Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
    echo "  Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
    echo "  Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
    echo "  Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
    echo "  Interested: " . ($overview['interested_count'] ?? 0) . "\n";
    echo "  Success Rate: " . ($overview['success_rate'] ?? 0) . "%\n";
} else {
    echo "✗ Telecaller Analytics API failed\n";
    echo "  Error: " . ($analyticsData['error'] ?? 'Unknown error') . "\n";
}

echo "\n";

// Test 3: Check call_history table directly
echo "=== Test 3: Direct call_history Query ===\n";
require_once 'config.php';

$query = "SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
    SUM(CASE WHEN call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected,
    SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callback_later
FROM call_history
WHERE DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";

$result = $conn->query($query);
$stats = $result->fetch_assoc();

echo "✓ Direct query successful\n";
echo "  Total (last 7 days): " . $stats['total'] . "\n";
echo "  Connected: " . $stats['connected'] . "\n";
echo "  Not Connected: " . $stats['not_connected'] . "\n";
echo "  Callback Later: " . $stats['callback_later'] . "\n";

echo "\n=== All Tests Complete ===\n";
?>
