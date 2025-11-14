<?php
/**
 * TeleCMI Test Call - Make a call to any number
 */

// Credentials
$appId = '33336628';
$appSecret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';
$userId = '5003';

// Handle form submission
$result = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['make_call'])) {
    $toNumber = $_POST['to_number'] ?? '';
    $userIdInput = $_POST['user_id'] ?? $userId;
    $webrtc = isset($_POST['webrtc']);
    $followme = isset($_POST['followme']);
    
    if (!empty($toNumber)) {
        $fullUserId = $userIdInput . '_' . $appId;
        
        $payload = [
            'user_id'  => $fullUserId,
            'secret'   => $appSecret,
            'to'       => (int)$toNumber,
            'webrtc'   => $webrtc,
            'followme' => $followme
        ];
        
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => 'https://rest.telecmi.com/v2/webrtc/click2call',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);
        
        $result = [
            'http_code' => $httpCode,
            'error' => $curlError,
            'response' => json_decode($response, true),
            'payload' => $payload
        ];
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>TeleCMI Test Call</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            min-height: 100vh; 
            padding: 20px; 
        }
        .container { 
            max-width: 600px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 20px; 
            padding: 40px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
        }
        h1 { 
            color: #333; 
            margin-bottom: 10px; 
            font-size: 28px;
        }
        .subtitle { 
            color: #666; 
            margin-bottom: 30px; 
            font-size: 14px;
        }
        .form-group { 
            margin-bottom: 20px; 
        }
        label { 
            display: block; 
            margin-bottom: 8px; 
            color: #555; 
            font-weight: 600; 
            font-size: 14px;
        }
        input[type="text"], input[type="tel"] { 
            width: 100%; 
            padding: 14px; 
            border: 2px solid #e0e0e0; 
            border-radius: 10px; 
            font-size: 16px; 
            transition: border-color 0.3s;
        }
        input[type="text"]:focus, input[type="tel"]:focus { 
            outline: none; 
            border-color: #667eea; 
        }
        .checkbox-group {
            display: flex;
            gap: 20px;
            margin-top: 10px;
        }
        .checkbox-label {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
        }
        input[type="checkbox"] {
            width: 20px;
            height: 20px;
            cursor: pointer;
        }
        button { 
            width: 100%; 
            padding: 16px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            border: none; 
            border-radius: 10px; 
            font-size: 18px; 
            font-weight: 600; 
            cursor: pointer; 
            transition: transform 0.2s, box-shadow 0.2s;
        }
        button:hover { 
            transform: translateY(-2px); 
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4); 
        }
        button:active { 
            transform: translateY(0); 
        }
        .success { 
            background: #d4edda; 
            border-left: 4px solid #28a745; 
            padding: 20px; 
            margin: 20px 0; 
            border-radius: 8px; 
            color: #155724; 
        }
        .error { 
            background: #f8d7da; 
            border-left: 4px solid #dc3545; 
            padding: 20px; 
            margin: 20px 0; 
            border-radius: 8px; 
            color: #721c24; 
        }
        .info { 
            background: #d1ecf1; 
            border-left: 4px solid #17a2b8; 
            padding: 15px; 
            margin: 20px 0; 
            border-radius: 8px; 
            color: #0c5460;
            font-size: 13px;
        }
        pre { 
            background: #f4f4f4; 
            padding: 15px; 
            border-radius: 8px; 
            overflow-x: auto; 
            font-size: 12px;
            margin-top: 10px;
        }
        .help-text {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .result-section {
            margin-top: 30px;
            padding-top: 30px;
            border-top: 2px solid #e0e0e0;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>📞 TeleCMI Test Call</h1>
    <p class="subtitle">Make a test call to any phone number</p>
    
    <div class="info">
        <strong>ℹ️ How it works:</strong>
        <ul style="margin-top: 10px; margin-left: 20px;">
            <li>Enter the phone number you want to call</li>
            <li>Click "Make Call" button</li>
            <li>TeleCMI will initiate the call</li>
        </ul>
    </div>
    
    <form method="post">
        <div class="form-group">
            <label for="user_id">User ID:</label>
            <input type="text" id="user_id" name="user_id" value="<?php echo htmlspecialchars($userId); ?>" required>
            <p class="help-text">Your TeleCMI user ID (default: 5003)</p>
        </div>
        
        <div class="form-group">
            <label for="to_number">Phone Number to Call:</label>
            <input type="tel" id="to_number" name="to_number" placeholder="918448079624" required>
            <p class="help-text">Enter with country code (e.g., 918448079624 for India)</p>
        </div>
        
        <div class="form-group">
            <label>Call Options:</label>
            <div class="checkbox-group">
                <label class="checkbox-label">
                    <input type="checkbox" name="webrtc" id="webrtc">
                    <span>WebRTC</span>
                </label>
                <label class="checkbox-label">
                    <input type="checkbox" name="followme" id="followme" checked>
                    <span>Follow Me</span>
                </label>
            </div>
            <p class="help-text">⚠️ Uncheck WebRTC for regular PSTN calls. Follow Me: Call will ring on your registered device</p>
        </div>
        
        <button type="submit" name="make_call">📞 Make Call</button>
    </form>
    
    <?php if ($result): ?>
    <div class="result-section">
        <h2 style="color: #333; margin-bottom: 15px;">Call Result</h2>
        
        <?php if ($result['http_code'] == 200 && (!isset($result['response']['error']) || $result['response']['error'] === false)): ?>
            <div class="success">
                <h3 style="margin-bottom: 10px;">✅ Call Initiated Successfully!</h3>
                <p>The call has been initiated to <strong><?php echo htmlspecialchars($result['payload']['to']); ?></strong></p>
                <?php if (isset($result['response']['call_id'])): ?>
                    <p style="margin-top: 10px;"><strong>Call ID:</strong> <?php echo htmlspecialchars($result['response']['call_id']); ?></p>
                <?php endif; ?>
            </div>
        <?php else: ?>
            <div class="error">
                <h3 style="margin-bottom: 10px;">❌ Call Failed</h3>
                <?php if (isset($result['response']['msg'])): ?>
                    <p><strong>Error:</strong> <?php echo htmlspecialchars($result['response']['msg']); ?></p>
                <?php endif; ?>
                <?php if (isset($result['response']['code'])): ?>
                    <p><strong>Error Code:</strong> <?php echo htmlspecialchars($result['response']['code']); ?></p>
                <?php endif; ?>
            </div>
        <?php endif; ?>
        
        <details style="margin-top: 20px;">
            <summary style="cursor: pointer; font-weight: 600; color: #667eea;">View Request Details</summary>
            <div style="margin-top: 15px;">
                <h4 style="color: #555; margin-bottom: 10px;">Request Payload:</h4>
                <pre><?php echo json_encode($result['payload'], JSON_PRETTY_PRINT); ?></pre>
                
                <h4 style="color: #555; margin-bottom: 10px; margin-top: 15px;">API Response:</h4>
                <pre><?php echo json_encode($result['response'], JSON_PRETTY_PRINT); ?></pre>
                
                <p style="margin-top: 10px; font-size: 13px; color: #666;">
                    <strong>HTTP Code:</strong> <?php echo $result['http_code']; ?>
                </p>
            </div>
        </details>
    </div>
    <?php endif; ?>
    
    <div style="margin-top: 30px; padding-top: 20px; border-top: 2px solid #e0e0e0; text-align: center;">
        <p style="color: #666; font-size: 13px;">
            <a href="telecmi_status.php" style="color: #667eea; text-decoration: none;">📊 View API Status</a> | 
            <a href="telecmi_demo.html" style="color: #667eea; text-decoration: none;">🎮 Interactive Demo</a>
        </p>
    </div>
</div>

<script>
// Auto-format phone number
document.getElementById('to_number').addEventListener('input', function(e) {
    // Remove any non-digit characters
    let value = e.target.value.replace(/\D/g, '');
    e.target.value = value;
});
</script>
</body>
</html>
