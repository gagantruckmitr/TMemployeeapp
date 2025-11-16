<?php
/**
 * Test Complete EasyGo IVR Flow
 * Simulates a call from the app to verify everything works
 */

header('Content-Type: text/html; charset=utf-8');

?>
<!DOCTYPE html>
<html>
<head>
    <title>EasyGo IVR Complete Flow Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; color: #856404; }
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
        button { background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin: 5px; }
        button:hover { background: #0056b3; }
        .test-form { background: #f8f9fa; padding: 15px; border-radius: 4px; margin: 15px 0; }
        input { padding: 8px; margin: 5px; border: 1px solid #ddd; border-radius: 4px; width: 200px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔵 EasyGo IVR Complete Flow Test</h1>
        
        <?php
        require_once 'config.php';
        
        // Check if token is configured
        $tokenConfigured = false;
        $tokenFile = 'easygo_ivr_api.php';
        if (file_exists($tokenFile)) {
            $content = file_get_contents($tokenFile);
            if (strpos($content, "define('EASYGO_MANUAL_TOKEN', 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN')") === false) {
                $tokenConfigured = true;
            }
        }
        
        if (!$tokenConfigured) {
            echo '<div class="status error">';
            echo '<strong>⚠️ TOKEN NOT CONFIGURED</strong><br>';
            echo 'The EasyGo API token is not set up. Please update EASYGO_MANUAL_TOKEN in easygo_ivr_api.php<br>';
            echo 'Contact EasyGo support to get a valid token.';
            echo '</div>';
        } else {
            echo '<div class="status success">';
            echo '<strong>✅ TOKEN CONFIGURED</strong><br>';
            echo 'EasyGo API token is set. You can test calls below.';
            echo '</div>';
        }
        ?>
        
        <h2>Test Call Initiation</h2>
        <div class="test-form">
            <form method="POST" action="">
                <label>Telecaller Phone (10 digits):</label><br>
                <input type="text" name="telecaller_phone" value="9876543210" required><br>
                
                <label>Client Phone (10 digits):</label><br>
                <input type="text" name="client_phone" value="9876543211" required><br>
                
                <label>Client Name:</label><br>
                <input type="text" name="client_name" value="Test Driver" required><br>
                
                <label>Contact Type:</label><br>
                <select name="contact_type">
                    <option value="driver">Driver</option>
                    <option value="transporter">Transporter</option>
                </select><br><br>
                
                <button type="submit" name="test_call">🔵 Initiate Test Call</button>
            </form>
        </div>
        
        <?php
        if (isset($_POST['test_call'])) {
            $telecallerPhone = preg_replace('/[^\d]/', '', $_POST['telecaller_phone']);
            $clientPhone = preg_replace('/[^\d]/', '', $_POST['client_phone']);
            $clientName = $_POST['client_name'];
            $contactType = $_POST['contact_type'];
            
            echo '<h3>Test Results:</h3>';
            
            // Validate phone numbers
            if (strlen($telecallerPhone) != 10 || strlen($clientPhone) != 10) {
                echo '<div class="status error">Invalid phone numbers. Must be 10 digits.</div>';
            } else {
                // Make API call
                $url = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . '/easygo_ivr_api.php?action=initiate_call';
                
                $data = [
                    'exten' => $telecallerPhone,
                    'number' => $clientPhone,
                    'caller_id' => '1',
                    'contact_id' => 'TEST123',
                    'contact_type' => $contactType,
                    'driver_name' => $clientName,
                    'duration' => ''
                ];
                
                echo '<div class="status info">';
                echo '<strong>Request:</strong><br>';
                echo 'URL: ' . $url . '<br>';
                echo 'Data: <pre>' . json_encode($data, JSON_PRETTY_PRINT) . '</pre>';
                echo '</div>';
                
                $ch = curl_init($url);
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                
                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);
                
                $result = json_decode($response, true);
                
                if ($result && $result['success']) {
                    echo '<div class="status success">';
                    echo '<strong>✅ CALL INITIATED SUCCESSFULLY!</strong><br>';
                    echo 'Reference ID: ' . ($result['reference_id'] ?? 'N/A') . '<br>';
                    echo 'Call Log ID: ' . ($result['call_log_id'] ?? 'N/A') . '<br>';
                    echo '<br><strong>Both phones should ring now!</strong>';
                    echo '</div>';
                    
                    echo '<div class="status info">';
                    echo '<strong>Response:</strong><pre>' . json_encode($result, JSON_PRETTY_PRINT) . '</pre>';
                    echo '</div>';
                } else {
                    echo '<div class="status error">';
                    echo '<strong>❌ CALL FAILED</strong><br>';
                    echo 'Error: ' . ($result['error'] ?? 'Unknown error') . '<br>';
                    echo '</div>';
                    
                    echo '<div class="status warning">';
                    echo '<strong>Response:</strong><pre>' . $response . '</pre>';
                    echo '</div>';
                }
            }
        }
        ?>
        
        <h2>Check Recent Call Logs</h2>
        <?php
        $stmt = $conn->prepare("
            SELECT id, caller_id, tc_for, driver_name, call_status, 
                   caller_number, user_number, reference_id, created_at
            FROM call_logs 
            WHERE tc_for LIKE 'easygo_ivr%'
            ORDER BY created_at DESC 
            LIMIT 5
        ");
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            echo '<table border="1" cellpadding="5" style="width:100%; border-collapse: collapse;">';
            echo '<tr style="background: #f8f9fa;">';
            echo '<th>ID</th><th>Type</th><th>Driver</th><th>Status</th><th>Phones</th><th>Reference</th><th>Time</th>';
            echo '</tr>';
            
            while ($row = $result->fetch_assoc()) {
                echo '<tr>';
                echo '<td>' . $row['id'] . '</td>';
                echo '<td>' . $row['tc_for'] . '</td>';
                echo '<td>' . $row['driver_name'] . '</td>';
                echo '<td>' . $row['call_status'] . '</td>';
                echo '<td>' . $row['caller_number'] . ' → ' . $row['user_number'] . '</td>';
                echo '<td>' . $row['reference_id'] . '</td>';
                echo '<td>' . $row['created_at'] . '</td>';
                echo '</tr>';
            }
            echo '</table>';
        } else {
            echo '<div class="status info">No EasyGo IVR calls found in logs yet.</div>';
        }
        $stmt->close();
        ?>
        
        <h2>Integration Checklist</h2>
        <div class="status info">
            <strong>✅ Completed:</strong><br>
            • Job Applicants Screen - Driver calls<br>
            • Match Making Screen - Driver calls<br>
            • Modern Job Card - Transporter calls<br>
            • Call logging to database<br>
            • Feedback modal integration<br>
            • Phone privacy (numbers hidden)<br>
            <br>
            <strong>⏳ Pending:</strong><br>
            • Valid EasyGo API token configuration<br>
            • Production testing with real calls<br>
        </div>
    </div>
</body>
</html>
