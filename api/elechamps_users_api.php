<?php
/**
 * Elechamps Users API
 * 
 * Returns users assigned to a specific admin (telecaller) for the elechamps system
 * 
 * Endpoint: /api/elechamps_users_api.php?admin_id=8
 * OR via route: /api/telehead/elechamps/{admin_id}/users
 */

// Include config for database connection
require_once __DIR__ . '/config.php';

// Get database connection
$conn = getDBConnection();

// Get admin ID from query parameter or URL path
$adminId = null;

// Try to get from query parameter first
if (isset($_GET['admin_id'])) {
    $adminId = intval($_GET['admin_id']);
}

// Try to parse from URL path (for route: /api/telehead/elechamps/{admin_id}/users)
if (!$adminId && isset($_SERVER['REQUEST_URI'])) {
    $uri = $_SERVER['REQUEST_URI'];
    if (preg_match('/\/elechamps\/(\d+)\/users/', $uri, $matches)) {
        $adminId = intval($matches[1]);
    }
}

if (!$adminId) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'Admin ID is required'
    ]);
    exit;
}

// Pagination parameters
$page = isset($_GET['page']) ? intval($_GET['page']) : 1;
$perPage = isset($_GET['per_page']) ? intval($_GET['per_page']) : 10;
$offset = ($page - 1) * $perPage;

try {
    // Get admin details
    $adminQuery = "SELECT id, name FROM admins WHERE id = ? LIMIT 1";
    $adminStmt = $conn->prepare($adminQuery);
    $adminStmt->bind_param('i', $adminId);
    $adminStmt->execute();
    $adminResult = $adminStmt->get_result();
    $admin = $adminResult->fetch_assoc();
    
    if (!$admin) {
        http_response_code(404);
        echo json_encode([
            'status' => 'error',
            'message' => 'Admin not found'
        ]);
        exit;
    }
    
    // Count total users assigned to this admin
    $countQuery = "SELECT COUNT(*) as total FROM users WHERE assigned_to = ?";
    $countStmt = $conn->prepare($countQuery);
    $countStmt->bind_param('i', $adminId);
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $countRow = $countResult->fetch_assoc();
    $totalUsers = $countRow['total'];
    
    // Calculate pagination
    $lastPage = ceil($totalUsers / $perPage);
    
    // Get users assigned to this admin with pagination
    $query = "
        SELECT 
            u.id,
            u.assigned_to,
            u.unique_id,
            u.sub_id,
            u.role,
            u.name,
            u.name_eng,
            u.mobile,
            u.email,
            u.city,
            u.states,
            u.pincode,
            u.address,
            u.images,
            u.avatar,
            u.Father_Name,
            u.DOB,
            u.vehicle_type,
            u.Sex,
            u.Marital_Status,
            u.Highest_Education,
            u.Driving_Experience,
            u.Type_of_License,
            u.License_Number,
            u.Expiry_date_of_License,
            u.Preferred_Location,
            u.Current_Monthly_Income,
            u.Expected_Monthly_Income,
            u.Aadhar_Number,
            u.job_placement,
            u.previous_employer,
            u.Aadhar_Photo,
            u.Driving_License,
            u.Transport_Name,
            u.Year_of_Establishment,
            u.Registered_ID,
            u.PAN_Number,
            u.GST_Number,
            u.Fleet_Size,
            u.Operational_Segment,
            u.Average_KM,
            u.Referral_Code,
            u.PAN_Image,
            u.GST_Certificate,
            u.status,
            u.Created_at,
            u.Updated_at,
            u.driver_completion,
            u.user_lang,
            COALESCE(u.driver_completion, 0) as profile_completion
        FROM users u
        WHERE u.assigned_to = ?
        ORDER BY u.Created_at DESC
        LIMIT ? OFFSET ?
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('iii', $adminId, $perPage, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
    
    // Return response
    echo json_encode([
        'status' => 'success',
        'admin_id' => $adminId,
        'admin_name' => $admin['name'],
        'assigned_user_count' => $totalUsers,
        'current_page' => $page,
        'per_page' => $perPage,
        'last_page' => $lastPage,
        'users' => $users
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
