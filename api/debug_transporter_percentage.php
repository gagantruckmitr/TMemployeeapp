<?php
/**
 * Quick debug script to compare transporter profile completion percentages
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

$transporterId = $_GET['id'] ?? null;

if (!$transporterId) {
    die(json_encode(['error' => 'Usage: ?id=TRANSPORTER_ID']));
}

header('Content-Type: application/json');

try {
    // Method 1: Helper
    $helperData = getProfileCompletionData($conn, $transporterId);
    
    // Method 2: Transporter Leads API logic
    $stmt = $conn->prepare("
        SELECT 
            name, email, transport_name, year_of_establishment,
            fleet_size, operational_segment, average_km, city, images, address,
            pan_number, pan_image, gst_certificate, mobile, states
        FROM users 
        WHERE id = ? AND role = 'transporter'
    ");
    
    $stmt->bind_param("i", $transporterId);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    
    if (!$user) {
        die(json_encode(['error' => 'Transporter not found']));
    }
    
    $requiredFields = [
        'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
        'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
        'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
    ];
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    $apiFieldStatus = [];
    
    foreach ($requiredFields as $field) {
        $value = $user[$field] ?? null;
        $isPresent = false;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $isPresent = true;
                $filledFields++;
            } elseif (is_array($decoded) && count($decoded) === 0) {
                $isPresent = false;
            } else {
                $isPresent = true;
                $filledFields++;
            }
        }
        
        $apiFieldStatus[$field] = [
            'present' => $isPresent,
            'value' => $value,
            'is_array' => is_array(json_decode($value, true)),
            'array_count' => is_array(json_decode($value, true)) ? count(json_decode($value, true)) : null
        ];
    }
    
    $apiPercentage = round(($filledFields / $totalFields) * 100);
    
    // Compare
    $match = ($helperData['percentage'] === $apiPercentage);
    
    // Find differences
    $differences = [];
    foreach ($requiredFields as $field) {
        $helperPresent = $helperData['document_status'][$field] ?? false;
        $apiPresent = $apiFieldStatus[$field]['present'] ?? false;
        
        if ($helperPresent !== $apiPresent) {
            $differences[] = [
                'field' => $field,
                'helper' => $helperPresent,
                'api' => $apiPresent,
                'value' => $apiFieldStatus[$field]['value']
            ];
        }
    }
    
    echo json_encode([
        'transporter_id' => $transporterId,
        'match' => $match,
        'helper' => [
            'percentage' => $helperData['percentage'],
            'filled' => $helperData['filled_fields'],
            'total' => $helperData['total_fields'],
            'fields' => $helperData['document_status']
        ],
        'api' => [
            'percentage' => $apiPercentage,
            'filled' => $filledFields,
            'total' => $totalFields,
            'fields' => array_map(fn($f) => $f['present'], $apiFieldStatus)
        ],
        'differences' => $differences,
        'raw_data' => $user
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
