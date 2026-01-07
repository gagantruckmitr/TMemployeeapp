<?php
// Test Analytics API with Caller ID 8
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

require_once 'config.php';

$callerId = 8;

echo "=== Testing Analytics API for Caller ID 8 ===\n\n";

// Test 1: Check basic call stats
echo "1. Basic Call Stats for Caller 8:\n";
try {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected,
            COUNT(CASE WHEN call_status = 'callback_later' THEN 1 END) as callbacks,
            COUNT(CASE 
                WHEN call_status IS NULL THEN 1
                WHEN call_status NOT IN ('connected', 'callback_later') THEN 1
                ELSE 0 
            END) as not_connected
        FROM call_logs
        WHERE caller_id = ?
    ");
    $stmt->execute([$callerId]);
    $stats = $stmt->fetch();
    
    echo "   Total Calls: {$stats['total_calls']}\n";
    echo "   Connected: {$stats['connected']}\n";
    echo "   Not Connected: {$stats['not_connected']}\n";
    echo "   Callbacks: {$stats['callbacks']}\n";
} catch (Exception $e) {
    echo "   ❌ Error: " . $e->getMessage() . "\n";
}

// Test 2: Check subscription count
echo "\n2. Subscription Count for Caller 8:\n";
try {
    $stmt = $pdo->prepare("
        SELECT COUNT(DISTINCT p.id) as subscription_count
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        WHERE cl.caller_id = ?
        AND p.payment_status = 'captured'
        AND p.created_at > cl.created_at
    ");
    $stmt->execute([$callerId]);
    $result = $stmt->fetch();
    
    echo "   Subscriptions: {$result['subscription_count']}\n";
} catch (Exception $e) {
    echo "   ❌ Error: " . $e->getMessage() . "\n";
}

// Test 3: Show sample subscriptions
echo "\n3. Sample Subscriptions (first 5):\n";
try {
    $stmt = $pdo->prepare("
        SELECT 
            cl.user_id,
            cl.driver_name,
            cl.created_at as call_time,
            p.created_at as payment_time,
            p.amount,
            TIMESTAMPDIFF(MINUTE, cl.created_at, p.created_at) as minutes_after_call
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        WHERE cl.caller_id = ?
        AND p.payment_status = 'captured'
        AND p.created_at > cl.created_at
        ORDER BY p.created_at DESC
        LIMIT 5
    ");
    $stmt->execute([$callerId]);
    $subscriptions = $stmt->fetchAll();
    
    if (count($subscriptions) > 0) {
        foreach ($subscriptions as $sub) {
            echo "   User: {$sub['driver_name']} (ID: {$sub['user_id']})\n";
            echo "   Call: {$sub['call_time']}\n";
            echo "   Payment: {$sub['payment_time']} (₹{$sub['amount']})\n";
            echo "   Time Gap: {$sub['minutes_after_call']} minutes\n";
            echo "   ---\n";
        }
    } else {
        echo "   No subscriptions found\n";
    }
} catch (Exception $e) {
    echo "   ❌ Error: " . $e->getMessage() . "\n";
}

// Test 4: Test API for different periods
echo "\n4. Testing API for Different Periods:\n";
$periods = ['today', 'week', 'month', 'all'];

foreach ($periods as $period) {
    echo "\n   Period: " . strtoupper($period) . "\n";
    
    try {
        $url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . 
               "/telecaller_analytics_api.php?caller_id={$callerId}&period={$period}";
        
        $context = stream_context_create(['http' => ['ignore_errors' => true]]);
        $response = @file_get_contents($url, false, $context);
        
        if ($response) {
            $data = json_decode($response, true);
            if ($data && $data['success']) {
                $overview = $data['data']['overview'] ?? [];
                echo "   ✅ Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
                echo "   ✅ Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
                echo "   ✅ Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
                echo "   ✅ Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
                echo "   ✅ Subscriptions: " . ($overview['subscription_count'] ?? 0) . "\n";
            } else {
                echo "   ❌ API Error: " . ($data['error'] ?? 'Unknown') . "\n";
            }
        } else {
            echo "   ❌ Could not reach API\n";
        }
    } catch (Exception $e) {
        echo "   ❌ Exception: " . $e->getMessage() . "\n";
    }
}

echo "\n=== Test Complete ===\n";
?>
