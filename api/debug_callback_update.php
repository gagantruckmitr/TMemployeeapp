<?php
/**
 * Debug script to see what's being sent to callback_requests_api.php
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$debug = [
    'method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'not set',
    'query_params' => $_GET,
    'post_data' => $_POST,
    'raw_input' => file_get_contents('php://input'),
    'headers' => getallheaders(),
    'timestamp' => date('Y-m-d H:i:s')
];

// Try to decode raw input as JSON
if (!empty($debug['raw_input'])) {
    $debug['json_decoded'] = json_decode($debug['raw_input'], true);
}

// Parse URL encoded data
if (!empty($debug['raw_input']) && strpos($debug['content_type'], 'application/x-www-form-urlencoded') !== false) {
    parse_str($debug['raw_input'], $parsed);
    $debug['parsed_form_data'] = $parsed;
}

echo json_encode($debug, JSON_PRETTY_PRINT);
?>
