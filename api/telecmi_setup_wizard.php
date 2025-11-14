<?php
/**
 * TeleCMI Setup Wizard - Complete One-Click Setup
 */

require_once 'config.php';

$step = $_GET['step'] ?? 1;

?>
<!DOCTYPE html>
<html>
<head>
    <title>TeleCMI Setup Wizard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        h1 { color: #333; margin-bottom: 10px; }
        .subtitle { color: #666; margin-bottom: 30px; }
        .steps { display: flex; justify-content: space-between; margin-bottom: 40px; }
        .step { flex: 1; text-align: center; padding: 15px; background: #f5f5f5; margin: 0 5px; border-radius: 10px; position: relative; }
        .step.active { background: #667eea; color: white; }
        .step.completed { background: #28a745; color: white; }
        .step-number { display: inline-block; width: 30px; height: 30px; line-height: 30px; border-radius: 50%; background: white; color: #333; font-weight: bold; margin-bottom: 5px; }
        .step.active .step-number { background: white; color: #667eea; }
        .step.completed .step-number { background: white; color: #28a745; }
        .content { margin: 30px 0; }
        .success { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 15px 0; border-radius: 5px; color: #155724; }
        .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 15px 0; border-radius: 5px; color: #721c24; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 15px 0; border-radius: 5px; color: #856404; }
        .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 15px 0; border-radius: 5px; color: #0c5460; }
        .btn { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 10px; margin: 10px 5px; font-weight: 600; transition: all 0.3s; border: none; cursor: pointer; font-size: 16px; }
        .btn:hover { background: #5568d3; transform: translateY(-2px); box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4); }
        .btn-success { background: #28a745; }
        .btn-success:hover { background: #218838; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
        pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
<div class="container">
    <h1>🚀 TeleCMI Setup Wizard</h1>
    <p class="subtitle">Complete setup in 3 easy steps</p>
    
    <div class="steps">
        <div class="step <?php echo $step >= 1 ? 'active' : ''; ?> <?php echo $step > 1 ? 'completed' : ''; ?>">
            <div class="step-number">1</div>
            <div>Environment</div>
        </div>
        <div class="step <?php echo $step >= 2 ? 'active' : ''; ?> <?php echo $step > 2 ? 'completed' : ''; ?>">
            <div class="step-number">2</div>
            <div>Database</div>
        </div>
        <div class="step <?php echo $step >= 3 ? 'active' : ''; ?>">
            <div class="step-number">3</div>
            <div>Test & Deploy</div>
        </div>
    </div>
    
    <div class="content">
        <?php
        
        switch ($step) {
            case 1:
                // Step 1: Environment Setup
                echo "<h2>Step 1: Environment Configuration</h2>";
                
                // Check if .env exists
                $possiblePaths = [
                    __DIR__ . '/../.env',
                    __DIR__ . '/../../.env',
                    '/var/www/vhosts/truckmitr.com/httpdocs/.env',
                ];
                
                $envFile = null;
                foreach ($possiblePaths as $path) {
                    if (file_exists($path)) {
                        $envFile = $path;
                        break;
                    }
                }
                
                if (!$envFile) {
                    echo "<div class='error'><strong>❌ .env file not found!</strong><br>Please create a .env file in your project root.</div>";
                    break;
                }
                
                echo "<div class='success'>✅ .env file found: <code>" . htmlspecialchars($envFile) . "</code></div>";
                
                // Check if TeleCMI vars exist
                $content = file_get_contents($envFile);
                $hasTelecmi = strpos($content, 'TELECMI_APP_ID') !== false;
                
                if ($hasTelecmi) {
                    echo "<div class='success'><strong>✅ TeleCMI configuration already exists!</strong></div>";
                    echo "<p>Your .env file already has TeleCMI credentials configured.</p>";
                    echo "<a href='?step=2' class='btn btn-success'>Continue to Step 2 →</a>";
                } else {
                    echo "<div class='warning'><strong>⚠️ TeleCMI configuration missing</strong></div>";
                    echo "<p>Click the button below to add TeleCMI credentials to your .env file:</p>";
                    
                    if (isset($_POST['add_config'])) {
                        $telecmiConfig = "\n# MyOperator IVR Configuration for Voice Calling\nMYOPERATOR_COMPANY_ID=5edf736f7308d685\nMYOPERATOR_SECRET_TOKEN=b177cf304671763bc77c35bdb0856de043702253c4967b7b145a34ca0d592ced\nMYOPERATOR_IVR_ID=656db25ba652e270\nMYOPERATOR_API_KEY=oomfKA3I2K6TCJYistHyb7sDf0l0F6c8AZro5DJh\nMYOPERATOR_CALLER_ID=911234567890\nMYOPERATOR_API_URL=https://obd-api.myoperator.co/obd-api-v1\n\n# TeleCMI IVR Configuration for Voice Calling\nTELECMI_APP_ID=33336628\nTELECMI_APP_SECRET=a7003cba-292c-4853-9792-66fe0f31270f\nTELECMI_SDK_BASE=https://piopiy.telecmi.com/v1/agentLogin\nTELECMI_REST_BASE=https://rest.telecmi.com/v2/click2call\nTELECMI_ACCESS_TOKEN=\n";
                        
                        if (file_put_contents($envFile, $telecmiConfig, FILE_APPEND)) {
                            echo "<div class='success'><strong>✅ Configuration added successfully!</strong></div>";
                            echo "<a href='?step=2' class='btn btn-success'>Continue to Step 2 →</a>";
                        } else {
                            echo "<div class='error'><strong>❌ Failed to write to .env file!</strong><br>Please add manually or check file permissions.</div>";
                        }
                    } else {
                        echo "<form method='post'>";
                        echo "<button type='submit' name='add_config' class='btn'>Add TeleCMI Configuration</button>";
                        echo "</form>";
                    }
                }
                break;
                
            case 2:
                // Step 2: Database Setup
                echo "<h2>Step 2: Database Configuration</h2>";
                
                $result = $conn->query("SHOW TABLES LIKE 'call_logs'");
                if ($result->num_rows > 0) {
                    echo "<div class='success'>✅ Table 'call_logs' exists</div>";
                    
                    // Check for provider column
                    $result = $conn->query("SHOW COLUMNS FROM call_logs LIKE 'provider'");
                    if ($result->num_rows > 0) {
                        echo "<div class='success'>✅ Column 'provider' exists</div>";
                    } else {
                        if (isset($_POST['add_column'])) {
                            if ($conn->query("ALTER TABLE call_logs ADD COLUMN provider VARCHAR(50) DEFAULT 'telecmi' AFTER duration")) {
                                echo "<div class='success'>✅ Column 'provider' added successfully!</div>";
                            } else {
                                echo "<div class='error'>❌ Failed to add column: " . $conn->error . "</div>";
                            }
                        } else {
                            echo "<div class='warning'>⚠️ Column 'provider' missing</div>";
                            echo "<form method='post'>";
                            echo "<button type='submit' name='add_column' class='btn'>Add Provider Column</button>";
                            echo "</form>";
                        }
                    }
                    
                    echo "<p style='margin-top:20px;'><a href='?step=3' class='btn btn-success'>Continue to Step 3 →</a></p>";
                } else {
                    echo "<div class='error'>❌ Table 'call_logs' does not exist</div>";
                    echo "<p>Please run the setup script first:</p>";
                    echo "<a href='setup_telecmi_table.php' class='btn' target='_blank'>Create Table</a>";
                }
                break;
                
            case 3:
                // Step 3: Test & Deploy
                echo "<h2>Step 3: Test & Deploy</h2>";
                echo "<div class='success'><strong>🎉 Setup Complete!</strong></div>";
                echo "<p>Your TeleCMI API is now configured and ready to use.</p>";
                
                echo "<h3>Test Your Setup:</h3>";
                echo "<p><a href='test_telecmi_live.php' class='btn' target='_blank'>🔴 Run Live Test</a></p>";
                
                echo "<h3>Try Interactive Demo:</h3>";
                echo "<p><a href='telecmi_demo.html' class='btn' target='_blank'>📞 Open Demo</a></p>";
                
                echo "<h3>API Endpoints:</h3>";
                $baseUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']);
                echo "<table>";
                echo "<tr><th>Endpoint</th><th>URL</th></tr>";
                echo "<tr><td>SDK Token</td><td><code>$baseUrl/telecmi_api.php?action=sdk_token</code></td></tr>";
                echo "<tr><td>Click-to-Call</td><td><code>$baseUrl/telecmi_api.php?action=click_to_call</code></td></tr>";
                echo "<tr><td>Webhook</td><td><code>$baseUrl/telecmi_api.php?action=webhook</code></td></tr>";
                echo "</table>";
                
                echo "<h3>Flutter Integration:</h3>";
                echo "<pre><code>// Make a call
final response = await http.post(
  Uri.parse('$baseUrl/telecmi_api.php?action=click_to_call'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'to': '919876543210',
    'callerid': '919123456789',
  }),
);</code></pre>";
                
                echo "<h3>Documentation:</h3>";
                echo "<p><a href='../TELECMI_API_SETUP.md' class='btn'>📚 Full Documentation</a></p>";
                break;
        }
        
        ?>
    </div>
</div>
</body>
</html>
<?php
$conn->close();
?>
