<?php
// Test script to verify profile completion calculation in search_users_api.php

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    die('Database connection failed: ' . $e->getMessage());
}

// Test with a driver and a transporter
echo "Testing Profile Completion Calculation\n";
echo "========================================\n\n";

// Get a sample driver
$stmt = $pdo->query("SELECT * FROM users WHERE role = 'driver' LIMIT 1");
$driver = $stmt->fetch();

if ($driver) {
    echo "DRIVER TEST:\n";
    echo "ID: " . $driver['id'] . "\n";
    echo "Name: " . $driver['name'] . "\n";
    
    // Calculate using the function from search_users_api.php
    $driverCompletion = calculateProfileCompletionFast($driver);
    echo "Profile Completion: " . $driverCompletion . "%\n\n";
    
    // Show which fields are filled
    $driverFields = [
        'name', 'email', 'city', 'sex', 'vehicle_type',
        'father_name', 'images', 'address', 'dob',
        'type_of_license', 'driving_experience', 'highest_education', 'license_number',
        'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
        'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
        'driving_license', 'previous_employer', 'job_placement'
    ];
    
    $filled = 0;
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
        echo "  $field: " . ($isFilled ? "✓" : "✗") . "\n";
    }
    echo "Filled: $filled / " . count($driverFields) . "\n\n";
}

// Get a sample transporter
$stmt = $pdo->query("SELECT * FROM users WHERE role = 'transporter' LIMIT 1");
$transporter = $stmt->fetch();

if ($transporter) {
    echo "TRANSPORTER TEST:\n";
    echo "ID: " . $transporter['id'] . "\n";
    echo "Name: " . $transporter['name'] . "\n";
    
    // Calculate using the function from search_users_api.php
    $transporterCompletion = calculateProfileCompletionFast($transporter);
    echo "Profile Completion: " . $transporterCompletion . "%\n\n";
    
    // Show which fields are filled - MUST INCLUDE 'mobile' and 'states'
    $transporterFields = [
        'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
        'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
        'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
    ];
    
    $filled = 0;
    foreach ($transporterFields as $field) {
        $value = $transporter[$field] ?? null;
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
        echo "  $field: " . ($isFilled ? "✓" : "✗") . " = " . (is_string($value) && strlen($value) > 50 ? substr($value, 0, 50) . "..." : $value) . "\n";
    }
    echo "Filled: $filled / " . count($transporterFields) . " = " . round(($filled / count($transporterFields)) * 100) . "%\n\n";
}

// Copy the function from search_users_api.php
function calculateProfileCompletionFast($user) {
    $role = $user['role'] ?? 'driver';
    
    $requiredFields = [];
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

echo "Test completed!\n";
?>
