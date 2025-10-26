<?php
// Simple CLI test for profile completion API
require_once __DIR__ . '/config.php';

echo "=== Profile Completion API Test ===\n\n";

// Test database connection
echo "1. Testing database connection...\n";
if ($conn->connect_error) {
    die("❌ Connection failed: " . $conn->connect_error . "\n");
}
echo "✅ Database connected\n\n";

// Get a sample user
echo "2. Fetching sample user...\n";
$result = $conn->query("SELECT id, unique_id, name, role FROM users WHERE role = 'driver' LIMIT 1");

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "✅ Found user: {$user['name']} ({$user['unique_id']})\n";
    echo "   Role: {$user['role']}\n";
    echo "   ID: {$user['id']}\n\n";
    
    $userId = $user['id'];
    
    // Test profile completion calculation
    echo "3. Testing profile completion calculation...\n";
    
    $stmt = $conn->prepare("
        SELECT 
            name, email, city, status, sex, vehicle_type,
            father_name, images, address, dob, role,
            type_of_license, driving_experience, highest_education, license_number,
            expiry_date_of_license, expected_monthly_income, current_monthly_income,
            marital_status, preferred_location, aadhar_number, aadhar_photo,
            driving_license, previous_employer, job_placement
        FROM users 
        WHERE id = ?
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $userData = $result->fetch_assoc();
    
    $requiredFields = [
        'name', 'email', 'city', 'sex', 'vehicle_type',
        'father_name', 'images', 'address', 'dob',
        'type_of_license', 'driving_experience', 'highest_education', 'license_number',
        'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
        'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
        'driving_license', 'previous_employer', 'job_placement'
    ];
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    $documentStatus = [];
    
    foreach ($requiredFields as $field) {
        $value = $userData[$field] ?? null;
        $isPresent = false;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $isPresent = true;
            } elseif (!is_array($decoded)) {
                $isPresent = true;
            }
        }
        
        $documentStatus[$field] = $isPresent;
        if ($isPresent) {
            $filledFields++;
        }
    }
    
    $percentage = round(($filledFields / $totalFields) * 100);
    
    echo "✅ Profile completion calculated\n";
    echo "   Percentage: {$percentage}%\n";
    echo "   Filled: {$filledFields}/{$totalFields}\n";
    echo "   Missing: " . ($totalFields - $filledFields) . "\n\n";
    
    // Show document status
    echo "4. Document Status:\n";
    $presentDocs = [];
    $missingDocs = [];
    
    foreach ($documentStatus as $field => $isPresent) {
        if ($isPresent) {
            $presentDocs[] = $field;
        } else {
            $missingDocs[] = $field;
        }
    }
    
    echo "   ✅ Present (" . count($presentDocs) . "):\n";
    foreach ($presentDocs as $doc) {
        echo "      - " . ucwords(str_replace('_', ' ', $doc)) . "\n";
    }
    
    echo "\n   ❌ Missing (" . count($missingDocs) . "):\n";
    foreach ($missingDocs as $doc) {
        echo "      - " . ucwords(str_replace('_', ' ', $doc)) . "\n";
    }
    
    echo "\n5. Testing API endpoint...\n";
    $apiUrl = "http://localhost" . dirname($_SERVER['SCRIPT_NAME']) . "/profile_completion_api.php?action=get_profile_details&user_id=" . $userId;
    echo "   URL: {$apiUrl}\n";
    echo "   (Access this URL in your browser to test the API)\n";
    
} else {
    echo "❌ No users found in database\n";
}

echo "\n=== Test Complete ===\n";
echo "\nTo test in browser, visit:\n";
echo "http://your-domain/api/test_profile_completion.php\n";

$conn->close();
?>
