<?php
/**
 * Debug script to compare profile completion calculations
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

// Get user ID from query parameter
$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    die(json_encode(['error' => 'user_id parameter required']));
}

// Get data using helper (used by job applicants API)
$helperData = getProfileCompletionData($conn, $userId);

// Get data using the same logic as profile_completion_api.php
$stmt = $conn->prepare("
    SELECT 
        u.id, u.unique_id, u.name, u.email, u.city, u.status, u.sex, u.vehicle_type,
        u.father_name, u.images, u.address, u.dob, u.role, u.created_at, u.updated_at,
        u.type_of_license, u.driving_experience, u.highest_education, u.license_number,
        u.expiry_date_of_license, u.expected_monthly_income, u.current_monthly_income,
        u.marital_status, u.preferred_location, u.aadhar_number, u.aadhar_photo,
        u.driving_license, u.previous_employer, u.job_placement,
        u.transport_name, u.year_of_establishment, u.fleet_size, u.operational_segment,
        u.average_km, u.pan_number, u.pan_image, u.gst_certificate, u.states,
        COALESCE(vt.vehicle_name, u.vehicle_type) as vehicle_type_name,
        s.name as state_name,
        s2.name as preferred_location_name
    FROM users u
    LEFT JOIN vehicle_type vt ON CAST(u.vehicle_type AS UNSIGNED) = vt.id
    LEFT JOIN states s ON u.states = s.id
    LEFT JOIN states s2 ON CAST(u.preferred_location AS UNSIGNED) = s2.id
    WHERE u.id = ?
");

$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

$requiredFields = [
    'name', 'email', 'city', 'sex', 'vehicle_type',
    'father_name', 'images', 'address', 'dob',
    'type_of_license', 'driving_experience', 'highest_education', 'license_number',
    'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
    'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
    'driving_license', 'previous_employer', 'job_placement'
];

$displayFields = [
    'vehicle_type' => 'vehicle_type_name',
    'preferred_location' => 'preferred_location_name',
    'states' => 'state_name'
];

$apiCalculation = [];
$filledFields = 0;

foreach ($requiredFields as $field) {
    $displayField = $displayFields[$field] ?? $field;
    $value = $user[$displayField] ?? $user[$field] ?? null;
    $isPresent = false;
    
    if ($value !== null && $value !== '') {
        $decoded = json_decode($value, true);
        if (is_array($decoded) && count($decoded) > 0) {
            $isPresent = true;
        } elseif (is_array($decoded) && count($decoded) === 0) {
            $isPresent = false; // Empty array
        } else {
            $isPresent = true;
        }
    }
    
    $apiCalculation[$field] = [
        'raw_value' => $value,
        'is_present' => $isPresent,
        'is_array' => is_array(json_decode($value, true)),
        'array_count' => is_array(json_decode($value, true)) ? count(json_decode($value, true)) : 'N/A'
    ];
    
    if ($isPresent) {
        $filledFields++;
    }
}

$apiPercentage = round(($filledFields / count($requiredFields)) * 100);

// Output comparison
header('Content-Type: application/json');
echo json_encode([
    'user_id' => $userId,
    'user_name' => $user['name'],
    'helper_calculation' => [
        'percentage' => $helperData['percentage'],
        'filled_fields' => $helperData['filled_fields'],
        'total_fields' => $helperData['total_fields'],
        'document_status' => $helperData['document_status']
    ],
    'api_calculation' => [
        'percentage' => $apiPercentage,
        'filled_fields' => $filledFields,
        'total_fields' => count($requiredFields)
    ],
    'field_by_field_comparison' => $apiCalculation,
    'differences' => array_filter($apiCalculation, function($field, $key) use ($helperData) {
        return $field['is_present'] !== ($helperData['document_status'][$key] ?? false);
    }, ARRAY_FILTER_USE_BOTH)
], JSON_PRETTY_PRINT);
?>
