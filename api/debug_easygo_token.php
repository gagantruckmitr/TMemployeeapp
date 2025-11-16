<?php
/**
 * Debug EasyGo Token Generation
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>EasyGo Token Generation Debug</h1>";

// Configuration
$username = 'admin@truckmitr.com';
$password = '6515a6cb823fcbe20f7287bd4659d5ba';
$tokenUrl = 'https://client.easygoivr.com/masterapiJwt/gentoken';

echo "<div style='background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0;'>";
echo "<h3>Configuration:</h3>";
echo "<p><strong>Username:</strong> $username</p>";
echo "<p><strong>Password:</strong> " . substr($password, 0, 10) . "...</p>";
echo "<p><strong>Token URL:</strong> $tokenUrl</p>";
echo "</div>";

echo "<h2>Step 1: Testing Token Generation (GET Request)</h2>";

$data = [
    'username' => $username,
    'password' => $password
];

echo "<p><strong>Request Data:</strong></p>";
echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";

// Build URL with query parameters
$fullUrl = $tokenUrl . '?' . http_build_query($data);
echo "<p><strong>Full URL:</strong> " . htmlspecialchars($fullUrl) . "</p>";

// Initialize cURL with GET request
$ch = curl_init($fullUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // For testing
curl_setopt($ch, CURLOPT_VERBOSE, true);

// Capture verbose output
$verbose = fopen('php://temp', 'w+');
curl_setopt($ch, CURLOPT_STDERR, $verbose);

echo "<p>Sending request...</p>";

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
$curlInfo = curl_getinfo($ch);

// Get verbose output
rewind($verbose);
$verboseLog = stream_get_contents($verbose);

curl_close($ch);

echo "<h3>Response Details:</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";

if ($curlError) {
    echo "<div style='background: #ffebee; padding: 15px; border-radius: 5px; color: #c62828;'>";
    echo "<h4>❌ cURL Error:</h4>";
    echo "<p>$curlError</p>";
    echo "</div>";
}

echo "<p><strong>Response Body:</strong></p>";
echo "<pre style='background: #fff; padding: 15px; border: 1px solid #ddd; border-radius: 5px;'>";
echo htmlspecialchars($response);
echo "</pre>";

// Try to decode JSON
$json = json_decode($response, true);
if ($json) {
    echo "<p><strong>Decoded JSON:</strong></p>";
    echo "<pre style='background: #e8f5e9; padding: 15px; border: 1px solid #4caf50; border-radius: 5px;'>";
    echo json_encode($json, JSON_PRETTY_PRINT);
    echo "</pre>";
    
    if (isset($json['token'])) {
        echo "<div style='background: #e8f5e9; padding: 15px; border-radius: 5px; color: #2e7d32; margin: 20px 0;'>";
        echo "<h3>✅ Token Generated Successfully!</h3>";
        echo "<p><strong>Token:</strong> " . substr($json['token'], 0, 50) . "...</p>";
        if (isset($json['expires_at'])) {
            echo "<p><strong>Expires At:</strong> {$json['expires_at']}</p>";
        }
        echo "</div>";
        
        // Test the token with a dial request
        echo "<hr><h2>Step 2: Testing Token with Dial API</h2>";
        testDialAPI($json['token']);
    } else {
        echo "<div style='background: #fff3cd; padding: 15px; border-radius: 5px; color: #856404;'>";
        echo "<h4>⚠️ Token Not Found in Response</h4>";
        echo "<p>The API responded but didn't include a token. Check the response structure above.</p>";
        echo "</div>";
    }
} else {
    echo "<div style='background: #ffebee; padding: 15px; border-radius: 5px; color: #c62828;'>";
    echo "<h4>❌ Invalid JSON Response</h4>";
    echo "<p>Could not parse response as JSON. Raw response shown above.</p>";
    echo "</div>";
}

// Show cURL info
echo "<hr><h3>cURL Debug Information:</h3>";
echo "<pre style='background: #f5f5f5; padding: 15px; border: 1px solid #ddd; border-radius: 5px; font-size: 12px;'>";
echo "URL: {$curlInfo['url']}\n";
echo "HTTP Code: {$curlInfo['http_code']}\n";
echo "Total Time: {$curlInfo['total_time']}s\n";
echo "Connect Time: {$curlInfo['connect_time']}s\n";
echo "Size Download: {$curlInfo['size_download']} bytes\n";
echo "\nVerbose Log:\n";
echo htmlspecialchars($verboseLog);
echo "</pre>";

// Show recommendations
if (!isset($json['token'])) {
    echo "<hr><h2>💡 Recommendations</h2>";
    echo "<div style='background: #e3f2fd; padding: 15px; border-radius: 5px;'>";
    echo "<ol>";
    echo "<li>Verify your EasyGo account credentials are correct</li>";
    echo "<li>Check if your account has API access enabled</li>";
    echo "<li>Contact EasyGo support to verify the token generation endpoint</li>";
    echo "<li>Check if there are any IP restrictions on your account</li>";
    echo "</ol>";
    echo "</div>";
}

function testDialAPI($token) {
    $dialUrl = 'https://client.easygoivr.com/easygoapiJwt/request/dial';
    
    $data = [
        'exten' => '08303154516',
        'number' => '06265760864',
        'did' => '6882742',
        'duration' => ''
    ];
    
    echo "<p>Testing dial API with generated token...</p>";
    echo "<p><strong>Dial URL:</strong> $dialUrl</p>";
    echo "<p><strong>Request Data:</strong></p>";
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    
    $ch = curl_init($dialUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'API-Token: ' . $token
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
    echo "<p><strong>Response:</strong></p>";
    echo "<pre style='background: #fff; padding: 15px; border: 1px solid #ddd; border-radius: 5px;'>";
    echo htmlspecialchars($response);
    echo "</pre>";
    
    $json = json_decode($response, true);
    if ($json) {
        echo "<p><strong>Decoded Response:</strong></p>";
        echo "<pre style='background: #e3f2fd; padding: 15px; border: 1px solid #2196f3; border-radius: 5px;'>";
        echo json_encode($json, JSON_PRETTY_PRINT);
        echo "</pre>";
        
        if ($httpCode === 200) {
            echo "<div style='background: #e8f5e9; padding: 15px; border-radius: 5px; color: #2e7d32; margin: 20px 0;'>";
            echo "<h3>✅ Dial API Test Successful!</h3>";
            echo "<p>The token works and calls can be initiated.</p>";
            echo "</div>";
        }
    }
}

?>

<style>
body {
    font-family: Arial, sans-serif;
    max-width: 1200px;
    margin: 20px auto;
    padding: 20px;
    background: #f5f5f5;
}
h1, h2, h3 {
    color: #333;
}
pre {
    overflow-x: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
}
</style>
