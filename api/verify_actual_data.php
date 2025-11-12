<?php
/**
 * Verify Actual Data in Database
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Verify Actual Database Data</h1>";
echo "<hr>";

// Check call_logs_match_making
$query1 = "SELECT id, driver_name, created_at, updated_at, 
          UNIX_TIMESTAMP(created_at) as unix_created
          FROM call_logs_match_making 
          ORDER BY id DESC 
          LIMIT 10";

$result1 = $conn->query($query1);

echo "<h2>Latest 10 Records from call_logs_match_making</h2>";
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>ID</th><th>Name</th><th>created_at (String)</th><th>UNIX Timestamp</th><th>Converted to IST</th></tr>";

while ($row = $result1->fetch_assoc()) {
    $createdStr = $row['created_at'];
    $unixTime = $row['unix_created'];
    $istTime = date('Y-m-d H:i:s', $unixTime);
    
    echo "<tr>";
    echo "<td>" . $row['id'] . "</td>";
    echo "<td>" . htmlspecialchars($row['driver_name'] ?? 'N/A') . "</td>";
    echo "<td><strong>" . $createdStr . "</strong></td>";
    echo "<td>" . $unixTime . "</td>";
    echo "<td>" . $istTime . "</td>";
    echo "</tr>";
}

echo "</table>";

// Check call_logs table
$tableCheck = $conn->query("SHOW TABLES LIKE 'call_logs'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    echo "<hr>";
    
    // First check what columns exist
    $columnsQuery = "SHOW COLUMNS FROM call_logs";
    $columnsResult = $conn->query($columnsQuery);
    $columns = [];
    while ($col = $columnsResult->fetch_assoc()) {
        $columns[] = $col['Field'];
    }
    
    // Build query based on available columns
    $nameColumn = in_array('name', $columns) ? 'name' : (in_array('caller_name', $columns) ? 'caller_name' : 'id');
    
    $query2 = "SELECT id, $nameColumn as name, created_at, 
              UNIX_TIMESTAMP(created_at) as unix_created
              FROM call_logs 
              ORDER BY id DESC 
              LIMIT 10";
    
    $result2 = $conn->query($query2);
    
    echo "<h2>Latest 10 Records from call_logs</h2>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Name</th><th>created_at (String)</th><th>UNIX Timestamp</th><th>Converted to IST</th></tr>";
    
    while ($row = $result2->fetch_assoc()) {
        $createdStr = $row['created_at'];
        $unixTime = $row['unix_created'];
        $istTime = date('Y-m-d H:i:s', $unixTime);
        
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . htmlspecialchars($row['name'] ?? 'N/A') . "</td>";
        echo "<td><strong>" . $createdStr . "</strong></td>";
        echo "<td>" . $unixTime . "</td>";
        echo "<td>" . $istTime . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<hr>";
    echo "<p style='color: orange;'>call_logs table does not exist</p>";
}

echo "<hr>";
echo "<h2>Current Time</h2>";
echo "<p><strong>PHP date():</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>PHP time():</strong> " . time() . "</p>";

$mysqlNow = $conn->query("SELECT NOW() as now, UNIX_TIMESTAMP(NOW()) as unix_now")->fetch_assoc();
echo "<p><strong>MySQL NOW():</strong> " . $mysqlNow['now'] . "</p>";
echo "<p><strong>MySQL UNIX:</strong> " . $mysqlNow['unix_now'] . "</p>";

echo "<hr>";
echo "<h2>Explanation</h2>";
echo "<p>If 'created_at (String)' shows IST time (like 17:xx), the data is CORRECT.</p>";
echo "<p>If your database viewer shows different time, it's converting the timezone for display.</p>";
echo "<p>The UNIX timestamp is the absolute truth - it's timezone-independent.</p>";
?>
