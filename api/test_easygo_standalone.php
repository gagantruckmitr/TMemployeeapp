<?php
/**
 * Standalone EasyGo IVR Test (No Database Required)
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Configuration
$username = 'admin@truckmitr.com';
$password = '6515a6cb823fcbe20f7287bd4659d5ba';
$did = '6882742';
$tokenUrl = 'https://client.easygoivr.com/masterapiJwt/gentoken';
$dialUrl = 'https://client.easygoivr.com/easygoapiJwt/request/dial';

// Test phone numbers
$telecallerPhone = '08303154516';
$clientPhone = '06265760864';

?>
<!DOCTYPE html>
<html>
<head>
    <title>EasyGo IVR Standalone Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1000px;
            margin: 20px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .section {
            background: white;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .success { background: #e8f5e9; border-left: 4px solid #4caf50; }
        .error { background: #ffebee; border-left: 4px solid #f44336; }
        .info { background: #e3f2fd; border-left: 4px solid #2196f3; }
        pre {
            background: #f5f5f5;
            padding: 15px;
            border-radius: 4px;
            overflow-x: auto;
        }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 0; }
    </style>
</head>
<body>
    <h1>🧪 EasyGo IVR Standalone Test</h1>
    
    <div class="section info">
        <h2>Configuration</h2>
        <p><strong>Username:</strong> <?php echo $username; ?></p>
        <p><strong>DID:</strong> <?php echo $did; ?></p>
        <p><strong>Telecaller Phone:</strong> <?php echo $telecallerPhone; ?></p>
        <p><strong>Client Phone:</strong> <?php echo $clientPhone; ?></p>
    </div>

    <?php
    // Step 1: Generate Token
    echo '<div class="section">';
    echo '<h2>Step 1: Generate Token (POST with Basic Auth)</h2>';
    
    echo '<p><strong>Request URL:</strong> ' . htmlspecialchars($tokenUrl) . '</p>';
    echo '<p><strong>Method:</strong> POST</p>';
    echo '<p><strong>Auth Type:</strong> HTTP Basic Authentication</p>';
    echo '<p><strong>Username:</strong> ' . htmlspecialchars($username) . '</p>';
    echo '<p><strong>Password:</strong> ' . substr($password, 0, 10) . '...</p>';
    
    $ch = curl_init($tokenUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    // Use HTTP Basic Authentication
    curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($ch, CURLOPT_USERPWD, $username . ':' . $password);
    
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $tokenResponse = curl_exec($ch);
    $tokenHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $tokenError = curl_error($ch);
    curl_close($ch);
    
    echo "<p><strong>HTTP Code:</strong> $tokenHttpCode</p>";
    
    if ($tokenError) {
        echo '<div class="error">';
        echo "<p><strong>Error:</strong> $tokenError</p>";
        echo '</div>';
        echo '</div>';
        exit;
    }
    
    echo "<p><strong>Response:</strong></p>";
    echo "<pre>" . htmlspecialchars($tokenResponse) . "</pre>";
    
    $tokenJson = json_decode($tokenResponse, true);
    
    if ($tokenJson && (isset($tokenJson['API_TOKEN']) || isset($tokenJson['token']))) {
        $token = $tokenJson['API_TOKEN'] ?? $tokenJson['token'];
        echo '<div class="success">';
        echo '<p>✅ <strong>Token Generated Successfully!</strong></p>';
        echo '<p><strong>Token:</strong> ' . substr($token, 0, 50) . '...</p>';
        echo '</div>';
        echo '</div>';
        
        // Step 2: Initiate Call
        echo '<div class="section">';
        echo '<h2>Step 2: Initiate Call</h2>';
        
        $callData = [
            'exten' => $telecallerPhone,
            'number' => $clientPhone,
            'did' => $did,
            'duration' => ''
        ];
        
        echo '<p><strong>Request Data:</strong></p>';
        echo '<pre>' . json_encode($callData, JSON_PRETTY_PRINT) . '</pre>';
        
        $ch = curl_init($dialUrl);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($callData));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'API-Token: ' . $token
        ]);
        
        $callResponse = curl_exec($ch);
        $callHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $callError = curl_error($ch);
        curl_close($ch);
        
        echo "<p><strong>HTTP Code:</strong> $callHttpCode</p>";
        
        if ($callError) {
            echo '<div class="error">';
            echo "<p><strong>Error:</strong> $callError</p>";
            echo '</div>';
        } else {
            echo "<p><strong>Response:</strong></p>";
            echo "<pre>" . htmlspecialchars($callResponse) . "</pre>";
            
            $callJson = json_decode($callResponse, true);
            
            if ($callHttpCode === 200) {
                echo '<div class="success">';
                echo '<h3>✅ Call Initiated Successfully!</h3>';
                echo '<p><strong>Both phones should ring now!</strong></p>';
                echo '<ul>';
                echo "<li>Telecaller phone: $telecallerPhone</li>";
                echo "<li>Client phone: $clientPhone</li>";
                echo '</ul>';
                if ($callJson) {
                    echo '<p><strong>Response Data:</strong></p>';
                    echo '<pre>' . json_encode($callJson, JSON_PRETTY_PRINT) . '</pre>';
                }
                echo '</div>';
            } else {
                echo '<div class="error">';
                echo '<h3>❌ Call Failed</h3>';
                echo "<p>HTTP Code: $callHttpCode</p>";
                if ($callJson) {
                    echo '<p><strong>Error Details:</strong></p>';
                    echo '<pre>' . json_encode($callJson, JSON_PRETTY_PRINT) . '</pre>';
                }
                echo '</div>';
            }
        }
        
        echo '</div>';
        
    } else {
        echo '<div class="error">';
        echo '<p>❌ <strong>Failed to generate token</strong></p>';
        echo '<p>Response does not contain a valid token.</p>';
        if ($tokenJson) {
            echo '<pre>' . json_encode($tokenJson, JSON_PRETTY_PRINT) . '</pre>';
        }
        echo '</div>';
        echo '</div>';
    }
    ?>
    
    <div class="section info">
        <h2>📋 Next Steps</h2>
        <p>If the call was successful:</p>
        <ol>
            <li>Both phones should have rung</li>
            <li>The API is working correctly</li>
            <li>You can now integrate it into your app</li>
        </ol>
        <p>If the call failed:</p>
        <ol>
            <li>Check the error message above</li>
            <li>Verify credentials are correct</li>
            <li>Ensure phone numbers are valid</li>
            <li>Contact EasyGo support if needed</li>
        </ol>
    </div>
</body>
</html>
