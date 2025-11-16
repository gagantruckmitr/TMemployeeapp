<?php
/**
 * Direct test of fresh_leads_api.php
 */

$callerId = $_GET['caller_id'] ?? 3;
$limit = $_GET['limit'] ?? 50;

echo "<h1>Testing Fresh Leads API</h1>";
echo "<p>Caller ID: $callerId, Limit: $limit</p>";

// Call the API
$apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/fresh_leads_api.php?action=fresh_leads&caller_id=$callerId&limit=$limit";

echo "<p>API URL: <a href='$apiUrl' target='_blank'>$apiUrl</a></p>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<h2>Response (HTTP $httpCode)</h2>";
echo "<pre style='background: #f0f0f0; padding: 10px; overflow: auto;'>";
echo htmlspecialchars($response);
echo "</pre>";

// Parse and display nicely
if ($httpCode === 200) {
    $data = json_decode($response, true);
    if ($data && isset($data['success'])) {
        echo "<h2>Parsed Response</h2>";
        echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
        echo "<tr><th>Field</th><th>Value</th></tr>";
        foreach ($data as $key => $value) {
            if ($key !== 'data') {
                echo "<tr><td><strong>$key</strong></td><td>" . (is_array($value) ? json_encode($value) : $value) . "</td></tr>";
            }
        }
        echo "</table>";
        
        if (isset($data['data']) && is_array($data['data'])) {
            echo "<h2>Leads Returned: " . count($data['data']) . "</h2>";
            if (count($data['data']) > 0) {
                echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
                echo "<tr><th>ID</th><th>TMID</th><th>Name</th><th>Mobile</th><th>City</th><th>Profile %</th></tr>";
                foreach (array_slice($data['data'], 0, 10) as $lead) {
                    echo "<tr>";
                    echo "<td>{$lead['id']}</td>";
                    echo "<td>{$lead['tmid']}</td>";
                    echo "<td>{$lead['name']}</td>";
                    echo "<td>{$lead['phoneNumber']}</td>";
                    echo "<td>{$lead['city']}</td>";
                    echo "<td>{$lead['profile_completion']}</td>";
                    echo "</tr>";
                }
                echo "</table>";
            } else {
                echo "<p style='color: red;'>⚠️ No leads returned!</p>";
            }
        }
    }
}
?>
