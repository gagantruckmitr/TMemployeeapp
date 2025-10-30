<!DOCTYPE html>
<html>
<head>
    <title>Manual IVR Call Test</title>
    <meta charset="utf-8">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px;
            width: 100%;
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
            margin-bottom: 25px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: bold;
            font-size: 14px;
        }
        input[type="text"] {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        input[type="text"]:focus {
            outline: none;
            border-color: #667eea;
        }
        .hint {
            font-size: 12px;
            color: #999;
            margin-top: 5px;
        }
        button {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 18px;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.2s;
        }
        button:hover {
            transform: translateY(-2px);
        }
        button:active {
            transform: translateY(0);
        }
        .result {
            margin-top: 30px;
            padding: 20px;
            border-radius: 8px;
            display: none;
        }
        .result.success {
            background: #d4edda;
            border: 2px solid #28a745;
            color: #155724;
            display: block;
        }
        .result.error {
            background: #f8d7da;
            border: 2px solid #dc3545;
            color: #721c24;
            display: block;
        }
        .result h3 {
            margin-bottom: 10px;
        }
        .result pre {
            background: rgba(0,0,0,0.05);
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
            font-size: 12px;
            margin-top: 10px;
        }
        .icon { font-size: 24px; margin-right: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📞 Manual IVR Call Test</h1>
        <p class="subtitle">Enter two phone numbers to test MyOperator IVR calling</p>
        
        <form method="POST" action="">
            <div class="form-group">
                <label for="driver_number">
                    <span class="icon">📱</span>Driver/Customer Number (Called FIRST)
                </label>
                <input 
                    type="text" 
                    id="driver_number" 
                    name="driver_number" 
                    placeholder="8383971722"
                    value="<?php echo isset($_POST['driver_number']) ? htmlspecialchars($_POST['driver_number']) : '8383971722'; ?>"
                    required
                    pattern="[0-9]{10}"
                    maxlength="10"
                >
                <div class="hint">Enter 10-digit mobile number (without +91)</div>
            </div>
            
            <div class="form-group">
                <label for="agent_number">
                    <span class="icon">👤</span>Telecaller/Agent Number (Connected NEXT)
                </label>
                <input 
                    type="text" 
                    id="agent_number" 
                    name="agent_number" 
                    placeholder="6394756798"
                    value="<?php echo isset($_POST['agent_number']) ? htmlspecialchars($_POST['agent_number']) : '6394756798'; ?>"
                    required
                    pattern="[0-9]{10}"
                    maxlength="10"
                >
                <div class="hint">Enter 10-digit mobile number (without +91)</div>
            </div>
            
            <button type="submit" name="make_call">
                <span class="icon">📞</span>Make Call Now
            </button>
        </form>
        
        <?php
        if (isset($_POST['make_call'])) {
            $driverNumber = preg_replace('/[^0-9]/', '', $_POST['driver_number']);
            $agentNumber = preg_replace('/[^0-9]/', '', $_POST['agent_number']);
            
            if (strlen($driverNumber) != 10 || strlen($agentNumber) != 10) {
                echo '<div class="result error">';
                echo '<h3>❌ Invalid Numbers</h3>';
                echo '<p>Both numbers must be exactly 10 digits.</p>';
                echo '</div>';
            } else {
                // MyOperator credentials
                $companyId = '5edf736f7308d685';
                $secretToken = 'b177cf304671763bc77c35bdb0856de043702253c4967b7b145a34ca0d592ced';
                $apiKey = 'oomfKA3I2K6TCJYistHyb7sDf0l0F6c8AZro5DJh';
                $ivrId = '656db25ba652e270';
                $callerId = '911234567890';
                $apiUrl = 'https://obd-api.myoperator.co/obd-api-v1';
                
                // Prepare payload
                $payload = [
                    'company_id' => $companyId,
                    'secret_token' => $secretToken,
                    'public_ivr_id' => $ivrId,
                    'type' => '2',
                    'number' => '+91' . $driverNumber,
                    'agent_number' => '+91' . $agentNumber,
                    'caller_id' => $callerId,
                    'reference_id' => 'MANUAL_' . time(),
                    'dtmf' => '0',
                    'retry' => '0',
                    'max_ring_time' => '30'
                ];
                
                // Call MyOperator API
                $ch = curl_init($apiUrl);
                curl_setopt_array($ch, [
                    CURLOPT_POST => true,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_HTTPHEADER => [
                        'x-api-key: ' . $apiKey,
                        'Content-Type: application/json'
                    ],
                    CURLOPT_POSTFIELDS => json_encode($payload),
                    CURLOPT_TIMEOUT => 30
                ]);
                
                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $error = curl_error($ch);
                curl_close($ch);
                
                if ($error) {
                    echo '<div class="result error">';
                    echo '<h3>❌ Connection Error</h3>';
                    echo '<p>' . htmlspecialchars($error) . '</p>';
                    echo '</div>';
                } else {
                    $data = json_decode($response, true);
                    
                    if ($httpCode >= 200 && $httpCode < 300) {
                        echo '<div class="result success">';
                        echo '<h3>✅ Call Initiated Successfully!</h3>';
                        echo '<p><strong>Driver Number:</strong> +91' . $driverNumber . ' (will ring FIRST)</p>';
                        echo '<p><strong>Agent Number:</strong> +91' . $agentNumber . ' (will ring when driver picks up)</p>';
                        if (isset($data['unique_id'])) {
                            echo '<p><strong>Unique ID:</strong> ' . $data['unique_id'] . '</p>';
                        }
                        if (isset($data['reference_id'])) {
                            echo '<p><strong>Reference ID:</strong> ' . $data['reference_id'] . '</p>';
                        }
                        echo '<p style="margin-top: 15px; padding: 10px; background: rgba(0,0,0,0.05); border-radius: 5px;">';
                        echo '<strong>📱 What happens next:</strong><br>';
                        echo '1. Driver phone rings NOW<br>';
                        echo '2. Driver hears IVR message<br>';
                        echo '3. Agent phone rings NEXT<br>';
                        echo '4. Both connected instantly!';
                        echo '</p>';
                        echo '<pre>' . json_encode($data, JSON_PRETTY_PRINT) . '</pre>';
                        echo '</div>';
                    } else {
                        echo '<div class="result error">';
                        echo '<h3>❌ Call Failed</h3>';
                        echo '<p><strong>HTTP Status:</strong> ' . $httpCode . '</p>';
                        if (isset($data['message'])) {
                            echo '<p><strong>Error:</strong> ' . htmlspecialchars($data['message']) . '</p>';
                        }
                        echo '<pre>' . json_encode($data, JSON_PRETTY_PRINT) . '</pre>';
                        echo '</div>';
                    }
                }
            }
        }
        ?>
    </div>
</body>
</html>
