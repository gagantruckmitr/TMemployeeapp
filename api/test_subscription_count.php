<?php
/**
 * Test Subscription Count Logic
 * Compare subscription counts across all three APIs
 */

require_once 'config.php';

$callerId = 8; // Sonam

echo "=== SUBSCRIPTION COUNT TEST FOR TELECALLER ID: $callerId ===\n\n";

// Test 1: Subscription API Logic (assigned_to based)
echo "1. SUBSCRIPTION API LOGIC (assigned_to based):\n";
echo "   Logic: Users assigned to telecaller with captured payments\n\n";

$periods = ['today', 'week', 'month', 'all'];

foreach ($periods as $period) {
    $dateFilter = '';
    switch ($period) {
        case 'today':
            $dateFilter = 'AND DATE(p.created_at) = CURDATE()';
            break;
        case 'week':
            $dateFilter = 'AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)';
            break;
        case 'month':
            $dateFilter = 'AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)';
            break;
        case 'all':
            $dateFilter = '';
            break;
    }
    
    $query = "
        SELECT COUNT(DISTINCT p.id) as subscription_count
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_to = ?
        AND p.payment_status = 'captured'
        $dateFilter
    ";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute([$callerId]);
    $result = $stmt->fetch();
    
    echo "   Period: " . strtoupper($period) . " => " . $result['subscription_count'] . " subscriptions\n";
}

echo "\n";

// Test 2: Get sample subscription data
echo "2. SAMPLE SUBSCRIPTION DATA (Today):\n";
$query = "
    SELECT 
        p.id as payment_id,
        u.id as user_id,
        u.name as user_name,
        u.mobile as user_mobile,
        u.assigned_to,
        p.amount,
        p.payment_status,
        p.created_at as payment_date
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = ?
    AND p.payment_status = 'captured'
    AND DATE(p.created_at) = CURDATE()
    ORDER BY p.created_at DESC
    LIMIT 5
";

$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$subscriptions = $stmt->fetchAll();

if (count($subscriptions) > 0) {
    foreach ($subscriptions as $sub) {
        echo "   - Payment ID: {$sub['payment_id']}, User: {$sub['user_name']} ({$sub['user_mobile']}), Amount: ₹{$sub['amount']}, Date: {$sub['payment_date']}\n";
    }
} else {
    echo "   No subscriptions found for today\n";
}

echo "\n";

// Test 3: Check users assigned to this telecaller
echo "3. USERS ASSIGNED TO TELECALLER:\n";
$query = "SELECT COUNT(*) as count FROM users WHERE assigned_to = ?";
$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$result = $stmt->fetch();
echo "   Total users assigned: " . $result['count'] . "\n";

$query = "
    SELECT COUNT(DISTINCT u.id) as count 
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = ?
    AND p.payment_status = 'captured'
";
$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$result = $stmt->fetch();
echo "   Users with captured payments: " . $result['count'] . "\n";

echo "\n";

// Test 4: Check call history for today
echo "4. CALL HISTORY FOR TODAY:\n";
$query = "
    SELECT 
        COUNT(*) as total_calls,
        SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
        SUM(CASE WHEN call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected,
        SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callback_later
    FROM call_history
    WHERE assigned_to = ?
    AND DATE(created_at) = CURDATE()
";
$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$result = $stmt->fetch();

echo "   Total calls: {$result['total_calls']}\n";
echo "   Connected: {$result['connected']}\n";
echo "   Not Connected: {$result['not_connected']}\n";
echo "   Callback Later: {$result['callback_later']}\n";

echo "\n=== TEST COMPLETE ===\n";
?>
