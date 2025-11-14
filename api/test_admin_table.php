<?php
require_once 'config.php';

echo "<h2>Testing Admins Table</h2>";

// Test 1: Check if admins table exists
echo "<h3>1. Checking admins table...</h3>";
$result = $conn->query("SHOW TABLES LIKE 'admins'");
if ($result && $result->num_rows > 0) {
    echo "✅ Admins table exists<br><br>";
} else {
    echo "❌ Admins table does not exist<br><br>";
    die();
}

// Test 2: Show table structure
echo "<h3>2. Admins table structure:</h3>";
$result = $conn->query("DESCRIBE admins");
if ($result) {
    echo "<table border='1' cellpadding='5'><tr><th>Field</th><th>Type</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td></tr>";
    }
    echo "</table><br>";
} else {
    echo "Error: " . $conn->error . "<br><br>";
}

// Test 3: Count all admin records
echo "<h3>3. Total admin records:</h3>";
$result = $conn->query("SELECT COUNT(*) as total FROM admins");
if ($result) {
    $row = $result->fetch_assoc();
    echo "Total: " . $row['total'] . "<br><br>";
} else {
    echo "Error: " . $conn->error . "<br><br>";
}

// Test 4: Show all admin users
echo "<h3>4. All admin users:</h3>";
$result = $conn->query("SELECT id, name, role, tc_for FROM admins LIMIT 20");
if ($result) {
    if ($result->num_rows > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Name</th><th>Role</th><th>TC For</th></tr>";
        while ($row = $result->fetch_assoc()) {
            $tcFor = $row['tc_for'] ?? 'NULL';
            echo "<tr><td>{$row['id']}</td><td>" . htmlspecialchars($row['name']) . "</td><td>{$row['role']}</td><td>{$tcFor}</td></tr>";
        }
        echo "</table><br>";
    } else {
        echo "No records found<br><br>";
    }
} else {
    echo "Error: " . $conn->error . "<br><br>";
}

// Test 5: Find suitable users for callback API
echo "<h3>5. Users suitable for callback API:</h3>";
$result = $conn->query("SELECT id, name, role, tc_for FROM admins WHERE role IN ('admin', 'manager') OR (role = 'telecaller' AND tc_for = 'call-back')");
if ($result) {
    if ($result->num_rows > 0) {
        echo "✅ Found " . $result->num_rows . " suitable users:<br>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Name</th><th>Role</th><th>TC For</th><th>Test Link</th></tr>";
        while ($row = $result->fetch_assoc()) {
            $tcFor = $row['tc_for'] ?? 'NULL';
            $testUrl = "callback_requests_api.php?action=index&auth_admin_id={$row['id']}";
            echo "<tr><td>{$row['id']}</td><td>" . htmlspecialchars($row['name']) . "</td><td>{$row['role']}</td><td>{$tcFor}</td>";
            echo "<td><a href='{$testUrl}' target='_blank'>Test</a></td></tr>";
        }
        echo "</table>";
    } else {
        echo "❌ No suitable users found<br>";
    }
} else {
    echo "Error: " . $conn->error . "<br>";
}

$conn->close();
?>
