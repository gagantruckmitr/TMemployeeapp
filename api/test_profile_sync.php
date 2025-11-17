<?php
require_once 'config.php';

// Test with a specific user ID
$userId = $_GET['user_id'] ?? 1;

echo "Testing Profile Completion Calculation Sync\n";
echo "==========================================\n\n";

// Get user data
$stmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();
$userData = $result->fetch_assoc();

if (!$userData) {
    die("User not found\n");
}

echo "User: {$userData['name']} (ID: {$userId})\n";
echo "Role: {$userData['role']}\n\n";

// Define required fields (EXACT same as both APIs)
$requiredFields = [
    'name', 'email', 'city', 'Sex', 'vehicle_type', 'Father_Name', 'images', 
    'address', 'DOB', 'Type_of_License', 'Driving_Experience', 'Highest_Education', 
    'License_Number', 'Expiry_date_of_License', 'Expected_Monthly_Income', 
    'Current_Monthly_Income', 'Marital_Status', 'Preferred_Location', 
    'Aadhar_Number', 'Aadhar_Photo', 'Driving_License', 'previous_employer', 
    'job_placement'
];

$totalFields = count($requiredFields);
$filledFields = 0;

echo "Field Analysis:\n";
echo "---------------\n";

foreach ($requiredFields as $field) {
    $value = $userData[$field] ?? null;
    
    // Check if field is filled (not empty, not null, not '0000-00-00', not empty array [])
    $isFilled = false;
    if (!empty($value) && $value !== '0000-00-00') {
        // Handle JSON fields - check if it's an empty array
        $decoded = json_decode($value, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            // It's valid JSON - check if it's an empty array
            $isFilled = !empty($decoded);
        } else {
            // Not JSON, just check if not empty
            $isFilled = true;
        }
    }
    
    if ($isFilled) $filledFields++;
    
    $status = $isFilled ? '✓' : '✗';
    $displayValue = is_string($value) ? substr($value, 0, 30) : json_encode($value);
    echo "$status $field: $displayValue\n";
}

$profileCompletion = $totalFields > 0 ? round(($filledFields / $totalFields) * 100) : 0;

echo "\n";
echo "Results:\n";
echo "--------\n";
echo "Total Fields: $totalFields\n";
echo "Filled Fields: $filledFields\n";
echo "Profile Completion: $profileCompletion%\n";
?>
