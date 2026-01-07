<?php
/**
 * Debug Subscription Mismatch
 * Find out why subscription screen shows 5 but dashboard shows 1
 */

require_once 'config.php';

$callerId = 8; // Sonam

echo "=== DEBUGGING SUBSCRIPTION MISMATCH ===\n\n";

// Check actual payments for today
echo "1. ACTUAL PAYMENTS FOR TODAY:\n";
$query = "
    SELECT 
        p.id as payment_id,
        p.user_id,
        u.name as user_name,
        u.mobile,
        u.assigned_to,
        p.amount,
        p.payment_status,
        p.created_at as payment_date,
        DATE(p.created_at) as payment_date_only,
        CURDATE() as today
    FROM payments p
    JOIN users u ON p.user_id = u.id
    WHERE u.assigned_to = ?
    AND p.payment_status = 'captured'
    AND DATE(p.created_at) = CURDATE()
    ORDER BY p.created_at DESC
";

$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$payments = $stmt->fetchAll();

echo "   Found " . count($payments) . " payments\n\n";

if (count($payments) > 0) {
    foreach ($payments as $payment) {
        echo "   Payment ID: {$payment['payment_id']}\n";
        echo "   User: {$payment['user_name']} (ID: {$payment['user_id']})\n";
        echo "   Mobile: {$payment['mobile']}\n";
        echo "   Amount: ₹{$payment['amount']}\n";
        echo "   Status: {$payment['payment_status']}\n";
        echo "   Date: {$payment['payment_date']}\n";
        echo "   Date Only: {$payment['payment_date_only']}\n";
        echo "   Today: {$payment['today']}\n";
        echo "   ---\n";
    }
}

echo "\n";

// Check what the subscription API returns
echo "2. SUBSCRIPTION API QUERY:\n";
$dateFilter = 'AND DATE(p.created_at) = CURDATE()';
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
echo "   Subscription API Count: " . $result['subscription_count'] . "\n\n";

// Check what the dashboard API returns
echo "3. DASHBOARD API QUERY:\n";
$paymentDateFilter = "AND DATE(p.created_at) = CURDATE()";
$query = "
    SELECT COUNT(DISTINCT p.id) as subscription_count
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = ?
    AND p.payment_status = 'captured'
    $paymentDateFilter
";
$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$result = $stmt->fetch();
echo "   Dashboard API Count: " . $result['subscription_count'] . "\n\n";

// Check timezone
echo "4. TIMEZONE CHECK:\n";
echo "   PHP Timezone: " . date_default_timezone_get() . "\n";
echo "   Current PHP Time: " . date('Y-m-d H:i:s') . "\n";
echo "   CURDATE(): ";
$stmt = $pdo->query("SELECT CURDATE() as today, NOW() as now");
$result = $stmt->fetch();
echo $result['today'] . "\n";
echo "   NOW(): " . $result['now'] . "\n\n";

// Check if there are payments with different dates
echo "5. RECENT PAYMENTS (Last 24 hours):\n";
$query = "
    SELECT 
        p.id,
        p.user_id,
        u.name,
        p.amount,
        p.created_at,
        DATE(p.created_at) as date_only,
        TIMESTAMPDIFF(HOUR, p.created_at, NOW()) as hours_ago
    FROM payments p
    JOIN users u ON p.user_id = u.id
    WHERE u.assigned_to = ?
    AND p.payment_status = 'captured'
    AND p.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ORDER BY p.created_at DESC
";
$stmt = $pdo->prepare($query);
$stmt->execute([$callerId]);
$recentPayments = $stmt->fetchAll();

echo "   Found " . count($recentPayments) . " payments in last 24 hours\n\n";
foreach ($recentPayments as $payment) {
    echo "   ID: {$payment['id']}, User: {$payment['name']}, Amount: ₹{$payment['amount']}\n";
    echo "   Created: {$payment['created_at']}, Date: {$payment['date_only']}, Hours ago: {$payment['hours_ago']}\n";
    echo "   ---\n";
}

echo "\n=== DEBUG COMPLETE ===\n";
?>
