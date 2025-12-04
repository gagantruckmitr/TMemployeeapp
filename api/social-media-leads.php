<?php
/**
 * Social Media Leads API
 * Fetches social media leads from database
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Database connection failed: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    $conn->query("SET time_zone = '+05:30'");
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($action === 'get_social_media_leads') {
    // Authentication check - verify user has tc_for = 'social-media'
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    if ($userId === 0) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Authentication required. User ID not provided.'
        ]);
        exit;
    }
    
    // First, try to find user in admins table by ID
    $authSql = "SELECT id, name, mobile, tc_for FROM admins WHERE id = ? LIMIT 1";
    $authStmt = $conn->prepare($authSql);
    $authStmt->bind_param('i', $userId);
    $authStmt->execute();
    $authResult = $authStmt->get_result();
    
    $user = null;
    
    // If not found by ID, try to find by matching mobile number in users table
    if ($authResult->num_rows === 0) {
        $authStmt->close();
        
        // Get mobile from users table
        $userSql = "SELECT mobile FROM users WHERE id = ? LIMIT 1";
        $userStmt = $conn->prepare($userSql);
        $userStmt->bind_param('i', $userId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        
        if ($userResult->num_rows > 0) {
            $userData = $userResult->fetch_assoc();
            $mobile = $userData['mobile'];
            $userStmt->close();
            
            // Now find in admins table by mobile
            $authSql2 = "SELECT id, name, mobile, tc_for FROM admins WHERE mobile = ? LIMIT 1";
            $authStmt2 = $conn->prepare($authSql2);
            $authStmt2->bind_param('s', $mobile);
            $authStmt2->execute();
            $authResult2 = $authStmt2->get_result();
            
            if ($authResult2->num_rows > 0) {
                $user = $authResult2->fetch_assoc();
            }
            $authStmt2->close();
        } else {
            $userStmt->close();
        }
    } else {
        $user = $authResult->fetch_assoc();
        $authStmt->close();
    }
    
    // If still no user found
    if ($user === null) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'User not found in system.'
        ]);
        exit;
    }
    
    // All telecallers can access social media leads
    // No tc_for restriction - access is controlled by assigned_id
    
    // Get the admin ID for filtering assigned leads
    $adminId = $user['id'];
    
    // Get only leads that:
    // 1. Are assigned to this telecaller (assigned_id matches admin id)
    // 2. Don't have call logs (not in history)
    // Exclude leads where a call log exists with matching mobile number and tc_for = 'social-media'
    // Use COLLATE to fix collation mismatch
    $sql = "SELECT sml.* 
            FROM social_media_leads sml
            LEFT JOIN call_logs cl ON sml.mobile COLLATE utf8mb4_unicode_ci = cl.user_number COLLATE utf8mb4_unicode_ci
                AND cl.tc_for = 'social-media'
            WHERE cl.id IS NULL
                AND sml.assigned_id = ?
            ORDER BY sml.created_at DESC 
            LIMIT 100";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param('i', $adminId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result) {
        $leads = [];
        while ($row = $result->fetch_assoc()) {
            $leads[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Social media leads fetched successfully.',
            'data' => $leads,
            'debug' => [
                'query_used' => 'LEFT JOIN with COLLATE and assigned_id filter',
                'total_leads' => count($leads),
                'admin_id' => $adminId,
                'file_modified' => date('Y-m-d H:i:s', filemtime(__FILE__))
            ]
        ]);
        $stmt->close();
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $conn->error,
            'sql' => $sql
        ]);
    }
} else {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid action'
    ]);
}

$conn->close();
?>