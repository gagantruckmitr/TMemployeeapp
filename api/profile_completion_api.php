<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/profile_completion_helper.php';

$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'get_profile_details':
            getProfileDetails($conn);
            break;
        default:
            throw new Exception('Invalid action');
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

function getProfileDetails($conn) {
    $userId = $_GET['user_id'] ?? null;
    
    if (!$userId) {
        throw new Exception('User ID is required');
    }
    
    // Use the shared helper function for consistent calculation
    $profileData = getProfileCompletionData($conn, $userId);
    
    if ($profileData === 0 || !isset($profileData['user_data'])) {
        throw new Exception('User not found or invalid data');
    }
    
    $user = $profileData['user_data'];
    
    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => $user['id'],
            'unique_id' => $user['unique_id'],
            'name' => $user['name'],
            'role' => $user['role'],
            'profile_completion' => [
                'percentage' => $profileData['percentage'],
                'filled_fields' => $profileData['filled_fields'],
                'total_fields' => $profileData['total_fields'],
                'document_status' => $profileData['document_status'],
                'document_values' => $profileData['document_values']
            ]
        ]
    ]);
}
?>
