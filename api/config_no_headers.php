<?php
/**
 * TruckMitr API Configuration - NO HEADERS VERSION
 * For APIs that need to set their own headers
 */

// ============================================
// DATABASE CONFIGURATION
// ============================================
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'truckmitr');
define('DB_USER', 'truckmitr');
define('DB_PASS', '825Redp&4');

// ============================================
// DATABASE CONNECTION FUNCTION
// ============================================
function getDBConnection() {
    try {
        if (defined('DB_PORT')) {
            $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
        } else {
            $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        }
        
        if ($conn->connect_error) {
            throw new Exception('Database connection failed: ' . $conn->connect_error);
        }
        
        if (!$conn->set_charset('utf8mb4')) {
            throw new Exception('Error setting charset: ' . $conn->error);
        }
        
        return $conn;
        
    } catch (Exception $e) {
        error_log('DB Connection Error: ' . $e->getMessage());
        return null;
    }
}

// ============================================
// HELPER FUNCTIONS
// ============================================
function sendError($message, $code = 400, $data = null) {
    http_response_code($code);
    $response = [
        'success' => false,
        'message' => $message
    ];
    if ($data !== null) {
        $response['data'] = $data;
    }
    echo json_encode($response);
    exit();
}

function sendSuccess($data = null, $message = 'Success') {
    http_response_code(200);
    $response = [
        'success' => true,
        'message' => $message
    ];
    if ($data !== null) {
        $response['data'] = $data;
    }
    echo json_encode($response);
    exit();
}

function sanitizeInput($conn, $input) {
    return $conn->real_escape_string(trim($input));
}

// ============================================
// TIMEZONE SETTING
// ============================================
date_default_timezone_set('Asia/Kolkata');

// ============================================
// ERROR REPORTING
// ============================================
if (DB_HOST === 'localhost' || DB_HOST === '127.0.0.1') {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(E_ALL);
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
}

// ============================================
// MYSQLI CONNECTION
// ============================================
$conn = getDBConnection();

if ($conn) {
    $conn->query("SET time_zone = '+05:30'");
}

// ============================================
// PDO CONNECTION
// ============================================
try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
    
    $pdo->exec("SET time_zone = '+05:30'");
    
} catch(PDOException $e) {
    error_log('PDO Connection Error: ' . $e->getMessage());
    $pdo = null;
}
