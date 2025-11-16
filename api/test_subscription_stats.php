<?php
/**
 * Test script for subscription stats API
 * Tests the query that matches subscriptions to telecaller calls
 */

require_once 'config.php';

// Test user ID (replace with actual telecaller ID)
$test_user_id = 1;

echo "<h2>Testing Subscription Stats API</h2>";
echo "<p>Testing for user_id: $test_user_id</p>";

try {
    // Test the main query
    echo "<h3>1. Testing Main Subscription Stats Query</h3>";
    $stmt = $pdo->prepare("
        SELECT 
            c.assigned_to,
            c.call_time,
            c.updated_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            p.amount,
            p.id as payment_id,
            p.payment_status,
            u.name as driver_name,
            u.unique_id as driver_tmid
        FROM call_hit c
        JOIN payments p ON c.user_id = p.user_id
        LEFT JOIN users u ON p.user_id = u.id
        WHERE c.assigned_to = :user_id
        AND p.start_at BETWEEN UNIX_TIMESTAMP(c.call_time) AND UNIX_TIMESTAMP(c.updated_at)
        AND p.payment_status = 'captured'
        ORDER BY c.assigned_to, c.call_time
        LIMIT 10
    ");
    
    $stmt->execute([':user_id' => $test_user_id]);
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<p>Found " . count($results) . " subscriptions</p>";
    
    if (count($results) > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Assigned To</th><th>Call Time</th><th>Updated At</th><th>Payment Time</th><th>Amount</th><th>Payment ID</th><th>Driver</th><th>TMID</th></tr>";
        foreach ($results as $row) {
            echo "<tr>";
            echo "<td>{$row['assigned_to']}</td>";
            echo "<td>{$row['call_time']}</td>";
            echo "<td>{$row['updated_at']}</td>";
            echo "<td>{$row['payment_start_time']}</td>";
            echo "<td>₹{$row['amount']}</td>";
            echo "<td>{$row['payment_id']}</td>";
            echo "<td>{$row['driver_name']}</td>";
            echo "<td>{$row['driver_tmid']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color: orange;'>No subscriptions found for this telecaller.</p>";
        echo "<p>This could mean:</p>";
        echo "<ul>";
        echo "<li>No calls have been made by this telecaller</li>";
        echo "<li>No drivers have subscribed after being called</li>";
        echo "<li>The assigned_to field is not set correctly in call_hit table</li>";
        echo "</ul>";
    }
    
    // Test aggregated stats
    echo "<h3>2. Testing Aggregated Stats</h3>";
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_subscriptions,
            SUM(p.amount) as total_revenue,
            COUNT(CASE WHEN DATE(FROM_UNIXTIME(p.start_at)) = CURDATE() THEN 1 END) as today_subscriptions,
            SUM(CASE WHEN DATE(FROM_UNIXTIME(p.start_at)) = CURDATE() THEN p.amount ELSE 0 END) as today_revenue,
            COUNT(CASE WHEN FROM_UNIXTIME(p.start_at) >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as month_subscriptions,
            SUM(CASE WHEN FROM_UNIXTIME(p.start_at) >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN p.amount ELSE 0 END) as month_revenue
        FROM call_hit c
        JOIN payments p ON c.user_id = p.user_id
        WHERE c.assigned_to = :user_id
        AND p.start_at BETWEEN UNIX_TIMESTAMP(c.call_time) AND UNIX_TIMESTAMP(c.updated_at)
        AND p.payment_status = 'captured'
    ");
    
    $stmt->execute([':user_id' => $test_user_id]);
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Metric</th><th>Value</th></tr>";
    echo "<tr><td>Total Subscriptions</td><td>{$stats['total_subscriptions']}</td></tr>";
    echo "<tr><td>Total Revenue</td><td>₹" . number_format($stats['total_revenue'], 2) . "</td></tr>";
    echo "<tr><td>Today's Subscriptions</td><td>{$stats['today_subscriptions']}</td></tr>";
    echo "<tr><td>Today's Revenue</td><td>₹" . number_format($stats['today_revenue'], 2) . "</td></tr>";
    echo "<tr><td>This Month's Subscriptions</td><td>{$stats['month_subscriptions']}</td></tr>";
    echo "<tr><td>This Month's Revenue</td><td>₹" . number_format($stats['month_revenue'], 2) . "</td></tr>";
    echo "</table>";
    
    // Check call_hit table structure
    echo "<h3>3. Checking call_hit Table Structure</h3>";
    $stmt = $pdo->query("DESCRIBE call_hit");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
    foreach ($columns as $col) {
        echo "<tr>";
        echo "<td>{$col['Field']}</td>";
        echo "<td>{$col['Type']}</td>";
        echo "<td>{$col['Null']}</td>";
        echo "<td>{$col['Key']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Check if assigned_to field exists and has data
    echo "<h3>4. Checking assigned_to Field Data</h3>";
    $stmt = $pdo->query("SELECT COUNT(*) as total, COUNT(assigned_to) as with_assigned_to FROM call_hit");
    $counts = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<p>Total call_hit records: {$counts['total']}</p>";
    echo "<p>Records with assigned_to: {$counts['with_assigned_to']}</p>";
    
    if ($counts['with_assigned_to'] == 0) {
        echo "<p style='color: red;'><strong>WARNING:</strong> No records have assigned_to field set!</p>";
    }
    
    echo "<h3>✅ Test Complete</h3>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>Error:</strong> " . $e->getMessage() . "</p>";
}
?>
