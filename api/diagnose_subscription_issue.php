<?php
/**
 * Comprehensive Subscription Issue Diagnosis
 * This script will identify exactly why subscriptions are showing as 0
 */

require_once 'config.php';

$issues = [];
$warnings = [];
$success = [];

echo "<!DOCTYPE html>";
echo "<html><head><title>Subscription Diagnosis</title>";
echo "<style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
    h2 { color: #555; margin-top: 30px; }
    .success { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 10px 0; }
    .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 10px 0; }
    .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 10px 0; }
    .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 10px 0; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
    th { background: #f8f9fa; font-weight: bold; }
    .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    .badge-success { background: #28a745; color: white; }
    .badge-danger { background: #dc3545; color: white; }
    .badge-warning { background: #ffc107; color: black; }
    .badge-info { background: #17a2b8; color: white; }
    pre { background: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
</style></head><body>";

echo "<div class='container'>";
echo "<h1>🔍 Subscription Issue Diagnosis</h1>";
echo "<p><em>Running comprehensive checks...</em></p>";

// Check 1: call_logs table exists and has data
echo "<h2>Check 1: call_logs Table</h2>";
$query = "SHOW TABLES LIKE 'call_logs'";
$result = $conn->query($query);

if ($result->num_rows > 0) {
    $success[] = "call_logs table exists";
    echo "<div class='success'>✅ call_logs table exists</div>";
    
    // Check record count
    $query = "SELECT COUNT(*) as count FROM call_logs";
    $result = $conn->query($query);
    $row = $result->fetch_assoc();
    $call_logs_count = $row['count'];
    
    if ($call_logs_count > 0) {
        $success[] = "call_logs has $call_logs_count records";
        echo "<div class='success'>✅ call_logs has <strong>$call_logs_count</strong> records</div>";
        
        // Check for NULL caller_id
        $query = "SELECT COUNT(*) as count FROM call_logs WHERE caller_id IS NULL";
        $result = $conn->query($query);
        $row = $result->fetch_assoc();
        $null_caller_count = $row['count'];
        
        if ($null_caller_count > 0) {
            $warnings[] = "$null_caller_count records have NULL caller_id";
            echo "<div class='warning'>⚠️ <strong>$null_caller_count</strong> records have NULL caller_id (these won't be attributed to any telecaller)</div>";
        }
        
        // Show sample records
        $query = "SELECT id, user_id, caller_id, call_time, call_status, call_duration FROM call_logs ORDER BY id DESC LIMIT 5";
        $result = $conn->query($query);
        echo "<p><strong>Sample records:</strong></p>";
        echo "<table><tr><th>ID</th><th>User ID</th><th>Caller ID</th><th>Call Time</th><th>Status</th><th>Duration</th></tr>";
        while ($row = $result->fetch_assoc()) {
            $caller_badge = $row['caller_id'] ? "<span class='badge badge-success'>{$row['caller_id']}</span>" : "<span class='badge badge-danger'>NULL</span>";
            echo "<tr><td>{$row['id']}</td><td>{$row['user_id']}</td><td>$caller_badge</td><td>{$row['call_time']}</td><td>{$row['call_status']}</td><td>{$row['call_duration']}s</td></tr>";
        }
        echo "</table>";
        
    } else {
        $issues[] = "call_logs table is empty";
        echo "<div class='error'>❌ call_logs table is <strong>EMPTY</strong> - No calls have been logged!</div>";
    }
} else {
    $issues[] = "call_logs table does not exist";
    echo "<div class='error'>❌ call_logs table does not exist!</div>";
}

// Check 2: payments table
echo "<h2>Check 2: payments Table</h2>";
$query = "SELECT COUNT(*) as count FROM payments";
$result = $conn->query($query);
$row = $result->fetch_assoc();
$payments_count = $row['count'];

if ($payments_count > 0) {
    $success[] = "payments has $payments_count records";
    echo "<div class='success'>✅ payments has <strong>$payments_count</strong> records</div>";
    
    // Check captured payments
    $query = "SELECT COUNT(*) as count FROM payments WHERE payment_status = 'captured'";
    $result = $conn->query($query);
    $row = $result->fetch_assoc();
    $captured_count = $row['count'];
    
    if ($captured_count > 0) {
        $success[] = "$captured_count captured payments";
        echo "<div class='success'>✅ <strong>$captured_count</strong> payments with status='captured'</div>";
        
        // Show sample
        $query = "SELECT id, user_id, amount, payment_status, created_at FROM payments WHERE payment_status = 'captured' ORDER BY id DESC LIMIT 5";
        $result = $conn->query($query);
        echo "<p><strong>Sample captured payments:</strong></p>";
        echo "<table><tr><th>ID</th><th>User ID</th><th>Amount</th><th>Status</th><th>Created At</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr><td>{$row['id']}</td><td>{$row['user_id']}</td><td>₹{$row['amount']}</td><td><span class='badge badge-success'>{$row['payment_status']}</span></td><td>{$row['created_at']}</td></tr>";
        }
        echo "</table>";
    } else {
        $issues[] = "No captured payments";
        echo "<div class='error'>❌ No payments with status='captured' - All payments must be captured to count as subscriptions!</div>";
    }
} else {
    $issues[] = "payments table is empty";
    echo "<div class='error'>❌ payments table is <strong>EMPTY</strong> - No payments have been recorded!</div>";
}

// Check 3: Matching records
echo "<h2>Check 3: Matching Records (call_logs + payments)</h2>";

if ($call_logs_count > 0 && $captured_count > 0) {
    $query = "
        SELECT 
            cl.id as call_log_id,
            cl.user_id as driver_id,
            cl.caller_id as telecaller_id,
            cl.call_time,
            p.id as payment_id,
            p.created_at as payment_created_at,
            p.amount,
            TIMESTAMPDIFF(MINUTE, cl.call_time, p.created_at) as minutes_after_call,
            CASE 
                WHEN p.created_at > cl.call_time THEN 'YES'
                ELSE 'NO'
            END as payment_after_call
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        WHERE p.payment_status = 'captured'
        ORDER BY cl.call_time DESC
        LIMIT 10
    ";
    
    $result = $conn->query($query);
    $matching_count = $result->num_rows;
    
    if ($matching_count > 0) {
        echo "<div class='info'>ℹ️ Found <strong>$matching_count</strong> records where call_logs.user_id matches payments.user_id</div>";
        
        // Check how many have payment after call
        $query = "
            SELECT COUNT(*) as count
            FROM call_logs cl
            JOIN payments p ON cl.user_id = p.user_id
            WHERE p.payment_status = 'captured'
            AND p.created_at > cl.call_time
        ";
        $result2 = $conn->query($query);
        $row = $result2->fetch_assoc();
        $valid_subscriptions = $row['count'];
        
        if ($valid_subscriptions > 0) {
            $success[] = "$valid_subscriptions valid subscriptions found";
            echo "<div class='success'>✅ <strong>$valid_subscriptions</strong> valid subscriptions (payment after call)</div>";
        } else {
            $issues[] = "All payments were made BEFORE calls";
            echo "<div class='error'>❌ All payments were made BEFORE the calls - Subscriptions only count if payment.created_at > call.call_time</div>";
        }
        
        // Show details
        echo "<p><strong>Matching records details:</strong></p>";
        echo "<table><tr><th>Call Log ID</th><th>Driver ID</th><th>Telecaller ID</th><th>Call Time</th><th>Payment Time</th><th>Minutes After</th><th>Valid?</th></tr>";
        $result->data_seek(0);
        while ($row = $result->fetch_assoc()) {
            $valid_badge = $row['payment_after_call'] == 'YES' ? 
                "<span class='badge badge-success'>YES</span>" : 
                "<span class='badge badge-danger'>NO</span>";
            $telecaller_badge = $row['telecaller_id'] ? 
                "<span class='badge badge-info'>{$row['telecaller_id']}</span>" : 
                "<span class='badge badge-danger'>NULL</span>";
            echo "<tr><td>{$row['call_log_id']}</td><td>{$row['driver_id']}</td><td>$telecaller_badge</td><td>{$row['call_time']}</td><td>{$row['payment_created_at']}</td><td>{$row['minutes_after_call']} min</td><td>$valid_badge</td></tr>";
        }
        echo "</table>";
        
    } else {
        $issues[] = "No matching user_id between call_logs and payments";
        echo "<div class='error'>❌ No matching records - call_logs.user_id doesn't match any payments.user_id</div>";
        echo "<div class='info'>This means drivers who were called haven't made any payments, or the user_id values don't match.</div>";
    }
} else {
    echo "<div class='warning'>⚠️ Skipping match check - need both call_logs and payments data</div>";
}

// Check 4: Telecaller IDs
echo "<h2>Check 4: Telecaller IDs</h2>";
$query = "SELECT DISTINCT caller_id FROM call_logs WHERE caller_id IS NOT NULL ORDER BY caller_id";
$result = $conn->query($query);

if ($result->num_rows > 0) {
    echo "<div class='success'>✅ Found telecaller IDs in call_logs</div>";
    echo "<p><strong>Available telecaller IDs:</strong></p>";
    echo "<ul>";
    while ($row = $result->fetch_assoc()) {
        $tc_id = $row['caller_id'];
        
        // Count subscriptions for this telecaller
        $query2 = "
            SELECT COUNT(*) as count
            FROM call_logs cl
            JOIN payments p ON cl.user_id = p.user_id
            WHERE p.payment_status = 'captured'
            AND p.created_at > cl.call_time
            AND cl.caller_id = $tc_id
        ";
        $result2 = $conn->query($query2);
        $row2 = $result2->fetch_assoc();
        $sub_count = $row2['count'];
        
        $badge = $sub_count > 0 ? 
            "<span class='badge badge-success'>$sub_count subscriptions</span>" : 
            "<span class='badge badge-warning'>0 subscriptions</span>";
        
        echo "<li>Telecaller ID: <strong>$tc_id</strong> $badge</li>";
    }
    echo "</ul>";
} else {
    $warnings[] = "No telecaller IDs found";
    echo "<div class='warning'>⚠️ No telecaller IDs found in call_logs (all caller_id are NULL)</div>";
}

// Check 5: admins table
echo "<h2>Check 5: admins Table</h2>";
$query = "SELECT COUNT(*) as count FROM admins";
$result = $conn->query($query);
$row = $result->fetch_assoc();
$admins_count = $row['count'];

if ($admins_count > 0) {
    echo "<div class='success'>✅ admins table has <strong>$admins_count</strong> records</div>";
    
    $query = "SELECT id, name, email FROM admins ORDER BY id LIMIT 5";
    $result = $conn->query($query);
    echo "<p><strong>Sample admins:</strong></p>";
    echo "<table><tr><th>ID</th><th>Name</th><th>Email</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['email']}</td></tr>";
    }
    echo "</table>";
} else {
    $warnings[] = "admins table is empty";
    echo "<div class='warning'>⚠️ admins table is empty</div>";
}

// Summary
echo "<h2>📋 Summary</h2>";

if (count($issues) == 0 && count($warnings) == 0) {
    echo "<div class='success'>";
    echo "<h3>✅ All Checks Passed!</h3>";
    echo "<p>The subscription system should be working. If you're still seeing 0 subscriptions:</p>";
    echo "<ol>";
    echo "<li>Make sure you're logged in with a telecaller ID that has subscriptions</li>";
    echo "<li>Check the API directly: <a href='telecaller_subscription_stats_api.php?user_id=TELECALLER_ID'>Test API</a></li>";
    echo "<li>Clear app cache and reload</li>";
    echo "</ol>";
    echo "</div>";
} else {
    if (count($issues) > 0) {
        echo "<div class='error'>";
        echo "<h3>❌ Critical Issues Found:</h3>";
        echo "<ul>";
        foreach ($issues as $issue) {
            echo "<li>$issue</li>";
        }
        echo "</ul>";
        echo "</div>";
    }
    
    if (count($warnings) > 0) {
        echo "<div class='warning'>";
        echo "<h3>⚠️ Warnings:</h3>";
        echo "<ul>";
        foreach ($warnings as $warning) {
            echo "<li>$warning</li>";
        }
        echo "</ul>";
        echo "</div>";
    }
    
    echo "<div class='info'>";
    echo "<h3>🔧 Recommended Actions:</h3>";
    echo "<ol>";
    
    if (in_array("call_logs table is empty", $issues)) {
        echo "<li><strong>Create test data:</strong> <a href='create_test_subscription_data_call_logs.php'>Run this script</a></li>";
    }
    
    if (in_array("No captured payments", $issues)) {
        echo "<li><strong>Create test payment:</strong> Add a payment record with status='captured'</li>";
    }
    
    if (in_array("No matching user_id between call_logs and payments", $issues)) {
        echo "<li><strong>Fix user_id mismatch:</strong> Ensure call_logs.user_id matches payments.user_id</li>";
    }
    
    if (in_array("All payments were made BEFORE calls", $issues)) {
        echo "<li><strong>Fix timestamps:</strong> Ensure payments.created_at > call_logs.call_time</li>";
    }
    
    echo "<li><strong>Create complete test data:</strong> <a href='create_test_subscription_data_call_logs.php'>Run this script</a></li>";
    echo "</ol>";
    echo "</div>";
}

if (count($success) > 0) {
    echo "<div class='success'>";
    echo "<h3>✅ Successful Checks:</h3>";
    echo "<ul>";
    foreach ($success as $item) {
        echo "<li>$item</li>";
    }
    echo "</ul>";
    echo "</div>";
}

echo "<hr>";
echo "<p><em>Diagnosis completed at " . date('Y-m-d H:i:s') . "</em></p>";
echo "</div></body></html>";
