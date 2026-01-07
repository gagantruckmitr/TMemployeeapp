<?php
/**
 * Test Toll-Free Feedback API
 */

echo "<h1>Testing Toll-Free Feedback API</h1>";

// Test 1: Submit Feedback
echo "<h2>Test 1: Submit Feedback</h2>";

$feedbackData = [
    'caller_id' => 1,
    'lead_id' => 1,
    'name' => 'Test Driver',
    'mobile' => '9876543210',
    'feedback' => 'Connected - Interested',
    'remarks' => 'Test feedback from API test'
];

// Determine the correct base URL
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$baseUrl = $protocol . '://' . $host;
$apiUrl = $baseUrl . '/api/toll_free_feedback_api.php';

echo "<p><strong>API URL:</strong> $apiUrl</p>";

$ch = curl_init($apiUrl . '?action=submit_feedback');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($feedbackData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
if ($curlError) {
    echo "<p><strong>cURL Error:</strong> $curlError</p>";
}
echo "<p><strong>Response:</strong></p>";
echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";

// Test 2: Get History
echo "<h2>Test 2: Get Call History</h2>";

$ch = curl_init($apiUrl . '?action=get_history&caller_id=1&limit=10');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
if ($curlError) {
    echo "<p><strong>cURL Error:</strong> $curlError</p>";
}
echo "<p><strong>Response:</strong></p>";
echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";

// Test 3: Check Database Connection
echo "<h2>Test 3: Database Connection</h2>";

require_once 'config.php';

try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM call_logs WHERE tc_for = 'toll-free'");
    $result = $stmt->fetch();
    echo "<p><strong>✅ Database Connected</strong></p>";
    echo "<p>Total toll-free calls in database: " . $result['count'] . "</p>";
} catch (Exception $e) {
    echo "<p><strong>❌ Database Error:</strong> " . $e->getMessage() . "</p>";
}

// Test 4: Check if users table exists
echo "<h2>Test 4: Check Users Table</h2>";

try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users LIMIT 1");
    $result = $stmt->fetch();
    echo "<p><strong>✅ Users table exists</strong></p>";
    echo "<p>Total users: " . $result['count'] . "</p>";
} catch (Exception $e) {
    echo "<p><strong>❌ Users table error:</strong> " . $e->getMessage() . "</p>";
}

// Test 5: Direct API Test (without cURL)
echo "<h2>Test 5: Direct API Test</h2>";

try {
    // Simulate POST data
    $_GET['action'] = 'submit_feedback';
    $_SERVER['REQUEST_METHOD'] = 'POST';
    
    $testData = [
        'caller_id' => 1,
        'lead_id' => 1,
        'name' => 'Direct Test Driver',
        'mobile' => '9876543210',
        'feedback' => 'Connected - Test',
        'remarks' => 'Direct API test'
    ];
    
    // Get user's TMID and role
    $userSql = "SELECT unique_id, role FROM users WHERE id = :lead_id LIMIT 1";
    $userStmt = $pdo->prepare($userSql);
    $userStmt->execute(['lead_id' => 1]);
    $user = $userStmt->fetch();
    
    if ($user) {
        echo "<p><strong>✅ User found:</strong></p>";
        echo "<pre>" . json_encode($user, JSON_PRETTY_PRINT) . "</pre>";
        
        // Try to insert
        $sql = "INSERT INTO call_logs (
                    caller_id,
                    user_id,
                    user_number,
                    driver_name,
                    feedback,
                    remarks,
                    call_status,
                    call_time,
                    tc_for,
                    unique_id_driver,
                    call_source
                ) VALUES (
                    :caller_id,
                    :user_id,
                    :user_number,
                    :driver_name,
                    :feedback,
                    :remarks,
                    'connected',
                    NOW(),
                    'toll-free',
                    :tmid,
                    'toll-free'
                )";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            'caller_id' => $testData['caller_id'],
            'user_id' => $testData['lead_id'],
            'user_number' => $testData['mobile'],
            'driver_name' => $testData['name'],
            'feedback' => $testData['feedback'],
            'remarks' => $testData['remarks'],
            'tmid' => $user['unique_id']
        ]);
        
        $callLogId = $pdo->lastInsertId();
        echo "<p><strong>✅ Direct insert successful!</strong></p>";
        echo "<p>Call Log ID: $callLogId</p>";
    } else {
        echo "<p><strong>❌ User not found with ID: 1</strong></p>";
    }
} catch (Exception $e) {
    echo "<p><strong>❌ Direct test error:</strong> " . $e->getMessage() . "</p>";
}

// Test 6: Check recent toll-free calls
echo "<h2>Test 6: Recent Toll-Free Calls</h2>";

try {
    $stmt = $pdo->query("
        SELECT 
            cl.id,
            cl.caller_id,
            cl.driver_name,
            cl.feedback,
            cl.call_status,
            cl.tc_for,
            cl.call_time
        FROM call_logs cl
        WHERE cl.tc_for = 'toll-free'
        ORDER BY cl.call_time DESC
        LIMIT 5
    ");
    $recentCalls = $stmt->fetchAll();
    
    echo "<p><strong>✅ Recent toll-free calls:</strong></p>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Caller ID</th><th>Driver Name</th><th>Feedback</th><th>Status</th><th>Time</th></tr>";
    foreach ($recentCalls as $call) {
        echo "<tr>";
        echo "<td>" . $call['id'] . "</td>";
        echo "<td>" . $call['caller_id'] . "</td>";
        echo "<td>" . $call['driver_name'] . "</td>";
        echo "<td>" . $call['feedback'] . "</td>";
        echo "<td>" . $call['call_status'] . "</td>";
        echo "<td>" . $call['call_time'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} catch (Exception $e) {
    echo "<p><strong>❌ Error:</strong> " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<p><strong>Test completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
