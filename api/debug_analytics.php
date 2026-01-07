<?php
// Debug Analytics API
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');

echo "=== Debug Analytics API ===\n\n";

// Test 1: Check if config.php exists and loads
echo "1. Testing config.php...\n";
if (file_exists('config.php')) {
    echo "   ✅ config.php exists\n";
    try {
        require_once 'config.php';
        echo "   ✅ config.php loaded\n";
        echo "   ✅ PDO connection: " . (isset($pdo) ? "OK" : "MISSING") . "\n";
    } catch (Exception $e) {
        echo "   ❌ Error loading config.php: " . $e->getMessage() . "\n";
        exit;
    }
} else {
    echo "   ❌ config.php not found\n";
    exit;
}

// Test 2: Check if update_activity_middleware.php exists
echo "\n2. Testing update_activity_middleware.php...\n";
if (file_exists('update_activity_middleware.php')) {
    echo "   ✅ update_activity_middleware.php exists\n";
    try {
        require_once 'update_activity_middleware.php';
        echo "   ✅ update_activity_middleware.php loaded\n";
    } catch (Exception $e) {
        echo "   ❌ Error loading middleware: " . $e->getMessage() . "\n";
    }
} else {
    echo "   ⚠️  update_activity_middleware.php not found (optional)\n";
}

// Test 3: Test database connection
echo "\n3. Testing database connection...\n";
try {
    $stmt = $pdo->query("SELECT 1");
    echo "   ✅ Database connection OK\n";
} catch (Exception $e) {
    echo "   ❌ Database error: " . $e->getMessage() . "\n";
    exit;
}

// Test 4: Check if call_logs table exists
echo "\n4. Testing call_logs table...\n";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM call_logs LIMIT 1");
    $result = $stmt->fetch();
    echo "   ✅ call_logs table exists\n";
    echo "   ✅ Total records: " . $result['count'] . "\n";
} catch (Exception $e) {
    echo "   ❌ call_logs table error: " . $e->getMessage() . "\n";
    exit;
}

// Test 5: Test the analytics query
echo "\n5. Testing analytics query...\n";
$callerId = 1;
$dateCondition = "DATE(created_at) = CURDATE()";

try {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks_scheduled,
            SUM(CASE WHEN COALESCE(call_status, '') NOT IN ('connected', 'callback_later') THEN 1 ELSE 0 END) as not_connected_calls
        FROM call_logs 
        WHERE caller_id = ? AND $dateCondition
    ");
    $stmt->execute([$callerId]);
    $stats = $stmt->fetch();
    
    echo "   ✅ Query executed successfully\n";
    echo "   Total Calls: " . ($stats['total_calls'] ?? 0) . "\n";
    echo "   Connected: " . ($stats['connected_calls'] ?? 0) . "\n";
    echo "   Not Connected: " . ($stats['not_connected_calls'] ?? 0) . "\n";
    echo "   Callbacks: " . ($stats['callbacks_scheduled'] ?? 0) . "\n";
} catch (Exception $e) {
    echo "   ❌ Query error: " . $e->getMessage() . "\n";
    exit;
}

// Test 6: Try loading the actual API
echo "\n6. Testing telecaller_analytics_api.php...\n";
try {
    $url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . "/telecaller_analytics_api.php?caller_id=1&period=today";
    echo "   URL: $url\n";
    
    $context = stream_context_create([
        'http' => [
            'ignore_errors' => true
        ]
    ]);
    
    $response = file_get_contents($url, false, $context);
    $httpCode = 200;
    
    if (isset($http_response_header)) {
        foreach ($http_response_header as $header) {
            if (preg_match('/HTTP\/\d\.\d\s+(\d+)/', $header, $matches)) {
                $httpCode = (int)$matches[1];
            }
        }
    }
    
    echo "   HTTP Code: $httpCode\n";
    
    if ($httpCode == 200) {
        echo "   ✅ API returned 200 OK\n";
        $data = json_decode($response, true);
        if ($data && isset($data['success'])) {
            echo "   ✅ Valid JSON response\n";
            echo "   Success: " . ($data['success'] ? 'true' : 'false') . "\n";
        } else {
            echo "   ⚠️  Response: " . substr($response, 0, 200) . "\n";
        }
    } else {
        echo "   ❌ API returned error $httpCode\n";
        echo "   Response: " . substr($response, 0, 500) . "\n";
    }
} catch (Exception $e) {
    echo "   ❌ Error calling API: " . $e->getMessage() . "\n";
}

echo "\n=== Debug Complete ===\n";
?>
