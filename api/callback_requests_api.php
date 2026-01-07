<?php
/**
 * Callback Requests API
 * Handles fetching, creating, and updating callback requests
 */

// 1. Include Configuration
require_once 'config.php';
require_once 'profile_completion_helper.php';

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
                // Check if content type is form-urlencoded or JSON
                $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
                
                if (strpos($contentType, 'application/json') !== false) {
                    $input = json_decode(file_get_contents('php://input'), true);
                } else {
                    $input = $_POST;
                }
                
                // Try multiple field names for compatibility
                $targetId = $id ?? ($input['request_id'] ?? ($input['callback_id'] ?? ($input['id'] ?? null)));
                
                if ($targetId) {
                    updateStatus($conn, $targetId);
                } else {
                    error_log("update_status: No ID found. Query ID: $id, POST: " . print_r($_POST, true));
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
    
    // Group by unique_id to avoid duplicate cards for same user
    $groupedData = [];
    $allRequests = [];
    
    while ($row = $result->fetch_assoc()) {
        $allRequests[] = $row;
    }
    
    // Group requests by unique_id
    foreach ($allRequests as $row) {
        $uniqueId = $row['unique_id'];
        
        if (!isset($groupedData[$uniqueId])) {
            // First request for this user - use as main card
            $enriched = enrichRequestData($conn, $row);
            $enriched['callback_history'] = []; // Initialize history array
            $groupedData[$uniqueId] = $enriched;
        }
        
        // Add this request to the user's callback history
        $groupedData[$uniqueId]['callback_history'][] = [
            'id' => $row['id'],
            'contact_reason' => $row['contact_reason'],
            'request_date_time' => $row['request_date_time'],
            'status' => $row['status'],
            'notes' => $row['notes'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at']
        ];
    }
    
    // Convert to indexed array and add callback count
    $data = array_values($groupedData);
    foreach ($data as &$item) {
        $item['callback_requests_count'] = count($item['callback_history']);
    }
    
    sendSuccess($data, 'Callback requests fetched successfully.');
}

/**
 * Fetch history of calls made by this user for callback requests only
 */
function getCallbackHistory($conn, $user) {
    if (!$user) {
        sendError('User not authenticated.', 401);
    }

    $userId = $user['id'];
    $role = $user['role'] ?? null;
    
    // Fetch callback requests with their latest call log feedback
    // Join with call_logs to get feedback information
    // IMPORTANT: Join on users.id (not callback_requests.id)
    
    $sql = "SELECT 
                cr.*,
                u.id as user_id,
                cl.feedback as call_feedback,
                cl.remarks as call_remarks,
                cl.call_time as last_call_time
            FROM callback_requests cr
            LEFT JOIN users u ON cr.unique_id = u.unique_id
            LEFT JOIN call_logs cl ON cl.user_id = u.id 
                AND cl.call_source = 'callback_requests'
                AND cl.id = (
                    SELECT id FROM call_logs 
                    WHERE user_id = u.id 
                    AND call_source = 'callback_requests'
                    ORDER BY call_time DESC 
                    LIMIT 1
                )
            WHERE 1=1";
    $params = [];
    $types = "";

    // Logic based on role
    if (strtolower($role) === 'telecaller') {
        // Telecallers can only see their own callback history
        $sql .= " AND cr.assigned_to = ? AND cr.status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')";
        $params[] = $userId;
        $types .= "i";
    } elseif (in_array(strtolower($role), ['admin', 'manager'])) {
        // Admins/managers can see all callback history
        $sql .= " AND cr.status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')";
    } else {
        // For any other role, show their assigned callback history
        $sql .= " AND cr.assigned_to = ? AND cr.status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')";
        $params[] = $userId;
        $types .= "i";
    }

    $sql .= " ORDER BY cr.updated_at DESC LIMIT 50";

    $stmt = $conn->prepare($sql);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->get_result();
    
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $enriched = enrichRequestData($conn, $row, true);
        
        // Add call log feedback if available
        if (!empty($row['call_feedback'])) {
            $enriched['call_feedback'] = $row['call_feedback'];
        }
        if (!empty($row['call_remarks'])) {
            $enriched['call_remarks'] = $row['call_remarks'];
        }
        if (!empty($row['last_call_time'])) {
            $enriched['last_call_time'] = $row['last_call_time'];
        }
        
        $data[] = $enriched;
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
    $appliedJobsCount = 0;
    $callHistoryCount = 0;
    $trainingStatus = 'Not Completed';
    $assignedTelecaller = 'N/A';
    $registrationDate = null;
    $appliedJobs = [];
    $callHistory = [];

    if ($uniqueId) {
        try {
        // Fetch related user with ALL fields needed for profile completion calculation
        // Explicitly select fields to ensure we get the correct field names
        $userSql = "SELECT 
                        id, unique_id, name, email, mobile, city, states, status, role, assigned_to, Created_at,
                        sex, vehicle_type, father_name, images, address, dob,
                        type_of_license, driving_experience, highest_education, license_number,
                        expiry_date_of_license, expected_monthly_income, current_monthly_income,
                        marital_status, preferred_location, aadhar_number, aadhar_photo,
                        driving_license, previous_employer, job_placement,
                        transport_name, year_of_establishment, fleet_size, operational_segment,
                        average_km, pan_number, pan_image, gst_certificate
                    FROM users WHERE unique_id = ? LIMIT 1";
        $uStmt = $conn->prepare($userSql);
        $uStmt->bind_param("s", $uniqueId);
        $uStmt->execute();
        $relatedUser = $uStmt->get_result()->fetch_assoc();

        if ($relatedUser) {
            // Use the shared helper function for consistent calculation
            $userId = $relatedUser['id'];
            $profileData = getProfileCompletionData($conn, $userId);
            $calculatedPercentage = $profileData['percentage'];
            $profileCompletion = $calculatedPercentage . '%';
            $userName = $relatedUser['name'] ?? 'Unknown';
            $userRole = $relatedUser['role'] ?? 'Unknown';
            error_log("✅ Profile completion for $userName (user_id: $userId, unique_id: $uniqueId, role: $userRole): $profileCompletion (calculated: $calculatedPercentage)");
            
            // Get actual registration date from users table (use Created_at which is the actual field name)
            if (!empty($relatedUser['Created_at'])) {
                $registrationDate = $relatedUser['Created_at'];
            } elseif (!empty($relatedUser['created_at'])) {
                $registrationDate = $relatedUser['created_at'];
            }
        } else {
            error_log("❌ No user found with unique_id: $uniqueId for callback request");
        }
            
            // Fetch subscription date
            $paySql = "SELECT created_at FROM payments 
                       WHERE unique_id = ? 
                       AND payment_status = 'captured'
                       ORDER BY created_at DESC LIMIT 1";
            $pStmt = $conn->prepare($paySql);
            $pStmt->bind_param("s", $uniqueId);
            $pStmt->execute();
            $payResult = $pStmt->get_result()->fetch_assoc();
            if ($payResult) {
                $subDate = date('Y-m-d', strtotime($payResult['created_at']));
            }
            
            // Parse profile picture - same logic as search_users_api.php
            if (!empty($relatedUser['images'])) {
                $images = json_decode($relatedUser['images'], true);
                if (is_array($images) && count($images) > 0) {
                    $imagePath = $images[0];
                    // Construct full URL with base URL
                    $profileImage = 'https://truckmitr.com/public/' . $imagePath;
                } elseif (!is_array($images) && is_string($relatedUser['images'])) {
                    // Handle case where images is a plain string, not JSON
                    $profileImage = 'https://truckmitr.com/public/' . $relatedUser['images'];
                }
            }
            
            // Get applied jobs list (use applyjobs table which is the correct table name)
            $jobsSql = "SELECT 
                            aj.id as application_id,
                            aj.job_id,
                            aj.created_at as applied_date,
                            j.job_id as job_code,
                            j.job_title,
                            j.job_location as location
                        FROM applyjobs aj
                        LEFT JOIN jobs j ON aj.job_id = j.id
                        WHERE aj.driver_id = ?
                        ORDER BY aj.created_at DESC
                        LIMIT 50";
            $jStmt = $conn->prepare($jobsSql);
            $userId = $relatedUser['id'];
            $jStmt->bind_param("i", $userId);
            $jStmt->execute();
            $jobsResult = $jStmt->get_result();
            $appliedJobs = [];
            while ($job = $jobsResult->fetch_assoc()) {
                $appliedJobs[] = $job;
            }
            $appliedJobsCount = count($appliedJobs);
            
            // Get call history list (all calls with feedback, not pending)
            $callsSql = "SELECT 
                            cl.id,
                            cl.caller_id,
                            a.name as telecaller_name,
                            cl.call_status,
                            cl.feedback,
                            cl.remarks,
                            cl.call_time,
                            cl.call_duration,
                            cl.recording_url,
                            cl.manual_call_recording_url,
                            cl.created_at
                        FROM call_logs cl
                        LEFT JOIN admins a ON cl.caller_id = a.id
                        WHERE cl.user_id = ? 
                        AND cl.call_status != 'pending'
                        AND (cl.feedback IS NOT NULL AND cl.feedback != '' AND cl.feedback != 'pending')
                        ORDER BY cl.call_time DESC
                        LIMIT 50";
            $cStmt = $conn->prepare($callsSql);
            $cStmt->bind_param("i", $userId);
            $cStmt->execute();
            $callsResult = $cStmt->get_result();
            $callHistory = [];
            while ($call = $callsResult->fetch_assoc()) {
                $callHistory[] = $call;
            }
            $callHistoryCount = count($callHistory);
            
            // Get training status (check if training is completed)
            // Try to get training status, but don't fail if table doesn't exist
            try {
                $trainingSql = "SELECT COUNT(*) as count FROM training WHERE unique_id = ? AND status = 'completed'";
                $tStmt = $conn->prepare($trainingSql);
                if ($tStmt) {
                    $tStmt->bind_param("s", $uniqueId);
                    $tStmt->execute();
                    $trainingResult = $tStmt->get_result()->fetch_assoc();
                    if ($trainingResult && $trainingResult['count'] > 0) {
                        $trainingStatus = 'Completed';
                    } else {
                        $trainingStatus = 'Not Completed';
                    }
                }
            } catch (Exception $e) {
                // Training table might not exist, default to Not Completed
                $trainingStatus = 'Not Completed';
                error_log("Training query error: " . $e->getMessage());
            }
            
            // Get assigned telecaller from users.assigned_to (NOT callback_requests.assigned_to)
            // This matches the logic in search_users_api.php
            if (!empty($relatedUser['assigned_to'])) {
                $assignedToId = $relatedUser['assigned_to'];
                $tcSql = "SELECT name FROM admins WHERE id = ? LIMIT 1";
                $tcStmt = $conn->prepare($tcSql);
                $tcStmt->bind_param("i", $assignedToId);
                $tcStmt->execute();
                $tcResult = $tcStmt->get_result()->fetch_assoc();
                if ($tcResult) {
                    $assignedTelecaller = $tcResult['name'];
                    error_log("✅ Assigned telecaller for {$relatedUser['name']}: $assignedTelecaller (ID: $assignedToId from users.assigned_to)");
                } else {
                    error_log("❌ No admin found with ID: $assignedToId for user {$relatedUser['name']}");
                }
            } else {
                error_log("⚠️ No assigned_to value in users table for {$relatedUser['name']} (user_id: {$relatedUser['id']})");
            }
        } catch (Exception $e) {
            // Log error but don't fail the entire request
            error_log("Error enriching callback request data: " . $e->getMessage());
        }
    }

    $row['profile_completion'] = $profileCompletion;
    $row['subscribe_date'] = $subDate;
    $row['images'] = $profileImage; // Always include images field (null if not available)
    
    // Add enriched data
    $row['applied_jobs_count'] = $appliedJobsCount;
    $row['call_history_count'] = $callHistoryCount;
    $row['training_status'] = $trainingStatus;
    $row['assigned_telecaller'] = $assignedTelecaller;
    
    // Add actual lists for the UI
    $row['applied_jobs'] = $appliedJobs ?? [];
    $row['call_history'] = $callHistory ?? [];
    
    // Add user_id for API calls that need it (CRITICAL for call_logs)
    if (isset($relatedUser['id'])) {
        $row['user_id'] = (int)$relatedUser['id'];
        error_log("✅ Set user_id={$relatedUser['id']} for callback request {$row['id']} (unique_id: $uniqueId)");
    } else {
        error_log("⚠️ No user_id found for callback request {$row['id']} (unique_id: $uniqueId)");
    }
    
    // Use actual registration date from users table if available
    if ($registrationDate) {
        $row['registration_date'] = $registrationDate;
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
    // Handle both JSON and form-urlencoded input
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    
    if (strpos($contentType, 'application/json') !== false) {
        $input = json_decode(file_get_contents('php://input'), true);
    } else {
        $input = $_POST;
    }
    
    // Get request_id from input if not provided as parameter
    if (!$id) {
        $id = $input['request_id'] ?? null;
    }
    
    if (!$id) {
        error_log("updateStatus: No ID provided. Input: " . print_r($input, true));
        sendError('Request ID is required', 400);
    }
    
    if (!isset($input['status'])) {
        error_log("updateStatus: No status provided. Input: " . print_r($input, true));
        sendError('Status is required', 400);
    }
    
    error_log("updateStatus: Processing ID=$id, Status=" . $input['status']);

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
        'callback' => 'Callback',
        'contacted' => 'Contacted',
        'resolved' => 'Resolved',
        'interested' => 'Interested',
        'not_interested' => 'Not Interested',
        'future_prospects' => 'Future Prospects'
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

    // Also update notes if provided
    $notes = $input['notes'] ?? null;
    
    if ($notes !== null) {
        $stmt = $conn->prepare("UPDATE callback_requests SET status = ?, notes = ?, updated_at = NOW() WHERE id = ?");
        $stmt->bind_param("ssi", $status, $notes, $id);
    } else {
        $stmt = $conn->prepare("UPDATE callback_requests SET status = ?, updated_at = NOW() WHERE id = ?");
        $stmt->bind_param("si", $status, $id);
    }

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

?>

