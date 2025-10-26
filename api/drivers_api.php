<?php
// Driver Data API for TruckMitr Smart Calling
// Place this file in your XAMPP htdocs folder
// Access via: http://localhost/api/drivers_api.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

// Get the request method and action
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? 'drivers';

// Handle different API endpoints
switch($action) {
    case 'drivers':
        handleDrivers($pdo);
        break;
    case 'driver':
        handleSingleDriver($pdo);
        break;
    case 'update_call_status':
        handleUpdateCallStatus($pdo);
        break;
    case 'log_call':
        handleLogCall($pdo);
        break;
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
}

function handleDrivers($pdo) {
    try {
        $limit = (int)($_GET['limit'] ?? 50);
        $offset = (int)($_GET['offset'] ?? 0);
        $search = $_GET['search'] ?? '';
        $status = $_GET['status'] ?? '';
        
        // First, check if users table exists and has data
        $checkSql = "SHOW TABLES LIKE 'users'";
        $stmt = $pdo->query($checkSql);
        $usersTableExists = $stmt->rowCount() > 0;
        
        if (!$usersTableExists) {
            // If users table doesn't exist, return sample data
            $sampleDrivers = [
                [
                    'id' => '1',
                    'name' => 'Rajesh Kumar',
                    'company' => 'Delhi Transport',
                    'phoneNumber' => '+91 98765 43210',
                    'email' => 'rajesh@example.com',
                    'city' => 'Delhi',
                    'state' => 'Delhi',
                    'status' => 'pending',
                    'lastFeedback' => null,
                    'lastCallTime' => null,
                    'remarks' => null,
                    'createdAt' => date('Y-m-d H:i:s'),
                    'updatedAt' => date('Y-m-d H:i:s')
                ],
                [
                    'id' => '2',
                    'name' => 'Amit Singh',
                    'company' => 'Mumbai Transport',
                    'phoneNumber' => '+91 87654 32109',
                    'email' => 'amit@example.com',
                    'city' => 'Mumbai',
                    'state' => 'Maharashtra',
                    'status' => 'connected',
                    'lastFeedback' => 'Interested in subscription',
                    'lastCallTime' => date('Y-m-d H:i:s', strtotime('-2 hours')),
                    'remarks' => null,
                    'createdAt' => date('Y-m-d H:i:s'),
                    'updatedAt' => date('Y-m-d H:i:s')
                ]
            ];
            
            echo json_encode([
                'success' => true,
                'data' => $sampleDrivers,
                'count' => count($sampleDrivers),
                'message' => 'Using sample data - users table not found',
                'timestamp' => date('Y-m-d H:i:s')
            ]);
            return;
        }
        
        // Check if call_logs table exists
        $checkCallLogsSql = "SHOW TABLES LIKE 'call_logs'";
        $stmt = $pdo->query($checkCallLogsSql);
        $callLogsExists = $stmt->rowCount() > 0;
        
        // Build query based on available tables
        if ($callLogsExists) {
            $sql = "SELECT 
                        u.id,
                        u.name,
                        u.mobile,
                        u.email,
                        u.city,
                        u.state,
                        u.created_at,
                        u.updated_at,
                        cl.call_time as last_call_time,
                        COALESCE(cl.call_status, 'pending') as call_status,
                        cl.feedback as last_feedback,
                        cl.remarks
                    FROM users u
                    LEFT JOIN call_logs cl ON u.id = cl.user_id 
                        AND cl.call_time = (
                            SELECT MAX(call_time) 
                            FROM call_logs cl2 
                            WHERE cl2.user_id = u.id
                        )
                    WHERE 1=1";
        } else {
            $sql = "SELECT 
                        u.id,
                        u.name,
                        u.mobile,
                        u.email,
                        u.city,
                        u.state,
                        u.created_at,
                        u.updated_at,
                        NULL as last_call_time,
                        'pending' as call_status,
                        NULL as last_feedback,
                        NULL as remarks
                    FROM users u
                    WHERE 1=1";
        }
        
        $params = [];
        
        // Add role filter if column exists
        try {
            $roleCheckSql = "SHOW COLUMNS FROM users LIKE 'role'";
            $stmt = $pdo->query($roleCheckSql);
            if ($stmt->rowCount() > 0) {
                $sql .= " AND u.role = ?";
                $params[] = 'driver';
            }
        } catch (Exception $e) {
            // Role column doesn't exist, continue without it
        }
        
        // Add search filter
        if (!empty($search)) {
            $sql .= " AND (u.name LIKE ? OR u.mobile LIKE ? OR COALESCE(u.email, '') LIKE ?)";
            $searchTerm = "%$search%";
            $params[] = $searchTerm;
            $params[] = $searchTerm;
            $params[] = $searchTerm;
        }
        
        // Add status filter
        if (!empty($status) && $callLogsExists) {
            $sql .= " AND COALESCE(cl.call_status, 'pending') = ?";
            $params[] = $status;
        }
        
        $sql .= " ORDER BY u.id DESC LIMIT $limit OFFSET $offset";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $drivers = $stmt->fetchAll();
        
        // Transform data for Flutter app
        $transformedDrivers = array_map(function($driver) {
            return [
                'id' => (string)$driver['id'],
                'name' => $driver['name'] ?? 'Unknown Driver',
                'company' => ($driver['city'] ?? 'Unknown') . ' Transport',
                'phoneNumber' => $driver['mobile'] ?? '',
                'email' => $driver['email'] ?? '',
                'city' => $driver['city'] ?? '',
                'state' => $driver['state'] ?? '',
                'status' => mapCallStatus($driver['call_status']),
                'lastFeedback' => $driver['last_feedback'],
                'lastCallTime' => $driver['last_call_time'],
                'remarks' => $driver['remarks'],
                'createdAt' => $driver['created_at'],
                'updatedAt' => $driver['updated_at']
            ];
        }, $drivers);
        
        echo json_encode([
            'success' => true,
            'data' => $transformedDrivers,
            'count' => count($transformedDrivers),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch drivers: ' . $e->getMessage()]);
    }
}

function handleSingleDriver($pdo) {
    $driverId = $_GET['id'] ?? '';
    
    if (empty($driverId)) {
        http_response_code(400);
        echo json_encode(['error' => 'Driver ID required']);
        return;
    }
    
    try {
        $sql = "SELECT 
                    u.*,
                    cl.call_time as last_call_time,
                    cl.call_status,
                    cl.feedback as last_feedback,
                    cl.remarks
                FROM users u
                LEFT JOIN call_logs cl ON u.id = cl.user_id 
                    AND cl.call_time = (SELECT MAX(call_time) FROM call_logs WHERE user_id = u.id)
                WHERE u.id = ? AND u.role = 'driver'";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$driverId]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
            http_response_code(404);
            echo json_encode(['error' => 'Driver not found']);
            return;
        }
        
        // Transform data
        $transformedDriver = [
            'id' => (string)$driver['id'],
            'name' => $driver['name'] ?? 'Unknown Driver',
            'company' => ($driver['city'] ?? 'Unknown') . ' Transport',
            'phoneNumber' => $driver['mobile'] ?? '',
            'email' => $driver['email'] ?? '',
            'city' => $driver['city'] ?? '',
            'state' => $driver['state'] ?? '',
            'status' => mapCallStatus($driver['call_status']),
            'lastFeedback' => $driver['last_feedback'],
            'lastCallTime' => $driver['last_call_time'],
            'remarks' => $driver['remarks'],
            'createdAt' => $driver['created_at'],
            'updatedAt' => $driver['updated_at']
        ];
        
        echo json_encode([
            'success' => true,
            'data' => $transformedDriver,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch driver: ' . $e->getMessage()]);
    }
}

function handleUpdateCallStatus($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $driverId = $input['driver_id'] ?? '';
    $status = $input['status'] ?? '';
    $feedback = $input['feedback'] ?? '';
    $remarks = $input['remarks'] ?? '';
    $callerId = $input['caller_id'] ?? 1; // Default to admin
    
    if (empty($driverId) || empty($status)) {
        http_response_code(400);
        echo json_encode(['error' => 'Driver ID and status required']);
        return;
    }
    
    try {
        // Get driver info
        $stmt = $pdo->prepare("SELECT mobile FROM users WHERE id = ?");
        $stmt->execute([$driverId]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
            http_response_code(404);
            echo json_encode(['error' => 'Driver not found']);
            return;
        }
        
        // Insert call log
        $sql = "INSERT INTO call_logs (caller_id, user_id, caller_number, user_number, call_status, feedback, remarks, call_time) 
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $driverId,
            '', // caller_number - can be fetched from caller_id if needed
            $driver['mobile'],
            $status,
            $feedback,
            $remarks
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Call status updated successfully',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update call status: ' . $e->getMessage()]);
    }
}

function handleLogCall($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $driverId = $input['driver_id'] ?? '';
    $callerId = $input['caller_id'] ?? 1;
    $referenceId = $input['reference_id'] ?? '';
    $apiResponse = $input['api_response'] ?? '';
    
    if (empty($driverId)) {
        http_response_code(400);
        echo json_encode(['error' => 'Driver ID required']);
        return;
    }
    
    try {
        // Get driver and caller info
        $stmt = $pdo->prepare("SELECT mobile FROM users WHERE id = ?");
        $stmt->execute([$driverId]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
            http_response_code(404);
            echo json_encode(['error' => 'Driver not found']);
            return;
        }
        
        // Insert call log
        $sql = "INSERT INTO call_logs (caller_id, user_id, caller_number, user_number, reference_id, api_response, call_time) 
                VALUES (?, ?, ?, ?, ?, ?, NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $driverId,
            '', // caller_number
            $driver['mobile'],
            $referenceId,
            $apiResponse
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Call logged successfully',
            'call_id' => $pdo->lastInsertId(),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to log call: ' . $e->getMessage()]);
    }
}

function mapCallStatus($dbStatus) {
    switch(strtolower($dbStatus ?? 'pending')) {
        case 'connected':
            return 'connected';
        case 'callback':
        case 'call_back':
            return 'callBack';
        case 'callback_later':
        case 'call_back_later':
            return 'callBackLater';
        case 'not_reachable':
        case 'notreachable':
            return 'notReachable';
        case 'not_interested':
        case 'notinterested':
            return 'notInterested';
        case 'invalid':
            return 'invalid';
        case 'pending':
        default:
            return 'pending';
    }
}

// If accessed directly, show API documentation
if (empty($_GET['action'])) {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>TruckMitr Drivers API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .endpoint { margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 5px; }
            .endpoint a { color: #007bff; text-decoration: none; }
            .endpoint a:hover { text-decoration: underline; }
            pre { background: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto; }
        </style>
    </head>
    <body>
        <h1>TruckMitr Drivers API</h1>
        <p>API endpoints for driver data management:</p>
        
        <div class="endpoint">
            <strong>Get All Drivers:</strong><br>
            <a href="?action=drivers" target="_blank">GET /drivers_api.php?action=drivers</a><br>
            <small>Parameters: limit, offset, search, status</small>
        </div>
        
        <div class="endpoint">
            <strong>Get Single Driver:</strong><br>
            <a href="?action=driver&id=1" target="_blank">GET /drivers_api.php?action=driver&id=1</a>
        </div>
        
        <div class="endpoint">
            <strong>Update Call Status:</strong><br>
            POST /drivers_api.php?action=update_call_status<br>
            <pre>
{
    "driver_id": "1",
    "status": "connected",
    "feedback": "Interested in subscription",
    "remarks": "Will call back tomorrow",
    "caller_id": "1"
}
            </pre>
        </div>
        
        <div class="endpoint">
            <strong>Log Call:</strong><br>
            POST /drivers_api.php?action=log_call<br>
            <pre>
{
    "driver_id": "1",
    "caller_id": "1",
    "reference_id": "CALL_123",
    "api_response": "Call completed successfully"
}
            </pre>
        </div>
        
        <h2>Status Values:</h2>
        <ul>
            <li>pending</li>
            <li>connected</li>
            <li>callBack</li>
            <li>callBackLater</li>
            <li>notReachable</li>
            <li>notInterested</li>
            <li>invalid</li>
        </ul>
    </body>
    </html>
    <?php
}
?>