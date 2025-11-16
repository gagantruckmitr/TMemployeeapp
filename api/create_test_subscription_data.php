<?php
/**
 * Helper script to create test subscription data
 * This simulates a scenario where a telecaller made a call and the driver subscribed
 */

require_once 'config.php';

echo "<h2>Creating Test Subscription Data</h2>";

try {
    // Step 1: Find or create a test telecaller
    echo "<h3>Step 1: Finding Test Telecaller</h3>";
    $stmt = $pdo->query("SELECT id, name FROM users WHERE role = 'telecaller' LIMIT 1");
    $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$telecaller) {
        echo "<p style='color: red;'>No telecaller found. Please create a telecaller user first.</p>";
        exit;
    }
    
    echo "<p>✅ Using telecaller: {$telecaller['name']} (ID: {$telecaller['id']})</p>";
    
    // Step 2: Find or create a test driver
    echo "<h3>Step 2: Finding Test Driver</h3>";
    $stmt = $pdo->query("SELECT id, name, mobile FROM users WHERE role = 'driver' OR role IS NULL LIMIT 1");
    $driver = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$driver) {
        echo "<p style='color: red;'>No driver found. Please create a driver user first.</p>";
        exit;
    }
    
    echo "<p>✅ Using driver: {$driver['name']} (ID: {$driver['id']})</p>";
    
    // Step 3: Create a call_hit record
    echo "<h3>Step 3: Creating Call Hit Record</h3>";
    
    $callTime = date('Y-m-d H:i:s', strtotime('-2 hours'));
    $updatedAt = date('Y-m-d H:i:s', strtotime('-1 hour'));
    
    $stmt = $pdo->prepare("
        INSERT INTO call_hit (user_id, assigned_to, call_time, updated_at, created_at)
        VALUES (:user_id, :assigned_to, :call_time, :updated_at, NOW())
    ");
    
    $stmt->execute([
        ':user_id' => $driver['id'],
        ':assigned_to' => $telecaller['id'],
        ':call_time' => $callTime,
        ':updated_at' => $updatedAt
    ]);
    
    $callHitId = $pdo->lastInsertId();
    echo "<p>✅ Created call_hit record (ID: {$callHitId})</p>";
    echo "<p>Call Time: {$callTime}</p>";
    echo "<p>Updated At: {$updatedAt}</p>";
    
    // Step 4: Create a payment record (subscription)
    echo "<h3>Step 4: Creating Payment Record</h3>";
    
    // Payment time should be between call_time and updated_at
    $paymentTime = strtotime('-90 minutes');
    
    $stmt = $pdo->prepare("
        INSERT INTO payments (
            user_id, 
            amount, 
            payment_status, 
            start_at, 
            end_at, 
            plan_id,
            payment_id,
            created_at
        )
        VALUES (
            :user_id,
            :amount,
            'captured',
            :start_at,
            :end_at,
            'test_plan_monthly',
            :payment_id,
            NOW()
        )
    ");
    
    $endAt = $paymentTime + (30 * 24 * 60 * 60); // 30 days later
    $paymentId = 'TEST_PAY_' . time() . '_' . rand(1000, 9999);
    
    $stmt->execute([
        ':user_id' => $driver['id'],
        ':amount' => 999.00,
        ':start_at' => $paymentTime,
        ':end_at' => $endAt,
        ':payment_id' => $paymentId
    ]);
    
    $dbPaymentId = $pdo->lastInsertId();
    echo "<p>✅ Created payment record (ID: {$dbPaymentId})</p>";
    echo "<p>Payment ID: {$paymentId}</p>";
    echo "<p>Amount: ₹999.00</p>";
    echo "<p>Payment Time: " . date('Y-m-d H:i:s', $paymentTime) . "</p>";
    
    // Step 5: Verify the subscription is tracked
    echo "<h3>Step 5: Verifying Subscription Tracking</h3>";
    
    $stmt = $pdo->prepare("
        SELECT 
            c.assigned_to,
            c.call_time,
            c.updated_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            p.amount,
            p.payment_id,
            p.payment_status,
            u.name as driver_name
        FROM call_hit c
        JOIN payments p ON c.user_id = p.user_id
        LEFT JOIN users u ON p.user_id = u.id
        WHERE c.assigned_to = :telecaller_id
        AND p.start_at BETWEEN UNIX_TIMESTAMP(c.call_time) AND UNIX_TIMESTAMP(c.updated_at)
        AND p.payment_status = 'captured'
        ORDER BY c.call_time DESC
        LIMIT 1
    ");
    
    $stmt->execute([':telecaller_id' => $telecaller['id']]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result) {
        echo "<p style='color: green;'>✅ SUCCESS! Subscription is now tracked for telecaller!</p>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Field</th><th>Value</th></tr>";
        echo "<tr><td>Telecaller ID</td><td>{$result['assigned_to']}</td></tr>";
        echo "<tr><td>Driver Name</td><td>{$result['driver_name']}</td></tr>";
        echo "<tr><td>Call Time</td><td>{$result['call_time']}</td></tr>";
        echo "<tr><td>Payment Time</td><td>{$result['payment_start_time']}</td></tr>";
        echo "<tr><td>Amount</td><td>₹{$result['amount']}</td></tr>";
        echo "<tr><td>Payment ID</td><td>{$result['payment_id']}</td></tr>";
        echo "</table>";
        
        echo "<h3>🎉 Test Data Created Successfully!</h3>";
        echo "<p>You can now:</p>";
        echo "<ul>";
        echo "<li>Login as telecaller: {$telecaller['name']} (ID: {$telecaller['id']})</li>";
        echo "<li>View the dashboard to see the subscription KPI</li>";
        echo "<li>Tap on the subscription KPI to see the detailed list</li>";
        echo "</ul>";
        
    } else {
        echo "<p style='color: red;'>❌ ERROR: Subscription not tracked. Check the query logic.</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>Error:</strong> " . $e->getMessage() . "</p>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}
?>
