<?php
/**
 * Test Click2Call IVR API
 * This script tests the Click2Call API integration
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>🧪 Click2Call IVR API Test</h1>";
echo "<hr>";

// Test 1: Check database connection
echo "<h2>Test 1: Database Connection</h2>";
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✅ Database connection successful<br>";
} catch(PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "<br>";
    exit;
}

// Test 2: Check if admins table has telecallers
echo "<h2>Test 2: Check Telecallers in Admins Table</h2>";
try {
    $stmt = $pdo->query("SELECT id, name, mobile, role FROM admins WHERE role = 'telecaller' LIMIT 10");
    $telecallers = $stmt->fetchAll();
    
    if (count($telecallers) > 0) {
        echo "✅ Found " . count($telecallers) . " telecaller(s)<br>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Role</th></tr>";
        foreach ($telecallers as $telecaller) {
            echo "<tr>";
            echo "<td>" . $telecaller['id'] . "</td>";
            echo "<td>" . $telecaller['name'] . "</td>";
            echo "<td>" . $telecaller['mobile'] . "</td>";
            echo "<td>" . $telecaller['role'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "⚠️ No telecallers found in database<br>";
        echo "💡 Tip: Make sure admins table has users with role='telecaller'<br>";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}

// Test 3: Check if users table has drivers
echo "<h2>Test 3: Check Drivers/Transporters in Users Table</h2>";
try {
    $stmt = $pdo->query("SELECT id, name, mobile, role FROM users WHERE role IN ('driver', 'transporter') LIMIT 5");
    $users = $stmt->fetchAll();
    
    if (count($users) > 0) {
        echo "✅ Found " . count($users) . " user(s)<br>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Role</th></tr>";
        foreach ($users as $user) {
            echo "<tr>";
            echo "<td>" . $user['id'] . "</td>";
            echo "<td>" . $user['name'] . "</td>";
            echo "<td>" . $user['mobile'] . "</td>";
            echo "<td>" . $user['role'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "⚠️ No drivers/transporters found in database<br>";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}

// Test 4: Test API endpoint with sample data
echo "<h2>Test 4: Test Click2Call API Endpoint</h2>";

// Get first telecaller and first driver for testing
$stmt = $pdo->query("SELECT id, name, mobile, role FROM admins WHERE role = 'telecaller' LIMIT 1");
$testTelecaller = $stmt->fetch();

// Debug: Show what we found
if ($testTelecaller) {
    error_log("Found telecaller: ID={$testTelecaller['id']}, Name={$testTelecaller['name']}, Role={$testTelecaller['role']}");
} else {
    error_log("No telecaller found!");
}

$stmt = $pdo->query("SELECT id, name, mobile FROM users WHERE role IN ('driver', 'transporter') LIMIT 1");
$testDriver = $stmt->fetch();

if ($testTelecaller && $testDriver) {
    echo "📋 Test Data:<br>";
    echo "- Telecaller: " . $testTelecaller['name'] . " (ID: " . $testTelecaller['id'] . ", Mobile: " . $testTelecaller['mobile'] . ")<br>";
    echo "- Driver: " . $testDriver['name'] . " (ID: " . $testDriver['id'] . ", Mobile: " . $testDriver['mobile'] . ")<br>";
    echo "<br>";
    
    // Prepare test payload
    $testPayload = [
        'driver_mobile' => $testDriver['mobile'],
        'caller_id' => $testTelecaller['id'],
        'driver_id' => $testDriver['id']
    ];
    
    echo "📤 Sending test request to API...<br>";
    echo "<pre>Payload: " . json_encode($testPayload, JSON_PRETTY_PRINT) . "</pre>";
    
    // Make API call
    $apiUrl = 'https://truckmitr.com/truckmitr-app/api/click2call_ivr_api.php?action=initiate_call';
    
    $ch = curl_init($apiUrl);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => json_encode($testPayload),
        CURLOPT_TIMEOUT => 30,
        CURLOPT_SSL_VERIFYPEER => true
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    echo "<h3>API Response:</h3>";
    echo "HTTP Code: " . $httpCode . "<br>";
    
    if ($error) {
        echo "❌ cURL Error: " . $error . "<br>";
    } else {
        echo "✅ Request successful<br>";
        echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";
        
        $responseData = json_decode($response, true);
        if ($responseData && isset($responseData['success']) && $responseData['success']) {
            echo "<div style='background: #d4edda; padding: 10px; border: 1px solid #c3e6cb; border-radius: 5px;'>";
            echo "✅ <strong>API Test Successful!</strong><br>";
            echo "Reference ID: " . ($responseData['data']['reference_id'] ?? 'N/A') . "<br>";
            echo "Status: " . ($responseData['data']['status'] ?? 'N/A') . "<br>";
            echo "</div>";
        } else {
            echo "<div style='background: #f8d7da; padding: 10px; border: 1px solid #f5c6cb; border-radius: 5px;'>";
            echo "⚠️ <strong>API returned an error</strong><br>";
            echo "Error: " . ($responseData['error'] ?? 'Unknown error') . "<br>";
            echo "</div>";
        }
    }
} else {
    echo "⚠️ Cannot test API - missing test data<br>";
    if (!$testTelecaller) {
        echo "❌ No telecaller found with role='telecaller' in admins table<br>";
    }
    if (!$testDriver) {
        echo "❌ No driver/transporter found in users table<br>";
    }
}

// Test 5: Check Click2Call API configuration
echo "<h2>Test 5: Click2Call API Configuration</h2>";
echo "API URL: https://154.210.187.101/C2CAPI/webresources/Click2CallPost<br>";
echo "UKEY: UFGMs6bXiXD4AIkjQGta8faKi<br>";
echo "Service No: 8037789293<br>";
echo "IVR Template ID: 345<br>";
echo "<br>";

// Test 6: Test direct Click2Call API call
echo "<h2>Test 6: Direct Click2Call API Test</h2>";
echo "⚠️ <strong>Note:</strong> This will make a REAL call if credentials are valid!<br>";
echo "<br>";

$testClick2CallPayload = [
    'sourcetype' => '0',
    'customivr' => true,
    'credittype' => '2',
    'filetype' => '2',
    'ukey' => 'UFGMs6bXiXD4AIkjQGta8faKi',
    'serviceno' => '8037789293',
    'ivrtemplateid' => '345',
    'custcli' => '8037789293',
    'isrefno' => true,
    'msisdnlist' => [
        [
            'phoneno' => '8303154516',  // Test driver number
            'agentno' => '8383971722'   // Test agent number
        ]
    ]
];

echo "📤 Test Payload:<br>";
echo "<pre>" . json_encode($testClick2CallPayload, JSON_PRETTY_PRINT) . "</pre>";

echo "<button onclick='testDirectAPI()'>🧪 Test Direct API Call</button>";
echo "<div id='directApiResult'></div>";

echo "<script>
function testDirectAPI() {
    document.getElementById('directApiResult').innerHTML = '<p>⏳ Testing... Please wait...</p>';
    
    fetch('https://154.210.187.101/C2CAPI/webresources/Click2CallPost', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        body: JSON.stringify(" . json_encode($testClick2CallPayload) . ")
    })
    .then(response => response.json())
    .then(data => {
        document.getElementById('directApiResult').innerHTML = 
            '<h3>✅ Direct API Response:</h3>' +
            '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
    })
    .catch(error => {
        document.getElementById('directApiResult').innerHTML = 
            '<h3>❌ Error:</h3>' +
            '<p>' + error.message + '</p>' +
            '<p><strong>Note:</strong> CORS or SSL errors are expected when testing from browser. The API should work from server-side PHP.</p>';
    });
}
</script>";

echo "<hr>";
echo "<h2>✅ Test Complete</h2>";
echo "<p>Check the results above to verify the Click2Call IVR API integration.</p>";
?>
