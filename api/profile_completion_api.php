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
    
    // Fetch user data
    $stmt = $conn->prepare("
        SELECT 
            id, unique_id, name, email, city, status, sex, vehicle_type,
            father_name, images, address, dob, role, created_at, updated_at,
            type_of_license, driving_experience, highest_education, license_number,
            expiry_date_of_license, expected_monthly_income, current_monthly_income,
            marital_status, preferred_location, aadhar_number, aadhar_photo,
            driving_license, previous_employer, job_placement,
            transport_name, year_of_establishment, fleet_size, operational_segment,
            average_km, pan_number, pan_image, gst_certificate
        FROM users 
        WHERE id = ?
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('User not found');
    }
    
    $user = $result->fetch_assoc();
    $role = $user['role'];
    
    // Define required fields based on role (excluding system fields)
    $requiredFields = [];
    if ($role === 'driver') {
        $requiredFields = [
            'name', 'email', 'city', 'sex', 'vehicle_type',
            'father_name', 'images', 'address', 'dob',
            'type_of_license', 'driving_experience', 'highest_education', 'license_number',
            'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
            'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
            'driving_license', 'previous_employer', 'job_placement'
        ];
    } elseif ($role === 'transporter') {
        $requiredFields = [
            'name', 'email', 'transport_name', 'year_of_establishment',
            'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
            'pan_number', 'pan_image', 'gst_certificate'
        ];
    }
    
    // Calculate document status and get actual values
    $documentStatus = [];
    $documentValues = [];
    $filledFields = 0;
    $totalFields = count($requiredFields);
    
    foreach ($requiredFields as $field) {
        $value = $user[$field] ?? null;
        $isPresent = false;
        $displayValue = null;
        
        if ($value !== null && $value !== '') {
            // Check if it's a JSON array with content
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $isPresent = true;
                // For arrays, show count or first item
                if (isset($decoded[0])) {
                    $displayValue = is_string($decoded[0]) ? $decoded[0] : json_encode($decoded[0]);
                } else {
                    $displayValue = count($decoded) . ' items';
                }
            } elseif (!is_array($decoded)) {
                $isPresent = true;
                $displayValue = $value;
            }
        }
        
        $documentStatus[$field] = $isPresent;
        $documentValues[$field] = $displayValue;
        
        if ($isPresent) {
            $filledFields++;
        }
    }
    
    $completionPercentage = $totalFields > 0 ? round(($filledFields / $totalFields) * 100) : 0;
    
    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => $user['id'],
            'unique_id' => $user['unique_id'],
            'name' => $user['name'],
            'role' => $role,
            'profile_completion' => [
                'percentage' => $completionPercentage,
                'filled_fields' => $filledFields,
                'total_fields' => $totalFields,
                'document_status' => $documentStatus,
                'document_values' => $documentValues
            ]
        ]
    ]);
}
?>
