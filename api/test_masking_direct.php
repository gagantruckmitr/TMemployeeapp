<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/profile_completion_helper.php';

echo "=== TESTING MASKING FUNCTION ===\n\n";

// Test the masking function
$testNumbers = [
    '321000000000',  // Aadhar (12 digits)
    'UP1420140002070',  // License
    'AAKCT8410G',  // PAN
    '446780137289',  // Aadhar
    'DL111998085044',  // License
];

foreach ($testNumbers as $number) {
    $masked = maskSensitiveNumber($number);
    echo "Original: $number\n";
    echo "Masked:   $masked\n";
    echo "\n";
}

echo "\n=== TESTING WITH REAL USER DATA ===\n\n";

$testUsers = [92, 90, 202, 204, 205];

foreach ($testUsers as $userId) {
    echo "User ID: $userId\n";
    echo str_repeat('-', 60) . "\n";
    
    $profileData = getProfileCompletionData($conn, $userId);
    
    if ($profileData !== 0) {
        $docValues = $profileData['document_values'];
        
        echo "Aadhar Number: " . ($docValues['aadhar_number'] ?? 'NULL') . "\n";
        echo "License Number: " . ($docValues['license_number'] ?? 'NULL') . "\n";
        echo "PAN Number: " . ($docValues['pan_number'] ?? 'NULL') . "\n";
        echo "GST Number: " . ($docValues['gst_number'] ?? 'NULL') . "\n";
        echo "Profile Completion: " . $profileData['percentage'] . "%\n";
    } else {
        echo "User not found\n";
    }
    
    echo "\n";
}
?>
