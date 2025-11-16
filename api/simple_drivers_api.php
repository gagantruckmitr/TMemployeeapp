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
    case 'insert_call_log':
        insertFullCallLog($pdo);
        break;
    case 'get_call_logs':
        getCallLogs($pdo);
        break;
    case 'get_call_log':
        getSingleCallLog($pdo);
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
                        u.images,
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
                        u.images,
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
            
            // Extract profile picture from images JSON and construct full URL
            $profilePicture = null;
            if (!empty($user['images'])) {
                $images = json_decode($user['images'], true);
                if (is_array($images) && count($images) > 0) {
                    $imagePath = $images[0];
                    $profilePicture = 'https://truckmitr.com/public/' . $imagePath;
                } elseif (!is_array($images) && is_string($user['images'])) {
                    $profilePicture = 'https://truckmitr.com/public/' . $user['images'];
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
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
                'profilePicture' => $profilePicture
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
        
        // Extract profile picture from images JSON and construct full URL
        $profilePicture = null;
        if (!empty($user['images'])) {
            $images = json_decode($user['images'], true);
            if (is_array($images) && count($images) > 0) {
                $imagePath = $images[0];
                $profilePicture = 'https://truckmitr.com/public/' . $imagePath;
            } elseif (!is_array($images) && is_string($user['images'])) {
                $profilePicture = 'https://truckmitr.com/public/' . $user['images'];
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
            'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
            'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
            'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
            'profilePicture' => $profilePicture
        ];
        
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
        
        // Insert call log with IST timezone
        $sql = "INSERT INTO call_logs (caller_id, user_id, caller_number, user_number, call_status, feedback, remarks, call_time) 
                VALUES (?, ?, ?, ?, ?, ?, ?, CONVERT_TZ(NOW(), '+00:00', '+05:30'))";
        
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
        
        // Insert call log with IST timezone
        $sql = "INSERT INTO call_logs (caller_id, user_id, caller_number, user_number, reference_id, api_response, call_time) 
                VALUES (?, ?, ?, ?, ?, ?, CONVERT_TZ(NOW(), '+00:00', '+05:30'))";
        
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

function insertFullCallLog($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['error' => 'Method not allowed. Use POST.']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Required fields
    $callerId = $input['caller_id'] ?? null;
    $userId = $input['user_id'] ?? null;
    $userNumber = $input['user_number'] ?? null;
    
    if (empty($callerId) || empty($userId) || empty($userNumber)) {
        echo json_encode([
            'error' => 'Required fields missing: caller_id, user_id, user_number',
            'received' => $input
        ]);
        return;
    }
    
    try {
        // Create call_logs table if it doesn't exist (with recording_url)
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
            `recording_url` varchar(500) DEFAULT NULL COMMENT 'Call recording URL',
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
        
        // Check if recording_url column exists, if not add it
        try {
            $checkColumn = $pdo->query("SHOW COLUMNS FROM call_logs LIKE 'recording_url'");
            if ($checkColumn->rowCount() == 0) {
                $pdo->exec("ALTER TABLE call_logs ADD COLUMN `recording_url` varchar(500) DEFAULT NULL COMMENT 'Call recording URL' AFTER `call_duration`");
            }
        } catch(Exception $e) {
            // Column might already exist, continue
        }
        
        // Prepare all fields with defaults
        $jobId = $input['job_id'] ?? null;
        $jobName = $input['job_name'] ?? null;
        $callerNumber = $input['caller_number'] ?? null;
        $transporterId = $input['transporter_id'] ?? null;
        $transporterTmId = $input['transporter_tm_id'] ?? null;
        $transporterName = $input['transporter_name'] ?? null;
        $transporterMobile = $input['transporter_mobile'] ?? null;
        $driverId = $input['driver_id'] ?? null;
        $driverTmId = $input['driver_tm_id'] ?? null;
        $driverName = $input['driver_name'] ?? null;
        $driverMobile = $input['driver_mobile'] ?? null;
        $callStatus = $input['call_status'] ?? 'pending';
        $callType = $input['call_type'] ?? 'telecaller';
        $callCount = $input['call_count'] ?? 1;
        $callInitiatedBy = $input['call_initiated_by'] ?? null;
        $feedback = $input['feedback'] ?? null;
        $remarks = $input['remarks'] ?? null;
        $notes = $input['notes'] ?? null;
        $referenceId = $input['reference_id'] ?? null;
        $apiResponse = $input['api_response'] ?? null;
        $callDuration = $input['call_duration'] ?? 0;
        $recordingUrl = $input['recording_url'] ?? null;
        $callTime = $input['call_time'] ?? null;
        $callInitiatedAt = $input['call_initiated_at'] ?? null;
        $callCompletedAt = $input['call_completed_at'] ?? null;
        $ipAddress = $input['ip_address'] ?? $_SERVER['REMOTE_ADDR'] ?? null;
        
        // Build SQL with all columns including recording_url
        $sql = "INSERT INTO call_logs (
                    job_id, job_name, caller_id, user_id, caller_number, user_number,
                    transporter_id, transporter_tm_id, transporter_name, transporter_mobile,
                    driver_id, driver_tm_id, driver_name, driver_mobile,
                    call_status, call_type, call_count, call_initiated_by,
                    feedback, remarks, notes, reference_id, api_response, call_duration,
                    recording_url, call_time, call_initiated_at, call_completed_at, ip_address,
                    created_at, updated_at
                ) VALUES (
                    ?, ?, ?, ?, ?, ?,
                    ?, ?, ?, ?,
                    ?, ?, ?, ?,
                    ?, ?, ?, ?,
                    ?, ?, ?, ?, ?, ?,
                    ?,
                    COALESCE(?, CONVERT_TZ(NOW(), '+00:00', '+05:30')),
                    COALESCE(?, CONVERT_TZ(NOW(), '+00:00', '+05:30')),
                    ?,
                    ?,
                    CONVERT_TZ(NOW(), '+00:00', '+05:30'),
                    CONVERT_TZ(NOW(), '+00:00', '+05:30')
                )";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $jobId, $jobName, $callerId, $userId, $callerNumber, $userNumber,
            $transporterId, $transporterTmId, $transporterName, $transporterMobile,
            $driverId, $driverTmId, $driverName, $driverMobile,
            $callStatus, $callType, $callCount, $callInitiatedBy,
            $feedback, $remarks, $notes, $referenceId, $apiResponse, $callDuration,
            $recordingUrl, $callTime, $callInitiatedAt, $callCompletedAt, $ipAddress
        ]);
        
        $insertedId = $pdo->lastInsertId();
        
        // Fetch the inserted record to return
        $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
        $stmt->execute([$insertedId]);
        $insertedRecord = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'message' => 'Call log inserted successfully with all columns',
            'call_log_id' => $insertedId,
            'data' => $insertedRecord,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to insert call log: ' . $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
    }
}

function getCallLogs($pdo) {
    try {
        // Check if call_logs table exists
        $stmt = $pdo->query("SHOW TABLES LIKE 'call_logs'");
        if ($stmt->rowCount() == 0) {
            echo json_encode([
                'success' => false,
                'error' => 'Call logs table not found',
                'message' => 'No call logs available yet'
            ]);
            return;
        }
        
        $limit = (int)($_GET['limit'] ?? 50);
        $offset = (int)($_GET['offset'] ?? 0);
        
        // Build query with filters
        $sql = "SELECT 
                    cl.*,
                    u.name as user_name,
                    u.mobile as user_mobile,
                    a.name as caller_name,
                    a.mobile as caller_mobile
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE 1=1";
        
        $params = [];
        
        // Filter by user_id
        if (!empty($_GET['user_id'])) {
            $sql .= " AND cl.user_id = ?";
            $params[] = $_GET['user_id'];
        }
        
        // Filter by caller_id
        if (!empty($_GET['caller_id'])) {
            $sql .= " AND cl.caller_id = ?";
            $params[] = $_GET['caller_id'];
        }
        
        // Filter by call_status
        if (!empty($_GET['call_status'])) {
            $sql .= " AND cl.call_status = ?";
            $params[] = $_GET['call_status'];
        }
        
        // Filter by reference_id
        if (!empty($_GET['reference_id'])) {
            $sql .= " AND cl.reference_id = ?";
            $params[] = $_GET['reference_id'];
        }
        
        // Filter by job_id
        if (!empty($_GET['job_id'])) {
            $sql .= " AND cl.job_id = ?";
            $params[] = $_GET['job_id'];
        }
        
        // Filter by date range
        if (!empty($_GET['from_date'])) {
            $sql .= " AND cl.call_time >= ?";
            $params[] = $_GET['from_date'];
        }
        
        if (!empty($_GET['to_date'])) {
            $sql .= " AND cl.call_time <= ?";
            $params[] = $_GET['to_date'];
        }
        
        // Order by most recent first
        $sql .= " ORDER BY cl.call_time DESC, cl.id DESC LIMIT $limit OFFSET $offset";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $callLogs = $stmt->fetchAll();
        
        // Get total count
        $countSql = "SELECT COUNT(*) as total FROM call_logs cl WHERE 1=1";
        $countParams = [];
        
        if (!empty($_GET['user_id'])) {
            $countSql .= " AND cl.user_id = ?";
            $countParams[] = $_GET['user_id'];
        }
        if (!empty($_GET['caller_id'])) {
            $countSql .= " AND cl.caller_id = ?";
            $countParams[] = $_GET['caller_id'];
        }
        if (!empty($_GET['call_status'])) {
            $countSql .= " AND cl.call_status = ?";
            $countParams[] = $_GET['call_status'];
        }
        
        $countStmt = $pdo->prepare($countSql);
        $countStmt->execute($countParams);
        $totalCount = $countStmt->fetch()['total'];
        
        echo json_encode([
            'success' => true,
            'data' => $callLogs,
            'count' => count($callLogs),
            'total' => $totalCount,
            'limit' => $limit,
            'offset' => $offset,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch call logs: ' . $e->getMessage()
        ]);
    }
}

function getSingleCallLog($pdo) {
    $callLogId = $_GET['id'] ?? '';
    
    if (empty($callLogId)) {
        echo json_encode(['error' => 'Call log ID required']);
        return;
    }
    
    try {
        $sql = "SELECT 
                    cl.*,
                    u.name as user_name,
                    u.mobile as user_mobile,
                    u.email as user_email,
                    a.name as caller_name,
                    a.mobile as caller_mobile,
                    a.email as caller_email
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE cl.id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$callLogId]);
        $callLog = $stmt->fetch();
        
        if (!$callLog) {
            echo json_encode([
                'success' => false,
                'error' => 'Call log not found'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $callLog,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch call log: ' . $e->getMessage()
        ]);
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
