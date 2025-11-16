<?php
// Test script to verify transporter profile API
require_once 'config.php';

echo "=== TESTING TRANSPORTER PROFILE API ===\n\n";

try {
    // 1. Find a transporter from the welcome-call leads
    echo "1. Finding a transporter from welcome-call leads...\n";
    $stmt = $conn->query("
        SELECT u.id, u.unique_id, u.name, u.role, u.Transport_Name
        FROM users u
        WHERE u.role = 'transporter'
        AND u.id NOT IN (
            SELECT DISTINCT transporter_id 
            FROM jobs
            WHERE transporter_id IS NOT NULL
            AND transporter_id != ''
            AND transporter_id > 0
        )
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs
            WHERE user_id IS NOT NULL
            AND user_id != ''
            AND user_id > 0
        )
        ORDER BY u.Created_at DESC
        LIMIT 1
    ");
    
    $transporter = $stmt->fetch_assoc();
    
    if (!$transporter) {
        echo "   ❌ No eligible transporter found!\n";
        exit;
    }
    
    echo "   ✅ Found transporter:\n";
    echo "      ID: {$transporter['id']}\n";
    echo "      TMID: {$transporter['unique_id']}\n";
    echo "      Name: {$transporter['name']}\n";
    echo "      Transport Name: {$transporter['Transport_Name']}\n\n";
    
    // 2. Test the profile completion API
    echo "2. Testing profile completion API...\n";
    $userId = $transporter['id'];
    
    // Simulate API call
    $_GET['action'] = 'get_profile_details';
    $_GET['user_id'] = $userId;
    
    // Capture output
    ob_start();
    include 'profile_completion_api.php';
    $apiResponse = ob_get_clean();
    
    echo "   API Response:\n";
    $data = json_decode($apiResponse, true);
    
    if ($data && $data['success']) {
        echo "   ✅ API call successful!\n\n";
        
        $profile = $data['data']['profile_completion'];
        echo "   Profile Completion: {$profile['percentage']}%\n";
        echo "   Filled Fields: {$profile['filled_fields']}/{$profile['total_fields']}\n\n";
        
        echo "   Document Status:\n";
        foreach ($profile['document_status'] as $field => $status) {
            $icon = $status ? '✅' : '❌';
            $value = $profile['document_values'][$field] ?? 'N/A';
            echo "      $icon $field: " . (is_string($value) ? substr($value, 0, 50) : $value) . "\n";
        }
        
        echo "\n   Transporter-Specific Fields:\n";
        $transporterFields = ['Transport_Name', 'Fleet_Size', 'Operational_Segment', 'PAN_Number', 'GST_Certificate'];
        foreach ($transporterFields as $field) {
            if (isset($profile['document_status'][$field])) {
                $icon = $profile['document_status'][$field] ? '✅' : '❌';
                $value = $profile['document_values'][$field] ?? 'N/A';
                echo "      $icon $field: $value\n";
            }
        }
        
    } else {
        echo "   ❌ API call failed!\n";
        echo "   Error: " . ($data['error'] ?? 'Unknown error') . "\n";
        echo "   Raw response: $apiResponse\n";
    }
    
    echo "\n=== TEST COMPLETE ===\n";
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
