<?php
/**
 * Debug Callback Profile Completion
 * Test the exact calculation used in callback_requests_api.php
 */

require_once 'config.php';

// Get a callback request to test
$callbackId = $_GET['callback_id'] ?? null;

if (!$callbackId) {
    // Get first callback request
    $stmt = $conn->prepare("SELECT * FROM callback_requests ORDER BY id DESC LIMIT 1");
    $stmt->execute();
    $callback = $stmt->get_result()->fetch_assoc();
    if ($callback) {
        $callbackId = $callback['id'];
    }
}

if (!$callbackId) {
    die("No callback requests found");
}

// Fetch callback request
$stmt = $conn->prepare("SELECT * FROM callback_requests WHERE id = ?");
$stmt->bind_param("i", $callbackId);
$stmt->execute();
$callback = $stmt->get_result()->fetch_assoc();

echo "<h2>Callback Request Debug</h2>";
echo "<p>Callback ID: {$callback['id']}</p>";
echo "<p>Unique ID: {$callback['unique_id']}</p>";
echo "<p>User Name: {$callback['user_name']}</p>";

// Fetch user data - EXACT SAME QUERY as callback_requests_api.php
$uniqueId = $callback['unique_id'];
$userSql = "SELECT * FROM users WHERE unique_id = ? LIMIT 1";
$uStmt = $conn->prepare($userSql);
$uStmt->bind_param("s", $uniqueId);
$uStmt->execute();
$user = $uStmt->get_result()->fetch_assoc();

if (!$user) {
    die("User not found for unique_id: $uniqueId");
}

echo "<h3>User: {$user['name']} (Role: {$user['role']})</h3>";

// Calculate profile completion - EXACT SAME LOGIC as callback_requests_api.php
$requiredFields = [];
$role = $user['role'] ?? '';

if ($role === 'driver') {
    $requiredFields = [
        'name', 'email', 'city', 'sex', 'vehicle_type',
        'father_name', 'images', 'address', 'dob',
        'type_of_license', 'driving_experience', 'highest_education', 'license_number',
        'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
        'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
        'driving_license', 'previous_employer', 'job_placement'
    ];
} elseif ($role === 'transporter') {
    $requiredFields = [
        'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
        'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
        'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
    ];
}

echo "<h4>Required Fields (" . count($requiredFields) . " total):</h4>";
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>Field</th><th>Status</th><th>Value</th><th>Debug</th></tr>";

$filledFields = 0;
$missingFields = [];
$filledFieldsList = [];

foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    $isFilled = false;
    $displayValue = 'NULL';
    $debug = '';
    
    if ($value !== null && $value !== '') {
        // Check if it's a JSON array with content - EXACT MATCH with profile_completion_helper.php
        $decoded = json_decode($value, true);
        
        if (is_array($decoded) && count($decoded) > 0) {
            $isFilled = true;
            $displayValue = "JSON Array (" . count($decoded) . " items)";
            $debug = "is_array=true, count=" . count($decoded);
        } elseif (is_array($decoded) && count($decoded) === 0) {
            // Empty array - not present
            $isFilled = false;
            $displayValue = "Empty JSON Array";
            $debug = "is_array=true, count=0 (EMPTY)";
        } else {
            // Not an array and not empty - it's a regular value
            $isFilled = true;
            $displayValue = strlen($value) > 50 ? substr($value, 0, 50) . '...' : $value;
            $debug = "is_array=false (regular value)";
        }
    } else {
        $debug = "value is null or empty string";
    }
    
    if ($isFilled) {
        $filledFields++;
        $filledFieldsList[] = $field;
        $status = "✅ FILLED";
        $color = "#d4edda";
    } else {
        $missingFields[] = $field;
        $status = "❌ MISSING";
        $color = "#f8d7da";
    }
    
    echo "<tr style='background-color: $color'>";
    echo "<td><strong>$field</strong></td>";
    echo "<td>$status</td>";
    echo "<td>" . htmlspecialchars($displayValue) . "</td>";
    echo "<td><small>$debug</small></td>";
    echo "</tr>";
}

echo "</table>";

$totalFields = count($requiredFields);
$completionPercentage = round(($filledFields / $totalFields) * 100);

echo "<h3>Profile Completion: $completionPercentage%</h3>";
echo "<p>Filled: $filledFields / $totalFields</p>";

if (!empty($missingFields)) {
    echo "<h4>Missing Fields:</h4>";
    echo "<ul>";
    foreach ($missingFields as $field) {
        echo "<li>$field</li>";
    }
    echo "</ul>";
}

echo "<hr>";
echo "<h4>What callback_requests_api.php returns:</h4>";
echo "<p>profile_completion: {$completionPercentage}%</p>";

// Show raw user data for debugging
echo "<hr>";
echo "<h4>Raw User Data (first 20 fields):</h4>";
echo "<pre>";
$count = 0;
foreach ($user as $key => $val) {
    if ($count++ > 20) break;
    $displayVal = is_string($val) && strlen($val) > 100 ? substr($val, 0, 100) . '...' : $val;
    echo "$key: " . var_export($displayVal, true) . "\n";
}
echo "</pre>";
?>
