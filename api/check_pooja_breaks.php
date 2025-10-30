<?php
/**
 * Check and Fix Pooja's Break Logs
 */

require_once 'config.php';

echo "<h2>Pooja's Break Logs Investigation</h2>";

// Get Pooja's ID
$result = $conn->query("SELECT id, name FROM admins WHERE name LIKE '%Pooja%' AND role = 'telecaller'");
$pooja = $result->fetch_assoc();
$poojaId = $pooja['id'];

echo "<p><strong>Telecaller:</strong> {$pooja['name']} (ID: {$poojaId})</p>";

// Show ALL break logs for Pooja today
echo "<h3>All Break Logs for Today:</h3>";
$result = $conn->query("
    SELECT 
        id,
        break_type,
        break_start,
        break_end,
        TIMESTAMPDIFF(SECOND, break_start, COALESCE(break_end, NOW())) as duration_seconds,
        CASE WHEN break_end IS NULL THEN 'OPEN' ELSE 'CLOSED' END as status
    FROM break_logs
    WHERE telecaller_id = {$poojaId}
    AND DATE(break_start) = CURDATE()
    ORDER BY break_start DESC
");

if ($result->num_rows > 0) {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>
            <th>ID</th>
            <th>Type</th>
            <th>Start</th>
            <th>End</th>
            <th>Duration</th>
            <th>Status</th>
            <th>Action</th>
          </tr>";
    
    $totalSeconds = 0;
    $hasOpenBreak = false;
    
    while ($row = $result->fetch_assoc()) {
        $minutes = floor($row['duration_seconds'] / 60);
        $seconds = $row['duration_seconds'] % 60;
        
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['break_type']}</td>";
        echo "<td>{$row['break_start']}</td>";
        echo "<td>" . ($row['break_end'] ?: 'NULL') . "</td>";
        echo "<td>{$minutes}m {$seconds}s</td>";
        echo "<td style='color: " . ($row['status'] == 'OPEN' ? 'red' : 'green') . ";'><strong>{$row['status']}</strong></td>";
        
        if ($row['status'] == 'OPEN') {
            echo "<td><a href='?close={$row['id']}' style='color: red;'>❌ CLOSE THIS</a></td>";
            $hasOpenBreak = true;
        } else {
            $totalSeconds += $row['duration_seconds'];
            echo "<td>✅ OK</td>";
        }
        
        echo "</tr>";
    }
    
    echo "</table>";
    
    $totalMinutes = floor($totalSeconds / 60);
    $totalSecs = $totalSeconds % 60;
    echo "<p><strong>Total Closed Break Duration:</strong> {$totalMinutes}m {$totalSecs}s</p>";
    
    if ($hasOpenBreak) {
        echo "<p style='color: red; font-weight: bold;'>⚠️ There are OPEN breaks that need to be closed!</p>";
    }
} else {
    echo "<p>No break logs found for today</p>";
}

// Handle close action
if (isset($_GET['close'])) {
    $breakId = intval($_GET['close']);
    
    // Get break start time
    $result = $conn->query("SELECT break_start FROM break_logs WHERE id = {$breakId}");
    $break = $result->fetch_assoc();
    
    // Close it with 5 minute duration
    $conn->query("UPDATE break_logs SET break_end = DATE_ADD(break_start, INTERVAL 5 MINUTE) WHERE id = {$breakId}");
    
    echo "<script>alert('Break #{$breakId} closed!'); window.location.href='check_pooja_breaks.php';</script>";
}

// Show what the API will calculate
echo "<br><h3>API Calculation:</h3>";
$result = $conn->query("
    SELECT 
        (SELECT SUM(TIMESTAMPDIFF(SECOND, break_start, break_end)) 
         FROM break_logs 
         WHERE telecaller_id = {$poojaId}
         AND DATE(break_start) = CURDATE() 
         AND break_end IS NOT NULL) as total_break_seconds_today
");
$calc = $result->fetch_assoc();
$apiSeconds = $calc['total_break_seconds_today'] ?: 0;
$apiMinutes = floor($apiSeconds / 60);
$apiSecs = $apiSeconds % 60;

echo "<p><strong>API will show:</strong> {$apiMinutes}m {$apiSecs}s ({$apiSeconds} seconds)</p>";

// Option to delete ALL breaks for today
echo "<br><h3>Nuclear Option:</h3>";
echo "<p><a href='?delete_all=1' onclick='return confirm(\"Are you sure you want to DELETE ALL of Pooja\\'s breaks for today?\")' style='color: red; font-weight: bold;'>🗑️ DELETE ALL BREAKS FOR TODAY</a></p>";

if (isset($_GET['delete_all'])) {
    $conn->query("DELETE FROM break_logs WHERE telecaller_id = {$poojaId} AND DATE(break_start) = CURDATE()");
    echo "<script>alert('All breaks deleted!'); window.location.href='check_pooja_breaks.php';</script>";
}

echo "<br><p><a href='test_status_tracking.php'>← Back to Status Tracking Test</a></p>";

$conn->close();
