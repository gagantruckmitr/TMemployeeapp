<?php
/**
 * Shared helper function for calculating profile completion
 * Used by both profile_completion_api.php and phase2_job_applicants_api.php
 */

/**
 * Mask sensitive numbers - show first 2 and last 2 digits only
 * Example: 1234567890 becomes 12******90
 */
function maskSensitiveNumber($number) {
    if (empty($number)) {
        return $number;
    }
    
    // Convert to string to handle scientific notation
    $number = (string)$number;
    $number = trim($number);
    
    // Remove any scientific notation by formatting as string
    if (is_numeric($number) && strpos($number, 'E') !== false) {
        $number = sprintf('%.0f', floatval($number));
    }
    
    $length = strlen($number);
    
    // If too short to mask, return as is
    if ($length <= 4) {
        return $number;
    }
    
    $first2 = substr($number, 0, 2);
    $last2 = substr($number, -2);
    $maskedLength = $length - 4;
    $masked = str_repeat('*', $maskedLength);
    
    return $first2 . $masked . $last2;
}

function getProfileCompletionData($conn, $userId, $roleOverride = null) {
    // Fetch user data with joins for vehicle_type and states
    $stmt = $conn->prepare("
        SELECT 
            u.id, u.unique_id, u.name, u.email, u.mobile, u.city, u.status, u.sex, u.vehicle_type,
            u.father_name, u.images, u.address, u.dob, u.role, u.created_at, u.updated_at,
            u.type_of_license, u.driving_experience, u.highest_education, u.license_number,
            u.expiry_date_of_license, u.expected_monthly_income, u.current_monthly_income,
            u.marital_status, u.preferred_location, u.aadhar_number, u.aadhar_photo,
            u.driving_license, u.previous_employer, u.job_placement,
            u.transport_name, u.year_of_establishment, u.fleet_size, u.operational_segment,
            u.average_km, u.pan_number, u.pan_image, u.gst_number, u.gst_certificate, u.states,
            COALESCE(vt.vehicle_name, u.vehicle_type) as vehicle_type_name,
            s.name as state_name,
            s2.name as preferred_location_name
        FROM users u
        LEFT JOIN vehicle_type vt ON CAST(u.vehicle_type AS UNSIGNED) = vt.id
        LEFT JOIN states s ON u.states = s.id
        LEFT JOIN states s2 ON CAST(u.preferred_location AS UNSIGNED) = s2.id
        WHERE u.id = ?
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        return 0;
    }
    
    $user = $result->fetch_assoc();
    // Use role override if provided, otherwise use database role
    $role = $roleOverride ?? $user['role'];
    
    // Define required fields based on role (excluding system fields)
    $requiredFields = [];
    $displayFields = []; // Fields with proper names for display
    
    if ($role === 'driver') {
        // Exclude system fields: unique_id, id, status, role, created_at, updated_at
        // Total: 23 fields to match Flutter app expectations
        $requiredFields = [
            'name', 'email', 'mobile', 'city', 'sex', 'vehicle_type',
            'father_name', 'images', 'address', 'dob',
            'type_of_license', 'driving_experience', 'highest_education', 'license_number',
            'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
            'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
            'driving_license', 'previous_employer', 'job_placement'
        ];
        
        // Map fields to their display names
        $displayFields = [
            'vehicle_type' => 'vehicle_type_name',
            'preferred_location' => 'preferred_location_name',
            'states' => 'state_name'
        ];
    } elseif ($role === 'transporter') {
        // Exclude system fields: unique_id, id
        // MUST MATCH transporter_leads_api.php calculateTransporterProfileCompletion()
        $requiredFields = [
            'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
            'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
            'images', 'address', 'pan_number', 'pan_image', 'gst_number', 'gst_certificate'
        ];
    }
    
    $documentStatus = [];
    $documentValues = [];
    $filledFields = 0;
    $totalFields = count($requiredFields);
    
    // Sensitive fields that need masking
    $sensitiveFields = ['license_number', 'pan_number', 'gst_number', 'aadhar_number'];
    
    foreach ($requiredFields as $field) {
        // Check if there's a display field mapping (e.g., vehicle_type -> vehicle_type_name)
        $displayField = $displayFields[$field] ?? $field;
        $value = $user[$displayField] ?? $user[$field] ?? null;
        $isPresent = false;
        $displayValue = null;
        
        if ($value !== null && $value !== '') {
            // Check if it's a JSON array with content
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $isPresent = true;
                // For arrays, show count or first item
                if (isset($decoded[0])) {
                    $displayValue = is_string($decoded[0]) ? $decoded[0] : json_encode($decoded[0]);
                } else {
                    $displayValue = count($decoded) . ' items';
                }
            } elseif (is_array($decoded) && count($decoded) === 0) {
                // Empty array - not present
                $isPresent = false;
            } else {
                // Not an array and not empty
                $isPresent = true;
                $displayValue = $value;
                
                // Mask sensitive fields (show first 2 and last 2 digits only)
                if (in_array($field, $sensitiveFields)) {
                    $displayValue = maskSensitiveNumber($value);
                }
            }
        }
        
        $documentStatus[$field] = $isPresent;
        $documentValues[$field] = $displayValue;
        
        if ($isPresent) {
            $filledFields++;
        }
    }
    
    // Add additional fields for display (state, vehicle name, location name)
    $documentValues['state'] = $user['state_name'] ?? null;
    $documentValues['vehicle_type_display'] = $user['vehicle_type_name'] ?? null;
    $documentValues['preferred_location_display'] = $user['preferred_location_name'] ?? null;
    
    $completionPercentage = $totalFields > 0 ? round(($filledFields / $totalFields) * 100) : 0;
    
    return [
        'percentage' => $completionPercentage,
        'filled_fields' => $filledFields,
        'total_fields' => $totalFields,
        'document_status' => $documentStatus,
        'document_values' => $documentValues,
        'user_data' => $user
    ];
}

// Simple function that just returns the percentage
function calculateProfileCompletion($conn, $userId, $roleOverride = null) {
    $data = getProfileCompletionData($conn, $userId, $roleOverride);
    return $data['percentage'];
}
?>
