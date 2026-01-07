<?php
// Debug driver profile completion calculation

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    die('Database connection failed: ' . $e->getMessage());
}

// Get a driver with only basic fields filled
$stmt = $pdo->query("
    SELECT * FROM users 
    WHERE role = 'driver' 
    AND name IS NOT NULL 
    AND email IS NOT NULL 
    AND mobile IS NOT NULL 
    AND states IS NOT NULL
    ORDER BY id DESC
    LIMIT 5
");

$drivers = $stmt->fetchAll();

echo "Testing Driver Profile Completion\n";
echo "==================================\n\n";

foreach ($drivers as $driver) {
    echo "Driver ID: " . $driver['id'] . "\n";
    echo "Name: " . $driver['name'] . "\n";
    echo "Email: " . $driver['email'] . "\n";
    echo "Mobile: " . $driver['mobile'] . "\n";
    echo "States: " . $driver['states'] . "\n\n";
    
    // Test with current function
    $completion = calculateProfileCompletionFast($driver);
    echo "Calculated Completion: " . $completion . "%\n\n";
    
    // Manual check of all fields
    $driverFields = [
        'name', 'email', 'mobile', 'states', 'city', 'sex', 'vehicle_type',
        'father_name', 'images', 'address', 'dob',
        'type_of_license', 'driving_experience', 'highest_education', 'license_number',
        'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
        'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
        'driving_license', 'previous_employer', 'job_placement'
    ];
    
    $filled = 0;
    echo "Field Status:\n";
    foreach ($driverFields as $field) {
        $value = $driver[$field] ?? null;
        $isFilled = false;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $isFilled = true;
            } elseif (!is_array($decoded)) {
                $isFilled = true;
            }
        }
        
        if ($isFilled) $filled++;
        
        $displayValue = '';
        if ($isFilled) {
            if (is_string($value) && strlen($value) > 30) {
                $displayValue = ' = ' . substr($value, 0, 30) . '...';
            } else {
                $displayValue = ' = ' . $value;
            }
        }
        
        echo "  " . str_pad($field, 25) . ": " . ($isFilled ? "✓" : "✗") . $displayValue . "\n";
    }
    
    echo "\nTotal: $filled / " . count($driverFields) . " = " . round(($filled / count($driverFields)) * 100) . "%\n";
    echo "\n" . str_repeat("-", 60) . "\n\n";
}

// Copy the function from search_users_api.php
function calculateProfileCompletionFast($user) {
    $role = $user['role'] ?? 'driver';
    
    $requiredFields = [];
    if ($role === 'driver') {
        $requiredFields = [
            'name', 'email', 'mobile', 'states', 'city', 'sex', 'vehicle_type',
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
    } else {
        return 0;
    }
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    
    if ($totalFields === 0) {
        return 0;
    }
    
    foreach ($requiredFields as $field) {
        $value = $user[$field] ?? null;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $filledFields++;
            } elseif (!is_array($decoded)) {
                $filledFields++;
            }
        }
    }
    
    $completionPercentage = round(($filledFields / $totalFields) * 100);
    
    return $completionPercentage;
}
?>
