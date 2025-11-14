<?php
/**
 * Test subscription date in jobs API
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

echo "<h2>Testing Subscription Date in Jobs API</h2>";

// Test 1: Check if users table has created_at
echo "<h3>Test 1: Check users table structure</h3>";
$query = "SHOW COLUMNS FROM users LIKE 'created_at'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ users.created_at column exists<br>";
    $row = $result->fetch_assoc();
    echo "Type: " . $row['Type'] . "<br>";
} else {
    echo "✗ users.created_at column NOT found<br>";
}

// Test 2: Get sample transporter with created_at
echo "<h3>Test 2: Sample transporter data</h3>";
$query = "SELECT id, name, unique_id, created_at FROM users WHERE role = 'transporter' LIMIT 1";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "Transporter: " . $user['name'] . "<br>";
    echo "TMID: " . $user['unique_id'] . "<br>";
    echo "Created At: " . $user['created_at'] . "<br>";
    
    // Calculate subscription duration
    if (!empty($user['created_at'])) {
        $createdDate = new DateTime($user['created_at']);
        $now = new DateTime();
        $diff = $now->diff($createdDate);
        
        if ($diff->y > 0) {
            $duration = $diff->y . " year" . ($diff->y > 1 ? "s" : "");
        } elseif ($diff->m > 0) {
            $duration = $diff->m . " month" . ($diff->m > 1 ? "s" : "");
        } elseif ($diff->d > 0) {
            $duration = $diff->d . " day" . ($diff->d > 1 ? "s" : "");
        } else {
            $duration = "Today";
        }
        
        echo "Subscription Duration: " . $duration . "<br>";
    }
} else {
    echo "No transporter found<br>";
}

// Test 3: Test jobs API response format
echo "<h3>Test 3: Jobs API with transporterCreatedAt</h3>";
$query = "SELECT j.*, u.created_at as transporter_created_at, u.name as transporter_name 
          FROM jobs j 
          LEFT JOIN users u ON j.transporter_id = u.id 
          WHERE j.assigned_to IS NOT NULL 
          LIMIT 1";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $job = $result->fetch_assoc();
    echo "Job ID: " . $job['job_id'] . "<br>";
    echo "Transporter: " . $job['transporter_name'] . "<br>";
    echo "Transporter Created At: " . ($job['transporter_created_at'] ?? 'NULL') . "<br>";
    echo "✓ transporterCreatedAt field available<br>";
} else {
    echo "No jobs found<br>";
}

$conn->close();
?>
