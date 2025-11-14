<?php
header('Content-Type: text/plain');
require_once 'config.php';

$uniqueId = 'TM2510BRDR10677';

echo "=== CHECKING USER: {$uniqueId} ===\n\n";

// Fetch user data
$query = "SELECT * FROM users WHERE unique_id = '{$uniqueId}'";
$result = $conn->query($query);

if (!$result || $result->num_rows === 0) {
    echo "User not found\n";
    exit;
}

$user = $result->fetch_assoc();
echo "User ID: {$user['id']}\n";
echo "Name: {$user['name']}\n";
echo "Role: {$user['role']}\n\n";

// Check each field
$requiredFields = [
    'name', 'email', 'city', 'sex', 'vehicle_type',
    'father_name', 'images', 'address', 'dob',
    'type_of_license', 'driving_experience', 'highest_education', 'license_number',
    'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
    'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
    'driving_license', 'previous_employer', 'job_placement'
];

$filledCount = 0;
$emptyFields = [];

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    
    $isFilled = false;
    $display = '';
    
    if ($value === null) {
        $display = '[NULL]';
    } elseif ($value === '') {
        $display = '[EMPTY]';
    } elseif ($value === '0000-00-00') {
        $display = '[BAD DATE]';
    } elseif ($value === '0') {
        $display = '[ZERO]';
    } else {
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            if (count($decoded) > 0) {
                $isFilled = true;
                $display = '[JSON: ' . count($decoded) . ' items]';
            } else {
                $display = '[EMPTY JSON]';
            }
        } else {
            $isFilled = true;
            $display = strlen($value) > 40 ? substr($value, 0, 40) . '...' : $value;
        }
    }
    
    if ($isFilled) {
        $filledCount++;
        echo "✓ {$field}: {$display}\n";
    } else {
        $emptyFields[] = $field;
        echo "✗ {$field}: {$display}\n";
    }
}

$percentage = round(($filledCount / count($requiredFields)) * 100);

echo "\n" . str_repeat("=", 80) . "\n";
echo "Total: " . count($requiredFields) . " | Filled: {$filledCount} | Empty: " . count($emptyFields) . "\n";
echo "PERCENTAGE: {$percentage}%\n";
echo str_repeat("=", 80) . "\n";

if (!empty($emptyFields)) {
    echo "\nEmpty fields: " . implode(', ', $emptyFields) . "\n";
}
?>
