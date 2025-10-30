<?php
/**
 * Cleanup Unclosed Break Logs
 * This script closes any break_logs records that don't have a break_end
 */

require_once 'config.php';

echo "<h2>Cleanup Unclosed Break Logs</h2>";

// Find all unclosed breaks
$result = $conn->query("
    SELECT 
        bl.*,
        a.name as telecaller_name,
        TIMESTAMPDIFF(MINUTE, bl.break_start, NOW()) as minutes_elapsed
    FROM break_logs bl
    INNER JOIN admins a ON bl.telecaller_id = a.id
    WHERE bl.break_end IS NULL
    ORDER BY bl.break_start DESC
");

if ($result->num_rows > 0) {
    echo "<p>Found {$result->num_rows} unclosed break(s)</p>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>
            <th>ID</th>
            <th>Telecaller</th>
            <th>Break Type</th>
            <th>Break Start</th>
            <th>Minutes Elapsed</th>
            <th>Action</th>
          </tr>";
    
    $closedCount = 0;
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['telecaller_name']}</td>";
        echo "<td>{$row['break_type']}</td>";
        echo "<td>{$row['break_start']}</td>";
        echo "<td>{$row['minutes_elapsed']}</td>";
        
        // If break started more than 1 hour ago, close it with reasonable duration
        if ($row['minutes_elapsed'] > 60) {
            // Close with 10 minute duration
            $stmt = $conn->prepare("UPDATE break_logs SET break_end = DATE_ADD(break_start, INTERVAL 10 MINUTE) WHERE id = ?");
            $stmt->bind_param("i", $row['id']);
            $stmt->execute();
            echo "<td style='color: green;'>✅ Closed (10 min duration)</td>";
            $closedCount++;
        } else {
            // This might be an active break, don't close it
            echo "<td style='color: orange;'>⚠️ Skipped (recent break)</td>";
        }
        
        echo "</tr>";
    }
    
    echo "</table>";
    echo "<br><p><strong>Closed {$closedCount} old unclosed break(s)</strong></p>";
} else {
    echo "<p style='color: green;'>✅ No unclosed breaks found - all clean!</p>";
}

// Show summary by telecaller
echo "<br><h3>Break Summary by Telecaller (Today)</h3>";
$result = $conn->query("
    SELECT 
        a.name as telecaller_name,
        COUNT(*) as break_count,
        SUM(TIMESTAMPDIFF(SECOND, bl.break_start, bl.break_end)) as total_seconds,
        SUM(CASE WHEN bl.break_end IS NULL THEN 1 ELSE 0 END) as unclosed_count
    FROM break_logs bl
    INNER JOIN admins a ON bl.telecaller_id = a.id
    WHERE DATE(bl.break_start) = CURDATE()
    GROUP BY bl.telecaller_id, a.name
");

if ($result->num_rows > 0) {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>
            <th>Telecaller</th>
            <th>Total Breaks</th>
            <th>Total Duration</th>
            <th>Unclosed</th>
          </tr>";
    
    while ($row = $result->fetch_assoc()) {
        $minutes = floor($row['total_seconds'] / 60);
        $seconds = $row['total_seconds'] % 60;
        $duration = "{$minutes}m {$seconds}s";
        
        echo "<tr>";
        echo "<td>{$row['telecaller_name']}</td>";
        echo "<td>{$row['break_count']}</td>";
        echo "<td>{$duration}</td>";
        echo "<td>" . ($row['unclosed_count'] > 0 ? "⚠️ {$row['unclosed_count']}" : "✅ 0") . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<p>No breaks taken today</p>";
}

echo "<br><p><a href='test_status_tracking.php'>View Status Tracking Test</a></p>";

$conn->close();
