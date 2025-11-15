<?php
/**
 * Test script to compare profile completion percentages
 * between the two different calculation methods
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

// Test with a sample driver ID
$testDriverId = isset($_GET['driver_id']) ? intval($_GET['driver_id']) : 1;

echo "<h2>Profile Completion Percentage Comparison</h2>";
echo "<p>Testing with Driver ID: $testDriverId</p>";

// Method 1: Using profile_completion_helper.php (used by job applicants API)
$helperData = getProfileCompletionData($conn, $testDriverId);

// Method 2: Simulating profile_completion_api.php logic
$stmt = $conn->prepare("
    SELECT 
        u.id, u.unique_id, u.name, u.email, u.city, u.status, u.sex, u.vehicle_type,
        u.father_name, u.images, u.address, u.dob, u.role, u.created_at, u.updated_at,
        u.type_of_license, u.driving_experience, u.highest_education, u.license_number,
        u.expiry_date_of_license, u.expected_monthly_income, u.current_monthly_income,
        u.marital_status, u.preferred_location, u.aadhar_number, u.aadhar_photo,
        u.driving_license, u.previous_employer, u.job_placement
    FROM users u
    WHERE u.id = ?
");

$stmt->bind_param("i", $testDriverId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

// Fields counted by profile_completion_api.php (23 fields - NO system fields)
$apiFields = [
    'name', 'email', 'city', 'sex', 'vehicle_type',
    'father_name', 'images', 'address', 'dob',
    'type_of_license', 'driving_experience', 'highest_education', 'license_number',
    'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
    'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
    'driving_license', 'previous_employer', 'job_placement'
];

$apiFilledFields = 0;
foreach ($apiFields as $field) {
    $value = $user[$field] ?? null;
    if ($value !== null && $value !== '') {
        $decoded = json_decode($value, true);
        if (is_array($decoded) && count($decoded) > 0) {
            $apiFilledFields++;
        } elseif (!is_array($decoded)) {
            $apiFilledFields++;
        }
    }
}

$apiPercentage = round(($apiFilledFields / count($apiFields)) * 100);

// Display comparison
echo "<h3>Results:</h3>";
echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Method</th><th>Total Fields</th><th>Filled Fields</th><th>Percentage</th></tr>";
echo "<tr>";
echo "<td><strong>Helper (Job Applicants)</strong></td>";
echo "<td>{$helperData['total_fields']}</td>";
echo "<td>{$helperData['filled_fields']}</td>";
echo "<td><strong>{$helperData['percentage']}%</strong></td>";
echo "</tr>";
echo "<tr>";
echo "<td><strong>API (Profile Details)</strong></td>";
echo "<td>" . count($apiFields) . "</td>";
echo "<td>$apiFilledFields</td>";
echo "<td><strong>$apiPercentage%</strong></td>";
echo "</tr>";
echo "</table>";

echo "<h3>Field Breakdown:</h3>";
echo "<h4>Helper Fields (includes system fields):</h4>";
echo "<pre>";
print_r(array_keys($helperData['document_status']));
echo "</pre>";

echo "<h4>API Fields (excludes system fields):</h4>";
echo "<pre>";
print_r($apiFields);
echo "</pre>";

echo "<h3>Difference Analysis:</h3>";
$helperFields = array_keys($helperData['document_status']);
$extraFields = array_diff($helperFields, $apiFields);
echo "<p><strong>Extra fields in Helper:</strong></p>";
echo "<pre>";
print_r($extraFields);
echo "</pre>";

echo "<h3>Conclusion:</h3>";
if ($helperData['percentage'] != $apiPercentage) {
    echo "<p style='color: red;'><strong>❌ MISMATCH DETECTED!</strong></p>";
    echo "<p>The helper includes system fields that should not be counted:</p>";
    echo "<ul>";
    foreach ($extraFields as $field) {
        echo "<li>$field</li>";
    }
    echo "</ul>";
} else {
    echo "<p style='color: green;'><strong>✅ Both methods match!</strong></p>";
}
?>
