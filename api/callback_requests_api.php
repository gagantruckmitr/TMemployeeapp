<?php
/**
 * Callback Requests API
 * Handles fetching, creating, and updating callback requests
 */

// 1. Include Configuration
require_once 'config.php';

// 2. Set Content Type
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 3. Route Request based on Method and Action
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';
$id = $_GET['id'] ?? null;

// 4. Authenticate User
$currentUser = authenticateUser($conn); 

try {
    switch ($method) {
        case 'GET':
            if ($action === 'index' || $action === 'list') {
                getCallbackRequests($conn, $currentUser);
            } elseif ($action === 'history') {
                getCallbackHistory($conn, $currentUser);
            } elseif ($action === 'show' && $id) {
                getSingleRequest($conn, $id);
            } elseif ($action === 'export') {
                exportCallbackRequests($conn);
            } else {
                sendError('Invalid GET action or missing ID', 400);
            }
            break;

        case 'POST':
            if ($action === 'store' || $action === 'add') {
                storeCallbackRequest($conn, $currentUser);
            } elseif ($action === 'update' && $id) {
                updateCallbackRequest($conn, $id);
            } elseif ($action === 'update_status') {
                // Handle both query param ID and body ID
                $input = json_decode(file_get_contents('php://input'), true);
                $targetId = $id ?? ($input['callback_id'] ?? null);
                if ($targetId) {
                    updateStatus($conn, $targetId);
                } else {
                    sendError('Callback ID is required', 400);
                }
            } else {
                sendError('Invalid POST action', 400);
            }
            break;

        default:
            sendError('Method not allowed', 405);
            break;
    }
} catch (Exception $e) {
    error_log("API Error: " . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}

// ==================================================================================
// FUNCTIONS
// ==================================================================================

function authenticateUser($conn) {
    // 1. Get headers
    $headers = [];
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
    }
    $authHeader = $headers['Authorization'] ?? '';
    
    // 2. Check for admin authentication first (from admins table)
    $adminId = $_REQUEST['auth_admin_id'] ?? null;
    if ($adminId) {
        $stmt = $conn->prepare("SELECT * FROM admins WHERE id = ? LIMIT 1");
        $stmt->bind_param("i", $adminId);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->fetch_assoc();
    }
    
    // Check for regular user authentication (from users table)
    $userId = $_REQUEST['auth_user_id'] ?? null;
    if ($userId) {
        $stmt = $conn->prepare("SELECT * FROM users WHERE id = ? LIMIT 1");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->fetch_assoc();
    }
    
    return null;
}

/**
 * Fetch all callback requests for user
 */
function getCallbackRequests($conn, $user) {
    if (!$user) {
        sendError('User not authenticated.', 401);
    }

    $role = $user['role'] ?? null;
    $userId = $user['id'];
    
    // Optional filter by specific telecaller ID
    $filterTelecallerId = $_GET['telecaller_id'] ?? null;

    // Base query
    $sql = "SELECT cr.* FROM callback_requests cr WHERE 1=1";
    $params = [];
    $types = "";

    // Logic based on role
    if (strtolower($role) === 'telecaller') {
        // Telecallers can only see their own assigned requests
        $sql .= " AND cr.assigned_to = ? AND cr.status IN ('Pending', 'Callback', 'Ringing / Call Busy', 'Disconnected', 'Swtiched Off / Out of Service or Network', 'Future Prospects')";
        $params[] = $userId;
        $types .= "i";
    } elseif (in_array(strtolower($role), ['admin', 'manager'])) {
        // Admins/managers can optionally filter by telecaller ID
        if ($filterTelecallerId) {
            $sql .= " AND cr.assigned_to = ?";
            $params[] = $filterTelecallerId;
            $types .= "i";
        }
    } else {
        // For any other role, default to showing assigned requests
        // This ensures "allow all telecaller" works even if role name varies
        $sql .= " AND cr.assigned_to = ?";
        $params[] = $userId;
        $types .= "i";
    }

    $sql .= " ORDER BY cr.created_at DESC";

    $stmt = $conn->prepare($sql);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->get_result();
    
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = enrichRequestData($conn, $row);
    }

    sendSuccess($data, 'Callback requests fetched successfully.');
}

/**
 * Fetch history of calls made by this user
 */
function getCallbackHistory($conn, $user) {
    if (!$user) {
        sendError('User not authenticated.', 401);
    }

    $userId = $user['id'];
    
    // Fetch from call_logs where caller_id matches
    // We join with users table to get user details
    // We might also want to join with callback_requests if we want to link them, 
    // but call_logs usually links to users table via user_id
    
    $query = "
        SELECT 
            cl.id,
            u.unique_id,
            u.name as user_name,
            u.mobile as mobile_number,
            cl.call_time as request_date_time,
            cl.remarks as notes,
            cl.call_status as status,
            u.role as app_type,
            u.images,
            u.assigned_to,
            'Call History' as contact_reason
        FROM call_logs cl
        JOIN users u ON cl.user_id = u.id
        WHERE cl.caller_id = ?
        ORDER BY cl.call_time DESC
        LIMIT 50
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $data = [];
    while ($row = $result->fetch_assoc()) {
        // Map status if needed, or keep as is
        // The app expects 'status' field.
        
        // Enrich with profile completion
        $data[] = enrichRequestData($conn, $row, true);
    }
    
    sendSuccess($data, 'Callback history fetched successfully.');
}

function enrichRequestData($conn, $row, $isHistory = false) {
    // Fetch related user for profile completion and subscription
    // If it's history, we already have user details from join, but let's be consistent
    $uniqueId = $row['unique_id'] ?? null;
    
    $profileCompletion = '0%';
    $subDate = 'N/A';
    $profileImage = null;

    if ($uniqueId) {
        // Fetch related user if not already fully available
        // For history, we have some fields, but let's fetch fresh to be sure
        $userSql = "SELECT * FROM users WHERE unique_id = ? LIMIT 1";
        $uStmt = $conn->prepare($userSql);
        $uStmt->bind_param("s", $uniqueId);
        $uStmt->execute();
        $relatedUser = $uStmt->get_result()->fetch_assoc();

        if ($relatedUser) {
            $profileCompletion = calculateProfileCompletion($relatedUser) . '%';
            
            // Fetch subscription date
            $paySql = "SELECT created_at FROM payments 
                       WHERE unique_id = ? 
                       ORDER BY created_at DESC LIMIT 1";
            $pStmt = $conn->prepare($paySql);
            $pStmt->bind_param("s", $uniqueId);
            $pStmt->execute();
            $payResult = $pStmt->get_result()->fetch_assoc();
            if ($payResult) {
                $subDate = date('Y-m-d', strtotime($payResult['created_at']));
            }
            
            // Image
            if (!empty($relatedUser['images'])) {
                $profileImage = $relatedUser['images'];
            }
        }
    }

    $row['profile_completion'] = $profileCompletion;
    $row['subscribe_date'] = $subDate;
    if ($profileImage) {
        $row['images'] = $profileImage; // Ensure images field is populated
    }
    
    // Ensure ID is int
    $row['id'] = (int)$row['id'];
    
    return $row;
}

function getSingleRequest($conn, $id) {
    $stmt = $conn->prepare("SELECT * FROM callback_requests WHERE id = ? LIMIT 1");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    $data = $result->fetch_assoc();

    if (!$data) {
        sendError('Callback request not found.', 404);
    }

    sendSuccess($data);
}

function updateCallbackRequest($conn, $id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Check if exists
    $checkStmt = $conn->prepare("SELECT id FROM callback_requests WHERE id = ?");
    $checkStmt->bind_param("i", $id);
    $checkStmt->execute();
    if ($checkStmt->get_result()->num_rows === 0) {
        sendError('Callback request not found.', 404);
    }

    $fields = [];
    $types = "";
    $params = [];
    $allowedFields = ['contact_reason', 'assigned_to', 'status', 'notes'];
    
    foreach ($allowedFields as $field) {
        if (isset($input[$field])) {
            $fields[] = "$field = ?";
            $types .= "s";
            $params[] = $input[$field];
        }
    }

    if (empty($fields)) {
        sendError('No valid fields provided for update', 400);
    }

    $sql = "UPDATE callback_requests SET " . implode(", ", $fields) . " WHERE id = ?";
    $types .= "i";
    $params[] = $id;

    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        getSingleRequest($conn, $id);
    } else {
        sendError('Failed to update request', 500);
    }
}

function updateStatus($conn, $id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['status'])) {
        sendError('Status is required', 400);
    }

    // Validate against DB Enum values
    $validStatuses = [
        'Pending', 'Contacted', 'Resolved', 'Ringing / Call Busy', 
        'Disconnected', 'Callback', 'Swtiched Off / Out of Service or Network', 
        'Interested', 'Not Interested', 'Future Prospects'
    ];
    
    // Also allow lowercase or mapped values if needed, but strict is safer for now
    // Or map common simple values to Enum values
    $statusMap = [
        'pending' => 'Pending',
        'completed' => 'Resolved',
        'cancelled' => 'Not Interested', // Mapping example
        'callback' => 'Callback'
    ];
    
    $status = $input['status'];
    if (isset($statusMap[strtolower($status)])) {
        $status = $statusMap[strtolower($status)];
    }
    
    if (!in_array($status, $validStatuses)) {
        // If not in strict list, check if it's a valid enum value anyway
        // For now, let's trust the input if it matches one of the valid ones
        // If not, maybe return error or try to save (DB will error if strict SQL mode)
    }

    $stmt = $conn->prepare("UPDATE callback_requests SET status = ? WHERE id = ?");
    $stmt->bind_param("si", $status, $id);

    if ($stmt->execute()) {
        sendSuccess(null, 'Status updated successfully.');
    } else {
        sendError('Database error: ' . $stmt->error, 500);
    }
}

function storeCallbackRequest($conn, $user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$user) {
        sendError('User not authenticated', 401);
    }

    if (empty($input['contact_reason'])) {
        sendError('contact_reason is required', 400);
    }

    $uniqueId = $user['unique_id'] ?? ('CB' . time());
    $userName = $user['name'];
    $mobile = $user['mobile'];
    $reason = $input['contact_reason'];
    $role = $user['role'];
    $status = 'Pending';
    $createdAt = date('Y-m-d H:i:s');

    $sql = "INSERT INTO callback_requests (unique_id, user_name, mobile_number, request_date_time, contact_reason, app_type, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sssssssss", $uniqueId, $userName, $mobile, $createdAt, $reason, $role, $status, $createdAt, $createdAt);

    if ($stmt->execute()) {
        $newId = $stmt->insert_id;
        
        // Send Email Logic
        $to = 'vikasharma76122@gmail.com';
        $subject = 'New Callback Request';
        $message = "User: $userName\nMobile: $mobile\nReason: $reason";
        $headers = 'From: no-reply@truckmitr.com' . "\r\n" .
                   'X-Mailer: PHP/' . phpversion();
        @mail($to, $subject, $message, $headers);

        $stmt = $conn->prepare("SELECT * FROM callback_requests WHERE id = ?");
        $stmt->bind_param("i", $newId);
        $stmt->execute();
        $newData = $stmt->get_result()->fetch_assoc();
        
        sendSuccess($newData, 'Callback request submitted successfully');
    } else {
        sendError('Failed to create request: ' . $stmt->error, 500);
    }
}

function exportCallbackRequests($conn) {
    $fromDate = $_GET['from_date'] ?? null;
    $toDate = $_GET['to_date'] ?? null;

    if (!$fromDate || !$toDate) {
        sendError('from_date and to_date are required', 400);
    }

    $toDate = date('Y-m-d 23:59:59', strtotime($toDate));
    $fromDate = date('Y-m-d 00:00:00', strtotime($fromDate));

    $sql = "SELECT * FROM callback_requests WHERE created_at BETWEEN ? AND ? ORDER BY created_at DESC";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $fromDate, $toDate);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $data = $result->fetch_all(MYSQLI_ASSOC);
    
    sendSuccess($data, 'Export data fetched successfully');
}

function calculateProfileCompletion($user) {
    $requiredFields = [];
    $role = $user['role'] ?? '';

    if ($role === 'driver') {
        $requiredFields = [
            'name', 'email', 'city', 'unique_id', 'id', 'status', 'sex', 'vehicle_type',
            'father_name', 'images', 'address', 'dob', 'role', 'created_at', 'updated_at',
            'type_of_license', 'driving_experience', 'highest_education', 'license_number',
            'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
            'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
            'driving_license', 'previous_employer', 'job_placement'
        ];
    } elseif ($role === 'transporter') {
        $requiredFields = [
            'name', 'email', 'unique_id', 'id', 'transport_name', 'year_of_establishment',
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
        $decodedJson = json_decode($value, true);

        if (is_array($decodedJson) && count($decodedJson) > 0) {
            $filledFields++;
        } elseif (!is_null($value) && $value !== '' && $value !== '[]') {
            $filledFields++;
        }
    }

    $completionPercentage = ($filledFields / $totalFields) * 100;
    return round($completionPercentage);
}
?>

