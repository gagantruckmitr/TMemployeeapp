<?php
header('Content-Type: text/plain');
require_once 'config.php';

$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    echo "Usage: compare_profile_calculations.php?user_id=123\n";
    exit;
}

echo "=== PROFILE COMPLETION COMPARISON ===\n\n";

// Fetch user data
$query = "SELECT * FROM users WHERE id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo "User not found\n";
    exit;
}

$user = $result->fetch_assoc();
echo "User ID: {$user['id']}\n";
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
echo str_repeat("=", 80) . "\n\n";

$filledCount = 0;
$emptyFields = [];
$filledFields = [];

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    
    // Use EXACT same logic as isFieldFilledInApplicants
    $isFilled = false;
    $reason = '';
    
    if ($value === null) {
        $reason = 'NULL';
    } elseif ($value === '') {
        $reason = 'Empty string';
    } elseif ($value === '0000-00-00') {
        $reason = 'Invalid date (0000-00-00)';
    } elseif ($value === '0') {
        $reason = 'Zero value';
    } else {
        // Check if JSON array
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            if (count($decoded) > 0) {
                $isFilled = true;
                $reason = 'JSON array with ' . count($decoded) . ' items';
            } else {
                $reason = 'Empty JSON array []';
            }
        } else {
            $isFilled = true;
            $reason = 'Has value: ' . (strlen($value) > 50 ? substr($value, 0, 50) . '...' : $value);
        }
    }
    
    if ($isFilled) {
        $filledCount++;
        $filledFields[] = $field;
        echo "✓ {$field}: {$reason}\n";
    } else {
        $emptyFields[] = $field;
        echo "✗ {$field}: {$reason}\n";
    }
}

$percentage = round(($filledCount / count($requiredFields)) * 100);

echo "\n" . str_repeat("=", 80) . "\n";
echo "SUMMARY:\n";
echo "Total Fields: " . count($requiredFields) . "\n";
echo "Filled Fields: {$filledCount}\n";
echo "Empty Fields: " . (count($requiredFields) - $filledCount) . "\n";
echo "Percentage: {$percentage}%\n\n";

if (!empty($emptyFields)) {
    echo "Empty fields: " . implode(', ', $emptyFields) . "\n\n";
}

// Now check what the database actually has for profile_completion column if it exists
$columns = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_completion'");
if ($columns && $columns->num_rows > 0) {
    echo "\nDatabase profile_completion column value: " . ($user['profile_completion'] ?? 'NULL') . "\n";
}
?>
