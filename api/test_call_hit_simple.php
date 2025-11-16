<?php
/**
 * Simple Call Hit Test - Verify API is working
 */
header('Content-Type: text/html; charset=utf-8');
require_once 'config.php';

echo "<h2>Call Hit API - Simple Test</h2>";

// Test 1: Check if table exists and has data
echo "<h3>1. Recent Call Hits (Last 5)</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            ch.id,
            ch.user_id,
            ch.call_time,
            ch.assigned_to,
            ch.created_at,
            u.name as user_name,
            a.name as telecaller_name
        FROM call_hit ch
        LEFT JOIN users u ON ch.user_id = u.id
        LEFT JOIN admins a ON ch.assigned_to = a.id
        ORDER BY ch.created_at DESC 
        LIMIT 5
    ");
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($results)) {
        echo "<p style='color: orange;'>⚠️ No call hits found. Try making a call from the app.</p>";
    } else {
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse;'>";
        echo "<tr style='background: #f0f0f0;'>";
        echo "<th>ID</th><th>User (Driver)</th><th>Telecaller</th><th>Call Time</th><th>Created At</th>";
        echo "</tr>";
        foreach ($results as $row) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['user_name']} (ID: {$row['user_id']})</td>";
            echo "<td>{$row['telecaller_name']} (ID: {$row['assigned_to']})</td>";
            echo "<td>{$row['call_time']}</td>";
            echo "<td>{$row['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
        echo "<p style='color: green;'>✅ Call hits are being logged successfully!</p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Test 2: Test API endpoint directly
echo "<h3>2. Test API Endpoint</h3>";
echo "<p>Testing POST to call_hit_api.php...</p>";

$testData = [
    'user_id' => '1',
    'call_time' => date('Y-m-d H:i:s'),
    'assigned_to' => '1'
];

echo "<pre>Test Data:\n";
print_r($testData);
echo "</pre>";

try {
    $stmt = $pdo->prepare("
        INSERT INTO call_hit (user_id, call_time, assigned_to, created_at, updated_at)
        VALUES (:user_id, :call_time, :assigned_to, NOW(), NOW())
    ");
    
    $stmt->execute([
        ':user_id' => $testData['user_id'],
        ':call_time' => $testData['call_time'],
        ':assigned_to' => $testData['assigned_to']
    ]);
    
    $id = $pdo->lastInsertId();
    echo "<p style='color: green;'>✅ Successfully inserted test call hit with ID: $id</p>";
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<h3>Summary</h3>";
echo "<p><strong>Status:</strong> ";
if (!empty($results)) {
    echo "<span style='color: green; font-weight: bold;'>✅ WORKING</span>";
} else {
    echo "<span style='color: orange; font-weight: bold;'>⚠️ NO DATA YET</span>";
}
echo "</p>";
echo "<p>If you see call hits above, the functionality is working correctly.</p>";
echo "<p>If not, try pressing a call button in the Flutter app and refresh this page.</p>";
?>
