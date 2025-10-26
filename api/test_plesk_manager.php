<?php
// Test script for Plesk server - Manager Dashboard API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo json_encode([
    'test' => 'Plesk Manager API Test',
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => phpversion(),
    'server' => $_SERVER['SERVER_NAME'] ?? 'unknown',
    'request_uri' => $_SERVER['REQUEST_URI'] ?? 'unknown',
    'steps' => []
], JSON_PRETTY_PRINT);

$steps = [];

// Step 1: Check if config file exists
$steps[] = ['step' => 1, 'action' => 'Checking config.php'];
if (file_exists(__DIR__ . '/config.php')) {
    $steps[] = ['step' => 1, 'status' => 'success', 'message' => 'config.php found'];
    require_once __DIR__ . '/config.php';
} else {
    $steps[] = ['step' => 1, 'status' => 'error', 'message' => 'config.php not found'];
    echo json_encode(['error' => 'config.php not found', 'steps' => $steps], JSON_PRETTY_PRINT);
    exit;
}

// Step 2: Check database connection
$steps[] = ['step' => 2, 'action' => 'Testing database connection'];
try {
    // Use the database config from config.php
    $host = defined('DB_HOST') ? DB_HOST : 'localhost';
    $dbname = defined('DB_NAME') ? DB_NAME : 'truckmitr';
    $username = defined('DB_USER') ? DB_USER : 'root';
    $password = defined('DB_PASS') ? DB_PASS : '';
    
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $steps[] = ['step' => 2, 'status' => 'success', 'message' => 'Database connected'];
} catch(PDOException $e) {
    $steps[] = ['step' => 2, 'status' => 'error', 'message' => $e->getMessage()];
    echo json_encode(['error' => 'Database connection failed', 'steps' => $steps], JSON_PRETTY_PRINT);
    exit;
}

// Step 3: Check if admins table exists
$steps[] = ['step' => 3, 'action' => 'Checking admins table'];
try {
    $stmt = $pdo->query("SHOW TABLES LIKE 'admins'");
    if ($stmt->rowCount() > 0) {
        $steps[] = ['step' => 3, 'status' => 'success', 'message' => 'admins table exists'];
    } else {
        $steps[] = ['step' => 3, 'status' => 'error', 'message' => 'admins table not found'];
    }
} catch(PDOException $e) {
    $steps[] = ['step' => 3, 'status' => 'error', 'message' => $e->getMessage()];
}

// Step 4: Check if telecaller_status table exists
$steps[] = ['step' => 4, 'action' => 'Checking telecaller_status table'];
try {
    $stmt = $pdo->query("SHOW TABLES LIKE 'telecaller_status'");
    if ($stmt->rowCount() > 0) {
        $steps[] = ['step' => 4, 'status' => 'success', 'message' => 'telecaller_status table exists'];
    } else {
        $steps[] = ['step' => 4, 'status' => 'warning', 'message' => 'telecaller_status table not found'];
    }
} catch(PDOException $e) {
    $steps[] = ['step' => 4, 'status' => 'error', 'message' => $e->getMessage()];
}

// Step 5: Count managers
$steps[] = ['step' => 5, 'action' => 'Counting managers'];
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'manager'");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    $steps[] = ['step' => 5, 'status' => 'success', 'message' => "Found $count managers"];
} catch(PDOException $e) {
    $steps[] = ['step' => 5, 'status' => 'error', 'message' => $e->getMessage()];
}

// Step 6: Count telecallers
$steps[] = ['step' => 6, 'action' => 'Counting telecallers'];
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    $steps[] = ['step' => 6, 'status' => 'success', 'message' => "Found $count telecallers"];
} catch(PDOException $e) {
    $steps[] = ['step' => 6, 'status' => 'error', 'message' => $e->getMessage()];
}

// Step 7: Test manager overview query
$steps[] = ['step' => 7, 'action' => 'Testing manager overview query'];
try {
    $stmt = $pdo->query("
        SELECT 
            COUNT(DISTINCT a.id) as total_telecallers,
            COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN a.id END) as online_telecallers
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        WHERE a.role = 'telecaller'
    ");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $steps[] = ['step' => 7, 'status' => 'success', 'data' => $result];
} catch(PDOException $e) {
    $steps[] = ['step' => 7, 'status' => 'error', 'message' => $e->getMessage()];
}

echo json_encode([
    'success' => true,
    'message' => 'All tests completed',
    'steps' => $steps,
    'database' => [
        'host' => $host,
        'database' => $dbname,
        'user' => $username
    ]
], JSON_PRETTY_PRINT);
