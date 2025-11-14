<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once 'config.php';

$userId = $_GET['user_id'] ?? null;
$userType = $_GET['user_type'] ?? 'driver';

// Log what we received
error_log("=== PROFILE COMPLETION API V2 ===");
error_log("Received user_id: " . var_export($userId, true));
error_log("Received user_type: " . var_export($userType, true));
error_log("All GET params: " . json_encode($_GET));

if (!$userId || $userId === '' || $userId === '0' || $userId === 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false, 
        'message' => 'user_id required',
        'debug' => [
            'received_user_id' => $userId,
            'received_user_type' => $userType,
            'all_params' => $_GET
        ]
    ]);
    exit;
}

try {
    // Simple query
    $query = "SELECT * FROM users WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }
    
    $user = $result->fetch_assoc();
    
    // Simple field check
    $fields = [];
    if ($userType === 'driver') {
        $fields = [
            'Basic Info' => ['name', 'email', 'city'],
            'Documents' => ['images']
        ];
    }
    
    $completion = [];
    $totalFields = 0;
    $filledFields = 0;
    
    foreach ($fields as $category => $fieldList) {
        $completion[$category] = [];
        foreach ($fieldList as $field) {
            $value = $user[$field] ?? null;
            $isFilled = !empty($value);
            
            $completion[$category][] = [
                'field' => $field,
                'label' => ucwords(str_replace('_', ' ', $field)),
                'value' => $value,
                'status' => $isFilled ? 'complete' : 'missing'
            ];
            
            $totalFields++;
            if ($isFilled) $filledFields++;
        }
    }
    
    $percentage = $totalFields > 0 ? round(($filledFields / $totalFields) * 100) : 0;
    
    echo json_encode([
        'success' => true,
        'data' => [
            'userId' => (int)$userId,
            'name' => $user['name'] ?? '',
            'userType' => $userType,
            'percentage' => $percentage,
            'filledFields' => $filledFields,
            'totalFields' => $totalFields,
            'completion' => $completion
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
