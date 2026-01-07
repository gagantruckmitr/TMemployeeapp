<?php
/**
 * Test what the callback_requests_api.php actually returns
 */

// Simulate the API call
$_SERVER['REQUEST_METHOD'] = 'GET';
$_GET['action'] = 'index';

// Capture output
ob_start();
require 'callback_requests_api.php';
$output = ob_get_clean();

// Pretty print the JSON
$data = json_decode($output, true);
if ($data && isset($data['data']) && count($data['data']) > 0) {
    $firstRequest = $data['data'][0];
    echo "=== FIRST CALLBACK REQUEST ===\n";
    echo "User Name: {$firstRequest['user_name']}\n";
    echo "Unique ID: {$firstRequest['unique_id']}\n";
    echo "Profile Completion: {$firstRequest['profile_completion']}\n";
    echo "Role: {$firstRequest['app_type']}\n\n";
    
    echo "=== FULL DATA ===\n";
    echo json_encode($firstRequest, JSON_PRETTY_PRINT);
} else {
    echo "No callback requests found or error:\n";
    echo $output;
}
?>
