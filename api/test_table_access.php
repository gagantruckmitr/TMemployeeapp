<?php
/**
 * Test Table Access
 */

ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

echo "<h1>Test Table Access</h1>";
echo "<hr>";

// Test 1: Can we query the table?
echo "<h2>Test 1: Query Table</h2>";
try {
    $result = $conn->query("SELECT COUNT(*) as count FROM call_logs");
    if ($result) {
        $row = $result->fetch_assoc();
        echo "<p style='color: green;'>✅ Table accessible. Total records: " . $row['count'] . "</p>";
    } else {
        echo "<p style='color: red;'>❌ Query failed: " . $conn->error . "</p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Exception: " . $e->getMessage() . "</p>";
}

// Test 2: Can we insert a minimal record?
echo "<hr>";
echo "<h2>Test 2: Minimal Insert</h2>";

$sql = "INSERT INTO call_logs (caller_id, user_id, user_number) VALUES (3, 99999, '+916394756798')";

if ($conn->query($sql)) {
    $insertId = $conn->insert_id;
    echo "<p style='color: green;'>✅ Minimal insert successful! ID: $insertId</p>";
    
    // Show the record
    $result = $conn->query("SELECT * FROM call_logs WHERE id = $insertId");
    if ($result) {
        $record = $result->fetch_assoc();
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Field</th><th>Value</th></tr>";
        foreach ($record as $key => $value) {
            echo "<tr><td>$key</td><td>" . htmlspecialchars($value ?? 'NULL') . "</td></tr>";
        }
        echo "</table>";
        
        // Clean up
        $conn->query("DELETE FROM call_logs WHERE id = $insertId");
        echo "<p><em>Test record deleted</em></p>";
    }
} else {
    echo "<p style='color: red;'>❌ Insert failed: " . $conn->error . "</p>";
}

echo "<hr>";
echo "<p>✅ Tests complete</p>";
?>
