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
$userType = $_GET['user_type'] ?? 'driver'; // driver or transporter

if (!$userId) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'user_id required']);
    exit;
}

try {
    // Fetch user data
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
    
    // Define required fields based on user type (exact field names from database - case-sensitive)
    $fields = [];
    if ($userType === 'driver') {
        $fields = [
            'Basic Info' => ['name', 'email', 'city', 'sex', 'father_name', 'address', 'dob'],
            'Professional' => ['vehicle_type', 'Type_of_License', 'Driving_Experience', 'highest_education', 'License_Number', 'expiry_date_of_license'],
            'Income' => ['expected_monthly_income', 'current_monthly_income', 'marital_status', 'Preferred_Location'],
            'Documents' => ['Aadhar_Number', 'aadhar_photo', 'driving_license', 'images'],
            'Employment' => ['previous_employer', 'job_placement']
        ];
    } else {
        $fields = [
            'Basic Info' => ['name', 'email', 'city', 'address', 'transport_name'],
            'Business' => ['year_of_establishment', 'fleet_size', 'operational_segment', 'average_km'],
            'Documents' => ['pan_number', 'pan_image', 'gst_certificate', 'images']
        ];
    }
    
    $completion = [];
    $totalFields = 0;
    $filledFields = 0;
    
    foreach ($fields as $category => $fieldList) {
        $completion[$category] = [];
        foreach ($fieldList as $field) {
            $value = $user[$field] ?? null;
            $isFilled = !empty($value) && $value !== '0000-00-00';
            
            $completion[$category][] = [
                'field' => $field,
                'label' => ucwords(str_replace('_', ' ', $field)),
                'value' => $isFilled ? $value : null,
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
