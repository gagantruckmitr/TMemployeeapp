<?php
/**
 * Test script to verify transporter profile completion consistency
 * between transporter_leads_api.php and profile_completion_helper.php
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

// Test with a transporter ID
$transporterId = $_GET['transporter_id'] ?? null;

if (!$transporterId) {
    echo "Usage: test_transporter_profile_consistency.php?transporter_id=123\n";
    exit;
}

echo "Testing Profile Completion Consistency for Transporter ID: $transporterId\n";
echo str_repeat("=", 80) . "\n\n";

try {
    // Method 1: Using profile_completion_helper.php
    $helperData = getProfileCompletionData($conn, $transporterId);
    
    echo "Method 1: profile_completion_helper.php\n";
    echo "  Percentage: " . $helperData['percentage'] . "%\n";
    echo "  Filled Fields: " . $helperData['filled_fields'] . "/" . $helperData['total_fields'] . "\n";
    echo "  Fields: " . implode(', ', array_keys($helperData['document_status'])) . "\n\n";
    
    // Method 2: Using transporter_leads_api.php logic
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
        echo "ERROR: Transporter not found!\n";
        exit;
    }
    
    $requiredFields = [
        'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
        'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
        'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
    ];
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    
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
    
    echo "Method 2: transporter_leads_api.php logic\n";
    echo "  Percentage: " . $completionPercentage . "%\n";
    echo "  Filled Fields: " . $filledFields . "/" . $totalFields . "\n";
    echo "  Fields: " . implode(', ', $requiredFields) . "\n\n";
    
    // Compare results
    echo str_repeat("=", 80) . "\n";
    if ($helperData['percentage'] === $completionPercentage) {
        echo "✅ SUCCESS: Both methods return the same percentage!\n";
        echo "   Percentage: " . $helperData['percentage'] . "%\n";
    } else {
        echo "❌ MISMATCH: Different percentages!\n";
        echo "   Helper: " . $helperData['percentage'] . "%\n";
        echo "   API: " . $completionPercentage . "%\n";
        echo "   Difference: " . abs($helperData['percentage'] - $completionPercentage) . "%\n";
    }
    echo str_repeat("=", 80) . "\n";
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
?>
