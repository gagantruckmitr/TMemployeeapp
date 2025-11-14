<?php
header('Content-Type: text/plain');
require_once 'config.php';

$userId = 10677;

echo "=== DEBUGGING profile_completion_api.php LOGIC ===\n\n";

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
$user = $result->fetch_assoc();

echo "User: {$user['name']} (ID: {$userId})\n";
echo "Role: {$user['role']}\n\n";

// Use EXACT logic from profile_completion_api.php
$requiredFields = [
    'name', 'email', 'city', 'sex', 'vehicle_type',
    'father_name', 'images', 'address', 'dob',
    'type_of_license', 'driving_experience', 'highest_education', 'license_number',
    'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
    'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
    'driving_license', 'previous_employer', 'job_placement'
];

$filledFields = 0;
$totalFields = count($requiredFields);

echo "Checking {$totalFields} fields:\n";
echo str_repeat("=", 100) . "\n\n";

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    $isPresent = false;
    
    // EXACT logic from profile_completion_api.php
    if ($value !== null && $value !== '' && $value !== '0000-00-00' && $value !== '0') {
        // Check if it's a JSON array with content
        $decoded = json_decode($value, true);
        if (is_array($decoded) && count($decoded) > 0) {
            $isPresent = true;
        } elseif (!is_array($decoded)) {
            $isPresent = true;
        }
    }
    
    if ($isPresent) {
        $filledFields++;
    }
    
    // Display
    $status = $isPresent ? '✓ FILLED' : '✗ EMPTY ';
    $displayValue = '';
    
    if ($value === null) {
        $displayValue = '[NULL]';
    } elseif ($value === '') {
        $displayValue = '[EMPTY STRING]';
    } elseif ($value === '0') {
        $displayValue = '[ZERO]';
    } elseif ($value === '0000-00-00') {
        $displayValue = '[BAD DATE]';
    } else {
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            $displayValue = '[JSON: ' . count($decoded) . ' items]';
        } else {
            $displayValue = strlen($value) > 50 ? substr($value, 0, 50) . '...' : $value;
        }
    }
    
    echo "{$status} | {$field}: {$displayValue}\n";
}

$percentage = round(($filledFields / $totalFields) * 100);

echo "\n" . str_repeat("=", 100) . "\n";
echo "RESULT: {$filledFields} / {$totalFields} = {$percentage}%\n";
echo str_repeat("=", 100) . "\n";
?>
