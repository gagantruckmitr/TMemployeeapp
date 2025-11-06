<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Debug information
$debug = [
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'not set',
    'http_content_type' => $_SERVER['HTTP_CONTENT_TYPE'] ?? 'not set',
    'request_uri' => $_SERVER['REQUEST_URI'],
    'query_string' => $_SERVER['QUERY_STRING'] ?? 'not set',
    'raw_post_data' => file_get_contents('php://input'),
    'post_data' => $_POST,
    'get_data' => $_GET,
    'all_headers' => getallheaders(),
];

echo json_encode($debug, JSON_PRETTY_PRINT);
?>
