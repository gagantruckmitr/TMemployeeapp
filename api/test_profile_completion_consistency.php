<?php
/**
 * Test that callback_requests_api.php and profile_completion_api.php return the same percentage
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

// Get a transporter user from callback_requests
$sql = "SELECT cr.unique_id, u.id as user_id, u.name, u.role 
        FROM callback_requests cr
        LEFT JOIN users u ON cr.unique_id = u.unique_id
        WHERE u.role = 'transporter'
        LIMIT 1";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    
    echo "=== TESTING PROFILE COMPLETION CONSISTENCY ===\n";
    echo "User: {$row['name']}\n";
    echo "User ID: {$row['user_id']}\n";
    echo "Unique ID: {$row['unique_id']}\n";
    echo "Role: {$row['role']}\n\n";
    
    // Method 1: Using profile_completion_helper.php (used by profile_completion_api.php)
    $profileData = getProfileCompletionData($conn, $row['user_id']);
    $percentage1 = $profileData['percentage'];
    
    echo "Method 1 (profile_completion_helper.php): $percentage1%\n";
    echo "  - Filled: {$profileData['filled_fields']}/{$profileData['total_fields']}\n\n";
    
    // Method 2: Simulate what callback_requests_api.php does now (after fix)
    // It fetches user by unique_id, then calls getProfileCompletionData with user_id
    $userSql = "SELECT id FROM users WHERE unique_id = ? LIMIT 1";
    $stmt = $conn->prepare($userSql);
    $uniqueId = $row['unique_id'];
    $stmt->bind_param("s", $uniqueId);
    $stmt->execute();
    $userResult = $stmt->get_result()->fetch_assoc();
    
    if ($userResult) {
        $userId = $userResult['id'];
        $profileData2 = getProfileCompletionData($conn, $userId);
        $percentage2 = $profileData2['percentage'];
        
        echo "Method 2 (callback_requests_api.php after fix): $percentage2%\n";
        echo "  - Filled: {$profileData2['filled_fields']}/{$profileData2['total_fields']}\n\n";
        
        if ($percentage1 === $percentage2) {
            echo "✅ SUCCESS: Both methods return the same percentage ($percentage1%)\n";
        } else {
            echo "❌ ERROR: Percentages don't match! ($percentage1% vs $percentage2%)\n";
        }
    } else {
        echo "❌ ERROR: Could not find user by unique_id\n";
    }
    
} else {
    echo "No transporter callback requests found\n";
}
?>
