<?php
/**
 * Test script to verify transporter recording upload setup
 */

require_once 'config.php';

echo "<h2>Transporter Recording Upload Test</h2>";

// 1. Check document root
echo "<h3>1. Server Paths</h3>";
echo "Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "<br>";
$uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/transporter/';
echo "Upload Directory: " . $uploadDir . "<br>";
echo "Directory Exists: " . (file_exists($uploadDir) ? 'YES' : 'NO') . "<br>";
echo "Directory Writable: " . (is_writable($uploadDir) ? 'YES' : 'NO') . "<br>";

// 2. Try to create directory if it doesn't exist
if (!file_exists($uploadDir)) {
    echo "<br><strong>Attempting to create directory...</strong><br>";
    if (mkdir($uploadDir, 0755, true)) {
        echo "✓ Directory created successfully<br>";
    } else {
        echo "✗ Failed to create directory<br>";
    }
}

// 3. Check database table structure
echo "<h3>2. Database Table Structure</h3>";
$query = "SHOW COLUMNS FROM job_brief_table LIKE 'call_recording'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ call_recording column exists in job_brief_table<br>";
    $row = $result->fetch_assoc();
    echo "Column Type: " . $row['Type'] . "<br>";
} else {
    echo "✗ call_recording column NOT found in job_brief_table<br>";
}

// 4. Check for recent job briefs
echo "<h3>3. Recent Job Briefs</h3>";
$query = "SELECT id, unique_id, job_id, created_at, call_recording 
          FROM job_brief_table 
          ORDER BY created_at DESC 
          LIMIT 5";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Transporter TMID</th><th>Job ID</th><th>Created At</th><th>Recording</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['unique_id'] . "</td>";
        echo "<td>" . $row['job_id'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td>" . ($row['call_recording'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No job briefs found<br>";
}

// 5. List existing recording files
echo "<h3>4. Existing Recording Files</h3>";
if (file_exists($uploadDir)) {
    $files = scandir($uploadDir);
    $recordingFiles = array_filter($files, function($file) {
        return !in_array($file, ['.', '..']);
    });
    
    if (count($recordingFiles) > 0) {
        echo "<ul>";
        foreach ($recordingFiles as $file) {
            $filePath = $uploadDir . $file;
            $fileSize = filesize($filePath);
            echo "<li>$file (" . number_format($fileSize) . " bytes)</li>";
        }
        echo "</ul>";
    } else {
        echo "No recording files found in directory<br>";
    }
} else {
    echo "Upload directory does not exist<br>";
}

// 6. Test file write permissions
echo "<h3>5. Write Permission Test</h3>";
if (file_exists($uploadDir)) {
    $testFile = $uploadDir . 'test_' . time() . '.txt';
    if (file_put_contents($testFile, 'test')) {
        echo "✓ Successfully wrote test file<br>";
        unlink($testFile);
        echo "✓ Successfully deleted test file<br>";
    } else {
        echo "✗ Failed to write test file<br>";
    }
} else {
    echo "Cannot test - directory doesn't exist<br>";
}

// 7. Check debug log
echo "<h3>6. Debug Log</h3>";
$logFile = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/transporter_upload_debug.log';
echo "Log File: $logFile<br>";
if (file_exists($logFile)) {
    echo "✓ Log file exists<br>";
    echo "<strong>Last 50 lines:</strong><br>";
    echo "<pre style='background: #f5f5f5; padding: 10px; max-height: 400px; overflow: auto;'>";
    $lines = file($logFile);
    $lastLines = array_slice($lines, -50);
    echo htmlspecialchars(implode('', $lastLines));
    echo "</pre>";
} else {
    echo "No log file found yet (will be created on first upload attempt)<br>";
}

?>
