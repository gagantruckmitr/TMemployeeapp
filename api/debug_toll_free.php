<?php
/**
 * Debug Toll-Free Feedback API
 * Shows detailed information about what's happening
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Toll-Free Feedback API Debug</h1>";

// Step 1: Check config.php
echo "<h2>Step 1: Check config.php</h2>";
try {
    require_once 'config.php';
    echo "<p>✅ config.php loaded successfully</p>";
    echo "<p>Database: " . DB_NAME . "</p>";
    echo "<p>Host: " . DB_HOST . "</p>";
} catch (Exception $e) {
    echo "<p>❌ Error loading config.php: " . $e->getMessage() . "</p>";
    die();
}

// Step 2: Check PDO connection
echo "<h2>Step 2: Check PDO Connection</h2>";
try {
    if (isset($pdo)) {
        echo "<p>✅ PDO connection exists</p>";
        $stmt = $pdo->query("SELECT 1");
        echo "<p>✅ PDO query works</p>";
    } else {
        echo "<p>❌ PDO connection not found</p>";
        die();
    }
} catch (Exception $e) {
    echo "<p>❌ PDO error: " . $e->getMessage() . "</p>";
    die();
}

// Step 3: Check users table
echo "<h2>Step 3: Check Users Table</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $result = $stmt->fetch();
    echo "<p>✅ Users table exists with " . $result['count'] . " records</p>";
    
    // Get a sample user
    $stmt = $pdo->query("SELECT id, unique_id, name, mobile FROM users ORDER BY id DESC LIMIT 1");
    $sampleUser = $stmt->fetch();
    if ($sampleUser) {
        echo "<p>Sample user ID: " . $sampleUser['id'] . " (" . $sampleUser['name'] . ")</p>";
    }
} catch (Exception $e) {
    echo "<p>❌ Users table error: " . $e->getMessage() . "</p>";
}

// Step 4: Check call_logs table
echo "<h2>Step 4: Check call_logs Table</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM call_logs WHERE tc_for = 'toll-free'");
    $result = $stmt->fetch();
    echo "<p>✅ call_logs table exists with " . $result['count'] . " toll-free records</p>";
} catch (Exception $e) {
    echo "<p>❌ call_logs table error: " . $e->getMessage() . "</p>";
}

// Step 5: Test INSERT
echo "<h2>Step 5: Test INSERT</h2>";
try {
    // Get a valid user
    $stmt = $pdo->query("SELECT id, unique_id, name, mobile FROM users ORDER BY id DESC LIMIT 1");
    $testUser = $stmt->fetch();
    
    if ($testUser) {
        echo "<p>Using test user: " . $testUser['name'] . " (ID: " . $testUser['id'] . ")</p>";
        
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
                    :call_status,
                    NOW(),
                    'toll-free',
                    :tmid,
                    'toll-free'
                )";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            'caller_id' => 3,
            'user_id' => $testUser['id'],
            'user_number' => $testUser['mobile'],
            'driver_name' => $testUser['name'],
            'feedback' => 'Debug Test - Connected',
            'remarks' => 'Automated debug test at ' . date('Y-m-d H:i:s'),
            'call_status' => 'connected',
            'tmid' => $testUser['unique_id']
        ]);
        
        $callLogId = $pdo->lastInsertId();
        echo "<p>✅ INSERT successful! Call log ID: $callLogId</p>";
        
        // Verify the insert
        $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
        $stmt->execute([$callLogId]);
        $inserted = $stmt->fetch();
        
        echo "<p>Inserted record:</p>";
        echo "<pre>" . json_encode($inserted, JSON_PRETTY_PRINT) . "</pre>";
        
    } else {
        echo "<p>❌ No users found in database</p>";
    }
} catch (Exception $e) {
    echo "<p>❌ INSERT error: " . $e->getMessage() . "</p>";
    echo "<p>SQL State: " . $e->getCode() . "</p>";
    echo "<p>Stack trace:</p>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}

// Step 6: Test the actual API endpoint
echo "<h2>Step 6: Test API Endpoint</h2>";
if ($testUser) {
    $testData = [
        'caller_id' => 3,
        'lead_id' => $testUser['id'],
        'name' => $testUser['name'],
        'mobile' => $testUser['mobile'],
        'feedback' => 'API Test - Connected',
        'remarks' => 'Testing via debug script'
    ];
    
    echo "<p>Sending request to API...</p>";
    echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";
    
    $ch = curl_init('http://localhost/api/toll_free_feedback_api.php?action=submit_feedback');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
    
    if ($curlError) {
        echo "<p><strong>❌ cURL Error:</strong> $curlError</p>";
    }
    
    if ($httpCode == 200) {
        echo "<p>✅ API returned 200 OK</p>";
    } else {
        echo "<p>❌ API returned error code: $httpCode</p>";
    }
    
    echo "<p><strong>Response:</strong></p>";
    if ($response) {
        $decoded = json_decode($response);
        if ($decoded) {
            echo "<pre>" . json_encode($decoded, JSON_PRETTY_PRINT) . "</pre>";
        } else {
            echo "<p>Raw response (not JSON):</p>";
            echo "<pre>" . htmlspecialchars($response) . "</pre>";
        }
    } else {
        echo "<p>No response received</p>";
    }
}

echo "<hr>";
echo "<p><strong>Debug completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
