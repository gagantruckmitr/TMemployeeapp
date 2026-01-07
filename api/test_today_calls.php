<?php
header('Content-Type: application/json');

require_once 'config.php';

echo "Testing Today's Call History for assigned_to = 8\n\n";

// Test 1: Check today's call_history data for assigned_to = 8
echo "=== Test 1: Today's Call History for assigned_to = 8 ===\n";
$query = "SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
    SUM(CASE WHEN call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected,
    SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callback_later,
    MIN(created_at) as first_call,
    MAX(created_at) as last_call
FROM call_history
WHERE assigned_to = 8
AND DATE(created_at) = CURDATE()";

$result = $conn->query($query);
$stats = $result->fetch_assoc();

echo "✓ Today's calls for assigned_to = 8:\n";
echo "  Total: " . $stats['total'] . "\n";
echo "  Connected: " . $stats['connected'] . "\n";
echo "  Not Connected: " . $stats['not_connected'] . "\n";
echo "  Callback Later: " . $stats['callback_later'] . "\n";
echo "  First Call: " . ($stats['first_call'] ?? 'N/A') . "\n";
echo "  Last Call: " . ($stats['last_call'] ?? 'N/A') . "\n\n";

// Test 2: Check all telecallers today
echo "=== Test 2: Today's Calls by All Telecallers ===\n";
$allQuery = "SELECT 
    ch.assigned_to,
    a.name as telecaller_name,
    COUNT(*) as total,
    SUM(CASE WHEN ch.call_status = 'connected' THEN 1 ELSE 0 END) as connected,
    SUM(CASE WHEN ch.call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected,
    SUM(CASE WHEN ch.call_status = 'callback_later' THEN 1 ELSE 0 END) as callback_later
FROM call_history ch
LEFT JOIN admins a ON ch.assigned_to = a.id
WHERE DATE(ch.created_at) = CURDATE()
GROUP BY ch.assigned_to, a.name
ORDER BY total DESC";

$allResult = $conn->query($allQuery);
while ($row = $allResult->fetch_assoc()) {
    echo "  " . ($row['telecaller_name'] ?? 'Unknown') . " (ID: " . $row['assigned_to'] . "):\n";
    echo "    Total: " . $row['total'] . " | Connected: " . $row['connected'] . 
         " | Not Connected: " . $row['not_connected'] . " | Callback: " . $row['callback_later'] . "\n";
}

echo "\n";

// Test 3: Sample of today's calls for assigned_to = 8
echo "=== Test 3: Sample of Today's Calls (Last 5) ===\n";
$sampleQuery = "SELECT 
    ch.id,
    ch.unique_id,
    u.name as driver_name,
    u.mobile as driver_mobile,
    ch.call_status,
    ch.call_feedback,
    ch.created_at
FROM call_history ch
LEFT JOIN users u ON ch.user_id = u.id
WHERE ch.assigned_to = 8
AND DATE(ch.created_at) = CURDATE()
ORDER BY ch.created_at DESC
LIMIT 5";

$sampleResult = $conn->query($sampleQuery);
while ($row = $sampleResult->fetch_assoc()) {
    $statusLabel = $row['call_status'];
    if ($statusLabel === 'connected') {
        $statusLabel = 'Connected';
    } elseif ($statusLabel === 'not_connected') {
        $statusLabel = 'Not Connected';
    } elseif ($statusLabel === 'callback_later') {
        $statusLabel = 'Call Back';
    }
    
    echo "  " . $row['created_at'] . " | " . ($row['driver_name'] ?? 'Unknown') . 
         " | " . $statusLabel . " | " . ($row['call_feedback'] ?? 'No feedback') . "\n";
}

echo "\n";

// Test 4: Test Analytics API for today
echo "=== Test 4: Analytics API for Today ===\n";
$ch = curl_init("http://localhost/api/telecaller_analytics_api.php?caller_id=8&period=today");
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
} else {
    echo "✗ API call failed\n";
    echo "  Testing with direct PHP call...\n";
    
    // Direct PHP test
    ob_start();
    $_GET['caller_id'] = 8;
    $_GET['period'] = 'today';
    include 'telecaller_analytics_api.php';
    $directResponse = ob_get_clean();
    
    $directData = json_decode($directResponse, true);
    if ($directData && isset($directData['success'])) {
        echo "✓ Direct PHP call successful\n";
        $overview = $directData['data']['overview'] ?? [];
        echo "  Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
        echo "  Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
        echo "  Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
        echo "  Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
    }
}

echo "\n=== All Tests Complete ===\n";
?>
