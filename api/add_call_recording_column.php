<?php
/**
 * Add call_recording column to call_logs_match_making table if it doesn't exist
 */

require_once 'config.php';

echo "<h2>Adding call_recording Column</h2>";

// Check if column exists
$checkQuery = "SHOW COLUMNS FROM call_logs_match_making LIKE 'call_recording'";
$result = $conn->query($checkQuery);

if ($result && $result->num_rows > 0) {
    echo "✓ call_recording column already exists<br>";
} else {
    echo "Column doesn't exist. Adding it now...<br>";
    
    $alterQuery = "ALTER TABLE call_logs_match_making 
                   ADD COLUMN call_recording VARCHAR(500) NULL 
                   AFTER notes";
    
    if ($conn->query($alterQuery)) {
        echo "✓ Successfully added call_recording column<br>";
    } else {
        echo "✗ Error adding column: " . $conn->error . "<br>";
    }
}

// Show table structure
echo "<h3>Current Table Structure:</h3>";
$structureQuery = "DESCRIBE call_logs_match_making";
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

?>
