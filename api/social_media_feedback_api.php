<?php
/**
 * Social Media Call Feedback API
 * Saves feedback to call_logs table with tc_for from admin table
 */

error_reporting(E_ALL);
ini_set('display_errors', 0); // Disable for production
ini_set('log_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

// Handle GET request for history
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = isset($_GET['action']) ? $_GET['action'] : '';
    
    if ($action === 'get_history') {
        $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
        
        if ($callerId === 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Caller ID required']);
            exit;
        }
        
        $sql = "SELECT * FROM call_logs 
                WHERE caller_id = $callerId 
                AND tc_for = 'social-media'
                ORDER BY created_at DESC 
                LIMIT 100";
        
        $result = $conn->query($sql);
        
        if ($result) {
            $history = [];
            while ($row = $result->fetch_assoc()) {
                $history[] = $row;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'History fetched successfully',
                'data' => $history
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Database error: ' . $conn->error]);
        }
        
        $conn->close();
        exit;
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$rawData = file_get_contents('php://input');
$data = json_decode($rawData, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON']);
    exit;
}

// Extract required fields
$callerId = isset($data['caller_id']) ? (int)$data['caller_id'] : 0;
$leadId = isset($data['lead_id']) ? (int)$data['lead_id'] : 0;
$name = isset($data['name']) ? $conn->real_escape_string(trim($data['name'])) : '';
$mobile = isset($data['mobile']) ? $conn->real_escape_string(trim($data['mobile'])) : '';
$source = isset($data['source']) ? $conn->real_escape_string(trim($data['source'])) : '';
$role = isset($data['role']) ? $conn->real_escape_string(trim($data['role'])) : '';
$feedback = isset($data['feedback']) ? $conn->real_escape_string(trim($data['feedback'])) : '';
$remarks = isset($data['remarks']) ? $conn->real_escape_string(trim($data['remarks'])) : '';

// Validate required fields
if ($callerId === 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Caller ID required']);
    exit;
}

if (empty($mobile)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Mobile number required']);
    exit;
}

if (empty($feedback)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Feedback required']);
    exit;
}

// Set tc_for as 'social-media' for all social media leads
$tcFor = 'social-media';

// Fetch telecaller info from admins table
$callerNumber = null;
$adminQuery = "SELECT mobile FROM admins WHERE id = $callerId LIMIT 1";
$adminResult = $conn->query($adminQuery);

if ($adminResult && $adminResult->num_rows > 0) {
    $adminRow = $adminResult->fetch_assoc();
    $callerNumber = $adminRow['mobile'];
}

// Combine source and role into notes field for reference
$notes = "Source: $source | Role: $role";
if (!empty($remarks)) {
    $notes .= " | Remarks: $remarks";
}

// Insert into call_logs table using correct column names
$sql = "INSERT INTO call_logs 
        (caller_id, tc_for, caller_number, driver_name, user_number, feedback, remarks, notes, call_status, created_at, updated_at) 
        VALUES 
        ($callerId, 
         '$tcFor', 
         " . ($callerNumber ? "'$callerNumber'" : "NULL") . ",
         '$name', 
         '$mobile', 
         '$feedback', 
         " . (!empty($remarks) ? "'$remarks'" : "NULL") . ", 
         '$notes',
         'completed',
         NOW(), 
         NOW())";

if ($conn->query($sql)) {
    $insertId = $conn->insert_id;
    
    // Update social media lead with feedback (only if not already added)
    if ($leadId > 0) {
        // Check if this feedback already exists in remarks
        $checkSql = "SELECT remarks FROM social_media_leads WHERE id = $leadId";
        $checkResult = $conn->query($checkSql);
        
        if ($checkResult && $checkResult->num_rows > 0) {
            $row = $checkResult->fetch_assoc();
            $existingRemarks = $row['remarks'] ?? '';
            
            // Only add feedback if it's not already there
            if (strpos($existingRemarks, "[Feedback: $feedback]") === false) {
                $updateLeadSql = "UPDATE social_media_leads 
                                 SET remarks = CONCAT(COALESCE(remarks, ''), '\n[Feedback: $feedback]'),
                                     updated_at = NOW()
                                 WHERE id = $leadId";
                $conn->query($updateLeadSql);
            }
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Feedback saved successfully',
        'data' => [
            'id' => $insertId,
            'tc_for' => $tcFor,
            'caller_id' => $callerId,
            'table' => 'call_logs'
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error
    ]);
}

$conn->close();
?>
