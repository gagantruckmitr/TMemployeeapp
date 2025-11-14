<?php
/**
 * Update TeleCMI Credentials on Server
 * This script will update the .env file with correct credentials
 */

echo "<!DOCTYPE html>";
echo "<html><head>";
echo "<title>Update TeleCMI Credentials</title>";
echo "<style>
    body { font-family: Arial, sans-serif; max-width: 900px; margin: 50px auto; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .container { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
    h1 { color: #333; margin-bottom: 20px; }
    .success { background: #d4edda; border-left: 4px solid #28a745; padding: 20px; margin: 20px 0; border-radius: 8px; color: #155724; }
    .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 20px; margin: 20px 0; border-radius: 8px; color: #721c24; }
    .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; margin: 20px 0; border-radius: 8px; color: #856404; }
    .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 20px; margin: 20px 0; border-radius: 8px; color: #0c5460; }
    pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 13px; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    .btn { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 10px; margin: 10px 5px; font-weight: 600; border: none; cursor: pointer; font-size: 16px; }
    .btn:hover { background: #5568d3; transform: translateY(-2px); }
    .btn-success { background: #28a745; }
    .btn-success:hover { background: #218838; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #667eea; color: white; }
</style>";
echo "</head><body><div class='container'>";

echo "<h1>🔧 Update TeleCMI Credentials</h1>";

// New credentials
$newAppId = '33336628';
$newAppSecret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';

// Find .env file
$possiblePaths = [
    '/var/www/vhosts/truckmitr.com/httpdocs/.env',
    '/var/www/vhosts/truckmitr.com/httpdocs/truckmitr-app/.env',
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
];

$envFile = null;
foreach ($possiblePaths as $path) {
    if (file_exists($path)) {
        $envFile = $path;
        break;
    }
}

if (!$envFile) {
    echo "<div class='error'>";
    echo "<h3>❌ .env File Not Found</h3>";
    echo "<p>Could not locate .env file in any expected location.</p>";
    echo "</div>";
    exit;
}

echo "<div class='info'>";
echo "<p><strong>.env file found:</strong> <code>$envFile</code></p>";
echo "</div>";

// Read current content
$content = file_get_contents($envFile);

// Check current credentials
preg_match('/TELECMI_APP_ID=(.*)/', $content, $currentAppId);
preg_match('/TELECMI_APP_SECRET=(.*)/', $content, $currentAppSecret);

echo "<h2>Current Credentials</h2>";
echo "<table>";
echo "<tr><th>Setting</th><th>Current Value</th><th>New Value</th></tr>";
echo "<tr><td>TELECMI_APP_ID</td><td><code>" . ($currentAppId[1] ?? 'Not set') . "</code></td><td><code>$newAppId</code></td></tr>";
echo "<tr><td>TELECMI_APP_SECRET</td><td><code>" . (isset($currentAppSecret[1]) ? substr($currentAppSecret[1], 0, 20) . '...' : 'Not set') . "</code></td><td><code>" . substr($newAppSecret, 0, 20) . "...</code></td></tr>";
echo "</table>";

// Check if update is needed
$needsUpdate = false;
if (!isset($currentAppSecret[1]) || trim($currentAppSecret[1]) !== $newAppSecret) {
    $needsUpdate = true;
}

if (!$needsUpdate) {
    echo "<div class='success'>";
    echo "<h3>✅ Credentials Already Up to Date!</h3>";
    echo "<p>The .env file already has the correct credentials.</p>";
    echo "</div>";
    
    echo "<p><a href='test_new_credentials.php' class='btn btn-success'>Test Credentials</a></p>";
    exit;
}

// Perform update if requested
if (isset($_POST['update'])) {
    
    // Check if file is writable
    if (!is_writable($envFile)) {
        echo "<div class='error'>";
        echo "<h3>❌ File Not Writable</h3>";
        echo "<p>The .env file is not writable. Please run:</p>";
        echo "<pre>chmod 644 $envFile</pre>";
        echo "</div>";
        exit;
    }
    
    // Create backup
    $backupFile = $envFile . '.backup.' . date('Y-m-d_H-i-s');
    if (copy($envFile, $backupFile)) {
        echo "<div class='info'>";
        echo "<p>✅ Backup created: <code>$backupFile</code></p>";
        echo "</div>";
    }
    
    // Update credentials
    $newContent = $content;
    
    // Update APP_SECRET
    $newContent = preg_replace(
        '/TELECMI_APP_SECRET=.*/',
        'TELECMI_APP_SECRET=' . $newAppSecret,
        $newContent
    );
    
    // Write updated content
    if (file_put_contents($envFile, $newContent)) {
        echo "<div class='success'>";
        echo "<h3>✅ Credentials Updated Successfully!</h3>";
        echo "<p>Your .env file has been updated with the correct TeleCMI credentials.</p>";
        echo "</div>";
        
        echo "<h3>Updated Values:</h3>";
        echo "<table>";
        echo "<tr><th>Setting</th><th>New Value</th></tr>";
        echo "<tr><td>TELECMI_APP_ID</td><td><code>$newAppId</code></td></tr>";
        echo "<tr><td>TELECMI_APP_SECRET</td><td><code>$newAppSecret</code></td></tr>";
        echo "</table>";
        
        // Test the new credentials
        echo "<h3>Testing New Credentials...</h3>";
        
        $testUser = 'update_test_' . time();
        $payload = json_encode([
            'app_id' => $newAppId,
            'app_secret' => $newAppSecret,
            'user' => $testUser,
        ]);
        
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => 'https://piopiy.telecmi.com/v1/agentLogin',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 10,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        $data = json_decode($response, true);
        
        if ($httpCode == 200 && isset($data['token'])) {
            echo "<div class='success'>";
            echo "<h3>🎉 SUCCESS! TeleCMI Authentication Working!</h3>";
            echo "<p>Your credentials are correct and the API is fully operational!</p>";
            echo "</div>";
            
            echo "<h3>✅ Your TeleCMI API is Ready!</h3>";
            echo "<p>You can now:</p>";
            echo "<ul>";
            echo "<li>✅ Generate SDK tokens for WebRTC calling</li>";
            echo "<li>✅ Make click-to-call requests</li>";
            echo "<li>✅ Integrate with your Flutter app</li>";
            echo "</ul>";
            
            echo "<h3>Next Steps:</h3>";
            echo "<p>";
            echo "<a href='telecmi_demo.html' class='btn btn-success'>📞 Try Interactive Demo</a> ";
            echo "<a href='telecmi_status.php' class='btn'>📊 View Status Dashboard</a>";
            echo "</p>";
            
            echo "<h3>API Endpoints:</h3>";
            $baseUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']);
            echo "<pre>";
            echo "SDK Token:      $baseUrl/telecmi_api.php?action=sdk_token\n";
            echo "Click-to-Call:  $baseUrl/telecmi_api.php?action=click_to_call\n";
            echo "Webhook:        $baseUrl/telecmi_api.php?action=webhook";
            echo "</pre>";
            
        } else {
            echo "<div class='warning'>";
            echo "<h3>⚠️ Credentials Updated but Authentication Failed</h3>";
            echo "<p><strong>Response:</strong></p>";
            echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
            echo "<p>Please verify these are the correct credentials from your TeleCMI dashboard.</p>";
            echo "</div>";
            
            echo "<p><a href='diagnose_telecmi_error.php' class='btn'>🔍 Diagnose Issue</a></p>";
        }
        
    } else {
        echo "<div class='error'>";
        echo "<h3>❌ Failed to Update File</h3>";
        echo "<p>Could not write to .env file. Please check file permissions.</p>";
        echo "</div>";
    }
    
} else {
    // Show confirmation form
    echo "<div class='warning'>";
    echo "<h3>⚠️ Ready to Update</h3>";
    echo "<p>This will update your .env file with the new TeleCMI credentials:</p>";
    echo "<ul>";
    echo "<li><strong>APP_ID:</strong> $newAppId</li>";
    echo "<li><strong>APP_SECRET:</strong> $newAppSecret</li>";
    echo "</ul>";
    echo "<p>A backup will be created before updating.</p>";
    echo "</div>";
    
    echo "<form method='post'>";
    echo "<button type='submit' name='update' class='btn btn-success'>✅ Update Credentials Now</button> ";
    echo "<a href='telecmi_status.php' class='btn'>Cancel</a>";
    echo "</form>";
}

echo "</div></body></html>";
?>
