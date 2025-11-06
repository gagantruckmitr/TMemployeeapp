<?php
/**
 * Test script to verify recording upload setup
 */

require_once 'config.php';

echo "<h2>Recording Upload Test</h2>";

// 1. Check document root
echo "<h3>1. Server Paths</h3>";
echo "Document Root: " . $_SERVER['DOCUMENT_ROOT'] . "<br>";
$uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/driver/';
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
$query = "SHOW COLUMNS FROM call_logs_match_making LIKE 'call_recording'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ call_recording column exists<br>";
    $row = $result->fetch_assoc();
    echo "Column Type: " . $row['Type'] . "<br>";
} else {
    echo "✗ call_recording column NOT found<br>";
}

// 4. Check for recent call logs
echo "<h3>3. Recent Call Logs</h3>";
$query = "SELECT id, unique_id_driver, caller_id, created_at, call_recording 
          FROM call_logs_match_making 
          ORDER BY created_at DESC 
          LIMIT 5";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Driver TMID</th><th>Caller ID</th><th>Created At</th><th>Recording</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['unique_id_driver'] . "</td>";
        echo "<td>" . $row['caller_id'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td>" . ($row['call_recording'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No call logs found<br>";
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

?>
