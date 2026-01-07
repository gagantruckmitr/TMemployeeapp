<?php
/**
 * Direct Test - Simulate Flutter App Request
 */

echo "<h1>Direct Toll-Free Feedback Test</h1>";

// Test with actual user data from production
$testCases = [
    [
        'caller_id' => 3,
        'lead_id' => 100,  // Try with a real user ID
        'name' => 'Test User',
        'mobile' => '9876543210',
        'feedback' => 'Connected - Interested',
        'remarks' => 'Test feedback'
    ],
    [
        'caller_id' => 8,
        'lead_id' => 200,  // Try with another user ID
        'name' => 'Another User',
        'mobile' => '9876543211',
        'feedback' => 'Not Reachable',
        'remarks' => ''
    ]
];

foreach ($testCases as $index => $testData) {
    echo "<h2>Test Case " . ($index + 1) . "</h2>";
    
    // Make actual POST request
    $ch = curl_init('http://localhost/api/toll_free_feedback_api.php?action=submit_feedback');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    echo "<p><strong>Request Data:</strong></p>";
    echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";
    
    echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
    
    if ($curlError) {
        echo "<p><strong>cURL Error:</strong> $curlError</p>";
    }
    
    echo "<p><strong>Response:</strong></p>";
    if ($response) {
        $decoded = json_decode($response);
        if ($decoded) {
            echo "<pre>" . json_encode($decoded, JSON_PRETTY_PRINT) . "</pre>";
        } else {
            echo "<pre>$response</pre>";
        }
    } else {
        echo "<p>No response</p>";
    }
    
    echo "<hr>";
}

// Also test with direct database query to find valid user IDs
echo "<h2>Finding Valid User IDs</h2>";

require_once 'config.php';

try {
    $stmt = $pdo->query("SELECT id, unique_id, name, mobile, role FROM users ORDER BY id DESC LIMIT 5");
    $users = $stmt->fetchAll();
    
    echo "<p><strong>Recent Users (use these IDs for testing):</strong></p>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>TMID</th><th>Name</th><th>Mobile</th><th>Role</th></tr>";
    foreach ($users as $user) {
        echo "<tr>";
        echo "<td>" . $user['id'] . "</td>";
        echo "<td>" . $user['unique_id'] . "</td>";
        echo "<td>" . $user['name'] . "</td>";
        echo "<td>" . $user['mobile'] . "</td>";
        echo "<td>" . $user['role'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Test with first valid user
    if (!empty($users)) {
        $validUser = $users[0];
        echo "<h2>Test with Valid User ID: " . $validUser['id'] . "</h2>";
        
        $testData = [
            'caller_id' => 3,
            'lead_id' => $validUser['id'],
            'name' => $validUser['name'],
            'mobile' => $validUser['mobile'],
            'feedback' => 'Connected - Test with valid user',
            'remarks' => 'Automated test'
        ];
        
        $ch = curl_init('http://localhost/api/toll_free_feedback_api.php?action=submit_feedback');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
        echo "<p><strong>Response:</strong></p>";
        if ($response) {
            $decoded = json_decode($response);
            if ($decoded) {
                echo "<pre>" . json_encode($decoded, JSON_PRETTY_PRINT) . "</pre>";
            } else {
                echo "<pre>$response</pre>";
            }
        }
    }
    
} catch (Exception $e) {
    echo "<p><strong>Error:</strong> " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<p><strong>Test completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
