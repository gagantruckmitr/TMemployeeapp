<?php
/**
 * Debug script to check profile completion calculation for callback requests
 */

require_once 'config.php';

// Get a callback request to test
$sql = "SELECT cr.*, u.* 
        FROM callback_requests cr
        LEFT JOIN users u ON cr.unique_id = u.unique_id
        WHERE u.role = 'transporter'
        LIMIT 1";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    
    echo "=== CALLBACK REQUEST DEBUG ===\n";
    echo "User Name: {$row['user_name']}\n";
    echo "Unique ID: {$row['unique_id']}\n";
    echo "Role: {$row['role']}\n\n";
    
    echo "=== DATABASE VALUES ===\n";
    echo "users.profile_completion (if exists): " . ($row['profile_completion'] ?? 'NULL') . "\n\n";
    
    echo "=== CALCULATED PROFILE COMPLETION ===\n";
    
    // Calculate profile completion using the same logic as callback_requests_api.php
    $requiredFields = [];
    $role = $row['role'] ?? '';

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

    $filledFields = 0;
    $totalFields = count($requiredFields);
    $missingFields = [];
    $filledFieldsList = [];
    
    foreach ($requiredFields as $field) {
        $value = $row[$field] ?? null;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $filledFields++;
                $filledFieldsList[] = $field;
            } elseif (is_array($decoded) && count($decoded) === 0) {
                $missingFields[] = $field;
            } else {
                $filledFields++;
                $filledFieldsList[] = $field;
            }
        } else {
            $missingFields[] = $field;
        }
    }

    $completionPercentage = ($filledFields / $totalFields) * 100;
    
    echo "Total Fields Required: $totalFields\n";
    echo "Filled Fields: $filledFields\n";
    echo "Completion Percentage: " . round($completionPercentage) . "%\n\n";
    
    echo "=== FILLED FIELDS ===\n";
    foreach ($filledFieldsList as $field) {
        $value = $row[$field];
        if (strlen($value) > 50) {
            $value = substr($value, 0, 50) . '...';
        }
        echo "✅ $field: $value\n";
    }
    
    echo "\n=== MISSING FIELDS ===\n";
    foreach ($missingFields as $field) {
        echo "❌ $field\n";
    }
    
} else {
    echo "No transporter callback requests found\n";
}
?>
