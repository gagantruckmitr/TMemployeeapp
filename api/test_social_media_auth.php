<?php
/**
 * Test Social Media Authentication
 * Tests if authentication is working correctly for social media endpoints
 */

header('Content-Type: application/json');

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Database connection failed: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
    echo "<h1>Social Media Authentication Test</h1>";
    
    // Test 1: Check admin table structure
    echo "<h2>Test 1: Admin Table Structure</h2>";
    $result = $conn->query("SHOW COLUMNS FROM admin LIKE 'tc_for'");
    if ($result && $result->num_rows > 0) {
        echo "<p style='color: green;'>✓ Column 'tc_for' exists in admin table</p>";
    } else {
        echo "<p style='color: red;'>✗ Column 'tc_for' NOT found in admin table</p>";
    }
    
    // Test 2: List all users with tc_for = 'social-media'
    echo "<h2>Test 2: Users with Social Media Access</h2>";
    $result = $conn->query("SELECT id, name, mobile, tc_for FROM admin WHERE LOWER(tc_for) = 'social-media'");
    if ($result && $result->num_rows > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>tc_for</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['name']}</td>";
            echo "<td>{$row['mobile']}</td>";
            echo "<td>{$row['tc_for']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color: orange;'>⚠ No users found with tc_for = 'social-media'</p>";
    }
    
    // Test 3: List all users with other tc_for values
    echo "<h2>Test 3: Users with Other Access</h2>";
    $result = $conn->query("SELECT id, name, mobile, tc_for FROM admin WHERE LOWER(tc_for) != 'social-media' LIMIT 10");
    if ($result && $result->num_rows > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>tc_for</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['name']}</td>";
            echo "<td>{$row['mobile']}</td>";
            echo "<td>{$row['tc_for']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No other users found</p>";
    }
    
    // Test 4: Test API authentication with a social-media user
    echo "<h2>Test 4: API Authentication Test</h2>";
    $result = $conn->query("SELECT id FROM admin WHERE LOWER(tc_for) = 'social-media' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $testUserId = $row['id'];
        echo "<p>Testing with user ID: <strong>$testUserId</strong></p>";
        echo "<p>Test URL: <a href='social-media-leads.php?action=get_social_media_leads&user_id=$testUserId' target='_blank'>Click to test API</a></p>";
    } else {
        echo "<p style='color: orange;'>⚠ Cannot test - no social-media users found</p>";
    }
    
    // Test 5: Test API authentication with a non-social-media user
    $result = $conn->query("SELECT id FROM admin WHERE LOWER(tc_for) != 'social-media' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $testUserId = $row['id'];
        echo "<p>Testing with non-social-media user ID: <strong>$testUserId</strong> (should be denied)</p>";
        echo "<p>Test URL: <a href='social-media-leads.php?action=get_social_media_leads&user_id=$testUserId' target='_blank'>Click to test API (should fail)</a></p>";
    }
    
    $conn->close();
    
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}
?>
