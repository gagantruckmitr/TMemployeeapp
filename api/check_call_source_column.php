<?php
/**
 * Check if call_source column exists in call_logs table
 */

require_once 'config.php';

echo "<h1>Call Source Column Check</h1>";

// Check if call_source column exists
$query = "SHOW COLUMNS FROM call_logs LIKE 'call_source'";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<p style='color: green;'>✅ <strong>call_source</strong> column EXISTS in call_logs table</p>";
    
    $column = $result->fetch_assoc();
    echo "<h3>Column Details:</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    echo "<tr>";
    echo "<td>{$column['Field']}</td>";
    echo "<td>{$column['Type']}</td>";
    echo "<td>{$column['Null']}</td>";
    echo "<td>{$column['Key']}</td>";
    echo "<td>" . ($column['Default'] ?? 'NULL') . "</td>";
    echo "<td>{$column['Extra']}</td>";
    echo "</tr>";
    echo "</table>";
} else {
    echo "<p style='color: red;'>❌ <strong>call_source</strong> column DOES NOT EXIST in call_logs table</p>";
    echo "<h3>Solution: Add the column</h3>";
    echo "<p>Run this SQL command:</p>";
    echo "<pre style='background: #f5f5f5; padding: 10px; border: 1px solid #ddd;'>";
    echo "ALTER TABLE call_logs ADD COLUMN call_source VARCHAR(50) NULL AFTER api_response;";
    echo "</pre>";
    
    echo "<h3>Or click the button below to add it automatically:</h3>";
    echo "<form method='post'>";
    echo "<button type='submit' name='add_column' style='padding: 10px 20px; background: #4CAF50; color: white; border: none; cursor: pointer; font-size: 16px;'>Add call_source Column</button>";
    echo "</form>";
    
    if (isset($_POST['add_column'])) {
        echo "<hr>";
        echo "<h3>Adding Column...</h3>";
        $alterQuery = "ALTER TABLE call_logs ADD COLUMN call_source VARCHAR(50) NULL AFTER api_response";
        if ($conn->query($alterQuery)) {
            echo "<p style='color: green;'>✅ Column added successfully!</p>";
            echo "<p><a href='check_call_source_column.php'>Refresh page</a></p>";
        } else {
            echo "<p style='color: red;'>❌ Failed to add column: " . $conn->error . "</p>";
        }
    }
}

// Show all columns in call_logs table
echo "<hr>";
echo "<h2>All Columns in call_logs Table</h2>";
$query = "SHOW COLUMNS FROM call_logs";
$result = $conn->query($query);

if ($result) {
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    
    while ($column = $result->fetch_assoc()) {
        $highlight = ($column['Field'] == 'call_source') ? "style='background: #ffffcc;'" : "";
        echo "<tr $highlight>";
        echo "<td><strong>{$column['Field']}</strong></td>";
        echo "<td>{$column['Type']}</td>";
        echo "<td>{$column['Null']}</td>";
        echo "<td>{$column['Key']}</td>";
        echo "<td>" . ($column['Default'] ?? 'NULL') . "</td>";
        echo "<td>{$column['Extra']}</td>";
        echo "</tr>";
    }
    
    echo "</table>";
}

$conn->close();
?>
