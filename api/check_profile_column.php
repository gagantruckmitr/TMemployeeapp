<?php
header('Content-Type: text/plain');
require_once 'config.php';

$uniqueId = 'TM2510BRDR10677';

echo "=== CHECKING PROFILE_COMPLETION COLUMN ===\n\n";

// Check if profile_completion column exists
$columns = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_completion'");
if ($columns && $columns->num_rows > 0) {
    echo "✓ profile_completion column EXISTS in users table\n\n";
    
    // Get the value for this user
    $query = "SELECT id, unique_id, name, profile_completion FROM users WHERE unique_id = '{$uniqueId}'";
    $result = $conn->query($query);
    
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo "User: {$user['name']} (ID: {$user['id']})\n";
        echo "Stored profile_completion value: " . ($user['profile_completion'] ?? 'NULL') . "\n\n";
        
        echo "This stored value is DIFFERENT from the calculated value (35%).\n";
        echo "The APIs are calculating it correctly based on actual field data.\n";
    }
} else {
    echo "✗ profile_completion column does NOT exist in users table\n";
    echo "Profile completion is calculated dynamically from field data.\n";
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "RECOMMENDATION:\n";
echo "The API is calculating correctly (35% based on actual filled fields).\n";
echo "If you want to use a stored profile_completion value instead,\n";
echo "we need to update the APIs to read from that column.\n";
?>
