<?php
// Transporter Leads API - Returns uncalled transporters for welcome calls
// Version: 1.0 - Production Ready
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Use config.php for database connection
require_once 'config.php';
require_once 'update_activity_middleware.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'transporter_leads';

switch($action) {
    case 'transporter_leads':
        getTransporterLeads($pdo);
        break;
    case 'mark_called':
        markTransporterAsCalled($pdo);
        break;
    case 'by_status':
        getTransportersByStatus($pdo);
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function getTransporterLeads($pdo) {
    try {
        $limit = (int)($_GET['limit'] ?? 50);
        $callerId = (int)($_GET['caller_id'] ?? 0);
        $status = $_GET['status'] ?? null;
        
        error_log("🔍 transporter_leads_api.php received caller_id: $callerId");
        
        // Ensure call_logs table exists
        createCallLogsTable($pdo);
        
        // If status filter is provided, get transporters by call status
        if ($status) {
            return getTransportersByStatus($pdo, $callerId, $status, $limit);
        }
        
        // ROUND ROBIN ASSIGNMENT LOGIC
        // Get all telecallers from admins table where tc_for = 'match-making' ONLY
        $telecallersStmt = $pdo->query("
            SELECT id FROM admins 
            WHERE role = 'telecaller'
            AND tc_for = 'match-making'
            ORDER BY id ASC
        ");
        $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_COLUMN);
        
        // If no telecallers found with tc_for = 'match-making', return empty
        if (empty($telecallers)) {
            error_log("⚠️ No telecallers found with tc_for = 'match-making'");
            echo json_encode([
                'success' => true,
                'data' => [],
                'count' => 0,
                'caller_id' => $callerId,
                'distribution' => 'round_robin',
                'note' => 'No telecallers with tc_for = match-making found',
                'timestamp' => date('Y-m-d H:i:s')
            ]);
            return;
        }
        
        // Check if current caller is in the match-making telecallers list
        $currentIndex = array_search($callerId, $telecallers);
        if ($currentIndex === false) {
            error_log("❌ Caller ID $callerId not authorized for match-making (tc_for != 'match-making')");
            echo json_encode([
                'success' => false,
                'error' => 'Access denied: Only telecallers with tc_for = match-making can access these leads',
                'caller_id' => $callerId,
                'timestamp' => date('Y-m-d H:i:s')
            ]);
            return;
        }
        
        error_log("🔍 Round Robin: Telecaller $callerId at index $currentIndex of " . count($telecallers) . " telecallers");
        
        // Get uncalled transporters who:
        // 1. Have role = 'transporter'
        // 2. Have NEVER posted any jobs (users.id not in jobs.transporter_id)
        // 3. Have NOT been called by ANY telecaller yet
        // 4. Assign in round-robin fashion
        $sql = "SELECT 
                    u.id,
                    u.unique_id,
                    u.name,
                    u.mobile,
                    u.email,
                    u.city,
                    u.states,
                    u.status,
                    u.role,
                    u.assigned_to,
                    u.images,
                    u.transport_name,
                    u.fleet_size,
                    u.operational_segment,
                    u.year_of_establishment,
                    u.Created_at,
                    u.Updated_at
                FROM users u
                WHERE u.role = 'transporter'
                AND u.id NOT IN (
                    -- Exclude transporters who have posted jobs (users.id = jobs.transporter_id)
                    SELECT DISTINCT transporter_id 
                    FROM jobs
                    WHERE transporter_id IS NOT NULL
                    AND transporter_id != ''
                    AND transporter_id > 0
                )
                AND u.id NOT IN (
                    -- Exclude transporters who have been called by ANY telecaller
                    SELECT DISTINCT user_id 
                    FROM call_logs
                    WHERE user_id IS NOT NULL
                    AND user_id != ''
                    AND user_id > 0
                )
                ORDER BY u.Created_at DESC";
        
        error_log("🔍 Fetching all uncalled transporters who have never posted jobs");
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute();
        $allTransporters = $stmt->fetchAll();
        
        error_log("🔍 Found " . count($allTransporters) . " total uncalled transporters without jobs");
        
        // ROUND ROBIN DISTRIBUTION - Distribute ALL transporters evenly
        // Each telecaller gets every Nth transporter where N = number of telecallers
        $totalTransporters = count($allTransporters);
        $telecallerCount = count($telecallers);
        
        // Find current telecaller's position in the list
        $currentIndex = array_search($callerId, $telecallers);
        if ($currentIndex === false) {
            $currentIndex = 0;
        }
        
        error_log("🔍 Distributing $totalTransporters transporters among $telecallerCount telecallers");
        error_log("🔍 Telecaller $callerId is at index $currentIndex");
        
        // Assign transporters using modulo distribution
        // Telecaller 0 gets: 0, 3, 6, 9, 12...
        // Telecaller 1 gets: 1, 4, 7, 10, 13...
        // Telecaller 2 gets: 2, 5, 8, 11, 14...
        $assignedTransporters = [];
        foreach ($allTransporters as $index => $transporter) {
            // Check if this transporter belongs to current telecaller
            if ($index % $telecallerCount == $currentIndex) {
                $assignedTransporters[] = $transporter;
                
                // Apply limit if specified
                if (count($assignedTransporters) >= $limit) {
                    break;
                }
            }
        }
        
        error_log("🔍 Telecaller $callerId assigned " . count($assignedTransporters) . " transporters out of $totalTransporters total");
        
        $users = $assignedTransporters;
        
        error_log("🔍 Telecaller $callerId assigned " . count($users) . " transporters via round-robin");
        
        // Transform to transporter format
        $transporters = array_map(function($user) use ($pdo) {
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
                }
            }
            
            // Calculate profile completion
            $profileCompletion = calculateTransporterProfileCompletion($pdo, $user['id']);
            
            // Extract profile picture from images JSON
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
            
            // Build company name from transport_name or city
            $company = $user['transport_name'] ?? ($user['city'] ? $user['city'] . ' Transport' : 'Transport Company');
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'Transporter ' . $user['id'],
                'company' => $company,
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? '',
                'state' => $user['states'] ?? '',
                'subscriptionStatus' => $subscriptionStatus,
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => 'pending',
                'lastFeedback' => null,
                'lastCallTime' => null,
                'remarks' => null,
                'paymentInfo' => null,
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
                'profile_completion' => $profileCompletion . '%',
                'profilePicture' => $profilePicture,
                // Transporter-specific fields
                'transportName' => $user['transport_name'] ?? '',
                'fleetSize' => $user['fleet_size'] ?? '',
                'operationalSegment' => $user['operational_segment'] ?? '',
                'yearOfEstablishment' => $user['year_of_establishment'] ?? ''
            ];
        }, $users);
        
        echo json_encode([
            'success' => true,
            'data' => $transporters,
            'count' => count($transporters),
            'caller_id' => $callerId,
            'distribution' => 'round_robin',
            'note' => 'Round-robin assignment: transporters without jobs and not called',
            'debug' => [
                'total_transporters_found' => count($allTransporters),
                'telecaller_count' => $telecallerCount,
                'assigned_to_this_telecaller' => count($users),
                'telecaller_index' => $currentIndex
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        error_log('Transporter leads error: ' . $e->getMessage());
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch transporter leads: ' . $e->getMessage()
        ]);
    }
}

function markTransporterAsCalled($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $transporterId = $input['transporter_id'] ?? '';
    $callerId = $input['caller_id'] ?? 1;
    $status = $input['status'] ?? 'pending';
    $feedback = $input['feedback'] ?? '';
    $remarks = $input['remarks'] ?? '';
    
    if (empty($transporterId)) {
        echo json_encode(['error' => 'Transporter ID required']);
        return;
    }
    
    try {
        // Get transporter info
        $stmt = $pdo->prepare("SELECT mobile, name, unique_id FROM users WHERE id = ? AND role = 'transporter'");
        $stmt->execute([$transporterId]);
        $transporter = $stmt->fetch();
        
        if (!$transporter) {
            echo json_encode(['error' => 'Transporter not found']);
            return;
        }
        
        // Ensure call_logs table exists
        createCallLogsTable($pdo);
        
        // Insert call log
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, transporter_id, transporter_tm_id, 
                 transporter_name, transporter_mobile, call_status, feedback, remarks, call_time, call_type) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'welcome_call')";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $transporterId,
            '',
            $transporter['mobile'],
            $transporterId,
            $transporter['unique_id'],
            $transporter['name'],
            $transporter['mobile'],
            $status,
            $feedback,
            $remarks
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Transporter marked as called',
            'call_id' => $pdo->lastInsertId(),
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        error_log('Mark transporter called error: ' . $e->getMessage());
        echo json_encode([
            'success' => false,
            'error' => 'Failed to mark as called: ' . $e->getMessage()
        ]);
    }
}

function getTransportersByStatus($pdo, $callerId, $status, $limit) {
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
        
        // Get transporters that have been called with this status by this telecaller
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
                    u.transport_name,
                    u.fleet_size,
                    u.operational_segment,
                    u.year_of_establishment,
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
                AND u.role = 'transporter'
                ORDER BY cl.call_time DESC
                LIMIT :limit";
        
        $stmt = $pdo->prepare($sql);
        $stmt->bindValue(':caller_id', $callerId, PDO::PARAM_INT);
        $stmt->bindValue(':call_status', $callStatus, PDO::PARAM_STR);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        $users = $stmt->fetchAll();
        
        // Transform to transporter format
        $transporters = array_map(function($user) use ($pdo) {
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
            
            // Calculate profile completion
            $profileCompletion = calculateTransporterProfileCompletion($pdo, $user['id']);
            
            // Extract profile picture
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
            
            $company = $user['transport_name'] ?? ($user['city'] ? $user['city'] . ' Transport' : 'Transport Company');
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'Transporter ' . $user['id'],
                'company' => $company,
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? '',
                'state' => $user['states'] ?? '',
                'subscriptionStatus' => $subscriptionStatus,
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => $user['call_status'] ?? 'pending',
                'lastFeedback' => $user['feedback'],
                'lastCallTime' => $user['last_call_time'],
                'remarks' => $user['remarks'],
                'paymentInfo' => null,
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
                'profile_completion' => $profileCompletion . '%',
                'profilePicture' => $profilePicture,
                'transportName' => $user['transport_name'] ?? '',
                'fleetSize' => $user['fleet_size'] ?? '',
                'operationalSegment' => $user['operational_segment'] ?? '',
                'yearOfEstablishment' => $user['year_of_establishment'] ?? ''
            ];
        }, $users);
        
        echo json_encode([
            'success' => true,
            'data' => $transporters,
            'count' => count($transporters),
            'caller_id' => $callerId,
            'status' => $status,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        error_log('Transporters by status error: ' . $e->getMessage());
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch transporters by status: ' . $e->getMessage()
        ]);
    }
}

function createCallLogsTable($pdo) {
    $sql = "CREATE TABLE IF NOT EXISTS `call_logs` (
        `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
        `job_id` varchar(255) DEFAULT NULL COMMENT 'Job reference (optional)',
        `job_name` varchar(255) DEFAULT NULL,
        `caller_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Telecaller user ID',
        `user_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Driver/Transporter user ID',
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

function calculateTransporterProfileCompletion($pdo, $userId) {
    try {
        // Fetch transporter data
        $stmt = $pdo->prepare("
            SELECT 
                name, email, transport_name, year_of_establishment,
                fleet_size, operational_segment, average_km, city, images, address,
                pan_number, pan_image, gst_certificate, mobile, states
            FROM users 
            WHERE id = ? AND role = 'transporter'
        ");
        
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if (!$user) {
            return 0;
        }
        
        // Define required fields for transporter
        // CRITICAL: MUST MATCH profile_completion_helper.php for consistency
        // Avatar shows this %, profile details page shows helper.php %
        $requiredFields = [
            'name', 'email', 'transport_name', 'year_of_establishment',
            'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
            'pan_number', 'pan_image', 'gst_certificate'
        ];
        
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
                    // Non-empty array - field is present
                    $filledFields++;
                } elseif (is_array($decoded) && count($decoded) === 0) {
                    // Empty array - field is NOT present
                    // Do not increment $filledFields
                } else {
                    // Not an array and not empty - field is present
                    $filledFields++;
                }
            }
        }
        
        $completionPercentage = round(($filledFields / $totalFields) * 100);
        
        return $completionPercentage;
        
    } catch(Exception $e) {
        error_log('Transporter profile completion calculation error: ' . $e->getMessage());
        return 0;
    }
}
?>
