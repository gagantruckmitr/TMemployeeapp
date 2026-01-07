<?php
// Simple Analytics Test
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

echo "Testing Analytics API Fix\n";
echo "==========================\n\n";

require_once 'config.php';

$callerId = 1;
$period = 'today';

// Test the date condition function
function getDateCondition($period) {
    switch($period) {
        case 'today': return "DATE(created_at) = CURDATE()";
        case 'week': return "created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
        case 'month': return "created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
        case 'year': return "created_at >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
        case 'all': return "1=1";
        default: return "created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    }
}

$dateCondition = getDateCondition($period);
echo "Date Condition: $dateCondition\n\n";

// Test 1: Overview stats (no JOIN - should work)
echo "Test 1: Overview Stats\n";
try {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks_scheduled
        FROM call_logs 
        WHERE caller_id = ? AND $dateCondition
    ");
    $stmt->execute([$callerId]);
    $stats = $stmt->fetch();
    echo "✅ Success\n";
    echo "Total: " . $stats['total_calls'] . "\n";
    echo "Connected: " . $stats['connected_calls'] . "\n";
    echo "Callbacks: " . $stats['callbacks_scheduled'] . "\n\n";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 2: With JOIN (the problematic one)
echo "Test 2: Query with JOIN (Fixed)\n";
try {
    $dateConditionWithAlias = str_replace('created_at', 'cl.created_at', $dateCondition);
    echo "Fixed Date Condition: $dateConditionWithAlias\n";
    
    $stmt = $pdo->prepare("
        SELECT 
            cl.*,
            COALESCE(cl.driver_name, u.name) as driver_name
        FROM call_logs cl
        LEFT JOIN users u ON cl.user_id = u.id
        WHERE cl.caller_id = ? 
        AND $dateConditionWithAlias
        LIMIT 5
    ");
    $stmt->execute([$callerId]);
    $calls = $stmt->fetchAll();
    echo "✅ Success\n";
    echo "Found " . count($calls) . " calls\n\n";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 3: Call the actual API
echo "Test 3: Full API Call\n";
try {
    // Include the API file
    ob_start();
    $_GET['caller_id'] = $callerId;
    $_GET['period'] = $period;
    
    include 'telecaller_analytics_api.php';
    
    $output = ob_get_clean();
    $data = json_decode($output, true);
    
    if ($data && isset($data['success'])) {
        if ($data['success']) {
            echo "✅ API Success\n";
            $overview = $data['data']['overview'] ?? [];
            echo "Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
            echo "Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
            echo "Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
            echo "Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
        } else {
            echo "❌ API Error: " . ($data['error'] ?? 'Unknown') . "\n";
        }
    } else {
        echo "⚠️  Invalid response\n";
        echo substr($output, 0, 200) . "\n";
    }
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

echo "\n==========================\n";
echo "Test Complete\n";
?>
