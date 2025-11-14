<?php
/**
 * Test payments table structure and data
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

echo "<h2>Testing Payments Table</h2>";

// Test 1: Check if payments table exists
echo "<h3>Test 1: Check payments table</h3>";
$query = "SHOW TABLES LIKE 'payments'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ payments table exists<br>";
} else {
    echo "✗ payments table NOT found<br>";
    exit;
}

// Test 2: Check table structure
echo "<h3>Test 2: Table structure</h3>";
$query = "DESCRIBE payments";
$result = $conn->query($query);
if ($result) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['Field'] . "</td>";
        echo "<td>" . $row['Type'] . "</td>";
        echo "<td>" . $row['Null'] . "</td>";
        echo "<td>" . $row['Key'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// Test 3: Check for TMID column
echo "<h3>Test 3: Check for TMID/unique_id column</h3>";
$query = "SHOW COLUMNS FROM payments WHERE Field LIKE '%unique%' OR Field LIKE '%tmid%' OR Field LIKE '%user%'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "Found columns:<br>";
    while ($row = $result->fetch_assoc()) {
        echo "- " . $row['Field'] . " (" . $row['Type'] . ")<br>";
    }
} else {
    echo "No TMID/unique_id column found<br>";
}

// Test 4: Sample data with captured status
echo "<h3>Test 4: Sample captured payments</h3>";
$query = "SELECT * FROM payments WHERE payment_status = 'captured' ORDER BY created_at DESC LIMIT 3";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    $first = true;
    while ($row = $result->fetch_assoc()) {
        if ($first) {
            echo "<tr>";
            foreach (array_keys($row) as $key) {
                echo "<th>$key</th>";
            }
            echo "</tr>";
            $first = false;
        }
        echo "<tr>";
        foreach ($row as $value) {
            echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
        }
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No captured payments found<br>";
}

// Test 5: Check if we can join with users table
echo "<h3>Test 5: Join payments with users</h3>";
$query = "SELECT 
            u.id, 
            u.unique_id as tmid, 
            u.name,
            p.payment_status,
            p.created_at as payment_date
          FROM users u
          LEFT JOIN payments p ON u.unique_id = p.unique_id
          WHERE p.payment_status = 'captured'
          LIMIT 3";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>User ID</th><th>TMID</th><th>Name</th><th>Payment Status</th><th>Payment Date</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['tmid'] . "</td>";
        echo "<td>" . $row['name'] . "</td>";
        echo "<td>" . $row['payment_status'] . "</td>";
        echo "<td>" . $row['payment_date'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "Could not join or no data found. Error: " . $conn->error . "<br>";
}

$conn->close();
?>
