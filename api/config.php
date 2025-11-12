<?php
/**
 * TruckMitr API Configuration
 * Central configuration file for all API endpoints
 */

// CORS Headers - Allow Flutter app to access APIs
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============================================
// DATABASE CONFIGURATION
// ============================================
// UPDATE THESE VALUES WHEN DEPLOYING TO INFINITYFREE OR OTHER HOSTING
// ============================================

// Production Settings - From .env file
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'truckmitr');
define('DB_USER', 'truckmitr');
define('DB_PASS', '825Redp&4');

// 000webhost Settings (Alternative)
// define('DB_HOST', 'localhost');
// define('DB_NAME', 'id12345678_truckmitr');
// define('DB_USER', 'id12345678_user');
// define('DB_PASS', 'your_password_here');

// ============================================
// DATABASE CONNECTION FUNCTION
// ============================================
function getDBConnection() {
    try {
        // Connect with port if defined
        if (defined('DB_PORT')) {
            $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
        } else {
            $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        }
        
        // Check connection
        if ($conn->connect_error) {
            throw new Exception('Database connection failed: ' . $conn->connect_error);
        }
        
        // Set charset to UTF-8
        if (!$conn->set_charset('utf8mb4')) {
            throw new Exception('Error setting charset: ' . $conn->error);
        }
        
        return $conn;
        
    } catch (Exception $e) {
        // Log error (in production, log to file instead of displaying)
        error_log('DB Connection Error: ' . $e->getMessage());
        
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed. Please try again later.',
            'error' => (DB_HOST === 'localhost') ? $e->getMessage() : null // Only show details in dev
        ]);
        exit();
    }
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Send error response
 */
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

/**
 * Send success response
 */
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

/**
 * Validate required POST parameters
 */
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

/**
 * Sanitize input string
 */
function sanitizeInput($conn, $input) {
    return $conn->real_escape_string(trim($input));
}

/**
 * Verify JWT token (if you implement authentication tokens)
 */
function verifyToken() {
    $headers = getallheaders();
    if (!isset($headers['Authorization'])) {
        sendError('Authorization token required', 401);
    }
    
    // Add your JWT verification logic here
    // For now, just return true
    return true;
}

/**
 * Log API request (optional - for debugging)
 */
function logRequest($endpoint, $method, $userId = null) {
    if (DB_HOST === 'localhost') { // Only log in development
        $logData = [
            'timestamp' => date('Y-m-d H:i:s'),
            'endpoint' => $endpoint,
            'method' => $method,
            'user_id' => $userId,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ];
        error_log('API Request: ' . json_encode($logData));
    }
}

// ============================================
// TIMEZONE SETTING
// ============================================
date_default_timezone_set('Asia/Kolkata'); // Set to Indian timezone

// Log timezone for debugging
error_log('PHP Timezone: ' . date_default_timezone_get() . ' | Current time: ' . date('Y-m-d H:i:s'));

// ============================================
// ERROR REPORTING
// ============================================
if (DB_HOST === 'localhost') {
    // Development: Show all errors
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    // Production: Hide errors, log them instead
    error_reporting(E_ALL);
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
}

// ============================================
// CONSTANTS
// ============================================
define('API_VERSION', '1.0.0');
define('MAX_UPLOAD_SIZE', 5 * 1024 * 1024); // 5MB
define('ALLOWED_ORIGINS', ['*']); // In production, specify your app's domain

// ============================================
// MYSQLI CONNECTION (for most APIs)
// ============================================
$conn = getDBConnection();

// Set MySQL timezone to IST so NOW() returns IST time strings
// MySQL stores in UTC but NOW() will return IST format
$conn->query("SET time_zone = '+05:30'");

// ============================================
// PDO CONNECTION (for admin panel)
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
    
    // Set MySQL timezone to IST so NOW() returns IST time strings
    $pdo->exec("SET time_zone = '+05:30'");
    
} catch(PDOException $e) {
    error_log('PDO Connection Error: ' . $e->getMessage());
    if (DB_HOST === 'localhost') {
        die('Database connection failed: ' . $e->getMessage());
    } else {
        die('Database connection failed. Please contact administrator.');
    }
}
