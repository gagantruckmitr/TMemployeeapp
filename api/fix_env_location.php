<?php
/**
 * Fix .env File Location - Copy TeleCMI config to the correct .env
 */

echo "<h1>Fix .env File Location</h1>";
echo "<hr>";

// Find all .env files
$possiblePaths = [
    '/var/www/vhosts/truckmitr.com/httpdocs/.env',
    '/var/www/vhosts/truckmitr.com/httpdocs/truckmitr-app/.env',
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
];

echo "<h2>Found .env Files:</h2>";
echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Path</th><th>Exists</th><th>Has TeleCMI</th><th>Lines</th></tr>";

$envFiles = [];
foreach ($possiblePaths as $path) {
    if (file_exists($path)) {
        $content = file_get_contents($path);
        $hasTelecmi = strpos($content, 'TELECMI_APP_ID') !== false;
        $lines = count(file($path));
        
        echo "<tr>";
        echo "<td><code>" . htmlspecialchars($path) . "</code></td>";
        echo "<td style='color:green;'>✅ Yes</td>";
        echo "<td>" . ($hasTelecmi ? "<strong style='color:green;'>✅ Yes</strong>" : "<span style='color:red;'>❌ No</span>") . "</td>";
        echo "<td>$lines lines</td>";
        echo "</tr>";
        
        $envFiles[$path] = [
            'content' => $content,
            'has_telecmi' => $hasTelecmi,
            'lines' => $lines
        ];
    }
}
echo "</table>";

// Find source (has TeleCMI) and target (doesn't have TeleCMI)
$sourceFile = null;
$targetFile = '/var/www/vhosts/truckmitr.com/httpdocs/.env'; // This is the one being used

foreach ($envFiles as $path => $info) {
    if ($info['has_telecmi']) {
        $sourceFile = $path;
        break;
    }
}

if (!$sourceFile) {
    echo "<div style='background:#f8d7da; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#721c24;'><strong>❌ No .env file with TeleCMI config found!</strong></p>";
    echo "<p>Please add TeleCMI configuration manually to: <code>$targetFile</code></p>";
    echo "</div>";
    
    echo "<h3>Add these lines to your .env:</h3>";
    echo "<pre>
# TeleCMI IVR Configuration for Voice Calling
TELECMI_APP_ID=33336628
TELECMI_APP_SECRET=a7003cba-292c-4853-9792-66fe0f31270f
TELECMI_SDK_BASE=https://piopiy.telecmi.com/v1/agentLogin
TELECMI_REST_BASE=https://rest.telecmi.com/v2/click2call
TELECMI_ACCESS_TOKEN=
</pre>";
    exit;
}

echo "<hr>";
echo "<h2>Action Plan:</h2>";
echo "<p><strong>Source:</strong> <code>" . htmlspecialchars($sourceFile) . "</code> (has TeleCMI config)</p>";
echo "<p><strong>Target:</strong> <code>" . htmlspecialchars($targetFile) . "</code> (needs TeleCMI config)</p>";

// Check if target already has TeleCMI
if (isset($envFiles[$targetFile]) && $envFiles[$targetFile]['has_telecmi']) {
    echo "<div style='background:#d4edda; padding:15px; border-radius:5px; margin:20px 0;'>";
    echo "<p style='color:#155724;'><strong>✅ Target file already has TeleCMI configuration!</strong></p>";
    echo "</div>";
    echo "<p><a href='verify_telecmi_setup.php' style='display:inline-block; padding:10px 20px; background:#667eea; color:white; text-decoration:none; border-radius:5px;'>Verify Setup</a></p>";
    exit;
}

// Extract TeleCMI config from source
$sourceContent = file_get_contents($sourceFile);
$lines = explode("\n", $sourceContent);
$telecmiConfig = "";
$inTelecmiSection = false;

foreach ($lines as $line) {
    if (strpos($line, '# TeleCMI') !== false || strpos($line, '# MyOperator') !== false) {
        $inTelecmiSection = true;
    }
    
    if ($inTelecmiSection) {
        $telecmiConfig .= $line . "\n";
    }
    
    // Stop at next major section or end
    if ($inTelecmiSection && trim($line) === '' && strlen($telecmiConfig) > 100) {
        break;
    }
}

echo "<h3>Configuration to Add:</h3>";
echo "<pre>" . htmlspecialchars($telecmiConfig) . "</pre>";

if (isset($_POST['copy_config'])) {
    // Check if target is writable
    if (!is_writable($targetFile)) {
        echo "<div style='background:#f8d7da; padding:15px; border-radius:5px; margin:20px 0;'>";
        echo "<p style='color:#721c24;'><strong>❌ Target file is not writable!</strong></p>";
        echo "<p>Run this command: <code>chmod 644 $targetFile</code></p>";
        echo "</div>";
        exit;
    }
    
    // Backup target file
    $backupFile = $targetFile . '.backup.' . date('Y-m-d_H-i-s');
    copy($targetFile, $backupFile);
    echo "<div style='background:#d1ecf1; padding:15px; border-radius:5px; margin:10px 0;'>";
    echo "<p style='color:#0c5460;'>✅ Backup created: <code>$backupFile</code></p>";
    echo "</div>";
    
    // Append TeleCMI config
    if (file_put_contents($targetFile, "\n" . $telecmiConfig, FILE_APPEND)) {
        echo "<div style='background:#d4edda; padding:15px; border-radius:5px; margin:20px 0;'>";
        echo "<p style='color:#155724;'><strong>✅ TeleCMI configuration copied successfully!</strong></p>";
        echo "</div>";
        
        echo "<h3>Next Steps:</h3>";
        echo "<ol>";
        echo "<li><a href='verify_telecmi_setup.php'>Verify Setup</a></li>";
        echo "<li><a href='test_telecmi_live.php'>Test Live Connection</a></li>";
        echo "<li><a href='telecmi_demo.html'>Try Interactive Demo</a></li>";
        echo "</ol>";
    } else {
        echo "<div style='background:#f8d7da; padding:15px; border-radius:5px; margin:20px 0;'>";
        echo "<p style='color:#721c24;'><strong>❌ Failed to write to target file!</strong></p>";
        echo "</div>";
    }
} else {
    echo "<form method='post'>";
    echo "<button type='submit' name='copy_config' style='padding:15px 30px; background:#667eea; color:white; border:none; border-radius:10px; font-size:16px; cursor:pointer; font-weight:600;'>Copy TeleCMI Config to Production .env</button>";
    echo "</form>";
}
