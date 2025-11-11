<?php
/**
 * Test script to check driver recording upload setup
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h2>Driver Recording Upload Test</h2>";

// 1. Check directory
$uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/driver/';
echo "<h3>1. Directory Check</h3>";
echo "Path: $uploadDir<br>";
echo "Exists: " . (file_exists($uploadDir) ? '✓ YES' : '✗ NO') . "<br>";
echo "Writable: " . (is_writable($uploadDir) ? '✓ YES' : '✗ NO') . "<br>";
echo "Permissions: " . (file_exists($uploadDir) ? substr(sprintf('%o', fileperms($uploadDir)), -4) : 'N/A') . "<br>";

// 2. Check database table
echo "<h3>2. Database Table Check</h3>";
if ($conn) {
    $checkTable = "SHOW TABLES LIKE 'call_logs_match_making'";
    $result = $conn->query($checkTable);
    
    if ($result && $result->num_rows > 0) {
        echo "Table 'call_logs_match_making': ✓ EXISTS<br>";
        
        // Check for call_recording column
        $checkColumn = "SHOW COLUMNS FROM call_logs_match_making LIKE 'call_recording'";
        $colResult = $conn->query($checkColumn);
        
        if ($colResult && $colResult->num_rows > 0) {
            echo "Column 'call_recording': ✓ EXISTS<br>";
            
            // Show column details
            $colInfo = $colResult->fetch_assoc();
            echo "Type: " . $colInfo['Type'] . "<br>";
            echo "Null: " . $colInfo['Null'] . "<br>";
        } else {
            echo "Column 'call_recording': ✗ MISSING<br>";
            echo "<strong>ACTION NEEDED:</strong> Run this SQL:<br>";
            echo "<code>ALTER TABLE call_logs_match_making ADD COLUMN call_recording VARCHAR(500) NULL;</code><br>";
        }
        
        // Check sample data
        echo "<br><h4>Sample Records:</h4>";
        $sampleQuery = "SELECT id, unique_id_driver, caller_id, job_id, call_recording, created_at 
                        FROM call_logs_match_making 
                        ORDER BY created_at DESC 
                        LIMIT 5";
        $sampleResult = $conn->query($sampleQuery);
        
        if ($sampleResult && $sampleResult->num_rows > 0) {
            echo "<table border='1' cellpadding='5'>";
            echo "<tr><th>ID</th><th>Driver TMID</th><th>Caller ID</th><th>Job ID</th><th>Recording</th><th>Created</th></tr>";
            while ($row = $sampleResult->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row['id'] . "</td>";
                echo "<td>" . $row['unique_id_driver'] . "</td>";
                echo "<td>" . $row['caller_id'] . "</td>";
                echo "<td>" . $row['job_id'] . "</td>";
                echo "<td>" . ($row['call_recording'] ? '✓ Has URL' : '✗ No URL') . "</td>";
                echo "<td>" . $row['created_at'] . "</td>";
                echo "</tr>";
            }
            echo "</table>";
        } else {
            echo "No records found in table.<br>";
        }
        
    } else {
        echo "Table 'call_logs_match_making': ✗ MISSING<br>";
    }
} else {
    echo "Database connection: ✗ FAILED<br>";
}

// 3. Check log file
echo "<h3>3. Debug Log Check</h3>";
$logFile = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/upload_debug.log';
echo "Log file: $logFile<br>";
if (file_exists($logFile)) {
    echo "Exists: ✓ YES<br>";
    echo "Size: " . filesize($logFile) . " bytes<br>";
    echo "<br><h4>Last 20 lines:</h4>";
    echo "<pre style='background:#f5f5f5; padding:10px; overflow:auto; max-height:300px;'>";
    $lines = file($logFile);
    $lastLines = array_slice($lines, -20);
    echo htmlspecialchars(implode('', $lastLines));
    echo "</pre>";
} else {
    echo "Exists: ✗ NO (will be created on first upload)<br>";
}

// 4. PHP Upload Settings
echo "<h3>4. PHP Upload Settings</h3>";
echo "upload_max_filesize: " . ini_get('upload_max_filesize') . "<br>";
echo "post_max_size: " . ini_get('post_max_size') . "<br>";
echo "max_file_uploads: " . ini_get('max_file_uploads') . "<br>";
echo "file_uploads: " . (ini_get('file_uploads') ? 'Enabled' : 'Disabled') . "<br>";

echo "<hr>";
echo "<p><strong>Test completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
