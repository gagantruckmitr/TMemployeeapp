<?php
/**
 * Check transporter data in users table
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "=== Checking Transporter Data ===\n\n";

$tmids = [
    'TM2510RJTR12680',
    'TM2510UPTR12912',
    'TM2511RJTR15627',
    'TM2510BRTR13498',
    'TM2511MHTR14489',
    'TM2511ANTR14973',
    'TM2511KATR14729'
];

foreach ($tmids as $tmid) {
    echo "Checking TMID: $tmid\n";
    
    $query = "SELECT unique_id, role, Transport_Name, name, name_eng FROM users WHERE unique_id = '$tmid'";
    $result = $conn->query($query);
    
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo "  Found in users table:\n";
        echo "    unique_id: " . $row['unique_id'] . "\n";
        echo "    role: " . $row['role'] . "\n";
        echo "    Transport_Name: " . ($row['Transport_Name'] ?? 'NULL') . "\n";
        echo "    name: " . ($row['name'] ?? 'NULL') . "\n";
        echo "    name_eng: " . ($row['name_eng'] ?? 'NULL') . "\n";
    } else {
        echo "  ❌ NOT FOUND in users table\n";
    }
    echo "\n";
}

echo "=== Test Complete ===\n";
?>
