<?php
/**
 * Test Time Insert - Diagnose timezone issues
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Time Insert Test</h1>";
echo "<hr>";

// Show current times
echo "<h2>Current Time Information</h2>";
echo "<p><strong>PHP date():</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>PHP timezone:</strong> " . date_default_timezone_get() . "</p>";
echo "<p><strong>PHP time():</strong> " . time() . "</p>";
echo "<hr>";

// Check MySQL timezone
$result = $conn->query("SELECT NOW() as now, @@session.time_zone as session_tz, @@global.time_zone as global_tz");
$row = $result->fetch_assoc();
echo "<h2>MySQL Time Information</h2>";
echo "<p><strong>MySQL NOW():</strong> " . $row['now'] . "</p>";
echo "<p><strong>Session timezone:</strong> " . $row['session_tz'] . "</p>";
echo "<p><strong>Global timezone:</strong> " . $row['global_tz'] . "</p>";
echo "<hr>";

// Test insert into call_logs_match_making
echo "<h2>Test Insert</h2>";

$testData = [
    'caller_id' => 999,
    'unique_id_transporter' => 'TEST123',
    'unique_id_driver' => 'TEST456',
    'driver_name' => 'Test Driver',
    'transporter_name' => 'Test Transporter',
    'feedback' => 'Test Feedback',
    'job_id' => 'TESTJOB001'
];

$insertQuery = "INSERT INTO call_logs_match_making 
    (caller_id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, feedback, job_id, created_at, updated_at)
    VALUES 
    ({$testData['caller_id']}, '{$testData['unique_id_transporter']}', '{$testData['unique_id_driver']}', 
     '{$testData['driver_name']}', '{$testData['transporter_name']}', '{$testData['feedback']}', 
     '{$testData['job_id']}', NOW(), NOW())";

echo "<p><strong>Insert Query:</strong></p>";
echo "<pre>" . htmlspecialchars($insertQuery) . "</pre>";

if ($conn->query($insertQuery)) {
    $insertId = $conn->insert_id;
    echo "<p style='color: green;'><strong>✓ Insert successful! ID: $insertId</strong></p>";
    
    // Read back the inserted record
    $selectQuery = "SELECT * FROM call_logs_match_making WHERE id = $insertId";
    $result = $conn->query($selectQuery);
    $inserted = $result->fetch_assoc();
    
    echo "<h3>Inserted Record:</h3>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Field</th><th>Value</th></tr>";
    echo "<tr><td>ID</td><td>" . $inserted['id'] . "</td></tr>";
    echo "<tr><td>created_at</td><td style='font-weight: bold; color: blue;'>" . $inserted['created_at'] . "</td></tr>";
    echo "<tr><td>updated_at</td><td style='font-weight: bold; color: blue;'>" . $inserted['updated_at'] . "</td></tr>";
    echo "</table>";
    
    // Compare times
    echo "<h3>Time Comparison:</h3>";
    $phpTime = date('Y-m-d H:i:s');
    $dbTime = $inserted['created_at'];
    $phpTimestamp = strtotime($phpTime);
    $dbTimestamp = strtotime($dbTime);
    $diff = $phpTimestamp - $dbTimestamp;
    $diffHours = round($diff / 3600, 2);
    
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Source</th><th>Time</th></tr>";
    echo "<tr><td>PHP (Expected IST)</td><td>" . $phpTime . "</td></tr>";
    echo "<tr><td>Database (Actual)</td><td>" . $dbTime . "</td></tr>";
    echo "<tr><td>Difference</td><td style='color: " . ($diff > 0 ? 'red' : 'green') . ";'>" . $diffHours . " hours</td></tr>";
    echo "</table>";
    
    if (abs($diff) > 300) { // More than 5 minutes difference
        echo "<p style='color: red;'><strong>⚠️ WARNING: Significant time difference detected!</strong></p>";
        echo "<p>The database is inserting times that are $diffHours hours different from PHP time.</p>";
        
        if ($diffHours < -5) {
            echo "<p><strong>Issue:</strong> Database time is behind PHP time by ~" . abs($diffHours) . " hours.</p>";
            echo "<p><strong>Likely cause:</strong> MySQL timezone is not set to IST (+05:30)</p>";
            echo "<p><strong>Solution:</strong> The SET time_zone command in config.php may not be working.</p>";
        }
    } else {
        echo "<p style='color: green;'><strong>✓ Times match! Timezone is configured correctly.</strong></p>";
    }
    
    // Clean up test record
    echo "<hr>";
    echo "<p><a href='?cleanup=$insertId' style='background: orange; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Delete Test Record</a></p>";
    
} else {
    echo "<p style='color: red;'><strong>✗ Insert failed:</strong> " . $conn->error . "</p>";
}

// Handle cleanup
if (isset($_GET['cleanup'])) {
    $cleanupId = (int)$_GET['cleanup'];
    if ($conn->query("DELETE FROM call_logs_match_making WHERE id = $cleanupId")) {
        echo "<p style='color: green;'><strong>✓ Test record deleted</strong></p>";
        echo "<p><a href='test_insert_time.php'>Run test again</a></p>";
    }
}

echo "<hr>";
echo "<p><em>Generated at: " . date('Y-m-d H:i:s') . " IST</em></p>";
?>
