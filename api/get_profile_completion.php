<?php
// Get Profile Completion API - Returns profile completion percentage for a user
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit;
}

try {
    $userId = (int)($_GET['user_id'] ?? 0);
    
    if (!$userId) {
        throw new Exception('user_id parameter required');
    }
    
    // Fetch user data
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
        throw new Exception('User not found');
    }
    
    $role = $user['role'];
    
    // Define required fields based on role
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
    
    if ($totalFields === 0) {
        $completionPercentage = 0;
    } else {
        foreach ($requiredFields as $field) {
            $value = $user[$field] ?? null;
            
            if ($value !== null && $value !== '') {
                // Check if it's a JSON array with content
                $decoded = json_decode($value, true);
                if (is_array($decoded) && count($decoded) > 0) {
                    $filledFields++;
                } elseif (!is_array($decoded)) {
                    $filledFields++;
                }
            }
        }
        
        $completionPercentage = round(($filledFields / $totalFields) * 100);
    }
    
    echo json_encode([
        'success' => true,
        'user_id' => $userId,
        'role' => $role,
        'profile_completion' => $completionPercentage,
        'filled_fields' => $filledFields,
        'total_fields' => $totalFields
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
