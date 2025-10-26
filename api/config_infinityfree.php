<?php
/**
 * InfinityFree MySQL Configuration
 * Special configuration for InfinityFree hosting
 */

// CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// InfinityFree MySQL Configuration
// For InfinityFree, we need to use the internal hostname
define('DB_HOST', 'sql112.infinityfree.com:3306');
define('DB_NAME', 'if0_40220924_truckmitr_db');
define('DB_USER', 'if0_40220924');
define('DB_PASS', 'axQ53mgSTWyB');

// Database Connection Function using PDO with specific DSN for InfinityFree
function getDBConnection() {
    try {
        // InfinityFree specific DSN format
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
        ];
        
        $conn = new PDO($dsn, DB_USER, DB_PASS, $options);
        return $conn;
        
    } catch (PDOException $e) {
        error_log('DB Connection Error: ' . $e->getMessage());
        
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed',
            'error' => $e->getMessage() // Remove in production
        ]);
        exit();
    }
}

// Helper Functions
function sendError($message, $code = 400, $data = null) {
    http_response_code($code);
    $response = ['success' => false, 'message' => $message];
    if ($data !== null) $response['data'] = $data;
    echo json_encode($response);
    exit();
}

function sendSuccess($data = null, $message = 'Success') {
    http_response_code(200);
    $response = ['success' => true, 'message' => $message];
    if ($data !== null) $response['data'] = $data;
    echo json_encode($response);
    exit();
}

function validateRequired($params, $required) {
    $missing = [];
    foreach ($required as $field) {
        if (!isset($params[$field]) || trim($params[$field]) === '') {
            $missing[] = $field;
        }
    }
    if (!empty($missing)) {
        sendError('Missing required fields: ' . implode(', ', $missing), 400);
    }
}

function sanitizeInput($input) {
    return htmlspecialchars(strip_tags(trim($input)), ENT_QUOTES, 'UTF-8');
}

// Timezone
date_default_timezone_set('Asia/Kolkata');

// Error Reporting
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

define('API_VERSION', '1.0.0');
?>
