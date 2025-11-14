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
    // Get only leads that don't have call logs (not in history)
    // Exclude leads where a call log exists with matching mobile number and tc_for = 'social-media'
    // Use COLLATE to fix collation mismatch
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
        
        echo json_encode([
            'success' => true,
            'message' => 'Social media leads fetched successfully.',
            'data' => $leads,
            'debug' => [
                'query_used' => 'LEFT JOIN with COLLATE',
                'total_leads' => count($leads),
                'file_modified' => date('Y-m-d H:i:s', filemtime(__FILE__))
            ]
        ]);
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
