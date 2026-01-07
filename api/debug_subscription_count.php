<?php
// Debug Subscription Count
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

require_once 'config.php';

$callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 1;

echo "=== Debug Subscription Count for Caller ID: $callerId ===\n\n";

// Test 1: Check if caller has any calls
echo "1. Checking calls for this telecaller:\n";
$stmt = $pdo->prepare("
    SELECT COUNT(*) as total_calls
    FROM call_logs
    WHERE caller_id = ?
");
$stmt->execute([$callerId]);
$callData = $stmt->fetch();
echo "   Total calls: {$callData['total_calls']}\n\n";

// Test 2: Check if any of those calls have matching payments
echo "2. Checking payments for users called by this telecaller:\n";
$stmt = $pdo->prepare("
    SELECT 
        cl.user_id,
        COUNT(DISTINCT cl.id) as calls_made,
        COUNT(DISTINCT p.id) as payments_found
    FROM call_logs cl
    LEFT JOIN payments p ON cl.user_id = p.user_id
    WHERE cl.caller_id = ?
    GROUP BY cl.user_id
    HAVING payments_found > 0
    LIMIT 10
");
$stmt->execute([$callerId]);
$results = $stmt->fetchAll();

if (count($results) > 0) {
    foreach ($results as $row) {
        echo "   User {$row['user_id']}: {$row['calls_made']} calls, {$row['payments_found']} payments\n";
    }
} else {
    echo "   No users with payments found\n";
}

// Test 3: Check subscription count with current logic
echo "\n3. Testing current subscription query:\n";
$stmt = $pdo->prepare("
    SELECT COUNT(DISTINCT p.id) as subscription_count
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE cl.caller_id = ?
    AND p.payment_status = 'captured'
    AND p.created_at > cl.created_at
");
$stmt->execute([$callerId]);
$subData = $stmt->fetch();
echo "   Subscription count: {$subData['subscription_count']}\n\n";

// Test 4: Check detailed subscription data
echo "4. Detailed subscription breakdown:\n";
$stmt = $pdo->prepare("
    SELECT 
        cl.user_id,
        cl.created_at as call_time,
        p.id as payment_id,
        p.created_at as payment_time,
        p.payment_status,
        TIMESTAMPDIFF(MINUTE, cl.created_at, p.created_at) as minutes_after_call
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE cl.caller_id = ?
    AND p.payment_status = 'captured'
    AND p.created_at > cl.created_at
    LIMIT 10
");
$stmt->execute([$callerId]);
$subs = $stmt->fetchAll();

if (count($subs) > 0) {
    foreach ($subs as $sub) {
        echo "   User {$sub['user_id']}: Payment {$sub['payment_id']} ";
        echo "({$sub['minutes_after_call']} min after call)\n";
    }
} else {
    echo "   No subscriptions found for this telecaller\n";
}

// Test 5: Try without time constraint
echo "\n5. Subscriptions WITHOUT time constraint (payment before or after call):\n";
$stmt = $pdo->prepare("
    SELECT COUNT(DISTINCT p.id) as subscription_count
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE cl.caller_id = ?
    AND p.payment_status = 'captured'
");
$stmt->execute([$callerId]);
$subData2 = $stmt->fetch();
echo "   Subscription count (no time check): {$subData2['subscription_count']}\n\n";

// Test 6: Show top telecallers with subscriptions
echo "6. Top telecallers with subscriptions:\n";
$stmt = $pdo->query("
    SELECT 
        cl.caller_id,
        COUNT(DISTINCT p.id) as subscription_count
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.created_at
    GROUP BY cl.caller_id
    ORDER BY subscription_count DESC
    LIMIT 5
");
$topCallers = $stmt->fetchAll();

foreach ($topCallers as $caller) {
    echo "   Caller {$caller['caller_id']}: {$caller['subscription_count']} subscriptions\n";
}

// Test 7: Test the actual API
echo "\n7. Testing Analytics API:\n";
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . 
       "/telecaller_analytics_api.php?caller_id={$callerId}&period=all";

$context = stream_context_create(['http' => ['ignore_errors' => true]]);
$response = @file_get_contents($url, false, $context);

if ($response) {
    $data = json_decode($response, true);
    if ($data && $data['success']) {
        $overview = $data['data']['overview'] ?? [];
        echo "   ✅ API Success\n";
        echo "   Subscriptions in API: " . ($overview['subscription_count'] ?? 'NOT FOUND') . "\n";
    } else {
        echo "   ❌ API Error: " . ($data['error'] ?? 'Unknown') . "\n";
    }
} else {
    echo "   ❌ Could not reach API\n";
}

echo "\n=== Debug Complete ===\n";
echo "\nRecommendation: ";
if ($subData['subscription_count'] > 0) {
    echo "Caller $callerId has {$subData['subscription_count']} subscriptions. Check API response.\n";
} else {
    echo "Caller $callerId has no subscriptions. Try with caller_id from the top list above.\n";
}
?>
