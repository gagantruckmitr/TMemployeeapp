<?php
/**
 * Setup TeleCMI call_logs table
 * Run this once to create the necessary database table
 */

require_once 'config.php';

echo "<h1>TeleCMI Database Setup</h1>";
echo "<hr>";

// Check if table exists
$result = $conn->query("SHOW TABLES LIKE 'call_logs'");

if ($result->num_rows > 0) {
    echo "<p style='color:orange;'>⚠️ Table 'call_logs' already exists.</p>";
    echo "<p>Do you want to view the structure? <a href='?view=1'>View Structure</a></p>";
    
    if (isset($_GET['view'])) {
        $result = $conn->query("DESCRIBE call_logs");
        echo "<h2>Current Table Structure:</h2>";
        echo "<table border='1' cellpadding='10'>";
        echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['Field']}</td>";
            echo "<td>{$row['Type']}</td>";
            echo "<td>{$row['Null']}</td>";
            echo "<td>{$row['Key']}</td>";
            echo "<td>" . ($row['Default'] ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        // Check if provider column exists
        $result = $conn->query("SHOW COLUMNS FROM call_logs LIKE 'provider'");
        if ($result->num_rows == 0) {
            echo "<p style='color:orange;'>⚠️ 'provider' column missing. Adding it...</p>";
            $conn->query("ALTER TABLE call_logs ADD COLUMN provider VARCHAR(50) DEFAULT 'telecmi' AFTER duration");
            echo "<p style='color:green;'>✅ 'provider' column added successfully!</p>";
        }
    }
} else {
    echo "<p>Creating 'call_logs' table...</p>";
    
    $sql = "CREATE TABLE IF NOT EXISTS call_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        call_id VARCHAR(255) UNIQUE,
        from_number VARCHAR(20),
        to_number VARCHAR(20),
        status VARCHAR(50),
        duration INT DEFAULT 0,
        provider VARCHAR(50) DEFAULT 'telecmi',
        initiated_at DATETIME,
        answered_at DATETIME NULL,
        ended_at DATETIME NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_call_id (call_id),
        INDEX idx_from_number (from_number),
        INDEX idx_to_number (to_number),
        INDEX idx_status (status),
        INDEX idx_provider (provider)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
    
    if ($conn->query($sql)) {
        echo "<p style='color:green;'>✅ Table 'call_logs' created successfully!</p>";
        
        // Show structure
        $result = $conn->query("DESCRIBE call_logs");
        echo "<h2>Table Structure:</h2>";
        echo "<table border='1' cellpadding='10'>";
        echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['Field']}</td>";
            echo "<td>{$row['Type']}</td>";
            echo "<td>{$row['Null']}</td>";
            echo "<td>{$row['Key']}</td>";
            echo "<td>" . ($row['Default'] ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color:red;'>❌ Error creating table: " . $conn->error . "</p>";
    }
}

echo "<hr>";
echo "<h2>Next Steps</h2>";
echo "<ul>";
echo "<li>✅ Database table is ready</li>";
echo "<li>Test the API: <a href='test_telecmi_api.php'>Run Tests</a></li>";
echo "<li>View documentation: <a href='../TELECMI_API_SETUP.md'>Setup Guide</a></li>";
echo "</ul>";

$conn->close();
