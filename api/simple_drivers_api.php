<?php
// Simple Drivers API for TruckMitr - Works with existing database structure
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
    
    // Include activity middleware
    require_once 'update_activity_middleware_pdo.php';
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'drivers';

switch($action) {
    case 'drivers':
        getDrivers($pdo);
        break;
    case 'driver':
        getSingleDriver($pdo);
        break;
    case 'update_call_status':
        updateCallStatus($pdo);
        break;
    case 'log_call':
        logCall($pdo);
        break;
    case 'test':
        testDatabase($pdo);
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function testDatabase($pdo) {
    try {
        // Check what tables exist
        $stmt = $pdo->query("SHOW TABLES");
        $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        $result = [
            'success' => true,
            'tables' => $tables,
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        // Check users table structure if it exists
        if (in_array('users', $tables)) {
            $stmt = $pdo->query("DESCRIBE users");
            $userColumns = $stmt->fetchAll();
            $result['users_structure'] = $userColumns;
            
            // Count users
            $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
            $result['users_count'] = $stmt->fetch()['count'];
            
            // Count drivers
            $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
            $result['drivers_count'] = $stmt->fetch()['count'];
            
            // Sample users
            $stmt = $pdo->query("SELECT * FROM users WHERE role = 'driver' LIMIT 3");
            $result['sample_drivers'] = $stmt->fetchAll();
        }
        
        echo json_encode($result);
        
    } catch(Exception $e) {
        echo json_encode(['error' => $e->getMessage()]);
    }
}

function getDrivers($pdo) {
    try {
        $limit = (int)($_GET['limit'] ?? 20);
        $offset = (int)($_GET['offset'] ?? 0);
        
        // Check if users table exists
        $stmt = $pdo->query("SHOW TABLES LIKE 'users'");
        if ($stmt->rowCount() == 0) {
            // Return error if no users table
            echo json_encode([
                'success' => false,
                'error' => 'Users table not found in database',
                'message' => 'Please ensure the database is properly set up with users table'
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
                        u.unique_id,
                        u.name,
                        u.mobile,
                        u.email,
                        u.city,
                        u.states,
                        u.status,
                        u.Created_at,
                        u.Updated_at,
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
                    WHERE u.role IN ('driver', 'transporter')";
        } else {
            $sql = "SELECT 
                        u.id,
                        u.unique_id,
                        u.name,
                        u.mobile,
                        u.email,
                        u.city,
                        u.states,
                        u.status,
                        u.Created_at,
                        u.Updated_at,
                        NULL as last_call_time,
                        'pending' as call_status,
                        NULL as last_feedback,
                        NULL as remarks
                    FROM users u
                    WHERE u.role IN ('driver', 'transporter')";
        }
        
        $params = [];
        
        // Add search filter if provided
        $search = $_GET['search'] ?? '';
        if (!empty($search)) {
            $sql .= " AND (u.name LIKE ? OR u.mobile LIKE ? OR COALESCE(u.email, '') LIKE ?)";
            $searchTerm = "%$search%";
            $params[] = $searchTerm;
            $params[] = $searchTerm;
            $params[] = $searchTerm;
        }
        
        // Add status filter
        $statusFilter = $_GET['status'] ?? '';
        if (!empty($statusFilter) && $callLogsExists) {
            $sql .= " AND COALESCE(cl.call_status, 'pending') = ?";
            $params[] = $statusFilter;
        }
        
        $sql .= " ORDER BY u.Created_at DESC LIMIT $limit OFFSET $offset";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $users = $stmt->fetchAll();
        
        // Transform to driver format
        $drivers = array_map(function($user) {
            // Generate TMid from unique_id or id
            $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
            
            // Determine subscription status based on available data
            $subscriptionStatus = 'inactive'; // default
            if (!empty($user['status'])) {
                switch(strtolower($user['status'])) {
                    case 'active':
                    case 'verified':
                    case 'approved':
                        $subscriptionStatus = 'active';
                        break;
                    case 'pending':
                    case 'under_review':
                        $subscriptionStatus = 'pending';
                        break;
                    case 'expired':
                    case 'suspended':
                        $subscriptionStatus = 'expired';
                        break;
                    default:
                        $subscriptionStatus = 'inactive';
                }
            }
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'Driver ' . $user['id'],
                'company' => $user['city'] ? $user['city'] . ' Transport' : '',
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? 'Unknown',
                'state' => $user['states'] ?? 'Unknown',
                'subscriptionStatus' => $subscriptionStatus,
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => mapCallStatus($user['call_status'] ?? 'pending'),
                'lastFeedback' => $user['last_feedback'],
                'lastCallTime' => $user['last_call_time'],
                'remarks' => $user['remarks'],
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s')
            ];
        }, $users);
        
        echo json_encode([
            'success' => true,
            'data' => $drivers,
            'count' => count($drivers),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['error' => 'Failed to fetch drivers: ' . $e->getMessage()]);
    }
}

function getSingleDriver($pdo) {
    $driverId = $_GET['id'] ?? '';
    
    if (empty($driverId)) {
        echo json_encode(['error' => 'Driver ID required']);
        return;
    }
    
    try {
        $sql = "SELECT u.*, cl.call_status, cl.feedback as last_feedback, cl.remarks, cl.call_time as last_call_time 
                FROM users u 
                LEFT JOIN call_logs cl ON u.id = cl.user_id 
                    AND cl.call_time = (SELECT MAX(call_time) FROM call_logs WHERE user_id = u.id)
                WHERE u.id = ? AND u.role IN ('driver', 'transporter')";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$driverId]);
        $user = $stmt->fetch();
        
        if (!$user) {
            echo json_encode(['error' => 'Driver not found']);
            return;
        }
        
        // Generate TMid from unique_id or id
        $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
        
        // Determine subscription status
        $subscriptionStatus = 'inactive';
        if (!empty($user['status'])) {
            switch(strtolower($user['status'])) {
                case 'active':
                case 'verified':
                case 'approved':
                    $subscriptionStatus = 'active';
                    break;
                case 'pending':
                case 'under_review':
                    $subscriptionStatus = 'pending';
                    break;
                case 'expired':
                case 'suspended':
                    $subscriptionStatus = 'expired';
                    break;
                default:
                    $subscriptionStatus = 'inactive';
            }
        }
        
        $driver = [
            'id' => (string)$user['id'],
            'tmid' => $tmid,
            'name' => $user['name'] ?? 'Driver ' . $user['id'],
            'company' => $user['city'] ? $user['city'] . ' Transport' : '',
            'phoneNumber' => $user['mobile'] ?? '',
            'email' => $user['email'] ?? '',
            'city' => $user['city'] ?? '',
            'state' => $user['states'] ?? '',
            'subscriptionStatus' => $subscriptionStatus,
            'userStatus' => $user['status'] ?? 'inactive',
            'callStatus' => mapCallStatus($user['call_status'] ?? 'pending'),
            'lastFeedback' => $user['last_feedback'],
            'lastCallTime' => $user['last_call_time'],
            'remarks' => $user['remarks'],
            'registrationDate' => $user['Created_at'] ?? date('Y-m-d H'),
            'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
          :i:s')
        ];('Y-m-d H'] ?? dateted_at['Upda $usert' =>tedAdaup  '
        
        echo json_encode([
            'success' => true,
            'data' => $driver,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['error' => 'Failed to fetch driver: ' . $e->getMessage()]);
    }
}

function updateCallStatus($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $driverId = $input['driver_id'] ?? '';
    $status = $input['status'] ?? '';
    $feedback = $input['feedback'] ?? '';
    $remarks = $input['remarks'] ?? '';
    $callerId = $input['caller_id'] ?? 1;
    
    if (empty($driverId) || empty($status)) {
        echo json_encode(['error' => 'Driver ID and status required']);
        return;
    }
    
    try {
        // Get driver info
        $stmt = $pdo->prepare("SELECT mobile FROM users WHERE id = ? AND role = 'driver'");
        $stmt->execute([$driverId]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
            echo json_encode(['error' => 'Driver not found']);
            return;
        }
        
        // Create call_logs table if it doesn't exist
        $createTableSql = "CREATE TABLE IF NOT EXISTS `call_logs` (
            `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            `job_id` varchar(255) DEFAULT NULL COMMENT 'Job reference (optional)',
            `job_name` varchar(255) DEFAULT NULL,
            `caller_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Telecaller user ID',
            `user_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Driver user ID',
            `caller_number` varchar(20) DEFAULT NULL,
            `user_number` varchar(20) NOT NULL,
            `transporter_id` bigint(20) UNSIGNED DEFAULT NULL,
            `transporter_tm_id` varchar(255) DEFAULT NULL,
            `transporter_name` varchar(255) DEFAULT NULL,
            `transporter_mobile` varchar(20) DEFAULT NULL,
            `driver_id` bigint(20) UNSIGNED DEFAULT NULL,
            `driver_tm_id` varchar(255) DEFAULT NULL,
            `driver_name` varchar(255) DEFAULT NULL,
            `driver_mobile` varchar(20) DEFAULT NULL,
            `call_status` enum('pending','connected','callback','callback_later','not_reachable','not_interested','invalid','completed','failed','cancelled') DEFAULT 'pending',
            `call_type` varchar(50) DEFAULT 'telecaller',
            `call_count` int(11) DEFAULT 1,
            `call_initiated_by` varchar(50) DEFAULT NULL,
            `feedback` text DEFAULT NULL,
            `remarks` text DEFAULT NULL,
            `notes` text DEFAULT NULL,
            `reference_id` varchar(100) DEFAULT NULL COMMENT 'MyOperator reference ID',
            `api_response` text DEFAULT NULL COMMENT 'MyOperator API response',
            `call_duration` int(11) DEFAULT 0 COMMENT 'Call duration in seconds',
            `call_time` timestamp NULL DEFAULT NULL,
            `call_initiated_at` timestamp NULL DEFAULT NULL,
            `call_completed_at` timestamp NULL DEFAULT NULL,
            `ip_address` varchar(45) DEFAULT NULL,
            `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_user_id` (`user_id`),
            KEY `idx_caller_id` (`caller_id`),
            KEY `idx_caller_user` (`caller_id`, `user_id`),
            KEY `idx_reference_id` (`reference_id`),
            KEY `idx_call_status` (`call_status`),
            KEY `idx_call_time` (`call_time`),
            KEY `idx_job_id` (`job_id`),
            KEY `idx_driver_id` (`driver_id`),
            KEY `idx_transporter_id` (`transporter_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        
        $pdo->exec($createTableSql);
        
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
        echo json_encode(['error' => 'Failed to update call status: ' . $e->getMessage()]);
    }
}

function logCall($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $driverId = $input['driver_id'] ?? '';
    $callerId = $input['caller_id'] ?? 1;
    $referenceId = $input['reference_id'] ?? '';
    $apiResponse = $input['api_response'] ?? '';
    
    if (empty($driverId)) {
        echo json_encode(['error' => 'Driver ID required']);
        return;
    }
    
    try {
        // Get driver info
        $stmt = $pdo->prepare("SELECT mobile FROM users WHERE id = ? AND role = 'driver'");
        $stmt->execute([$driverId]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
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

// No sample data - using real database only

// Show documentation if accessed directly
if (empty($_GET['action'])) {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>TruckMitr Drivers API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .endpoint { margin: 15px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #007bff; }
            .endpoint a { color: #007bff; text-decoration: none; font-weight: bold; }
            .endpoint a:hover { text-decoration: underline; }
            .method { display: inline-block; padding: 2px 8px; background: #28a745; color: white; border-radius: 4px; font-size: 12px; margin-right: 10px; }
            .method.post { background: #ffc107; color: black; }
            h1 { color: #333; text-align: center; }
            h2 { color: #007bff; border-bottom: 2px solid #007bff; padding-bottom: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚛 TruckMitr Drivers API</h1>
            <p>Real-time driver data API for Smart Calling feature</p>
            
            <h2>📊 Test Endpoints</h2>
            <div class="endpoint">
                <span class="method">GET</span>
                <strong>Database Test:</strong><br>
                <a href="?action=test" target="_blank">GET /simple_drivers_api.php?action=test</a><br>
                <small>Check database connection and table structure</small>
            </div>
            
            <h2>👥 Driver Endpoints</h2>
            <div class="endpoint">
                <span class="method">GET</span>
                <strong>Get All Drivers:</strong><br>
                <a href="?action=drivers" target="_blank">GET /simple_drivers_api.php?action=drivers</a><br>
                <a href="?action=drivers&limit=5" target="_blank">GET /simple_drivers_api.php?action=drivers&limit=5</a><br>
                <small>Parameters: limit, offset, search, status</small>
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span>
                <strong>Get Single Driver:</strong><br>
                <a href="?action=driver&id=90" target="_blank">GET /simple_drivers_api.php?action=driver&id=90</a><br>
                <small>Replace 90 with actual driver ID</small>
            </div>
            
            <h2>📞 Call Management</h2>
            <div class="endpoint">
                <span class="method post">POST</span>
                <strong>Update Call Status:</strong><br>
                POST /simple_drivers_api.php?action=update_call_status<br>
                <small>Body: {"driver_id":"90","status":"connected","feedback":"Interested"}</small>
            </div>
            
            <div class="endpoint">
                <span class="method post">POST</span>
                <strong>Log Call:</strong><br>
                POST /simple_drivers_api.php?action=log_call<br>
                <small>Body: {"driver_id":"90","reference_id":"CALL_123"}</small>
            </div>
            
            <h2>📋 Status Values</h2>
            <ul>
                <li><strong>pending</strong> - Not called yet</li>
                <li><strong>connected</strong> - Call successful</li>
                <li><strong>callback</strong> - Need to call back</li>
                <li><strong>callback_later</strong> - Call back later</li>
                <li><strong>not_reachable</strong> - Phone not reachable</li>
                <li><strong>not_interested</strong> - Driver not interested</li>
                <li><strong>invalid</strong> - Invalid phone number</li>
            </ul>
            
            <h2>🎯 Features</h2>
            <ul>
                <li>✅ Real database integration</li>
                <li>✅ TMid generation from unique_id</li>
                <li>✅ Subscription status mapping</li>
                <li>✅ Call status tracking</li>
                <li>✅ Search and filtering</li>
                <li>✅ Auto table creation</li>
            </ul>
        </div>
    </body>
    </html>
    <?php
}
?>