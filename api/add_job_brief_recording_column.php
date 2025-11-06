<?php
/**
 * Add call_recording column to job_brief table if it doesn't exist
 */

require_once 'config.php';

echo "<h2>Adding call_recording Column to job_brief_table</h2>";

// Check if column exists
$checkQuery = "SHOW COLUMNS FROM job_brief_table LIKE 'call_recording'";
$result = $conn->query($checkQuery);

if ($result && $result->num_rows > 0) {
    echo "✓ call_recording column already exists<br>";
} else {
    echo "Column doesn't exist. Adding it now...<br>";
    
    $alterQuery = "ALTER TABLE job_brief_table 
                   ADD COLUMN call_recording VARCHAR(500) NULL 
                   AFTER call_status_feedback";
    
    if ($conn->query($alterQuery)) {
        echo "✓ Successfully added call_recording column<br>";
    } else {
        echo "✗ Error adding column: " . $conn->error . "<br>";
    }
}

// Show table structure
echo "<h3>Current job_brief_table Structure:</h3>";
$structureQuery = "DESCRIBE job_brief_table";
$result = $conn->query($structureQuery);

if ($result) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['Field'] . "</td>";
        echo "<td>" . $row['Type'] . "</td>";
        echo "<td>" . $row['Null'] . "</td>";
        echo "<td>" . $row['Key'] . "</td>";
        echo "<td>" . ($row['Default'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// Create transporter recording directory
echo "<h3>Creating Transporter Recording Directory:</h3>";
$uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/transporter/';
echo "Directory: $uploadDir<br>";

if (!file_exists($uploadDir)) {
    if (mkdir($uploadDir, 0755, true)) {
        echo "✓ Directory created successfully<br>";
    } else {
        echo "✗ Failed to create directory<br>";
    }
} else {
    echo "✓ Directory already exists<br>";
}

echo "Directory Writable: " . (is_writable($uploadDir) ? 'YES' : 'NO') . "<br>";

?>
