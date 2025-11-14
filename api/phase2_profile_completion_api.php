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

if (!$userId || $userId === '' || $userId === '0' || $userId === 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false, 
        'message' => 'user_id required',
        'received_user_id' => $userId,
        'received_user_type' => $userType
    ]);
    exit;
}

try {
    // Fetch user data - use specific SELECT to ensure correct column names
    $query = "SELECT 
        id, unique_id, name, email, city, status, sex, vehicle_type,
        father_name, images, address, dob, role, created_at, updated_at,
        type_of_license, driving_experience, highest_education, license_number,
        expiry_date_of_license, expected_monthly_income, current_monthly_income,
        marital_status, preferred_location, aadhar_number, aadhar_photo,
        driving_license, previous_employer, job_placement,
        transport_name, year_of_establishment, fleet_size, operational_segment,
        average_km, pan_number, pan_image, gst_certificate
    FROM users WHERE id = ?";
    
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
    
    // Helper function to check if field is filled
    function isFieldFilled($value) {
        if ($value === null || $value === '' || $value === '0000-00-00' || $value === '0') {
            return false;
        }
        
        $decoded = json_decode($value, true);
        if (is_array($decoded) && count($decoded) > 0) {
            return true;
        } elseif (!is_array($decoded)) {
            return true;
        }
        
        return false;
    }
    
    // Helper function to get display value
    function getDisplayValue($value) {
        if ($value === null || $value === '' || $value === '0000-00-00' || $value === '0') {
            return null;
        }
        
        $decoded = json_decode($value, true);
        if (is_array($decoded) && count($decoded) > 0) {
            if (isset($decoded[0])) {
                return is_string($decoded[0]) ? $decoded[0] : json_encode($decoded[0]);
            } else {
                return count($decoded) . ' items';
            }
        }
        
        return $value;
    }
    
    // Helper function to get full image URL
    function getFullImageUrl($imagePath) {
        if (empty($imagePath) || $imagePath === null) {
            return null;
        }
        
        // If already a full URL, return as is
        if (strpos($imagePath, 'http://') === 0 || strpos($imagePath, 'https://') === 0) {
            return $imagePath;
        }
        
        // Otherwise, prepend the base URL
        return 'https://truckmitr.com/public/' . $imagePath;
    }
    
    // Define required fields based on user type with categories
    $fields = [];
    if ($userType === 'driver') {
        $fields = [
            'Basic Info' => ['name', 'email', 'city', 'sex', 'father_name', 'address', 'dob', 'images'],
            'Professional' => ['vehicle_type', 'type_of_license', 'driving_experience', 'highest_education', 'license_number', 'expiry_date_of_license'],
            'Income' => ['expected_monthly_income', 'current_monthly_income', 'marital_status', 'preferred_location'],
            'Documents' => ['aadhar_number', 'aadhar_photo', 'driving_license'],
            'Employment' => ['previous_employer', 'job_placement']
        ];
    } else {
        $fields = [
            'Basic Info' => ['name', 'email', 'transport_name', 'city', 'images', 'address'],
            'Business' => ['year_of_establishment', 'fleet_size', 'operational_segment', 'average_km'],
            'Documents' => ['pan_number', 'pan_image', 'gst_certificate']
        ];
    }
    
    $completion = [];
    $totalFields = 0;
    $filledFields = 0;
    
    foreach ($fields as $category => $fieldList) {
        $completion[$category] = [];
        foreach ($fieldList as $field) {
            $value = $user[$field] ?? null;
            $isFilled = isFieldFilled($value);
            $displayValue = getDisplayValue($value);
            
            $completion[$category][] = [
                'field' => $field,
                'label' => ucwords(str_replace('_', ' ', $field)),
                'value' => $displayValue,
                'status' => $isFilled ? 'complete' : 'missing'
            ];
            
            $totalFields++;
            if ($isFilled) $filledFields++;
        }
    }
    
    $percentage = $totalFields > 0 ? round(($filledFields / $totalFields) * 100) : 0;
    
    // Get profile image URL
    $profileImageUrl = getFullImageUrl($user['images'] ?? null);
    
    echo json_encode([
        'success' => true,
        'data' => [
            'userId' => (int)$userId,
            'name' => $user['name'] ?? '',
            'userType' => $userType,
            'percentage' => $percentage,
            'filledFields' => $filledFields,
            'totalFields' => $totalFields,
            'profileImageUrl' => $profileImageUrl,
            'completion' => $completion
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
