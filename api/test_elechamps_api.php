<?php
/**
 * Test Elechamps API Integration
 * 
 * This script tests the elechamps API endpoint to verify it returns data correctly
 * 
 * Usage: https://truckmitr.com/api/test_elechamps_api.php?admin_id=8
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Get admin ID from query parameter
$adminId = isset($_GET['admin_id']) ? intval($_GET['admin_id']) : 8;

// Test the elechamps API
$apiUrl = "https://truckmitr.com/api/telehead/elechamps/{$adminId}/users";

echo "Testing Elechamps API\n";
echo "====================\n\n";
echo "API URL: $apiUrl\n\n";

// Initialize cURL
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

// Execute request
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

// Check for errors
if ($error) {
    echo json_encode([
        'success' => false,
        'error' => 'cURL Error: ' . $error,
        'http_code' => $httpCode
    ], JSON_PRETTY_PRINT);
    exit;
}

// Decode response
$data = json_decode($response, true);

if ($httpCode !== 200) {
    echo json_encode([
        'success' => false,
        'error' => 'HTTP Error',
        'http_code' => $httpCode,
        'response' => $response
    ], JSON_PRETTY_PRINT);
    exit;
}

// Display results
echo json_encode([
    'success' => true,
    'http_code' => $httpCode,
    'admin_id' => $adminId,
    'api_status' => $data['status'] ?? 'unknown',
    'admin_name' => $data['admin_name'] ?? 'N/A',
    'assigned_user_count' => $data['assigned_user_count'] ?? 0,
    'current_page' => $data['current_page'] ?? 1,
    'per_page' => $data['per_page'] ?? 10,
    'last_page' => $data['last_page'] ?? 1,
    'users_in_response' => isset($data['users']) ? count($data['users']) : 0,
    'sample_user' => isset($data['users'][0]) ? [
        'id' => $data['users'][0]['id'] ?? null,
        'unique_id' => $data['users'][0]['unique_id'] ?? null,
        'name_eng' => $data['users'][0]['name_eng'] ?? null,
        'mobile' => $data['users'][0]['mobile'] ?? null,
        'role' => $data['users'][0]['role'] ?? null,
        'profile_completion' => $data['users'][0]['profile_completion'] ?? null,
        'driver_completion' => $data['users'][0]['driver_completion'] ?? null,
        'states' => $data['users'][0]['states'] ?? null,
        'Created_at' => $data['users'][0]['Created_at'] ?? null,
    ] : null,
    'full_response' => $data
], JSON_PRETTY_PRINT);
?>
