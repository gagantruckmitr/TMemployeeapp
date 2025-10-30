<?php
/**
 * Reset Break Duration in telecaller_status table
 */

require_once 'config.php';

echo "<h2>Reset Break Duration</h2>";

// Get all telecallers
$result = $conn->query("
    SELECT 
        ts.telecaller_id,
        a.name,
        ts.total_break_duration as old_duration,
        (SELECT SUM(TIMESTAMPDIFF(SECOND, break_start, break_end)) 
         FROM break_logs 
         WHERE telecaller_id = ts.telecaller_id 
         AND DATE(break_start) = CURDATE() 
         AND break_end IS NOT NULL) as actual_duration
    FROM telecaller_status ts
    INNER JOIN admins a ON ts.telecaller_id = a.id
    WHERE a.role = 'telecaller'
");

echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr style='background: #f0f0f0;'>
        <th>ID</th>
        <th>Name</th>
        <th>Old Duration (telecaller_status)</th>
        <th>Actual Duration (break_logs)</th>
        <th>Action</th>
      </tr>";

while ($row = $result->fetch_assoc()) {
    $oldMinutes = floor($row['old_duration'] / 60);
    $oldSeconds = $row['old_duration'] % 60;
    
    $actualDuration = $row['actual_duration'] ?: 0;
    $actualMinutes = floor($actualDuration / 60);
    $actualSeconds = $actualDuration % 60;
    
    $needsUpdate = $row['old_duration'] != $actualDuration;
    
    echo "<tr>";
    echo "<td>{$row['telecaller_id']}</td>";
    echo "<td>{$row['name']}</td>";
    echo "<td style='color: red;'>{$oldMinutes}m {$oldSeconds}s ({$row['old_duration']}s)</td>";
    echo "<td style='color: green;'>{$actualMinutes}m {$actualSeconds}s ({$actualDuration}s)</td>";
    
    if ($needsUpdate) {
        // Update the telecaller_status table
        $stmt = $conn->prepare("UPDATE telecaller_status SET total_break_duration = ? WHERE telecaller_id = ?");
        $stmt->bind_param("ii", $actualDuration, $row['telecaller_id']);
        $stmt->execute();
        
        echo "<td style='color: green; font-weight: bold;'>✅ UPDATED</td>";
    } else {
        echo "<td>✅ OK</td>";
    }
    
    echo "</tr>";
}

echo "</table>";

echo "<br><h3>Summary:</h3>";
echo "<p>✅ All telecaller_status records have been synchronized with actual break_logs data</p>";
echo "<p>The break duration shown in the app should now be correct!</p>";

echo "<br><p><a href='test_status_tracking.php'>View Status Tracking Test</a></p>";
echo "<p><a href='check_pooja_breaks.php'>Check Pooja's Breaks</a></p>";

$conn->close();
