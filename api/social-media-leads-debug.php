<?php
/**
 * Social Media Leads API - DEBUG VERSION
 * Fetches social media leads from database with detailed logging
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

$debugLog = [];

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Database connection failed: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    $conn->query("SET time_zone = '+05:30'");
    $debugLog[] = "✅ Database connected";
    
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
$debugLog[] = "Action: $action";

if ($action === 'get_social_media_leads') {
    // Authentication check - verify user has tc_for = 'social-media'
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    $debugLog[] = "User ID from request: $userId";
    
    if ($userId === 0) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Authentication required. User ID not provided.',
            'debug' => $debugLog
        ]);
        exit;
    }
    
    // First, try to find user in admins table by ID
    $authSql = "SELECT id, name, mobile, tc_for FROM admins WHERE id = ? LIMIT 1";
    $authStmt = $conn->prepare($authSql);
    $authStmt->bind_param('i', $userId);
    $authStmt->execute();
    $authResult = $authStmt->get_result();
    
    $debugLog[] = "Checked admins table by ID $userId: " . $authResult->num_rows . " rows";
    
    $user = null;
    
    // If not found by ID, try to find by matching mobile number in users table
    if ($authResult->num_rows === 0) {
        $authStmt->close();
        $debugLog[] = "User not found in admins by ID, checking users table...";
        
        // Get mobile from users table
        $userSql = "SELECT mobile FROM users WHERE id = ? LIMIT 1";
        $userStmt = $conn->prepare($userSql);
        $userStmt->bind_param('i', $userId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        
        $debugLog[] = "Checked users table by ID $userId: " . $userResult->num_rows . " rows";
        
        if ($userResult->num_rows > 0) {
            $userData = $userResult->fetch_assoc();
            $mobile = $userData['mobile'];
            $userStmt->close();
            
            $debugLog[] = "Found mobile in users table: $mobile";
            
            // Now find in admins table by mobile
            $authSql2 = "SELECT id, name, mobile, tc_for FROM admins WHERE mobile = ? LIMIT 1";
            $authStmt2 = $conn->prepare($authSql2);
            $authStmt2->bind_param('s', $mobile);
            $authStmt2->execute();
            $authResult2 = $authStmt2->get_result();
            
            $debugLog[] = "Checked admins table by mobile $mobile: " . $authResult2->num_rows . " rows";
            
            if ($authResult2->num_rows > 0) {
                $user = $authResult2->fetch_assoc();
                $debugLog[] = "✅ Found user in admins: ID=" . $user['id'] . ", tc_for=" . $user['tc_for'];
            } else {
                $debugLog[] = "❌ No admin found with mobile $mobile";
            }
            $authStmt2->close();
        } else {
            $userStmt->close();
            $debugLog[] = "❌ No user found in users table with ID $userId";
        }
    } else {
        $user = $authResult->fetch_assoc();
        $authStmt->close();
        $debugLog[] = "✅ Found user directly in admins: ID=" . $user['id'] . ", tc_for=" . $user['tc_for'];
    }
    
    // If still no user found
    if ($user === null) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'User not found in social media system.',
            'debug' => $debugLog
        ]);
        exit;
    }
    
    // Check if user has social-media access
    $debugLog[] = "Checking tc_for: '" . $user['tc_for'] . "' vs 'social-media'";
    $debugLog[] = "Lowercase comparison: '" . strtolower($user['tc_for']) . "' === 'social-media'";
    
    if (strtolower($user['tc_for']) !== 'social-media') {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Access denied. This feature is only available to users assigned to Social Media leads.',
            'user_tc_for' => $user['tc_for'],
            'user_mobile' => $user['mobile'],
            'debug' => $debugLog
        ]);
        exit;
    }
    
    $debugLog[] = "✅ Access granted!";
    
    // Get only leads that don't have call logs (not in history)
    $sql = "SELECT sml.* 
            FROM social_media_leads sml
            LEFT JOIN call_logs cl ON sml.mobile COLLATE utf8mb4_unicode_ci = cl.user_number COLLATE utf8mb4_unicode_ci
                AND cl.tc_for = 'social-media'
            WHERE cl.id IS NULL
            ORDER BY sml.created_at DESC 
            LIMIT 100";
    
    $result = $conn->query($sql);
    
    if ($result) {
        $leads = [];
        while ($row = $result->fetch_assoc()) {
            $leads[] = $row;
        }
        
        $debugLog[] = "✅ Fetched " . count($leads) . " leads";
        
        echo json_encode([
            'success' => true,
            'message' => 'Social media leads fetched successfully.',
            'data' => $leads,
            'debug' => $debugLog
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $conn->error,
            'sql' => $sql,
            'debug' => $debugLog
        ]);
    }
} else {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid action',
        'debug' => $debugLog
    ]);
}

$conn->close();
?>
