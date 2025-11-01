<?php
// Test Manager Dashboard API - Quick verification script
header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<h2 style='color: green;'>✅ Database Connected</h2>";
} catch(PDOException $e) {
    die("<h2 style='color: red;'>❌ Connection Failed: " . $e->getMessage() . "</h2>");
}

echo "<h1>Manager Dashboard API Test</h1><hr>";

// Test Overview
echo "<h3>Test 1: Overview Data</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            COUNT(DISTINCT CASE WHEN a.role = 'telecaller' THEN a.id END) as total_telecallers,
            COUNT(DISTINCT cl.id) as total_calls_today,
            SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as interested_calls_today
        FROM admins a
        LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
        WHERE a.role = 'telecaller'
    ");
    $result = $stmt->fetch();
    echo "<p>✅ Success: " . json_encode($result) . "</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

echo "<hr><p><a href='manager_dashboard_api.php?action=overview'>Test Full API</a></p>";
?>
