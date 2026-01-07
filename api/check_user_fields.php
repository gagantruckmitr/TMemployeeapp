<?php
/**
 * Check actual field names in users table
 */

require_once 'config.php';

// Get table structure
$result = $conn->query("DESCRIBE users");

echo "<h2>Users Table Structure</h2>";
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>Field Name</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";

$fields = [];
while ($row = $result->fetch_assoc()) {
    $fields[] = $row['Field'];
    echo "<tr>";
    echo "<td><strong>{$row['Field']}</strong></td>";
    echo "<td>{$row['Type']}</td>";
    echo "<td>{$row['Null']}</td>";
    echo "<td>{$row['Key']}</td>";
    echo "<td>{$row['Default']}</td>";
    echo "</tr>";
}

echo "</table>";

echo "<h3>Field Names (for copy-paste):</h3>";
echo "<pre>";
print_r($fields);
echo "</pre>";

// Check a sample user
$stmt = $conn->prepare("SELECT * FROM users WHERE role = 'driver' LIMIT 1");
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if ($user) {
    echo "<h3>Sample Driver User Fields:</h3>";
    echo "<pre>";
    foreach ($user as $key => $val) {
        $displayVal = is_string($val) && strlen($val) > 50 ? substr($val, 0, 50) . '...' : $val;
        echo "$key => " . var_export($displayVal, true) . "\n";
    }
    echo "</pre>";
}

// Check a transporter
$stmt = $conn->prepare("SELECT * FROM users WHERE role = 'transporter' LIMIT 1");
$stmt->execute();
$transporter = $stmt->get_result()->fetch_assoc();

if ($transporter) {
    echo "<h3>Sample Transporter User Fields:</h3>";
    echo "<pre>";
    foreach ($transporter as $key => $val) {
        $displayVal = is_string($val) && strlen($val) > 50 ? substr($val, 0, 50) . '...' : $val;
        echo "$key => " . var_export($displayVal, true) . "\n";
    }
    echo "</pre>";
}
?>
