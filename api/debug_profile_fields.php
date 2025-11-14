<?php
header('Content-Type: application/json');
require_once 'config.php';

$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    echo json_encode(['error' => 'user_id required']);
    exit;
}

// Fetch user data
$query = "SELECT * FROM users WHERE id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['error' => 'User not found']);
    exit;
}

$user = $result->fetch_assoc();

// Check each field
$requiredFields = [
    'name', 'email', 'city', 'sex', 'vehicle_type',
    'father_name', 'images', 'address', 'dob',
    'type_of_license', 'driving_experience', 'highest_education', 'license_number',
    'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
    'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
    'driving_license', 'previous_employer', 'job_placement'
];

$fieldDetails = [];
$filledCount = 0;

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    $rawValue = $value;
    
    // Check if filled
    $isFilled = false;
    $reason = '';
    
    if ($value === null) {
        $reason = 'NULL';
    } elseif ($value === '') {
        $reason = 'Empty string';
    } elseif ($value === '0000-00-00') {
        $reason = 'Invalid date';
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
                $reason = 'Empty JSON array';
            }
        } else {
            $isFilled = true;
            $reason = 'Has value';
        }
    }
    
    if ($isFilled) {
        $filledCount++;
    }
    
    $fieldDetails[$field] = [
        'value' => $rawValue,
        'isFilled' => $isFilled,
        'reason' => $reason,
        'type' => gettype($value),
        'length' => is_string($value) ? strlen($value) : null
    ];
}

$percentage = round(($filledCount / count($requiredFields)) * 100);

echo json_encode([
    'userId' => $userId,
    'name' => $user['name'],
    'role' => $user['role'],
    'totalFields' => count($requiredFields),
    'filledFields' => $filledCount,
    'percentage' => $percentage,
    'fieldDetails' => $fieldDetails
], JSON_PRETTY_PRINT);
?>
