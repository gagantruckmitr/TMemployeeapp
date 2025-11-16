<?php
/**
 * Test EasyGo IVR with Existing Token
 * Use this if token generation is not working
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Use the existing token you provided
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjaWQiOiI1MTEiLCJ1c2VyX2lkIjoiMTI4OSIsInVzZXJfbG9naW4iOiJhZG1pbkB0cnVja21pdHIuY29tIiwia3ljIjoiMSIsImV4cCI6MTc2MzQ4MDI5NywiY2xpZW50aXAiOm51bGwsImlwIjoiNDkuMzYuMTQ0LjI0MyIsImlzYWRtaW4iOiIxIiwiZGlyZWN0RGlhbCI6IjEiLCJzZXJ2ZXIiOm51bGx9.9sLOjmgP0D0cmPLe54C8ha8HcNnmwSn6QP3EEGXn5FY';

$did = '6882742';
$dialUrl = 'https://client.easygoivr.com/easygoapiJwt/request/dial';

// Test phone numbers
$telecallerPhone = '08303154516';
$clientPhone = '06394756798';

?>
<!DOCTYPE html>
<html>
<head>
    <title>EasyGo IVR Test with Token</title>
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
    <h1>📞 EasyGo IVR Test with Existing Token</h1>
    
    <div class="section info">
        <h2>Configuration</h2>
        <p><strong>Token:</strong> <?php echo substr($token, 0, 50); ?>...</p>
        <p><strong>DID:</strong> <?php echo $did; ?></p>
        <p><strong>Telecaller Phone:</strong> <?php echo $telecallerPhone; ?></p>
        <p><strong>Client Phone:</strong> <?php echo $clientPhone; ?></p>
    </div>

    <?php
    // Initiate Call
    echo '<div class="section">';
    echo '<h2>Initiating Call...</h2>';
    
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
            echo '<p><strong>🎉 Both phones should ring now!</strong></p>';
            echo '<ul>';
            echo "<li>📱 Telecaller phone: $telecallerPhone</li>";
            echo "<li>👤 Client phone: $clientPhone</li>";
            echo '<li>⏰ Answer either phone to connect</li>';
            echo '</ul>';
            if ($callJson) {
                echo '<p><strong>Response Data:</strong></p>';
                echo '<pre>' . json_encode($callJson, JSON_PRETTY_PRINT) . '</pre>';
            }
            echo '</div>';
            
            // Save to database
            require_once 'config.php';
            
            $referenceId = $callJson['call_id'] ?? $callJson['reference_id'] ?? uniqid('easygo_');
            $responseJson = json_encode($callJson);
            
            $stmt = $conn->prepare("
                INSERT INTO call_logs 
                (caller_id, tc_for, user_id, call_status, caller_number, user_number,
                 reference_id, api_response, call_initiated_at, created_at, updated_at)
                VALUES (1, 'easygo_ivr_test', 'TEST_USER', 'connected', ?, ?, ?, ?, NOW(), NOW(), NOW())
            ");
            
            $stmt->bind_param('ssss', $telecallerPhone, $clientPhone, $referenceId, $responseJson);
            
            if ($stmt->execute()) {
                $callLogId = $conn->insert_id;
                echo '<div class="info">';
                echo '<h3>💾 Saved to Database</h3>';
                echo "<p><strong>Call Log ID:</strong> $callLogId</p>";
                echo "<p><strong>Reference ID:</strong> $referenceId</p>";
                echo '</div>';
            }
            
            $stmt->close();
            $conn->close();
            
        } else {
            echo '<div class="error">';
            echo '<h3>❌ Call Failed</h3>';
            echo "<p>HTTP Code: $callHttpCode</p>";
            if ($callJson) {
                echo '<p><strong>Error Details:</strong></p>';
                echo '<pre>' . json_encode($callJson, JSON_PRETTY_PRINT) . '</pre>';
            }
            
            // Check if token expired
            if ($callHttpCode === 401 || $callHttpCode === 403) {
                echo '<div class="info" style="margin-top: 20px;">';
                echo '<h4>🔑 Token May Be Expired</h4>';
                echo '<p>The token might have expired. You need to:</p>';
                echo '<ol>';
                echo '<li>Contact EasyGo support to get a new token</li>';
                echo '<li>Or verify your account credentials</li>';
                echo '<li>Update the token in this file</li>';
                echo '</ol>';
                echo '</div>';
            }
            echo '</div>';
        }
    }
    
    echo '</div>';
    ?>
    
    <div class="section info">
        <h2>📋 What This Test Does</h2>
        <ol>
            <li>Uses the existing EasyGo API token</li>
            <li>Sends a call request to EasyGo dial API</li>
            <li>Both phones should ring simultaneously</li>
            <li>Saves the call log to your database</li>
        </ol>
        
        <h3>If Successful:</h3>
        <p>✅ Your EasyGo integration is working!</p>
        <p>✅ You can now use this in your Flutter app</p>
        
        <h3>If Failed:</h3>
        <p>❌ Token might be expired (check expiry: 1763480297)</p>
        <p>❌ Contact EasyGo support for a new token</p>
    </div>
</body>
</html>
