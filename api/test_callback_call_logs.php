<?php
/**
 * Test script to verify callback request call logging
 * This script checks:
 * 1. callback_requests table structure
 * 2. call_logs table structure
 * 3. Sample data insertion
 * 4. Verification of user_id mapping
 */

header('Content-Type: application/json');

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    die(json_encode(['success' => false, 'error' => 'Database connection failed: ' . $e->getMessage()]));
}

$results = [];

// 1. Check callback_requests table structure
$results['callback_requests_structure'] = [];
try {
    $stmt = $pdo->query("DESCRIBE callback_requests");
    $results['callback_requests_structure'] = $stmt->fetchAll();
} catch(Exception $e) {
    $results['callback_requests_structure_error'] = $e->getMessage();
}

// 2. Check call_logs table structure
$results['call_logs_structure'] = [];
try {
    $stmt = $pdo->query("DESCRIBE call_logs");
    $results['call_logs_structure'] = $stmt->fetchAll();
} catch(Exception $e) {
    $results['call_logs_structure_error'] = $e->getMessage();
}

// 3. Get sample callback request with user mapping
$results['sample_callback_request'] = null;
try {
    $sql = "SELECT 
                cr.*,
                u.id as actual_user_id,
                u.name as actual_user_name,
                u.mobile as actual_user_mobile
            FROM callback_requests cr
            LEFT JOIN users u ON cr.unique_id = u.unique_id
            WHERE cr.status IN ('Pending', 'Callback')
            LIMIT 1";
    $stmt = $pdo->query($sql);
    $results['sample_callback_request'] = $stmt->fetch();
} catch(Exception $e) {
    $results['sample_callback_request_error'] = $e->getMessage();
}

// 4. Check if callback_requests have user_id mapping
$results['callback_requests_with_user_mapping'] = [];
try {
    $sql = "SELECT 
                cr.id as callback_id,
                cr.unique_id,
                cr.user_name,
                u.id as user_id,
                u.name as user_name_from_users
            FROM callback_requests cr
            LEFT JOIN users u ON cr.unique_id = u.unique_id
            WHERE cr.status IN ('Pending', 'Callback')
            LIMIT 5";
    $stmt = $pdo->query($sql);
    $results['callback_requests_with_user_mapping'] = $stmt->fetchAll();
} catch(Exception $e) {
    $results['callback_requests_with_user_mapping_error'] = $e->getMessage();
}

// 5. Check recent call_logs from callback_requests
$results['recent_callback_call_logs'] = [];
try {
    $sql = "SELECT 
                cl.*,
                u.name as user_name,
                u.unique_id as user_tmid
            FROM call_logs cl
            LEFT JOIN users u ON cl.user_id = u.id
            WHERE cl.tc_for = 'callback_requests' OR cl.reference_id LIKE 'CALLBACK_%'
            ORDER BY cl.created_at DESC
            LIMIT 5";
    $stmt = $pdo->query($sql);
    $results['recent_callback_call_logs'] = $stmt->fetchAll();
} catch(Exception $e) {
    $results['recent_callback_call_logs_error'] = $e->getMessage();
}

// 6. Summary
$results['summary'] = [
    'callback_requests_table_exists' => !isset($results['callback_requests_structure_error']),
    'call_logs_table_exists' => !isset($results['call_logs_structure_error']),
    'sample_request_found' => $results['sample_callback_request'] !== null,
    'user_mapping_working' => count($results['callback_requests_with_user_mapping']) > 0,
    'callback_call_logs_exist' => count($results['recent_callback_call_logs']) > 0,
];

echo json_encode($results, JSON_PRETTY_PRINT);
?>
