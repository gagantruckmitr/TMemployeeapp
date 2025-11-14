<?php
header('Content-Type: text/plain');
require_once 'config.php';

$uniqueId = $_GET['unique_id'] ?? null;

if (!$uniqueId) {
    echo "Usage: check_user_profile.php?unique_id=TM2510BRDR10677\n";
    exit;
}

echo "=== PROFILE COMPLETION CHECK ===\n\n";

// Fetch user data by unique_id
$query = "SELECT * FROM users WHERE unique_id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $uniqueId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo "User not found with unique_id: {$uniqueId}\n";
    exit;
}

$user = $result->fetch_assoc();
echo "User ID: {$user['id']}\n";
echo "Unique ID: {$user['unique_id']}\n";
echo "Name: {$user['name']}\n";
echo "Role: {$user['role']}\n\n";

// Check each field with the EXACT logic from phase2_job_applicants_api.php
$requiredFields = [
    'name', 'email', 'city', 'sex', 'vehicle_type',
    'father_name', 'images', 'address', 'dob',
    'type_of_license', 'driving_experience', 'highest_education', 'license_number',
    'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
    'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
    'driving_license', 'previous_employer', 'job_placement'
];

echo "Checking " . count($requiredFields) . " fields:\n";
echo str_repeat("=", 100) . "\n\n";

$filledCount = 0;
$emptyFields = [];

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    
    // Use EXACT same logic as isFieldFilledInApplicants
    $isFilled = false;
    $displayValue = '';
    
    if ($value === null) {
        $displayValue = '[NULL]';
    } elseif ($value === '') {
        $displayValue = '[EMPTY STRING]';
    } elseif ($value === '0000-00-00') {
        $displayValue = '[INVALID DATE: 0000-00-00]';
    } elseif ($value === '0') {
        $displayValue = '[ZERO]';
    } else {
        // Check if JSON array
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            if (count($decoded) > 0) {
                $isFilled = true;
                $displayValue = '[JSON ARRAY: ' . count($decoded) . ' items] ' . json_encode($decoded);
            } else {
                $displayValue = '[EMPTY JSON ARRAY: []]';
            }
        } else {
            $isFilled = true;
            $displayValue = strlen($value) > 60 ? substr($value, 0, 60) . '...' : $value;
        }
    }
    
    $status = $isFilled ? '✓ FILLED' : '✗ EMPTY ';
    
    if ($isFilled) {
        $filledCount++;
        echo "{$status} | {$field}: {$displayValue}\n";
    } else {
        $emptyFields[] = $field;
        echo "{$status} | {$field}: {$displayValue}\n";
    }
}

$percentage = round(($filledCount / count($requiredFields)) * 100);

echo "\n" . str_repeat("=", 100) . "\n";
echo "CALCULATION SUMMARY:\n";
echo "Total Fields Required: " . count($requiredFields) . "\n";
echo "Filled Fields: {$filledCount}\n";
echo "Empty Fields: " . (count($requiredFields) - $filledCount) . "\n";
echo "PERCENTAGE: {$percentage}%\n";
echo str_repeat("=", 100) . "\n\n";

if (!empty($emptyFields)) {
    echo "EMPTY FIELDS LIST:\n";
    foreach ($emptyFields as $field) {
        echo "  - {$field}\n";
    }
}
?>
