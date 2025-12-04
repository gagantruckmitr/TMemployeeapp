<?php
/**
 * Test Transporter Leads Access Control
 * Verify that only tc_for = 'match-making' users can access
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Transporter Leads Access Control Test</h1>";
echo "<p>Testing that only telecallers with tc_for = 'match-making' can access transporter leads</p>";

require_once 'config.php';

// Get all telecallers and their tc_for values
$query = "SELECT id, name, email, tc_for FROM admins WHERE role = 'telecaller' ORDER BY id ASC";
$result = $conn->query($query);

echo "<h2>All Telecallers</h2>";
echo "<table border='1' cellpadding='5' cellspacing='0'>";
echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>tc_for</th><th>Access</th></tr>";

$matchMakingUsers = [];
$otherUsers = [];

while ($row = $result->fetch_assoc()) {
    $access = ($row['tc_for'] === 'match-making') ? '✅ ALLOWED' : '❌ DENIED';
    $color = ($row['tc_for'] === 'match-making') ? 'green' : 'red';
    
    echo "<tr>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['name']}</td>";
    echo "<td>{$row['email']}</td>";
    echo "<td><strong>{$row['tc_for']}</strong></td>";
    echo "<td style='color: $color; font-weight: bold;'>$access</td>";
    echo "</tr>";
    
    if ($row['tc_for'] === 'match-making') {
        $matchMakingUsers[] = $row;
    } else {
        $otherUsers[] = $row;
    }
}

echo "</table>";

echo "<h2>Summary</h2>";
echo "<p>✅ <strong>" . count($matchMakingUsers) . "</strong> telecallers with tc_for = 'match-making' (ALLOWED)</p>";
echo "<p>❌ <strong>" . count($otherUsers) . "</strong> telecallers with other tc_for values (DENIED)</p>";

// Test API calls
echo "<h2>API Test Results</h2>";

if (count($matchMakingUsers) > 0) {
    echo "<h3>Test 1: Allowed User (tc_for = 'match-making')</h3>";
    $testUser = $matchMakingUsers[0];
    echo "<p>Testing with User ID: <strong>{$testUser['id']}</strong> ({$testUser['name']})</p>";
    
    $url = 'https://truckmitr.com/truckmitr-app/api/transporter_leads_api.php?action=transporter_leads&caller_id=' . $testUser['id'] . '&limit=5';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: <strong>$httpCode</strong></p>";
    
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "<p style='color: green; font-weight: bold;'>✅ SUCCESS - User can access transporter leads</p>";
        echo "<p>Leads returned: <strong>" . ($data['count'] ?? 0) . "</strong></p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ FAILED - User was denied access</p>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    }
}

if (count($otherUsers) > 0) {
    echo "<h3>Test 2: Denied User (tc_for != 'match-making')</h3>";
    $testUser = $otherUsers[0];
    echo "<p>Testing with User ID: <strong>{$testUser['id']}</strong> ({$testUser['name']}, tc_for = '{$testUser['tc_for']}')</p>";
    
    $url = 'https://truckmitr.com/truckmitr-app/api/transporter_leads_api.php?action=transporter_leads&caller_id=' . $testUser['id'] . '&limit=5';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: <strong>$httpCode</strong></p>";
    
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && !$data['success']) {
        echo "<p style='color: green; font-weight: bold;'>✅ SUCCESS - User was correctly denied access</p>";
        echo "<p>Error message: <em>" . ($data['error'] ?? 'N/A') . "</em></p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ FAILED - User should have been denied but wasn't</p>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    }
}

echo "<hr>";
echo "<h2>Expected Behavior</h2>";
echo "<ul>";
echo "<li>✅ Users with tc_for = 'match-making' should get transporter leads</li>";
echo "<li>❌ Users with other tc_for values should get 'Access denied' error</li>";
echo "<li>📊 Leads are distributed via round-robin among match-making telecallers</li>";
echo "</ul>";

$conn->close();
?>
