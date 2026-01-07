<?php
/**
 * Test Script: Callback Requests Profile Completion & Assigned Telecaller
 * 
 * This script tests:
 * 1. Profile completion calculation for a specific user
 * 2. Assigned telecaller name retrieval
 * 
 * Usage: 
 * - Update $testUniqueId with a real unique_id from your database
 * - Run: php api/test_callback_profile_completion.php
 * - Or access via browser: http://your-domain/api/test_callback_profile_completion.php
 */

require_once 'config.php';

// TEST CONFIGURATION
$testUniqueId = 'TM000001'; // Change this to a real unique_id from your database

echo "<h1>Callback Requests - Profile Completion & Assigned Telecaller Test</h1>\n";
echo "<hr>\n";

// Fetch user
$userSql = "SELECT * FROM users WHERE unique_id = ? LIMIT 1";
$stmt = $conn->prepare($userSql);
$stmt->bind_param("s", $testUniqueId);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if (!$user) {
    echo "<p style='color: red;'>❌ User not found with unique_id: $testUniqueId</p>\n";
    echo "<p>Please update the \$testUniqueId variable in this script with a valid unique_id from your database.</p>\n";
    exit;
}

echo "<h2>User Information</h2>\n";
echo "<table border='1' cellpadding='5'>\n";
echo "<tr><th>Field</th><th>Value</th></tr>\n";
echo "<tr><td>Unique ID</td><td>{$user['unique_id']}</td></tr>\n";
echo "<tr><td>Name</td><td>{$user['name']}</td></tr>\n";
echo "<tr><td>Role</td><td>{$user['role']}</td></tr>\n";
echo "<tr><td>Mobile</td><td>{$user['mobile']}</td></tr>\n";
echo "</table>\n";

// Test Profile Completion
echo "<h2>Profile Completion Test</h2>\n";

$role = $user['role'] ?? '';
$requiredFields = [];

if ($role === 'driver') {
    $requiredFields = [
        'name', 'email', 'mobile', 'city', 'sex', 'vehicle_type',
        'father_name', 'images', 'address', 'dob',
        'type_of_license', 'driving_experience', 'highest_education', 'license_number',
        'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
        'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
        'driving_license', 'previous_employer', 'job_placement'
    ];
} elseif ($role === 'transporter') {
    $requiredFields = [
        'name', 'email', 'transport_name', 'year_of_establishment',
        'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
        'pan_number', 'pan_image', 'gst_certificate'
    ];
}

$filledFields = 0;
$totalFields = count($requiredFields);
$filledFieldsList = [];
$missingFieldsList = [];

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    
    if ($value !== null && $value !== '') {
        $decodedJson = json_decode($value, true);
        if (is_array($decodedJson)) {
            if (count($decodedJson) > 0) {
                $filledFields++;
                $filledFieldsList[] = $field;
            } else {
                $missingFieldsList[] = "$field (empty array)";
            }
        } else {
            $filledFields++;
            $filledFieldsList[] = $field;
        }
    } else {
        $missingFieldsList[] = "$field (null/empty)";
    }
}

$completionPercentage = ($filledFields / $totalFields) * 100;

echo "<p><strong>Total Required Fields:</strong> $totalFields</p>\n";
echo "<p><strong>Filled Fields:</strong> $filledFields</p>\n";
echo "<p><strong>Profile Completion:</strong> <span style='font-size: 24px; color: green;'>" . round($completionPercentage) . "%</span></p>\n";

echo "<h3>✅ Filled Fields ($filledFields)</h3>\n";
echo "<ul>\n";
foreach ($filledFieldsList as $field) {
    echo "<li style='color: green;'>$field</li>\n";
}
echo "</ul>\n";

echo "<h3>❌ Missing Fields (" . count($missingFieldsList) . ")</h3>\n";
echo "<ul>\n";
foreach ($missingFieldsList as $field) {
    echo "<li style='color: red;'>$field</li>\n";
}
echo "</ul>\n";

// Test Assigned Telecaller
echo "<hr>\n";
echo "<h2>Assigned Telecaller Test</h2>\n";

// Check callback_requests table
$cbSql = "SELECT assigned_to FROM callback_requests WHERE unique_id = ? LIMIT 1";
$cbStmt = $conn->prepare($cbSql);
$cbStmt->bind_param("s", $testUniqueId);
$cbStmt->execute();
$cbResult = $cbStmt->get_result()->fetch_assoc();

$assignedToId = $cbResult['assigned_to'] ?? $user['assigned_to'] ?? null;

echo "<p><strong>Assigned To ID (from callback_requests):</strong> " . ($cbResult['assigned_to'] ?? 'NULL') . "</p>\n";
echo "<p><strong>Assigned To ID (from users):</strong> " . ($user['assigned_to'] ?? 'NULL') . "</p>\n";
echo "<p><strong>Final Assigned To ID:</strong> " . ($assignedToId ?? 'NULL') . "</p>\n";

if ($assignedToId) {
    $tcSql = "SELECT id, name, role FROM admins WHERE id = ? LIMIT 1";
    $tcStmt = $conn->prepare($tcSql);
    $tcStmt->bind_param("i", $assignedToId);
    $tcStmt->execute();
    $telecaller = $tcStmt->get_result()->fetch_assoc();
    
    if ($telecaller) {
        echo "<p><strong>✅ Assigned Telecaller:</strong> <span style='color: green; font-size: 18px;'>{$telecaller['name']}</span></p>\n";
        echo "<p><strong>Telecaller Role:</strong> {$telecaller['role']}</p>\n";
    } else {
        echo "<p style='color: red;'>❌ No admin found with ID: $assignedToId</p>\n";
    }
} else {
    echo "<p style='color: orange;'>⚠️ No telecaller assigned to this user</p>\n";
}

echo "<hr>\n";
echo "<h2>Summary</h2>\n";
echo "<ul>\n";
echo "<li><strong>Profile Completion:</strong> " . round($completionPercentage) . "% ($filledFields/$totalFields fields)</li>\n";
echo "<li><strong>Assigned Telecaller:</strong> " . ($telecaller['name'] ?? 'N/A') . "</li>\n";
echo "</ul>\n";

echo "<p><em>Test completed at " . date('Y-m-d H:i:s') . "</em></p>\n";
?>
