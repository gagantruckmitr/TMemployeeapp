<?php
// Check Call Data for Different Periods
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

require_once 'config.php';

echo "=== Checking Call Data ===\n\n";

// Check all callers
echo "1. All Callers with Call Logs:\n";
$stmt = $pdo->query("
    SELECT 
        caller_id,
        COUNT(*) as total_calls,
        MIN(DATE(created_at)) as first_call,
        MAX(DATE(created_at)) as last_call
    FROM call_logs
    GROUP BY caller_id
    ORDER BY total_calls DESC
    LIMIT 10
");
$callers = $stmt->fetchAll();

foreach ($callers as $caller) {
    echo "   Caller ID {$caller['caller_id']}: {$caller['total_calls']} calls ";
    echo "(from {$caller['first_call']} to {$caller['last_call']})\n";
}

// Check caller_id=1 specifically
echo "\n2. Caller ID 1 - Detailed Breakdown:\n";
$periods = [
    'today' => "DATE(created_at) = CURDATE()",
    'yesterday' => "DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)",
    'week' => "created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)",
    'month' => "created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)",
    'all' => "1=1"
];

foreach ($periods as $label => $condition) {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks
        FROM call_logs
        WHERE caller_id = 1 AND $condition
    ");
    $stmt->execute();
    $stats = $stmt->fetch();
    
    echo "   " . ucfirst($label) . ": {$stats['total']} calls ";
    echo "(Connected: {$stats['connected']}, Callbacks: {$stats['callbacks']})\n";
}

// Show recent calls for caller_id=1
echo "\n3. Recent 5 Calls for Caller ID 1:\n";
$stmt = $pdo->prepare("
    SELECT 
        id,
        DATE(created_at) as call_date,
        TIME(created_at) as call_time,
        call_status,
        driver_name
    FROM call_logs
    WHERE caller_id = 1
    ORDER BY created_at DESC
    LIMIT 5
");
$stmt->execute();
$recentCalls = $stmt->fetchAll();

if (count($recentCalls) > 0) {
    foreach ($recentCalls as $call) {
        echo "   [{$call['call_date']} {$call['call_time']}] ";
        echo "{$call['driver_name']} - {$call['call_status']}\n";
    }
} else {
    echo "   No calls found for caller_id=1\n";
}

// Suggest which caller to use
echo "\n4. Recommendation:\n";
if (count($callers) > 0) {
    $bestCaller = $callers[0];
    echo "   Use caller_id={$bestCaller['caller_id']} for testing\n";
    echo "   This caller has {$bestCaller['total_calls']} total calls\n";
    
    // Test with this caller
    echo "\n5. Testing API with caller_id={$bestCaller['caller_id']}:\n";
    $testUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . 
               "/telecaller_analytics_api.php?caller_id={$bestCaller['caller_id']}&period=all";
    
    $context = stream_context_create(['http' => ['ignore_errors' => true]]);
    $response = @file_get_contents($testUrl, false, $context);
    
    if ($response) {
        $data = json_decode($response, true);
        if ($data && $data['success']) {
            $overview = $data['data']['overview'] ?? [];
            echo "   ✅ API Success!\n";
            echo "   Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
            echo "   Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
            echo "   Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
            echo "   Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
        } else {
            echo "   ❌ API Error: " . ($data['error'] ?? 'Unknown') . "\n";
        }
    } else {
        echo "   ❌ Could not reach API\n";
    }
} else {
    echo "   ⚠️  No call logs found in database\n";
}

echo "\n=== Check Complete ===\n";
?>
