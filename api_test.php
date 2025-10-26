<?php
// Simple API Test for TruckMitr Database
// Place this file in your XAMPP htdocs folder
// Access via: http://localhost/api_test.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration (same as your Flutter app)
$host = 'localhost';
$dbname = 'truckmitr';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

// Get the request method and path
$method = $_SERVER['REQUEST_METHOD'];
$path = $_GET['action'] ?? 'test';

// Handle different API endpoints
switch($path) {
    case 'test':
        handleTest($pdo);
        break;
    case 'login':
        handleLogin($pdo);
        break;
    case 'dashboard':
        handleDashboard($pdo);
        break;
    case 'callbacks':
        handleCallbacks($pdo);
        break;
    case 'users':
        handleUsers($pdo);
        break;
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
}

function handleTest($pdo) {
    try {
        // Test database connection
        $stmt = $pdo->query("SELECT 1 as test, NOW() as current_time");
        $result = $stmt->fetch();
        
        // Get table counts
        $tables = [];
        $tableNames = ['admins', 'users', 'callback_requests', 'call_logs'];
        
        foreach($tableNames as $table) {
            $stmt = $pdo->query("SELECT COUNT(*) as count FROM $table");
            $tables[$table] = $stmt->fetch()['count'];
        }
        
        echo json_encode([
            'status' => 'success',
            'message' => 'Database connection successful',
            'test_query' => $result,
            'table_counts' => $tables,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Test failed: ' . $e->getMessage()]);
    }
}

function handleLogin($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $email = $input['email'] ?? '';
    $password = $input['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        http_response_code(400);
        echo json_encode(['error' => 'Email and password required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("SELECT * FROM admins WHERE email = ? AND password = ?");
        $stmt->execute([$email, $password]);
        $admin = $stmt->fetch();
        
        if ($admin) {
            // Remove password from response
            unset($admin['password']);
            echo json_encode([
                'success' => true,
                'message' => 'Login successful',
                'user' => $admin
            ]);
        } else {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid credentials'
            ]);
        }
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Login failed: ' . $e->getMessage()]);
    }
}

function handleDashboard($pdo) {
    try {
        $stats = [];
        
        // Total drivers
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
        $stats['totalDrivers'] = (int)$stmt->fetch()['count'];
        
        // Total transporters
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'transporter'");
        $stats['totalTransporters'] = (int)$stmt->fetch()['count'];
        
        // Total admins
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM admins");
        $stats['totalAdmins'] = (int)$stmt->fetch()['count'];
        
        // Callback statistics
        $stmt = $pdo->query("SELECT status, COUNT(*) as count FROM callback_requests GROUP BY status");
        $callbackStats = [];
        while ($row = $stmt->fetch()) {
            $key = 'callbacks_' . strtolower(str_replace([' ', '/'], ['_', '_'], $row['status']));
            $callbackStats[$key] = (int)$row['count'];
        }
        
        // Total callbacks
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM callback_requests");
        $stats['totalCallbacks'] = (int)$stmt->fetch()['count'];
        
        // Total call logs
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM call_logs");
        $stats['totalCallLogs'] = (int)$stmt->fetch()['count'];
        
        // Merge callback stats
        $stats = array_merge($stats, $callbackStats);
        
        echo json_encode([
            'success' => true,
            'data' => $stats,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Dashboard data failed: ' . $e->getMessage()]);
    }
}

function handleCallbacks($pdo) {
    try {
        $limit = $_GET['limit'] ?? 20;
        $offset = $_GET['offset'] ?? 0;
        $status = $_GET['status'] ?? null;
        
        $sql = "SELECT * FROM callback_requests";
        $params = [];
        
        if ($status) {
            $sql .= " WHERE status = ?";
            $params[] = $status;
        }
        
        $sql .= " ORDER BY request_date_time DESC LIMIT ? OFFSET ?";
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $callbacks = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $callbacks,
            'count' => count($callbacks),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Callbacks data failed: ' . $e->getMessage()]);
    }
}

function handleUsers($pdo) {
    try {
        $role = $_GET['role'] ?? null;
        $limit = $_GET['limit'] ?? 20;
        $offset = $_GET['offset'] ?? 0;
        
        $sql = "SELECT * FROM users";
        $params = [];
        
        if ($role) {
            $sql .= " WHERE role = ?";
            $params[] = $role;
        }
        
        $sql .= " ORDER BY created_at DESC LIMIT ? OFFSET ?";
        $params[] = (int)$limit;
        $params[] = (int)$offset;
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $users = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $users,
            'count' => count($users),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Users data failed: ' . $e->getMessage()]);
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>TruckMitr API Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .endpoint { margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 5px; }
        .endpoint a { color: #007bff; text-decoration: none; }
        .endpoint a:hover { text-decoration: underline; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>TruckMitr API Test Endpoints</h1>
    <p>Test your database connection and API endpoints:</p>
    
    <div class="endpoint">
        <strong>Test Connection:</strong><br>
        <a href="?action=test" target="_blank">GET /api_test.php?action=test</a>
    </div>
    
    <div class="endpoint">
        <strong>Dashboard Stats:</strong><br>
        <a href="?action=dashboard" target="_blank">GET /api_test.php?action=dashboard</a>
    </div>
    
    <div class="endpoint">
        <strong>Callback Requests:</strong><br>
        <a href="?action=callbacks" target="_blank">GET /api_test.php?action=callbacks</a><br>
        <a href="?action=callbacks&status=Pending" target="_blank">GET /api_test.php?action=callbacks&status=Pending</a>
    </div>
    
    <div class="endpoint">
        <strong>Users:</strong><br>
        <a href="?action=users" target="_blank">GET /api_test.php?action=users</a><br>
        <a href="?action=users&role=driver" target="_blank">GET /api_test.php?action=users&role=driver</a><br>
        <a href="?action=users&role=transporter" target="_blank">GET /api_test.php?action=users&role=transporter</a>
    </div>
    
    <div class="endpoint">
        <strong>Login Test (POST):</strong><br>
        <form method="post" action="?action=login">
            <input type="email" name="email" placeholder="Email" value="admin@test.com" required><br><br>
            <input type="password" name="password" placeholder="Password" value="admin123" required><br><br>
            <button type="submit">Test Login</button>
        </form>
    </div>
    
    <h2>Setup Instructions:</h2>
    <ol>
        <li>Make sure XAMPP is running (Apache + MySQL)</li>
        <li>Import your database: <code>assets/database/truckmitr (1).sql</code></li>
        <li>Run test data: <code>database_test_data.sql</code></li>
        <li>Update Flutter app database config</li>
        <li>Test endpoints above</li>
    </ol>
</body>
</html>