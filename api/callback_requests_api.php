<?php
/**
 * Callback Requests API (Core PHP Version)
 * Handles fetching, creating, and updating callback requests
 */

// 1. Include Configuration
require_once 'config.php';

// 2. Set Content Type
header('Content-Type: application/json');

// 3. Route Request based on Method and Action
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';
$id = $_GET['id'] ?? null;

// 4. Authenticate User (Basic Token Check Implementation)
// In a real scenario, you would decode a JWT here.
// For this script, we assume the user ID or Unique ID is passed in headers or params for context.
// YOU MUST IMPLEMENT ROBUST AUTH LOGIC HERE matching your app's auth system.
$currentUser = authenticateUser($conn); 

try {
    switch ($method) {
        case 'GET':
            if ($action === 'index') {
                getCallbackRequests($conn, $currentUser);
            } elseif ($action === 'show' && $id) {
                getSingleRequest($conn, $id);
            } elseif ($action === 'export') {
                // Export usually returns a file, requiring headers adjustment. 
                // Simplified here to return JSON data for the frontend to generate CSV/Excel.
                exportCallbackRequests($conn);
            } else {
                sendError('Invalid GET action or missing ID', 400);
            }
            break;

        case 'POST':
            if ($action === 'store') {
                storeCallbackRequest($conn, $currentUser);
            } elseif ($action === 'update' && $id) {
                updateCallbackRequest($conn, $id);
            } elseif ($action === 'update_status' && $id) {
                updateStatus($conn, $id);
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

/**
 * Mock Authentication function
 * In Core PHP, you likely read headers for a Bearer token and query the users table.
 */
function authenticateUser($conn) {
    // 1. Get headers
    $headers = getallheaders();
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
    
    // 3. Check for regular user authentication (from users table)
    $userId = $_REQUEST['auth_user_id'] ?? null;
    if ($userId) {
        $stmt = $conn->prepare("SELECT * FROM users WHERE id = ? LIMIT 1");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->fetch_assoc();
    }
    
    // No authentication provided
    return null;
}

/**
 * ✅ API: Fetch all callback requests for user
 */
function getCallbackRequests($conn, $user) {
    if (!$user) {
        sendError('User not authenticated.', 401);
    }


    $role = $user['role'] ?? null;
    $tc_for = $user['tc_for'] ?? null;
    $userId = $user['id'];
    
    // Optional filter by specific telecaller ID
    $filterTelecallerId = $_GET['telecaller_id'] ?? null;

    // Only show callback requests assigned to telecallers 17 and 18 (tc_for = 'call-back')
    $sql = "SELECT cr.* FROM callback_requests cr 
            WHERE cr.assigned_to IN (17, 18) ";
    
    // Logic based on role
    if ($role === 'telecaller' && $tc_for === 'call-back') {
        // Telecallers can only see their own assigned requests
        if (!in_array($userId, [17, 18])) {
            sendError('Access denied. Only telecallers 17 and 18 can access callback requests.', 403);
        }
        $sql .= " AND cr.assigned_to = ? ORDER BY cr.created_at DESC";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $userId);
    } elseif (in_array($role, ['admin', 'manager'])) {
        // Admins/managers can optionally filter by telecaller ID
        if ($filterTelecallerId && in_array($filterTelecallerId, [17, 18])) {
            $sql .= " AND cr.assigned_to = ? ORDER BY cr.created_at DESC";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $filterTelecallerId);
        } else {
            $sql .= " ORDER BY cr.created_at DESC";
            $stmt = $conn->prepare($sql); // No params needed
        }
    } else {
        sendError('Access denied.', 403);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    
    $data = [];
    while ($row = $result->fetch_assoc()) {
        // Append profile completion and subscription date
        // We need to fetch the related user for this specific callback request
        $uniqueId = $row['unique_id'];
        
        // Fetch related user
        $userSql = "SELECT * FROM users WHERE unique_id = ? LIMIT 1";
        $uStmt = $conn->prepare($userSql);
        $uStmt->bind_param("s", $uniqueId);
        $uStmt->execute();
        $relatedUser = $uStmt->get_result()->fetch_assoc();

        $profileCompletion = $relatedUser ? calculateProfileCompletion($relatedUser) . '%' : '0%';
        
        // Fetch subscription date (Latest payment)
        $subDate = 'N/A';
        if ($relatedUser) {
             $paySql = "SELECT created_at FROM payments 
                        WHERE unique_id = ? 
                        ORDER BY created_at DESC LIMIT 1";
             $pStmt = $conn->prepare($paySql);
             $pStmt->bind_param("s", $relatedUser['unique_id']);
             $pStmt->execute();
             $payResult = $pStmt->get_result()->fetch_assoc();
             if ($payResult) {
                 $subDate = date('Y-m-d', strtotime($payResult['created_at']));
             }
        }

        $row['profile_completion'] = $profileCompletion;
        $row['subscribe_date'] = $subDate;
        
        $data[] = $row;
    }

    sendSuccess($data, 'Callback requests fetched successfully.');
}

/**
 * ✅ API: Fetch single callback request by ID
 */
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

/**
 * ✅ API: Update callback request
 */
function updateCallbackRequest($conn, $id) {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Check if exists
    $checkStmt = $conn->prepare("SELECT id FROM callback_requests WHERE id = ?");
    $checkStmt->bind_param("i", $id);
    $checkStmt->execute();
    if ($checkStmt->get_result()->num_rows === 0) {
        sendError('Callback request not found.', 404);
    }

    // Build Update Query dynamically
    $fields = [];
    $types = "";
    $params = [];

    // Only allow specific fields
    $allowedFields = ['contact_reason', 'assigned_to', 'status'];
    
    foreach ($allowedFields as $field) {
        if (isset($input[$field])) {
            $fields[] = "$field = ?";
            $types .= "s"; // Assuming strings for simplicity, adjust if assigned_to is int
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
        // Fetch updated data
        getSingleRequest($conn, $id);
    } else {
        sendError('Failed to update request', 500);
    }
}

/**
 * ✅ API: Update only status
 */
function updateStatus($conn, $id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['status'])) {
        sendError('Status is required', 400);
    }

    $validStatuses = ['pending', 'in-progress', 'completed', 'cancelled'];
    if (!in_array($input['status'], $validStatuses)) {
        sendError('Invalid status value', 400);
    }

    $stmt = $conn->prepare("UPDATE callback_requests SET status = ? WHERE id = ?");
    $stmt->bind_param("si", $input['status'], $id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows === 0) {
             // Check if ID existed
             $check = $conn->query("SELECT id FROM callback_requests WHERE id = $id");
             if ($check->num_rows === 0) sendError('Callback request not found', 404);
        }
        sendSuccess(null, 'Status updated successfully.');
    } else {
        sendError('Database error', 500);
    }
}

/**
 * ✅ API: Store new callback request
 */
function storeCallbackRequest($conn, $user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$user) {
        sendError('User not authenticated', 401);
    }

    if (empty($input['contact_reason'])) {
        sendError('contact_reason is required', 400);
    }

    $uniqueId = $user['unique_id'] ?? ('CB' . time()); // Fallback if empty
    $userName = $user['name'];
    $mobile = $user['mobile'];
    $reason = $input['contact_reason'];
    $role = $user['role'];
    $status = 'pending';
    $createdAt = date('Y-m-d H:i:s'); // Now uses IST from config.php

    $sql = "INSERT INTO callback_requests (unique_id, user_name, mobile_number, request_date_time, contact_reason, app_type, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sssssssss", $uniqueId, $userName, $mobile, $createdAt, $reason, $role, $status, $createdAt, $createdAt);

    if ($stmt->execute()) {
        $newId = $stmt->insert_id;
        
        // Send Email Logic (Simplified for Core PHP)
        // Note: Core PHP mail() is simple, for robust mailing use PHPMailer
        $to = 'vikasharma76122@gmail.com';
        $subject = 'New Callback Request';
        $message = "User: $userName\nMobile: $mobile\nReason: $reason";
        $headers = 'From: no-reply@truckmitr.com' . "\r\n" .
                   'X-Mailer: PHP/' . phpversion();

        // Suppress warning if mail server not configured on localhost
        @mail($to, $subject, $message, $headers);

        // Return created object
        $stmt = $conn->prepare("SELECT * FROM callback_requests WHERE id = ?");
        $stmt->bind_param("i", $newId);
        $stmt->execute();
        $newData = $stmt->get_result()->fetch_assoc();
        
        sendSuccess($newData, 'Callback request submitted successfully');
    } else {
        sendError('Failed to create request: ' . $stmt->error, 500);
    }
}

/**
 * ✅ API: Export callback requests
 * Returns JSON data. Frontend should convert to Excel/CSV.
 */
function exportCallbackRequests($conn) {
    $fromDate = $_GET['from_date'] ?? null;
    $toDate = $_GET['to_date'] ?? null;

    if (!$fromDate || !$toDate) {
        sendError('from_date and to_date are required', 400);
    }

    // Add time to cover the full end date
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

/**
 * ✅ Helper function to calculate profile completion %
 * (Adapted from your Laravel code)
 */
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

        // Decode JSON if the field is stored as a JSON string in DB
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