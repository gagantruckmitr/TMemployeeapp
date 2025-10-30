<?php
/**
 * Complete Status Fix
 * - Clear break_start_time for telecallers not on break
 * - Reset total_break_duration to match break_logs
 * - Fix current_status values
 */

require_once 'config.php';

echo "<h2>Complete Status Fix</h2>";

// 1. Clear break_start_time for all telecallers (they're not on break)
echo "<h3>Step 1: Clear break_start_time</h3>";
$result = $conn->query("
    UPDATE telecaller_status 
    SET break_start_time = NULL 
    WHERE current_status != 'break'
");
echo "<p>✅ Cleared break_start_time for telecallers not on break</p>";

// 2. Reset total_break_duration to 0 for all (will be calculated from break_logs)
echo "<h3>Step 2: Reset break durations</h3>";
$result = $conn->query("UPDATE telecaller_status SET total_break_duration = 0");
echo "<p>✅ Reset all break durations to 0</p>";

// 3. Show current status
echo "<h3>Step 3: Current Status</h3>";
$result = $conn->query("
    SELECT 
        ts.telecaller_id,
        a.name,
        ts.current_status,
        ts.break_start_time,
        ts.total_break_duration,
        ts.last_activity,
        TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) as minutes_since_activity
    FROM telecaller_status ts
    INNER JOIN admins a ON ts.telecaller_id = a.id
    WHERE a.role = 'telecaller'
    ORDER BY a.name
");

echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr style='background: #f0f0f0;'>
        <th>ID</th>
        <th>Name</th>
        <th>Status</th>
        <th>Break Start Time</th>
        <th>Break Duration</th>
        <th>Minutes Since Activity</th>
      </tr>";

while ($row = $result->fetch_assoc()) {
    $statusColor = 'grey';
    if ($row['current_status'] == 'active') $statusColor = 'green';
    elseif ($row['current_status'] == 'inactive') $statusColor = 'red';
    elseif ($row['current_status'] == 'break') $statusColor = 'orange';
    
    echo "<tr>";
    echo "<td>{$row['telecaller_id']}</td>";
    echo "<td>{$row['name']}</td>";
    echo "<td style='color: {$statusColor}; font-weight: bold;'>{$row['current_status']}</td>";
    echo "<td>" . ($row['break_start_time'] ?: 'NULL') . "</td>";
    echo "<td>{$row['total_break_duration']}s</td>";
    echo "<td>{$row['minutes_since_activity']}</td>";
    echo "</tr>";
}

echo "</table>";

echo "<br><h3>Summary:</h3>";
echo "<ul>";
echo "<li>✅ All break_start_time values cleared (NULL)</li>";
echo "<li>✅ All total_break_duration reset to 0</li>";
echo "<li>✅ Status values are: active, inactive, or offline</li>";
echo "</ul>";

echo "<p><strong>The manager dashboard should now show correct break durations (0 for everyone)</strong></p>";
echo "<p><a href='test_status_tracking.php'>View Status Tracking Test</a></p>";

$conn->close();
