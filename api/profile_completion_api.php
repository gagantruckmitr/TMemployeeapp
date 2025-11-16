<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'get_profile_details':
            getProfileDetails($conn);
            break;
        default:
            throw new Exception('Invalid action');
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

function getProfileDetails($conn) {
    $userId = $_GET['user_id'] ?? null;
    
    if (!$userId) {
        throw new Exception('User ID is required');
    }
    
    // Fetch user data with joins for vehicle_type and states
    $stmt = $conn->prepare("
        SELECT 
            u.id, u.unique_id, u.name, u.email, u.city, u.status, u.Sex, u.vehicle_type,
            u.Father_Name, u.images, u.address, u.DOB, u.role, u.Created_at, u.Updated_at,
            u.Type_of_License, u.Driving_Experience, u.Highest_Education, u.License_Number,
            u.Expiry_date_of_License, u.Expected_Monthly_Income, u.Current_Monthly_Income,
            u.Marital_Status, u.Preferred_Location, u.Aadhar_Number, u.Aadhar_Photo,
            u.Driving_License, u.previous_employer, u.job_placement,
            u.Transport_Name, u.Year_of_Establishment, u.Fleet_Size, u.Operational_Segment,
            u.Average_KM, u.PAN_Number, u.PAN_Image, u.GST_Certificate, u.states,
            COALESCE(vt.vehicle_name, u.vehicle_type) as vehicle_type_name,
            s.name as state_name,
            s2.name as preferred_location_name
        FROM users u
        LEFT JOIN vehicle_type vt ON CAST(u.vehicle_type AS UNSIGNED) = vt.id
        LEFT JOIN states s ON u.states = s.id
        LEFT JOIN states s2 ON CAST(u.Preferred_Location AS UNSIGNED) = s2.id
        WHERE u.id = ?
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('User not found');
    }
    
    $user = $result->fetch_assoc();
    $role = $user['role'];
    
    // Define required fields based on role (excluding system fields)
    $requiredFields = [];
    $displayFields = []; // Fields with proper names for display
    
    if ($role === 'driver') {
        $requiredFields = [
            'name', 'email', 'city', 'Sex', 'vehicle_type',
            'Father_Name', 'images', 'address', 'DOB',
            'Type_of_License', 'Driving_Experience', 'Highest_Education', 'License_Number',
            'Expiry_date_of_License', 'Expected_Monthly_Income', 'Current_Monthly_Income',
            'Marital_Status', 'Preferred_Location', 'Aadhar_Number', 'Aadhar_Photo',
            'Driving_License', 'previous_employer', 'job_placement'
        ];
        
        // Map fields to their display names
        $displayFields = [
            'vehicle_type' => 'vehicle_type_name',
            'Preferred_Location' => 'preferred_location_name',
            'states' => 'state_name'
        ];
    } elseif ($role === 'transporter') {
        $requiredFields = [
            'name', 'email', 'Transport_Name', 'Year_of_Establishment',
            'Fleet_Size', 'Operational_Segment', 'Average_KM', 'city', 'images', 'address',
            'PAN_Number', 'PAN_Image', 'GST_Certificate'
        ];
    }
    
    // Calculate document status and get actual values
    $documentStatus = [];
    $documentValues = [];
    $filledFields = 0;
    $totalFields = count($requiredFields);
    
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
    
    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => $user['id'],
            'unique_id' => $user['unique_id'],
            'name' => $user['name'],
            'role' => $role,
            'profile_completion' => [
                'percentage' => $completionPercentage,
                'filled_fields' => $filledFields,
                'total_fields' => $totalFields,
                'document_status' => $documentStatus,
                'document_values' => $documentValues
            ]
        ]
    ]);
}
?>
