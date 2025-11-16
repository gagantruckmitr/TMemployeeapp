<?php
/**
 * Create Test Subscription Data using call_logs table
 * This matches the new subscription logic from subscription.php
 */

require_once 'config.php';

echo "<h2>Creating Test Subscription Data (call_logs based)</h2>";
echo "<hr>";

try {
    // Step 1: Find or create a test telecaller from admins table
    echo "<h3>Step 1: Finding Test Telecaller</h3>";
    $query = "SELECT id, name FROM admins ORDER BY id LIMIT 1";
    $result = $conn->query($query);
    $telecaller = $result->fetch_assoc();
    
    if (!$telecaller) {
        echo "<p style='color: red;'>No telecaller found in admins table. Creating one...</p>";
        $conn->query("INSERT INTO admins (name, email, password) VALUES ('Test Telecaller', 'test@example.com', 'test123')");
        $telecaller = ['id' => $conn->insert_id, 'name' => 'Test Telecaller'];
    }
    
    echo "<p style='color: green;'>✅ Using telecaller: {$telecaller['name']} (ID: {$telecaller['id']})</p>";
    
    // Step 2: Find or create a test driver from users table
    echo "<h3>Step 2: Finding Test Driver</h3>";
    $query = "SELECT id, name, mobile, unique_id FROM users ORDER BY id LIMIT 1";
    $result = $conn->query($query);
    $driver = $result->fetch_assoc();
    
    if (!$driver) {
        echo "<p style='color: red;'>No driver found in users table. Creating one...</p>";
        $conn->query("INSERT INTO users (name, mobile, unique_id) VALUES ('Test Driver', '9876543210', 'TM" . rand(10000, 99999) . "')");
        $driver_id = $conn->insert_id;
        $result = $conn->query("SELECT id, name, mobile, unique_id FROM users WHERE id = $driver_id");
        $driver = $result->fetch_assoc();
    }
    
    echo "<p style='color: green;'>✅ Using driver: {$driver['name']} (ID: {$driver['id']}, TMID: {$driver['unique_id']})</p>";
    
    // Step 3: Create a call_logs record
    echo "<h3>Step 3: Creating Call Log Record</h3>";
    
    $callTime = date('Y-m-d H:i:s', strtotime('-2 hours'));
    
    $query = "
        INSERT INTO call_logs (
            user_id, 
            caller_id, 
            call_time, 
            call_status, 
            call_duration,
            driver_name,
            user_number,
            created_at
        )
        VALUES (
            {$driver['id']},
            {$telecaller['id']},
            '$callTime',
            'completed',
            180,
            '{$driver['name']}',
            '{$driver['mobile']}',
            NOW()
        )
    ";
    
    if ($conn->query($query)) {
        $callLogId = $conn->insert_id;
        echo "<p style='color: green;'>✅ Created call_logs record (ID: {$callLogId})</p>";
        echo "<p>Call Time: {$callTime}</p>";
        echo "<p>Call Duration: 180 seconds (3 minutes)</p>";
    } else {
        throw new Exception("Failed to create call_logs record: " . $conn->error);
    }
    
    // Step 4: Create a payment record (subscription)
    echo "<h3>Step 4: Creating Payment Record</h3>";
    
    // Payment time should be AFTER call_time (e.g., 30 minutes after the call)
    $paymentCreatedAt = date('Y-m-d H:i:s', strtotime('-90 minutes'));
    $paymentStartAt = strtotime('-90 minutes');
    $paymentEndAt = $paymentStartAt + (30 * 24 * 60 * 60); // 30 days later
    $paymentId = 'pay_TEST_' . time() . '_' . rand(1000, 9999);
    
    $query = "
        INSERT INTO payments (
            user_id, 
            amount, 
            payment_status, 
            start_at, 
            end_at, 
            plan_id,
            payment_id,
            payment_type,
            created_at
        )
        VALUES (
            {$driver['id']},
            999.00,
            'captured',
            $paymentStartAt,
            $paymentEndAt,
            'plan_monthly',
            '$paymentId',
            'subscription',
            '$paymentCreatedAt'
        )
    ";
    
    if ($conn->query($query)) {
        $dbPaymentId = $conn->insert_id;
        echo "<p style='color: green;'>✅ Created payment record (ID: {$dbPaymentId})</p>";
        echo "<p>Payment ID: {$paymentId}</p>";
        echo "<p>Amount: ₹999.00</p>";
        echo "<p>Payment Created At: {$paymentCreatedAt}</p>";
        echo "<p>Subscription Start: " . date('Y-m-d H:i:s', $paymentStartAt) . "</p>";
        echo "<p>Subscription End: " . date('Y-m-d H:i:s', $paymentEndAt) . "</p>";
    } else {
        throw new Exception("Failed to create payment record: " . $conn->error);
    }
    
    // Step 5: Verify the subscription is tracked
    echo "<h3>Step 5: Verifying Subscription Tracking</h3>";
    
    $query = "
        SELECT 
            cl.id as call_log_id,
            cl.user_id as driver_id,
            COALESCE(cl.driver_name, u.name) as driver_name,
            COALESCE(cl.user_number, u.mobile) as driver_mobile,
            u.unique_id as driver_tmid,
            cl.caller_id as telecaller_id,
            a.name as telecaller_name,
            cl.call_time,
            cl.call_status,
            cl.call_duration,
            p.id as payment_id,
            p.created_at as payment_created_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            TIMESTAMPDIFF(MINUTE, cl.call_time, p.created_at) as minutes_after_call,
            p.amount,
            p.payment_id as razorpay_payment_id,
            p.payment_status
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        LEFT JOIN users u ON cl.user_id = u.id
        LEFT JOIN admins a ON cl.caller_id = a.id
        WHERE p.payment_status = 'captured'
        AND p.created_at > cl.call_time
        AND cl.caller_id = {$telecaller['id']}
        ORDER BY cl.call_time DESC
        LIMIT 1
    ";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Verification query failed: " . $conn->error);
    }
    
    $subscription = $result->fetch_assoc();
    
    if ($subscription) {
        echo "<p style='color: green; font-size: 18px;'><strong>✅ SUCCESS! Subscription is now tracked for telecaller!</strong></p>";
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
        echo "<tr><th>Field</th><th>Value</th></tr>";
        echo "<tr><td>Call Log ID</td><td>{$subscription['call_log_id']}</td></tr>";
        echo "<tr><td>Telecaller ID</td><td>{$subscription['telecaller_id']}</td></tr>";
        echo "<tr><td>Telecaller Name</td><td>{$subscription['telecaller_name']}</td></tr>";
        echo "<tr><td>Driver ID</td><td>{$subscription['driver_id']}</td></tr>";
        echo "<tr><td>Driver Name</td><td>{$subscription['driver_name']}</td></tr>";
        echo "<tr><td>Driver TMID</td><td>{$subscription['driver_tmid']}</td></tr>";
        echo "<tr><td>Driver Mobile</td><td>{$subscription['driver_mobile']}</td></tr>";
        echo "<tr><td>Call Time</td><td>{$subscription['call_time']}</td></tr>";
        echo "<tr><td>Call Status</td><td>{$subscription['call_status']}</td></tr>";
        echo "<tr><td>Call Duration</td><td>{$subscription['call_duration']} seconds</td></tr>";
        echo "<tr><td>Payment Created At</td><td>{$subscription['payment_created_at']}</td></tr>";
        echo "<tr><td>Payment Start Time</td><td>{$subscription['payment_start_time']}</td></tr>";
        echo "<tr><td>Minutes After Call</td><td>{$subscription['minutes_after_call']} minutes</td></tr>";
        echo "<tr><td>Amount</td><td>₹{$subscription['amount']}</td></tr>";
        echo "<tr><td>Payment ID</td><td>{$subscription['razorpay_payment_id']}</td></tr>";
        echo "<tr><td>Payment Status</td><td>{$subscription['payment_status']}</td></tr>";
        echo "</table>";
        
        echo "<hr>";
        echo "<h3>🎉 Test Data Created Successfully!</h3>";
        echo "<div style='background: #e8f5e9; padding: 15px; border-radius: 8px; margin: 20px 0;'>";
        echo "<p><strong>Next Steps:</strong></p>";
        echo "<ol>";
        echo "<li>Login to the app as telecaller with ID: <strong>{$telecaller['id']}</strong></li>";
        echo "<li>View the dashboard to see the subscription count</li>";
        echo "<li>Tap on 'My Subscriptions' to see the detailed list</li>";
        echo "</ol>";
        echo "</div>";
        
        echo "<div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;'>";
        echo "<p><strong>Test API Endpoints:</strong></p>";
        echo "<ul>";
        echo "<li><a href='telecaller_subscription_stats_api.php?user_id={$telecaller['id']}' target='_blank'>Stats API</a></li>";
        echo "<li><a href='telecaller_subscriptions_api.php?user_id={$telecaller['id']}&period=all' target='_blank'>Subscriptions API</a></li>";
        echo "<li><a href='test_subscription_direct.php' target='_blank'>Direct Test</a></li>";
        echo "</ul>";
        echo "</div>";
        
    } else {
        echo "<p style='color: red; font-size: 18px;'><strong>❌ ERROR: Subscription not tracked!</strong></p>";
        echo "<p>The query didn't return any results. This could mean:</p>";
        echo "<ul>";
        echo "<li>Payment created_at is not after call_time</li>";
        echo "<li>Payment status is not 'captured'</li>";
        echo "<li>user_id doesn't match between call_logs and payments</li>";
        echo "</ul>";
        
        echo "<p><strong>Debug Info:</strong></p>";
        echo "<p>Call Time: $callTime</p>";
        echo "<p>Payment Created At: $paymentCreatedAt</p>";
        echo "<p>Payment is after call: " . ($paymentCreatedAt > $callTime ? 'YES' : 'NO') . "</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>Error:</strong> " . $e->getMessage() . "</p>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}

echo "<hr>";
echo "<p><em>Script completed at " . date('Y-m-d H:i:s') . "</em></p>";
