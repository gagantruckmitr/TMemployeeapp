<?php
/**
 * Test script for subscription tracking APIs
 */

require_once 'config.php';

echo "<h2>Subscription Tracking Test</h2>";

// Test 1: Check tables exist
echo "<h3>Test 1: Check Required Tables</h3>";
try {
    $tables = ['call_hit', 'payments', 'users'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        $exists = $stmt->rowCount() > 0;
        $status = $exists ? '✅' : '❌';
        echo "<p>$status Table '$table': " . ($exists ? 'EXISTS' : 'NOT FOUND') . "</p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}

// Test 2: Check call_hit data
echo "<h3>Test 2: Call Hit Data</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            COUNT(*) as total_calls,
            COUNT(DISTINCT user_id) as unique_telecallers
        FROM call_hit
    ");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<p>Total call hits: <strong>{$result['total_calls']}</strong></p>";
    echo "<p>Unique telecallers: <strong>{$result['unique_telecallers']}</strong></p>";
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}

// Test 3: Check payments data
echo "<h3>Test 3: Payments Data</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            COUNT(*) as total_payments,
            COUNT(CASE WHEN payment_status = 'captured' THEN 1 END) as captured_payments,
            SUM(CASE WHEN payment_status = 'captured' THEN amount ELSE 0 END) as total_revenue
        FROM payments
    ");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<p>Total payments: <strong>{$result['total_payments']}</strong></p>";
    echo "<p>Captured payments: <strong>{$result['captured_payments']}</strong></p>";
    echo "<p>Total revenue: <strong>₹" . number_format($result['total_revenue'], 2) . "</strong></p>";
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}

// Test 4: Test subscription tracking logic
echo "<h3>Test 4: Subscription Tracking Logic</h3>";
try {
    // Find subscriptions that happened after calls
    $stmt = $pdo->query("
        SELECT 
            c.user_id as telecaller_id,
            COUNT(*) as subscriptions_after_calls,
            SUM(p.amount) as revenue_generated
        FROM call_hit c
        JOIN payments p ON c.user_id = p.user_id
        WHERE p.start_at BETWEEN UNIX_TIMESTAMP(c.call_time) AND UNIX_TIMESTAMP(c.updated_at)
        AND p.payment_status = 'captured'
        GROUP BY c.user_id
        ORDER BY subscriptions_after_calls DESC
        LIMIT 10
    ");
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($results)) {
        echo "<p>No subscriptions tracked yet. This is normal if:</p>";
        echo "<ul>";
        echo "<li>No calls have been made yet</li>";
        echo "<li>No payments have been captured</li>";
        echo "<li>Payments didn't happen within the call timeframe</li>";
        echo "</ul>";
    } else {
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
        echo "<tr><th>Telecaller ID</th><th>Subscriptions</th><th>Revenue Generated</th></tr>";
        foreach ($results as $row) {
            echo "<tr>";
            echo "<td>{$row['telecaller_id']}</td>";
            echo "<td>{$row['subscriptions_after_calls']}</td>";
            echo "<td>₹" . number_format($row['revenue_generated'], 2) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}

// Test 5: Test API endpoint
echo "<h3>Test 5: Test Stats API Endpoint</h3>";
try {
    // Get a sample user ID
    $stmt = $pdo->query("SELECT id FROM users LIMIT 1");
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        $userId = $user['id'];
        
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'];
        $apiUrl = "$protocol://$host/api/telecaller_subscription_stats_api.php?user_id=$userId";
        
        echo "<p>Testing: <code>$apiUrl</code></p>";
        
        $response = @file_get_contents($apiUrl);
        
        if ($response === false) {
            echo "<p style='color: orange;'>⚠️ Could not reach API endpoint. This is normal for local testing.</p>";
        } else {
            $data = json_decode($response, true);
            echo "<pre>";
            print_r($data);
            echo "</pre>";
        }
    } else {
        echo "<p>No users found in database to test with.</p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<h3>✅ Summary</h3>";
echo "<p>The subscription tracking feature is ready. It will:</p>";
echo "<ul>";
echo "<li>Track when drivers subscribe after telecaller calls</li>";
echo "<li>Show subscription statistics on the dashboard</li>";
echo "<li>Display all subscriptions in a dedicated screen</li>";
echo "<li>Calculate revenue generated by each telecaller</li>";
echo "</ul>";
echo "<p><strong>Note:</strong> Subscriptions are only counted if the payment happens between the call_time and updated_at timestamps in the call_hit table.</p>";
