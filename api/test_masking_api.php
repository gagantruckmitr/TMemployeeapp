<?php
// Test the profile completion API with masking

$testUsers = [
    ['id' => 92, 'name' => 'Deepak Arora', 'role' => 'driver'],
    ['id' => 90, 'name' => 'Anil Kumar', 'role' => 'transporter'],
    ['id' => 202, 'name' => 'GEDU Chaudhary', 'role' => 'driver'],
];

echo "=== TESTING PROFILE COMPLETION API WITH MASKING ===\n\n";

foreach ($testUsers as $user) {
    echo "Testing User: {$user['name']} (ID: {$user['id']}, Role: {$user['role']})\n";
    echo str_repeat('-', 60) . "\n";
    
    $url = "http://localhost/api/profile_completion_api.php?action=get_profile_details&user_id={$user['id']}";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    curl_close($ch);
    
    $data = json_decode($response, true);
    
    if ($data && $data['success']) {
        $docValues = $data['data']['profile_completion']['document_values'];
        
        echo "Aadhar Number: " . ($docValues['aadhar_number'] ?? 'NULL') . "\n";
        echo "License Number: " . ($docValues['license_number'] ?? 'NULL') . "\n";
        echo "PAN Number: " . ($docValues['pan_number'] ?? 'NULL') . "\n";
        echo "GST Number: " . ($docValues['gst_number'] ?? 'NULL') . "\n";
    } else {
        echo "Error: " . ($data['error'] ?? 'Unknown error') . "\n";
    }
    
    echo "\n";
}
?>
