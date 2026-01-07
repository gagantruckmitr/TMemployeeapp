<?php
/**
 * Check if users table has a profile_completion field and what values it contains
 */

require_once 'config.php';

// Check if the column exists
$sql = "SHOW COLUMNS FROM users LIKE 'profile_completion'";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    echo "✅ users.profile_completion column EXISTS\n\n";
    
    // Get some sample values
    $sql = "SELECT unique_id, name, role, profile_completion FROM users WHERE profile_completion IS NOT NULL LIMIT 10";
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        echo "=== SAMPLE VALUES ===\n";
        while ($row = $result->fetch_assoc()) {
            echo "{$row['unique_id']} - {$row['name']} ({$row['role']}): {$row['profile_completion']}\n";
        }
    } else {
        echo "No users have profile_completion values\n";
    }
} else {
    echo "❌ users.profile_completion column DOES NOT EXIST\n";
}
?>
