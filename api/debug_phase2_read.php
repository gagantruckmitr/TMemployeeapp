<?php
header('Content-Type: text/plain');
require_once 'config.php';

$userId = 10677;

echo "=== DEBUGGING WHAT phase2 APIs ARE READING ===\n\n";

// Method 1: Direct SELECT * (what phase2_profile_completion_api.php uses)
echo "METHOD 1: SELECT * FROM users (phase2_profile_completion_api.php)\n";
echo str_repeat("=", 100) . "\n";

$query1 = "SELECT * FROM users WHERE id = ?";
$stmt1 = $conn->prepare($query1);
$stmt1->bind_param("i", $userId);
$stmt1->execute();
$result1 = $stmt1->get_result();
$user1 = $result1->fetch_assoc();

$fields = ['sex', 'father_name', 'dob', 'type_of_license', 'driving_experience', 
           'highest_education', 'license_number', 'expiry_date_of_license',
           'expected_monthly_income', 'current_monthly_income', 'marital_status',
           'preferred_location', 'aadhar_number', 'aadhar_photo', 'driving_license'];

foreach ($fields as $field) {
    $value = $user1[$field] ?? 'NOT_EXISTS';
    $display = $value === null ? '[NULL]' : ($value === '' ? '[EMPTY]' : $value);
    echo "{$field}: {$display}\n";
}

echo "\n" . str_repeat("=", 100) . "\n";
echo "METHOD 2: Specific SELECT (profile_completion_api.php)\n";
echo str_repeat("=", 100) . "\n";

$stmt2 = $conn->prepare("
    SELECT 
        id, unique_id, name, email, city, status, sex, vehicle_type,
        father_name, images, address, dob, role, created_at, updated_at,
        type_of_license, driving_experience, highest_education, license_number,
        expiry_date_of_license, expected_monthly_income, current_monthly_income,
        marital_status, preferred_location, aadhar_number, aadhar_photo,
        driving_license, previous_employer, job_placement
    FROM users 
    WHERE id = ?
");

$stmt2->bind_param("i", $userId);
$stmt2->execute();
$result2 = $stmt2->get_result();
$user2 = $result2->fetch_assoc();

foreach ($fields as $field) {
    $value = $user2[$field] ?? 'NOT_EXISTS';
    $display = $value === null ? '[NULL]' : ($value === '' ? '[EMPTY]' : $value);
    echo "{$field}: {$display}\n";
}

echo "\n" . str_repeat("=", 100) . "\n";
echo "COMPARISON\n";
echo str_repeat("=", 100) . "\n";

$differences = 0;
foreach ($fields as $field) {
    $val1 = $user1[$field] ?? null;
    $val2 = $user2[$field] ?? null;
    
    if ($val1 !== $val2) {
        $differences++;
        echo "DIFFERENCE in {$field}:\n";
        echo "  SELECT *: " . ($val1 === null ? '[NULL]' : $val1) . "\n";
        echo "  Specific: " . ($val2 === null ? '[NULL]' : $val2) . "\n";
    }
}

if ($differences === 0) {
    echo "✓ NO DIFFERENCES - Both methods return the same data\n";
    echo "\nThe issue must be in the field checking logic, not the data retrieval.\n";
} else {
    echo "\n✗ FOUND {$differences} DIFFERENCES\n";
}
?>
