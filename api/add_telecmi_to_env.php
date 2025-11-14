<?php
/**
 * Add TeleCMI Configuration to .env file
 * This script will append TeleCMI variables to your .env file
 */

echo "<h1>Add TeleCMI to .env File</h1>";
echo "<hr>";

// Find .env file
$possiblePaths = [
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
    dirname(dirname(__DIR__)) . '/.env',
    $_SERVER['DOCUMENT_ROOT'] . '/../.env',
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
    die("<p style='color:red;'>❌ .env file not found!</p>");
}

echo "<p><strong>.env file found:</strong> <code>" . htmlspecialchars($envFile) . "</code></p>";

// Check if TeleCMI variables already exist
$content = file_get_contents($envFile);

if (strpos($content, 'TELECMI_APP_ID') !== false) {
    echo "<div style='background:#fff3cd; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#856404;'><strong>⚠️ TeleCMI variables already exist in .env file!</strong></p>";
    echo "<p>If you want to update them, please edit the .env file manually or delete the existing TELECMI lines first.</p>";
    echo "</div>";
    
    echo "<h3>Current TeleCMI Configuration:</h3>";
    $lines = explode("\n", $content);
    echo "<pre>";
    foreach ($lines as $line) {
        if (strpos($line, 'TELECMI') !== false) {
            echo htmlspecialchars($line) . "\n";
        }
    }
    echo "</pre>";
    
    echo "<p><a href='verify_telecmi_setup.php' style='display:inline-block; padding:10px 20px; background:#667eea; color:white; text-decoration:none; border-radius:5px;'>Verify Setup</a></p>";
    exit;
}

// TeleCMI configuration to add
$telecmiConfig = "

# MyOperator IVR Configuration for Voice Calling
# Get these from your MyOperator dashboard: https://myoperator.com
# Click-to-Call API connects telecaller and driver for two-way voice conversation
MYOPERATOR_COMPANY_ID=5edf736f7308d685
MYOPERATOR_SECRET_TOKEN=b177cf304671763bc77c35bdb0856de043702253c4967b7b145a34ca0d592ced
MYOPERATOR_IVR_ID=656db25ba652e270
MYOPERATOR_API_KEY=oomfKA3I2K6TCJYistHyb7sDf0l0F6c8AZro5DJh
MYOPERATOR_CALLER_ID=911234567890
MYOPERATOR_API_URL=https://obd-api.myoperator.co/obd-api-v1

# TeleCMI IVR Configuration for Voice Calling
# Get these from your TeleCMI dashboard: https://piopiy.telecmi.com
# SDK token for WebRTC calling and Click-to-Call API
TELECMI_APP_ID=33336628
TELECMI_APP_SECRET=a7003cba-292c-4853-9792-66fe0f31270f
TELECMI_SDK_BASE=https://piopiy.telecmi.com/v1/agentLogin
TELECMI_REST_BASE=https://rest.telecmi.com/v2/click2call
TELECMI_ACCESS_TOKEN=
";

// Check if file is writable
if (!is_writable($envFile)) {
    echo "<div style='background:#f8d7da; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#721c24;'><strong>❌ .env file is not writable!</strong></p>";
    echo "<p>Please run this command on your server:</p>";
    echo "<pre>chmod 644 " . htmlspecialchars($envFile) . "</pre>";
    echo "<p>Or add the following lines manually to your .env file:</p>";
    echo "<pre>" . htmlspecialchars($telecmiConfig) . "</pre>";
    echo "</div>";
    exit;
}

// Backup the original file
$backupFile = $envFile . '.backup.' . date('Y-m-d_H-i-s');
if (copy($envFile, $backupFile)) {
    echo "<div style='background:#d1ecf1; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#0c5460;'>✅ Backup created: <code>" . htmlspecialchars($backupFile) . "</code></p>";
    echo "</div>";
}

// Append TeleCMI configuration
if (file_put_contents($envFile, $telecmiConfig, FILE_APPEND)) {
    echo "<div style='background:#d4edda; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#155724;'><strong>✅ TeleCMI configuration added successfully!</strong></p>";
    echo "</div>";
    
    echo "<h3>Added Configuration:</h3>";
    echo "<pre>" . htmlspecialchars($telecmiConfig) . "</pre>";
    
    echo "<h3>Next Steps:</h3>";
    echo "<ol>";
    echo "<li><a href='verify_telecmi_setup.php'>Verify Setup</a> - Check if everything is configured correctly</li>";
    echo "<li><a href='test_telecmi_live.php'>Test Live Connection</a> - Test connection to TeleCMI servers</li>";
    echo "<li><a href='telecmi_demo.html'>Try Interactive Demo</a> - Test SDK token and calling</li>";
    echo "</ol>";
    
} else {
    echo "<div style='background:#f8d7da; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#721c24;'><strong>❌ Failed to write to .env file!</strong></p>";
    echo "<p>Please add the following lines manually to your .env file:</p>";
    echo "<pre>" . htmlspecialchars($telecmiConfig) . "</pre>";
    echo "</div>";
}
