<?php
/**
 * Test Driver/Transporter Separation
 * Verify that drivers and transporters are properly separated by API
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Driver/Transporter Separation Test</h1>";
echo "<p>Testing that drivers and transporters are shown in the correct APIs based on tc_for</p>";

require_once 'config.php';

// Get telecallers and their tc_for values
$query = "SELECT id, name, email, tc_for FROM admins WHERE role = 'telecaller' ORDER BY tc_for, id ASC";
$result = $conn->query($query);

$telecallers = [];
while ($row = $result->fetch_assoc()) {
    $telecallers[] = $row;
}

echo "<h2>Telecallers by tc_for</h2>";
echo "<table border='1' cellpadding='5' cellspacing='0'>";
echo "<tr><th>ID</th><th>Name</th><th>tc_for</th><th>Should See</th></tr>";

foreach ($telecallers as $tc) {
    $shouldSee = '';
    switch ($tc['tc_for']) {
        case 'match-making':
            $shouldSee = 'Transporters (via transporter_leads_api.php)';
            break;
        case 'welcome-call':
            $shouldSee = 'Drivers ONLY (via fresh_leads_api.php)';
            break;
        default:
            $shouldSee = 'Drivers (via fresh_leads_api.php)';
    }
    
    echo "<tr>";
    echo "<td>{$tc['id']}</td>";
    echo "<td>{$tc['name']}</td>";
    echo "<td><strong>{$tc['tc_for']}</strong></td>";
    echo "<td>$shouldSee</td>";
    echo "</tr>";
}

echo "</table>";

// Test with welcome-call user
$welcomeCallUsers = array_filter($telecallers, fn($tc) => $tc['tc_for'] === 'welcome-call');
$matchMakingUsers = array_filter($telecallers, fn($tc) => $tc['tc_for'] === 'match-making');

if (count($welcomeCallUsers) > 0) {
    echo "<h2>Test 1: Welcome-Call User (Should See ONLY Drivers)</h2>";
    $testUser = reset($welcomeCallUsers);
    echo "<p>Testing with User ID: <strong>{$testUser['id']}</strong> ({$testUser['name']}, tc_for = '{$testUser['tc_for']}')</p>";
    
    $url = 'https://truckmitr.com/truckmitr-app/api/fresh_leads_api.php?action=fresh_leads&caller_id=' . $testUser['id'] . '&limit=10';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: <strong>$httpCode</strong></p>";
    
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "<p style='color: green; font-weight: bold;'>✅ API returned successfully</p>";
        echo "<p>Leads returned: <strong>" . ($data['count'] ?? 0) . "</strong></p>";
        
        // Check if any transporters are in the results
        if (isset($data['data']) && is_array($data['data'])) {
            $hasTransporters = false;
            foreach ($data['data'] as $lead) {
                // Check in database if this user is a transporter
                $checkQuery = "SELECT role FROM users WHERE id = " . (int)$lead['id'];
                $checkResult = $conn->query($checkQuery);
                if ($checkResult && $row = $checkResult->fetch_assoc()) {
                    if ($row['role'] === 'transporter') {
                        $hasTransporters = true;
                        echo "<p style='color: red;'>✗ FOUND TRANSPORTER: {$lead['name']} (ID: {$lead['id']})</p>";
                    }
                }
            }
            
            if (!$hasTransporters) {
                echo "<p style='color: green; font-weight: bold;'>✅ CORRECT: No transporters found in results (drivers only)</p>";
            } else {
                echo "<p style='color: red; font-weight: bold;'>✗ FAILED: Transporters found in driver leads!</p>";
            }
        }
    } else {
        echo "<p style='color: orange;'>⚠ API returned error or no data</p>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    }
}

if (count($matchMakingUsers) > 0) {
    echo "<h2>Test 2: Match-Making User (Should See ONLY Transporters)</h2>";
    $testUser = reset($matchMakingUsers);
    echo "<p>Testing with User ID: <strong>{$testUser['id']}</strong> ({$testUser['name']}, tc_for = '{$testUser['tc_for']}')</p>";
    
    // Test fresh_leads_api (should be denied)
    echo "<h3>2a. Testing fresh_leads_api.php (should be denied)</h3>";
    $url = 'https://truckmitr.com/truckmitr-app/api/fresh_leads_api.php?action=fresh_leads&caller_id=' . $testUser['id'] . '&limit=10';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: <strong>$httpCode</strong></p>";
    
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && !$data['success']) {
        echo "<p style='color: green; font-weight: bold;'>✅ CORRECT: Match-making user denied access to driver leads</p>";
        echo "<p>Error: <em>" . ($data['error'] ?? 'N/A') . "</em></p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ FAILED: Match-making user should not access driver leads</p>";
    }
    
    // Test transporter_leads_api (should succeed)
    echo "<h3>2b. Testing transporter_leads_api.php (should succeed)</h3>";
    $url = 'https://truckmitr.com/truckmitr-app/api/transporter_leads_api.php?action=transporter_leads&caller_id=' . $testUser['id'] . '&limit=10';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: <strong>$httpCode</strong></p>";
    
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "<p style='color: green; font-weight: bold;'>✅ CORRECT: Match-making user can access transporter leads</p>";
        echo "<p>Leads returned: <strong>" . ($data['count'] ?? 0) . "</strong></p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ FAILED: Match-making user should access transporter leads</p>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    }
}

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<table border='1' cellpadding='10' cellspacing='0'>";
echo "<tr><th>tc_for Value</th><th>API to Use</th><th>Shows</th></tr>";
echo "<tr><td><strong>welcome-call</strong></td><td>fresh_leads_api.php</td><td>Drivers ONLY</td></tr>";
echo "<tr><td><strong>match-making</strong></td><td>transporter_leads_api.php</td><td>Transporters ONLY</td></tr>";
echo "<tr><td><strong>toll-free</strong></td><td>toll_free_search_api.php</td><td>Toll-free leads</td></tr>";
echo "<tr><td><strong>social-media</strong></td><td>social-media-leads.php</td><td>Social media leads</td></tr>";
echo "</table>";

echo "<h2>Expected Behavior</h2>";
echo "<ul>";
echo "<li>✅ <strong>welcome-call</strong> users see ONLY drivers (no transporters)</li>";
echo "<li>✅ <strong>match-making</strong> users see ONLY transporters (no drivers)</li>";
echo "<li>✅ Each type of lead is completely separated</li>";
echo "<li>✅ No mixing of drivers and transporters</li>";
echo "</ul>";

$conn->close();
?>
