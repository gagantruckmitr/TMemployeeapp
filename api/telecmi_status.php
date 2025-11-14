<?php
/**
 * TeleCMI Complete Status Check
 * Shows the current status of your TeleCMI integration
 */

require_once 'config.php';

?>
<!DOCTYPE html>
<html>
<head>
    <title>TeleCMI Status</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        h1 { color: #333; margin-bottom: 10px; }
        h2 { color: #667eea; margin-top: 30px; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .status-card { background: #f8f9fa; padding: 20px; border-radius: 10px; border-left: 4px solid #ccc; }
        .status-card.success { border-left-color: #28a745; background: #d4edda; }
        .status-card.error { border-left-color: #dc3545; background: #f8d7da; }
        .status-card.warning { border-left-color: #ffc107; background: #fff3cd; }
        .status-card h3 { font-size: 14px; color: #666; margin-bottom: 10px; }
        .status-card .value { font-size: 24px; font-weight: bold; color: #333; }
        .btn { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 8px; margin: 5px; font-weight: 600; transition: all 0.3s; }
        .btn:hover { background: #5568d3; transform: translateY(-2px); }
        .btn-success { background: #28a745; }
        .btn-success:hover { background: #218838; }
        .btn-danger { background: #dc3545; }
        .btn-danger:hover { background: #c82333; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
        .alert { padding: 15px; border-radius: 8px; margin: 15px 0; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-danger { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .alert-warning { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
    </style>
</head>
<body>
<div class="container">
    <h1>📊 TeleCMI Integration Status</h1>
    <p style="color: #666; margin-bottom: 30px;">Complete overview of your TeleCMI setup</p>
    
    <?php
    
    // Load environment
    function loadEnv() {
        $paths = [
            '/var/www/vhosts/truckmitr.com/httpdocs/.env',
            __DIR__ . '/../.env',
            __DIR__ . '/../../.env',
        ];
        
        foreach ($paths as $path) {
            if (file_exists($path)) {
                $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
                foreach ($lines as $line) {
                    if (strpos(trim($line), '#') === 0) continue;
                    if (strpos($line, '=') === false) continue;
                    
                    list($name, $value) = explode('=', $line, 2);
                    $name = trim($name);
                    $value = trim($value);
                    
                    if (!array_key_exists($name, $_ENV)) {
                        $_ENV[$name] = $value;
                        putenv("$name=$value");
                    }
                }
                return $path;
            }
        }
        return false;
    }
    
    $envPath = loadEnv();
    
    // Get credentials
    $appId = getenv('TELECMI_APP_ID') ?: '33336628';
    $appSecret = getenv('TELECMI_APP_SECRET') ?: 'a7003cba-292c-4853-9792-66fe0f31270f';
    $sdkBase = getenv('TELECMI_SDK_BASE') ?: 'https://piopiy.telecmi.com/v1/agentLogin';
    $restBase = getenv('TELECMI_REST_BASE') ?: 'https://rest.telecmi.com/v2/click2call';
    
    // Status checks
    $envOk = $envPath !== false;
    $credsOk = !empty($appId) && !empty($appSecret);
    
    // Check database
    $dbOk = false;
    $providerOk = false;
    try {
        $result = $conn->query("SHOW TABLES LIKE 'call_logs'");
        $dbOk = $result->num_rows > 0;
        
        if ($dbOk) {
            $result = $conn->query("SHOW COLUMNS FROM call_logs LIKE 'provider'");
            $providerOk = $result->num_rows > 0;
        }
    } catch (Exception $e) {
        $dbOk = false;
    }
    
    // Check API file
    $apiOk = file_exists(__DIR__ . '/telecmi_api.php');
    
    // Test TeleCMI connection
    $telecmiOk = false;
    $telecmiMsg = '';
    
    if ($credsOk) {
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $sdkBase,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 5,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode([
                'app_id' => $appId,
                'app_secret' => $appSecret,
                'user' => 'status_check_' . time(),
            ]),
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode == 200) {
            $data = json_decode($response, true);
            if (isset($data['token'])) {
                $telecmiOk = true;
                $telecmiMsg = 'Connected successfully';
            } else {
                $telecmiMsg = 'Connected but no token received';
            }
        } else {
            $telecmiMsg = "HTTP $httpCode";
        }
    }
    
    // Overall status
    $allOk = $envOk && $credsOk && $dbOk && $providerOk && $apiOk && $telecmiOk;
    
    ?>
    
    <!-- Overall Status -->
    <?php if ($allOk): ?>
        <div class="alert alert-success">
            <h3 style="margin-bottom: 10px;">✅ All Systems Operational!</h3>
            <p>Your TeleCMI API is fully configured and ready to use.</p>
        </div>
    <?php else: ?>
        <div class="alert alert-warning">
            <h3 style="margin-bottom: 10px;">⚠️ Setup Incomplete</h3>
            <p>Some components need attention. See details below.</p>
        </div>
    <?php endif; ?>
    
    <!-- Status Cards -->
    <div class="status-grid">
        <div class="status-card <?php echo $envOk ? 'success' : 'error'; ?>">
            <h3>Environment File</h3>
            <div class="value"><?php echo $envOk ? '✅ Found' : '❌ Missing'; ?></div>
        </div>
        
        <div class="status-card <?php echo $credsOk ? 'success' : 'error'; ?>">
            <h3>Credentials</h3>
            <div class="value"><?php echo $credsOk ? '✅ Set' : '❌ Missing'; ?></div>
        </div>
        
        <div class="status-card <?php echo $dbOk ? 'success' : 'error'; ?>">
            <h3>Database Table</h3>
            <div class="value"><?php echo $dbOk ? '✅ Ready' : '❌ Missing'; ?></div>
        </div>
        
        <div class="status-card <?php echo $telecmiOk ? 'success' : ($credsOk ? 'warning' : 'error'); ?>">
            <h3>TeleCMI Connection</h3>
            <div class="value"><?php echo $telecmiOk ? '✅ Online' : '⚠️ ' . $telecmiMsg; ?></div>
        </div>
    </div>
    
    <!-- Configuration Details -->
    <h2>Configuration Details</h2>
    
    <table>
        <tr>
            <th>Component</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
        <tr>
            <td><strong>.env File</strong></td>
            <td><?php echo $envOk ? '✅' : '❌'; ?></td>
            <td><?php echo $envPath ? "<code>$envPath</code>" : 'Not found'; ?></td>
        </tr>
        <tr>
            <td><strong>TELECMI_APP_ID</strong></td>
            <td><?php echo $appId ? '✅' : '❌'; ?></td>
            <td><code><?php echo $appId ?: 'Not set'; ?></code></td>
        </tr>
        <tr>
            <td><strong>TELECMI_APP_SECRET</strong></td>
            <td><?php echo $appSecret ? '✅' : '❌'; ?></td>
            <td><code><?php echo $appSecret ? substr($appSecret, 0, 15) . '...' : 'Not set'; ?></code></td>
        </tr>
        <tr>
            <td><strong>SDK Base URL</strong></td>
            <td>✅</td>
            <td><code><?php echo $sdkBase; ?></code></td>
        </tr>
        <tr>
            <td><strong>REST Base URL</strong></td>
            <td>✅</td>
            <td><code><?php echo $restBase; ?></code></td>
        </tr>
        <tr>
            <td><strong>call_logs Table</strong></td>
            <td><?php echo $dbOk ? '✅' : '❌'; ?></td>
            <td><?php echo $dbOk ? 'Exists' : 'Missing'; ?></td>
        </tr>
        <tr>
            <td><strong>provider Column</strong></td>
            <td><?php echo $providerOk ? '✅' : '❌'; ?></td>
            <td><?php echo $providerOk ? 'Exists' : 'Missing'; ?></td>
        </tr>
        <tr>
            <td><strong>API File</strong></td>
            <td><?php echo $apiOk ? '✅' : '❌'; ?></td>
            <td><?php echo $apiOk ? 'telecmi_api.php exists' : 'Missing'; ?></td>
        </tr>
    </table>
    
    <!-- API Endpoints -->
    <h2>API Endpoints</h2>
    
    <?php $baseUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']); ?>
    
    <table>
        <tr>
            <th>Endpoint</th>
            <th>URL</th>
        </tr>
        <tr>
            <td>SDK Token</td>
            <td><code><?php echo $baseUrl; ?>/telecmi_api.php?action=sdk_token</code></td>
        </tr>
        <tr>
            <td>Click-to-Call</td>
            <td><code><?php echo $baseUrl; ?>/telecmi_api.php?action=click_to_call</code></td>
        </tr>
        <tr>
            <td>Webhook</td>
            <td><code><?php echo $baseUrl; ?>/telecmi_api.php?action=webhook</code></td>
        </tr>
    </table>
    
    <!-- Actions -->
    <h2>Quick Actions</h2>
    
    <div style="margin: 20px 0;">
        <?php if ($allOk): ?>
            <a href="test_telecmi_live.php" class="btn btn-success">🔴 Test Live Connection</a>
            <a href="telecmi_demo.html" class="btn btn-success">📞 Try Interactive Demo</a>
        <?php else: ?>
            <?php if (!$providerOk && $dbOk): ?>
                <a href="setup_telecmi_table.php?view=1" class="btn">Fix Database</a>
            <?php endif; ?>
            <a href="telecmi_setup_wizard.php" class="btn">Run Setup Wizard</a>
            <a href="verify_telecmi_setup.php" class="btn">Detailed Verification</a>
        <?php endif; ?>
        
        <a href="debug_env.php" class="btn">Debug Environment</a>
    </div>
    
    <!-- Documentation -->
    <h2>Documentation</h2>
    <p>
        <a href="../TELECMI_API_SETUP.md" class="btn">📚 Complete Documentation</a>
        <a href="../TELECMI_QUICK_START.md" class="btn">⚡ Quick Start Guide</a>
        <a href="../START_HERE.md" class="btn">🚀 Getting Started</a>
    </p>
    
    <hr style="margin: 30px 0;">
    <p style="text-align: center; color: #666;">
        Last checked: <?php echo date('Y-m-d H:i:s'); ?> | 
        <a href="?refresh=1" style="color: #667eea;">Refresh Status</a>
    </p>
</div>
</body>
</html>
<?php
$conn->close();
?>
