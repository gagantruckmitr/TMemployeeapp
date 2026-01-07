<?php
/**
 * Test script to debug callback requests API refresh issue
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

require_once 'config.php';

echo json_encode([
    'test' => 'Starting callback requests API test',
    'timestamp' => date('Y-m-d H:i:s')
]) . "\n\n";

// Test database connection
try {
    $testConn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    if ($testConn->connect_error) {
        die(json_encode(['error' => 'Connection failed: ' . $testConn->connect_error]));
    }
    echo json_encode(['success' => 'Database connected']) . "\n\n";
} catch (Exception $e) {
    die(json_encode(['error' => 'Exception: ' . $e->getMessage()]));
}

// Test fetching callback requests
try {
    $sql = "SELECT * FROM callback_requests LIMIT 1";
    $result = $testConn->query($sql);
    
    if ($result) {
        $row = $result->fetch_assoc();
        echo json_encode([
            'success' => 'Callback requests table accessible',
            'sample_row' => $row
        ], JSON_PRETTY_PRINT) . "\n\n";
    } else {
        echo json_encode(['error' => 'Query failed: ' . $testConn->error]) . "\n\n";
    }
} catch (Exception $e) {
    echo json_encode(['error' => 'Exception: ' . $e->getMessage()]) . "\n\n";
}

// Test fetching users table
try {
    $sql = "SELECT * FROM users LIMIT 1";
    $result = $testConn->query($sql);
    
    if ($result) {
        echo json_encode(['success' => 'Users table accessible']) . "\n\n";
    } else {
        echo json_encode(['error' => 'Users query failed: ' . $testConn->error]) . "\n\n";
    }
} catch (Exception $e) {
    echo json_encode(['error' => 'Exception: ' . $e->getMessage()]) . "\n\n";
}

// Test training table existence
try {
    $sql = "SHOW TABLES LIKE 'training'";
    $result = $testConn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        echo json_encode(['success' => 'Training table exists']) . "\n\n";
    } else {
        echo json_encode(['warning' => 'Training table does not exist']) . "\n\n";
    }
} catch (Exception $e) {
    echo json_encode(['error' => 'Exception: ' . $e->getMessage()]) . "\n\n";
}

// Test the actual API endpoint
echo json_encode(['test' => 'Testing actual API endpoint...']) . "\n\n";

// Simulate API call
$_GET['action'] = 'index';
$_REQUEST['auth_admin_id'] = 1; // Use a valid admin ID

try {
    ob_start();
    include 'callback_requests_api.php';
    $output = ob_get_clean();
    
    echo json_encode(['api_response' => $output], JSON_PRETTY_PRINT) . "\n\n";
} catch (Exception $e) {
    echo json_encode(['error' => 'API call failed: ' . $e->getMessage()]) . "\n\n";
}

$testConn->close();
?>
