<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/profile_completion_helper.php';

// Test with a driver user
$driverUserId = 1; // Change this to a real driver ID
$transporterUserId = 2; // Change this to a real transporter ID

echo "=== TESTING DRIVER PROFILE ===\n\n";

$driverData = getProfileCompletionData($conn, $driverUserId);

if ($driverData !== 0) {
    echo "Driver Fields:\n";
    echo "Aadhar Number: " . ($driverData['document_values']['aadhar_number'] ?? 'NULL') . "\n";
    echo "License Number: " . ($driverData['document_values']['license_number'] ?? 'NULL') . "\n";
    echo "\n";
}

echo "\n=== TESTING TRANSPORTER PROFILE ===\n\n";

$transporterData = getProfileCompletionData($conn, $transporterUserId, 'transporter');

if ($transporterData !== 0) {
    echo "Transporter Fields:\n";
    echo "PAN Number: " . ($transporterData['document_values']['pan_number'] ?? 'NULL') . "\n";
    echo "GST Certificate: " . ($transporterData['document_values']['gst_certificate'] ?? 'NULL') . "\n";
    echo "\n";
}

// Query to find users with these fields
echo "\n=== FINDING USERS WITH SENSITIVE DATA ===\n\n";

$query = "SELECT id, unique_id, name, role, aadhar_number, license_number, pan_number 
          FROM users 
          WHERE (aadhar_number IS NOT NULL AND aadhar_number != '') 
             OR (license_number IS NOT NULL AND license_number != '')
             OR (pan_number IS NOT NULL AND pan_number != '')
          LIMIT 5";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        echo "User ID: {$row['id']} ({$row['unique_id']}) - {$row['name']} - Role: {$row['role']}\n";
        echo "  Aadhar: " . ($row['aadhar_number'] ?: 'NULL') . "\n";
        echo "  License: " . ($row['license_number'] ?: 'NULL') . "\n";
        echo "  PAN: " . ($row['pan_number'] ?: 'NULL') . "\n";
        echo "\n";
    }
} else {
    echo "No users found with sensitive data\n";
}
?>
