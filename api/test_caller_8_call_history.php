<?php
header('Content-Type: application/json');

require_once 'config.php';

echo "Testing Telecaller Analytics API for assigned_to = 8\n\n";

// Test 1: Check call_history data for assigned_to = 8
echo "=== Test 1: Direct call_history Query for assigned_to = 8 ===\n";
$query = "SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
    SUM(CASE WHEN call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected,
    SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callback_later
FROM call_history
WHERE assigned_to = 8
AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";

$result = $conn->query($query);
$stats = $result->fetch_assoc();

echo "✓ Direct query successful\n";
echo "  Total (last 7 days): " . $stats['total'] . "\n";
echo "  Connected: " . $stats['connected'] . "\n";
echo "  Not Connected: " . $stats['not_connected'] . "\n";
echo "  Callback Later: " . $stats['callback_later'] . "\n\n";

// Test 2: Check call distribution
echo "=== Test 2: Call Distribution for assigned_to = 8 ===\n";
$distQuery = "SELECT 
    call_status,
    COUNT(*) as count
FROM call_history
WHERE assigned_to = 8
AND created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY call_status";

$distResult = $conn->query($distQuery);
while ($row = $distResult->fetch_assoc()) {
    $label = $row['call_status'];
    if ($label === 'connected') {
        $label = 'Connected';
    } elseif ($label === 'not_connected') {
        $label = 'Not Connected';
    } elseif ($label === 'callback_later') {
        $label = 'Call Back';
    }
    echo "  $label: " . $row['count'] . "\n";
}

echo "\n";

// Test 3: Call Analytics API
echo "=== Test 3: Telecaller Analytics API Response ===\n";
$ch = curl_init("http://localhost/api/telecaller_analytics_api.php?caller_id=8&period=week");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);

if ($data && isset($data['success']) && $data['success']) {
    echo "✓ API call successful\n";
    $overview = $data['data']['overview'] ?? [];
    echo "  Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
    echo "  Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
    echo "  Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
    echo "  Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
    echo "  Success Rate: " . ($overview['success_rate'] ?? 0) . "%\n\n";
    
    echo "  Call Distribution:\n";
    $distribution = $data['data']['call_distribution'] ?? [];
    foreach ($distribution as $item) {
        echo "    " . $item['call_status'] . ": " . $item['count'] . " (" . $item['percentage'] . "%)\n";
    }
} else {
    echo "✗ API call failed\n";
    echo "  Error: " . ($data['error'] ?? 'Unknown error') . "\n";
    echo "  Response: " . substr($response, 0, 500) . "\n";
}

echo "\n=== All Tests Complete ===\n";
?>
