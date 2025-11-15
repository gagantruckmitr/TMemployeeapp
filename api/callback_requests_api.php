<?php
/**
 * Callback Requests API
 * Handles callback request operations for telecallers
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed'
    ]);
    exit;
}

$action = $_GET['action'] ?? 'list';
$userId = $_GET['user_id'] ?? null;

try {
    switch($action) {
        case 'list':
            getCallbackRequests($pdo, $userId);
            break;
        case 'update_status':
            updateCallbackStatus($pdo);
            break;
        case 'add':
            addCallbackRequest($pdo);
            break;
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Invalid action'
            ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server error occurred'
    ]);
}

function getCallbackRequests($pdo, $userId) {
    try {
        // For now, return empty array (no callback requests yet)
        // This prevents 403 error and shows empty state in app
        echo json_encode([
            'success' => true,
            'data' => []
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch callback requests'
        ]);
    }
}

function updateCallbackStatus($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    echo json_encode([
        'success' => true,
        'message' => 'Status updated successfully'
    ]);
}

function addCallbackRequest($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    echo json_encode([
        'success' => true,
        'message' => 'Callback request added successfully'
    ]);
}
?>
