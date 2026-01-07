<?php
/**
 * Show detailed field-by-field comparison
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

// Get a transporter user
$sql = "SELECT id, unique_id, name, role FROM users WHERE role = 'transporter' LIMIT 1";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    
    echo "=== DETAILED FIELD ANALYSIS ===\n";
    echo "User: {$row['name']}\n";
    echo "User ID: {$row['id']}\n";
    echo "Unique ID: {$row['unique_id']}\n\n";
    
    $profileData = getProfileCompletionData($conn, $row['id']);
    
    echo "Overall: {$profileData['percentage']}% ({$profileData['filled_fields']}/{$profileData['total_fields']})\n\n";
    
    echo "=== FIELD STATUS ===\n";
    foreach ($profileData['document_status'] as $field => $isPresent) {
        $value = $profileData['document_values'][$field] ?? 'NULL';
        $status = $isPresent ? '✅' : '❌';
        
        // Truncate long values
        if (strlen($value) > 60) {
            $value = substr($value, 0, 60) . '...';
        }
        
        echo "$status $field: $value\n";
    }
    
} else {
    echo "No transporter users found\n";
}
?>
