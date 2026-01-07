<?php
/**
 * Test script to verify profile completion percentage consistency
 * between smart calling card and profile completion details screen
 */

header('Content-Type: application/json');
require_once 'config.php';
require_once 'profile_completion_helper.php';

try {
    // Test with a specific user ID (replace with actual driver ID)
    $userId = $_GET['user_id'] ?? 0;
    
    if (!$userId) {
        echo json_encode([
            'error' => 'Please provide user_id parameter',
            'example' => '?user_id=123'
        ]);
        exit;
    }
    
    // Method 1: Using PDO (fresh_leads_api.php method)
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("
        SELECT 
            name, email, mobile, city, states, status, sex, vehicle_type, role,
            father_name, images, address, dob,
            type_of_license, driving_experience, highest_education, license_number,
            expiry_date_of_license, expected_monthly_income, current_monthly_income,
            marital_status, preferred_location, aadhar_number, aadhar_photo,
            driving_license, previous_employer, job_placement,
            transport_name, year_of_establishment, fleet_size, operational_segment,
            average_km, pan_number, pan_image, gst_certificate
        FROM users 
        WHERE id = ?
    ");
    
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user) {
        echo json_encode(['error' => 'User not found']);
        exit;
    }
    
    $role = $user['role'];
    
    // Calculate using fresh_leads_api.php logic (FIXED)
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
    }
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    $fieldDetails = [];
    
    foreach ($requiredFields as $field) {
        $value = $user[$field] ?? null;
        $isPresent = false;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                // CRITICAL: Empty arrays should NOT count as filled
                if (count($decoded) > 0) {
                    $isPresent = true;
                }
            } else {
                $isPresent = true;
            }
        }
        
        if ($isPresent) {
            $filledFields++;
        }
        
        $fieldDetails[$field] = [
            'filled' => $isPresent,
            'value' => is_array($decoded ?? null) ? 'array[' . count($decoded) . ']' : ($value ? 'present' : 'empty')
        ];
    }
    
    $smartCallingPercentage = round(($filledFields / $totalFields) * 100);
    
    // Method 2: Using mysqli (profile_completion_helper.php method)
    $profileData = getProfileCompletionData($conn, $userId);
    $profileDetailsPercentage = $profileData['percentage'];
    
    echo json_encode([
        'success' => true,
        'user_id' => $userId,
        'name' => $user['name'],
        'role' => $role,
        'smart_calling_card_percentage' => $smartCallingPercentage,
        'profile_details_screen_percentage' => $profileDetailsPercentage,
        'match' => $smartCallingPercentage === $profileDetailsPercentage,
        'filled_fields' => $filledFields,
        'total_fields' => $totalFields,
        'field_details' => $fieldDetails,
        'note' => 'Both percentages should now match after the fix'
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>
