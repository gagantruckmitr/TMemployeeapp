<?php
/**
 * Final Complete Fix
 * - Fix all status values to use online/offline/break
 * - Clear break_start_time for non-break statuses
 * - Update Pooja's status
 */

require_once 'config.php';

echo "<h2>Final Complete Status Fix</h2>";

// 1. Update all 'active' to 'online'
$result = $conn->query("UPDATE telecaller_status SET current_status = 'online' WHERE current_status = 'active'");
echo "<p>✅ Changed 'active' to 'online': {$conn->affected_rows} rows</p>";

// 2. Update all 'inactive' to 'offline'
$result = $conn->query("UPDATE telecaller_status SET current_status = 'offline' WHERE current_status = 'inactive'");
echo "<p>✅ Changed 'inactive' to 'offline': {$conn->affected_rows} rows</p>";

// 3. Clear break_start_time for non-break statuses
$result = $conn->query("UPDATE telecaller_status SET break_start_time = NULL WHERE current_status != 'break'");
echo "<p>✅ Cleared break_start_time for non-break statuses: {$conn->affected_rows} rows</p>";

// 4. Reset total_break_duration to 0
$result = $conn->query("UPDATE telecaller_status SET total_break_duration = 0");
echo "<p>✅ Reset all break durations to 0</p>";

// 5. Update Pooja specifically
$result = $conn->query("UPDATE telecaller_status SET current_status = 'online', last_activity = NOW(), break_start_time = NULL WHERE telecaller_id = 3");
echo "<p>✅ Updated Pooja's status to online</p>";

// Show current status
echo "<h3>Current Status (Sorted by Recent Login):</h3>";
$result = $conn->query("
    SELECT 
        ts.telecaller_id,
        a.name,
        ts.current_status,
        ts.login_time,
        ts.break_start_time,
        ts.last_activity,
        TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) as minutes_since_activity,
        CASE 
            WHEN ts.login_time IS NULL THEN 'offline'
            WHEN ts.logout_time IS NOT NULL AND ts.logout_time > ts.login_time THEN 'offline'
            WHEN ts.current_status = 'offline' THEN 'offline'
            WHEN ts.current_status = 'break' THEN 'break'
            WHEN ts.current_status = 'on_call' THEN 'on_call'
            WHEN TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) >= 10 THEN 'inactive'
            WHEN ts.current_status = 'online' THEN 'online'
            ELSE 'online'
        END as display_status
    FROM telecaller_status ts
    INNER JOIN admins a ON ts.telecaller_id = a.id
    WHERE a.role = 'telecaller'
    ORDER BY ts.login_time DESC, ts.last_activity DESC
");

echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr style='background: #f0f0f0;'>
        <th>ID</th>
        <th>Name</th>
        <th>DB Status</th>
        <th>Display Status</th>
        <th>Login Time</th>
        <th>Break Start</th>
        <th>Minutes Since Activity</th>
      </tr>";

while ($row = $result->fetch_assoc()) {
    $dbColor = 'grey';
    if ($row['current_status'] == 'online') $dbColor = 'green';
    elseif ($row['current_status'] == 'break') $dbColor = 'orange';
    elseif ($row['current_status'] == 'offline') $dbColor = 'grey';
    
    $displayColor = 'grey';
    if ($row['display_status'] == 'online') $displayColor = 'green';
    elseif ($row['display_status'] == 'inactive') $displayColor = 'red';
    elseif ($row['display_status'] == 'break') $displayColor = 'orange';
    elseif ($row['display_status'] == 'offline') $displayColor = 'grey';
    
    echo "<tr>";
    echo "<td>{$row['telecaller_id']}</td>";
    echo "<td><strong>{$row['name']}</strong></td>";
    echo "<td style='color: {$dbColor}; font-weight: bold;'>{$row['current_status']}</td>";
    echo "<td style='color: {$displayColor}; font-weight: bold;'>{$row['display_status']}</td>";
    echo "<td>" . ($row['login_time'] ?: 'Never') . "</td>";
    echo "<td>" . ($row['break_start_time'] ?: 'NULL') . "</td>";
    echo "<td>{$row['minutes_since_activity']}</td>";
    echo "</tr>";
}

echo "</table>";

echo "<br><h3>✅ Summary:</h3>";
echo "<ul>";
echo "<li>Database stores: 'online', 'offline', 'break', 'on_call'</li>";
echo "<li>Display shows: 'online' (green), 'inactive' (red), 'break' (orange), 'offline' (grey)</li>";
echo "<li>Sorted by: Most recent login first</li>";
echo "<li>All break_start_time cleared for non-break statuses</li>";
echo "</ul>";

echo "<p><a href='test_status_tracking.php'>View Status Tracking Test</a></p>";

$conn->close();
