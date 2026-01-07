<?php
// Test Subscription KPI
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

require_once 'config.php';

echo "=== Testing Subscription KPI ===\n\n";

// Test 1: Check subscription_status column
echo "1. Checking subscription_status column in users table:\n";
try {
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'subscription_status'");
    $column = $stmt->fetch();
    if ($column) {
        echo "   ✅ Column exists\n";
        echo "   Type: {$column['Type']}\n";
        echo "   Default: {$column['Default']}\n";
    } else {
        echo "   ❌ Column 'subscription_status' not found\n";
    }
} catch (Exception $e) {
    echo "   ❌ Error: " . $e->getMessage() . "\n";
}

// Test 2: Check subscription values
echo "\n2. Subscription status distribution:\n";
try {
    $stmt = $pdo->query("
        SELECT 
            subscription_status,
            COUNT(*) as count
        FROM users
        WHERE role IN ('driver', 'transporter')
        GROUP BY subscription_status
        ORDER BY count DESC
    ");
    $results = $stmt->fetchAll();
    
    if (count($results) > 0) {
        foreach ($results as $row) {
            $status = $row['subscription_status'] ?? 'NULL';
            echo "   {$status}: {$row['count']} users\n";
        }
    } else {
        echo "   No users found\n";
    }
} catch (Exception $e) {
    echo "   ❌ Error: " . $e->getMessage() . "\n";
}

// Test 3: Check subscriptions by telecaller (using call_logs + payments logic)
echo "\n3. Subscriptions by telecaller (call_logs + payments):\n";
try {
    $stmt = $pdo->query("
        SELECT 
            cl.caller_id,
            COUNT(DISTINCT p.id) as subscription_count,
            COUNT(DISTINCT cl.user_id) as users_called
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        WHERE p.payment_status = 'captured'
        AND p.created_at > cl.created_at
        GROUP BY cl.caller_id
        ORDER BY subscription_count DESC
        LIMIT 10
    ");
    $results = $stmt->fetchAll();
    
    if (count($results) > 0) {
        foreach ($results as $row) {
            echo "   Caller {$row['caller_id']}: {$row['subscription_count']} subscriptions ";
            echo "(from {$row['users_called']} users called)\n";
        }
    } else {
        echo "   No subscriptions found\n";
    }
} catch (Exception $e) {
    echo "   ❌ Error: " . $e->getMessage() . "\n";
}

// Test 4: Test the API
echo "\n4. Testing Analytics API with subscription KPI:\n";
$callerId = 1;
$period = 'all';

try {
    $url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . 
           "/telecaller_analytics_api.php?caller_id={$callerId}&period={$period}";
    
    $context = stream_context_create(['http' => ['ignore_errors' => true]]);
    $response = @file_get_contents($url, false, $context);
    
    if ($response) {
        $data = json_decode($response, true);
        if ($data && $data['success']) {
            $overview = $data['data']['overview'] ?? [];
            echo "   ✅ API Success!\n";
            echo "   Total Calls: " . ($overview['total_calls'] ?? 0) . "\n";
            echo "   Connected: " . ($overview['connected_calls'] ?? 0) . "\n";
            echo "   Not Connected: " . ($overview['not_connected_calls'] ?? 0) . "\n";
            echo "   Callbacks: " . ($overview['callbacks_scheduled'] ?? 0) . "\n";
            echo "   Subscriptions: " . ($overview['subscription_count'] ?? 0) . "\n";
        } else {
            echo "   ❌ API Error: " . ($data['error'] ?? 'Unknown') . "\n";
        }
    } else {
        echo "   ❌ Could not reach API\n";
    }
} catch (Exception $e) {
    echo "   ❌ Exception: " . $e->getMessage() . "\n";
}

echo "\n=== Test Complete ===\n";
?>
