<?php
/**
 * Check Call Logs Table Structure
 */

require_once 'config.php';

echo "<h1>Call Logs Table Structure</h1>";
echo "<hr>";

// Get table structure
$result = $conn->query("DESCRIBE call_logs");

if ($result) {
    echo "<h2>Table Columns:</h2>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th>";
    echo "</tr>";
    
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td><strong>" . $row['Field'] . "</strong></td>";
        echo "<td>" . $row['Type'] . "</td>";
        echo "<td>" . $row['Null'] . "</td>";
        echo "<td>" . $row['Key'] . "</td>";
        echo "<td>" . ($row['Default'] ?? 'NULL') . "</td>";
        echo "<td>" . $row['Extra'] . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<p style='color: red;'>Error: " . $conn->error . "</p>";
}

// Get sample data
echo "<hr>";
echo "<h2>Sample Data (Last 5 Records):</h2>";

$result2 = $conn->query("SELECT * FROM call_logs ORDER BY created_at DESC LIMIT 5");

if ($result2 && $result2->num_rows > 0) {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse; font-size: 12px;'>";
    
    // Get column names
    $fields = $result2->fetch_fields();
    echo "<tr style='background: #f0f0f0;'>";
    foreach ($fields as $field) {
        echo "<th>" . $field->name . "</th>";
    }
    echo "</tr>";
    
    // Show data
    while ($row = $result2->fetch_assoc()) {
        echo "<tr>";
        foreach ($row as $value) {
            echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
        }
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<p>No data found or error: " . $conn->error . "</p>";
}

// Show indexes
echo "<hr>";
echo "<h2>Table Indexes:</h2>";

$result3 = $conn->query("SHOW INDEX FROM call_logs");

if ($result3) {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>Key Name</th><th>Column</th><th>Unique</th><th>Type</th>";
    echo "</tr>";
    
    while ($row = $result3->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['Key_name'] . "</td>";
        echo "<td>" . $row['Column_name'] . "</td>";
        echo "<td>" . ($row['Non_unique'] == 0 ? 'Yes' : 'No') . "</td>";
        echo "<td>" . $row['Index_type'] . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
}

echo "<hr>";
echo "<p><strong>✅ Structure check complete!</strong></p>";
?>
