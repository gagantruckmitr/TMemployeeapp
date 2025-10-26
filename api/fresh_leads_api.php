<?php
// Fresh Leads API - Returns only uncalled leads for telecaller
// Version: 2.0 - Updated with registration date and payment info
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Use config.php for database connection
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'fresh_leads';

switch($action) {
    case 'fresh_leads':
        getFreshLeads($pdo);
        break;
    case 'mark_called':
        markAsCalled($pdo);
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function getFreshLeads($pdo) {
    try {
        $limit = (int)($_GET['limit'] ?? 50);
        $callerId = (int)($_GET['caller_id'] ?? 0);
        $status = $_GET['status'] ?? null;
        
        // DEBUG: Log what caller_id we received
        error_log("🔍 fresh_leads_api.php received caller_id: $callerId");
        
        // Ensure call_logs table exists
        createCallLogsTable($pdo);
        
        // If status filter is provided, get drivers by call status
        if ($status) {
            return getDriversByStatus($pdo, $callerId, $status, $limit);
        }
        
        // Check if payments table exists
        $checkPaymentsSql = "SHOW TABLES LIKE 'payments'";
        $stmt = $pdo->query($checkPaymentsSql);
        $paymentsExists = $stmt->rowCount() > 0;
        
        // Get total number of active telecallers from admins table
        $telecallerCountStmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
        $telecallerCount = (int)$telecallerCountStmt->fetch()['count'];
        
        // If no telecallers found, default to 2
        if ($telecallerCount == 0) {
            $telecallerCount = 2;
        }
        
        // Get all active telecaller IDs ordered by ID from admins table
        $telecallersStmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
        $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_COLUMN);
        
        // Find the position of current telecaller in the list
        $callerPosition = array_search($callerId, $telecallers);
        if ($callerPosition === false) {
            $callerPosition = 0; // Default to first position if not found
        }
        
        // Debug: Log the distribution
        error_log("Round-robin: Caller ID $callerId, Position $callerPosition, Total telecallers: $telecallerCount");
        
        // TRUE ROUND-ROBIN: Show leads where assigned_to matches this telecaller
        // Database has alternating assignments: Lead1→TC1, Lead2→TC2, Lead3→TC1, Lead4→TC2
        // This query simply filters by assigned_to column
        
        $sql = "SELECT 
                    u.id,
                    u.unique_id,
                    u.name,
                    u.mobile,
                    u.email,
                    u.city,
                    u.states,
                    u.status,
                    u.assigned_to,
                    u.Created_at,
                    u.Updated_at
                FROM users u
                WHERE u.role = 'driver'
                AND u.assigned_to = :caller_id
                AND u.id NOT IN (
                    SELECT DISTINCT user_id 
                    FROM call_logs
                    WHERE caller_id = :caller_id
                )
                ORDER BY u.Created_at DESC
                LIMIT :limit";
        
        $stmt = $pdo->prepare($sql);
        $stmt->bindValue(':caller_id', $callerId, PDO::PARAM_INT);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        $users = $stmt->fetchAll();
        
        // Transform to driver format
        $drivers = array_map(function($user) use ($pdo) {
            $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
            
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
                }
            }
            
            // Build payment info - set to null (payments table columns don't match)
            $paymentInfo = null;
            
            // Calculate profile completion
            $profileCompletion = calculateProfileCompletion($pdo, $user['id']);
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'Driver ' . $user['id'],
                'company' => ($user['city'] ?? 'Unknown') . ' Transport',
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? 'Unknown',
                'state' => $user['states'] ?? 'Unknown',
                'subscriptionStatus' => $subscriptionStatus,
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => 'pending',
                'lastFeedback' => null,
                'lastCallTime' => null,
                'remarks' => null,
                'paymentInfo' => $paymentInfo,
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
                'profile_completion' => $profileCompletion . '%'
            ];
        }, $users);
        
        echo json_encode([
            'success' => true,
            'data' => $drivers,
            'count' => count($drivers),
            'caller_id' => $callerId,
            'distribution' => 'assigned_to_column',
            'note' => 'Showing leads assigned to this telecaller via assigned_to column',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['error' => 'Failed to fetch fresh leads: ' . $e->getMessage()]);
    }
}

function markAsCalled($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $driverId = $input['driver_id'] ?? '';
    $callerId = $input['caller_id'] ?? 1;
    $status = $input['status'] ?? 'pending';
    $feedback = $input['feedback'] ?? '';
    $remarks = $input['remarks'] ?? '';
    
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
        
        // Ensure call_logs table exists
        createCallLogsTable($pdo);
        
        // Insert call log
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, call_status, feedback, remarks, call_time) 
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $driverId,
            '',
            $driver['mobile'],
            $status,
            $feedback,
            $remarks
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Lead marked as called',
            'call_id' => $pdo->lastInsertId(),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['error' => 'Failed to mark as called: ' . $e->getMessage()]);
    }
}

function getDriversByStatus($pdo, $callerId, $status, $limit) {
    try {
        // Map status to call_status values
        $statusMap = [
            'connected' => 'connected',
            'callback' => 'callback',
            'callback_later' => 'callback_later',
            'not_reachable' => 'not_reachable',
            'not_interested' => 'not_interested',
            'invalid' => 'invalid'
        ];
        
        $callStatus = $statusMap[$status] ?? $status;
        
        // Get drivers that have been called with this status by this telecaller
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
                    cl.call_status,
                    cl.feedback,
                    cl.remarks,
                    cl.call_time as last_call_time
                FROM call_logs cl
                INNER JOIN users u ON cl.user_id = u.id
                WHERE cl.caller_id = :caller_id
                AND cl.call_status = :call_status
                AND u.role = 'driver'
                ORDER BY cl.call_time DESC
                LIMIT :limit";
        
        $stmt = $pdo->prepare($sql);
        $stmt->bindValue(':caller_id', $callerId, PDO::PARAM_INT);
        $stmt->bindValue(':call_status', $callStatus, PDO::PARAM_STR);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        $users = $stmt->fetchAll();
        
        // Transform to driver format
        $drivers = array_map(function($user) use ($pdo) {
            $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
            
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
                }
            }
            
            // Build payment info - set to null (payments table columns don't match)
            $paymentInfo = null;
            
            // Calculate profile completion
            $profileCompletion = calculateProfileCompletion($pdo, $user['id']);
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'Driver ' . $user['id'],
                'company' => ($user['city'] ?? 'Unknown') . ' Transport',
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? 'Unknown',
                'state' => $user['states'] ?? 'Unknown',
                'subscriptionStatus' => $subscriptionStatus,
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => $user['call_status'] ?? 'pending',
                'lastFeedback' => $user['feedback'],
                'lastCallTime' => $user['last_call_time'],
                'remarks' => $user['remarks'],
                'paymentInfo' => $paymentInfo,
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
                'profile_completion' => $profileCompletion . '%'
            ];
        }, $users);
        
        echo json_encode([
            'success' => true,
            'data' => $drivers,
            'count' => count($drivers),
            'caller_id' => $callerId,
            'status' => $status,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['error' => 'Failed to fetch drivers by status: ' . $e->getMessage()]);
    }
}

function createCallLogsTable($pdo) {
    $sql = "CREATE TABLE IF NOT EXISTS `call_logs` (
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
    
    $pdo->exec($sql);
}

function calculateProfileCompletion($pdo, $userId) {
    try {
        // Fetch user data
        $stmt = $pdo->prepare("
            SELECT 
                name, email, city, status, sex, vehicle_type, role,
                father_name, images, address, dob,
                type_of_license, driving_experience, highest_education, license_number,
                expiry_date_of_license, expected_monthly_income, current_monthly_income,
                marital_status, preferred_location, aadhar_number, aadhar_photo,
                driving_license, previous_employer, job_placement,
                transport_name, year_of_establishment, fleet_size, operational_segment,
                average_km, pan_number, pan_image, gst_certificate
            FROM users 
            WHERE id = ?
        ");
        
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if (!$user) {
            return 0;
        }
        
        $role = $user['role'];
        
        // Define required fields based on role
        $requiredFields = [];
        if ($role === 'driver') {
            $requiredFields = [
                'name', 'email', 'city', 'status', 'sex', 'vehicle_type',
                'father_name', 'images', 'address', 'dob',
                'type_of_license', 'driving_experience', 'highest_education', 'license_number',
                'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
                'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
                'driving_license', 'previous_employer', 'job_placement'
            ];
        } elseif ($role === 'transporter') {
            $requiredFields = [
                'name', 'email', 'transport_name', 'year_of_establishment',
                'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
                'pan_number', 'pan_image', 'gst_certificate'
            ];
        }
        
        $filledFields = 0;
        $totalFields = count($requiredFields);
        
        if ($totalFields === 0) {
            return 0;
        }
        
        foreach ($requiredFields as $field) {
            $value = $user[$field] ?? null;
            
            if ($value !== null && $value !== '') {
                // Check if it's a JSON array with content
                $decoded = json_decode($value, true);
                if (is_array($decoded) && count($decoded) > 0) {
                    $filledFields++;
                } elseif (!is_array($decoded)) {
                    $filledFields++;
                }
            }
        }
        
        $completionPercentage = round(($filledFields / $totalFields) * 100);
        
        return $completionPercentage;
        
    } catch(Exception $e) {
        error_log('Profile completion calculation error: ' . $e->getMessage());
        return 0;
    }
}
?>


