<?php
/**
 * Debug Webhook API
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);

echo json_encode([
    'success' => true,
    'message' => 'Debug info',
    'data' => [
        'method' => $_SERVER['REQUEST_METHOD'],
        'input' => $input,
        'raw_input' => file_get_contents('php://input')
    ]
], JSON_PRETTY_PRINT);
?>
