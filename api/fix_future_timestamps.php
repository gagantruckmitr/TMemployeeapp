<?php
/**
 * Fix Future Timestamps in applyjobs Table
 * This script corrects timestamps that are in the future
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Fix Future Timestamps</h1>";
echo "<hr>";

// Check if we're in dry-run mode or actual fix mode
$dryRun = !isset($_GET['fix']) || $_GET['fix'] !== 'yes';

if ($dryRun) {
    echo "<p style='color: orange;'><strong>DRY RUN MODE</strong> - No changes will be made</p>";
    echo "<p>To actually fix the timestamps, add <code>?fix=yes</code> to the URL</p>";
} else {
    echo "<p style='color: red;'><strong>FIX MODE</strong> - Timestamps will be corrected</p>";
}
echo "<hr>";

// Find all future timestamps
$query = "SELECT 
    a.id,
    a.job_id,
    a.driver_id,
    u.name as driver_name,
    a.created_at,
    UNIX_TIMESTAMP(a.created_at) as created_timestamp,
    UNIX_TIMESTAMP(NOW()) as current_timestamp,
    UNIX_TIMESTAMP(a.created_at) - UNIX_TIMESTAMP(NOW()) as diff_seconds
FROM applyjobs a
LEFT JOIN users u ON a.driver_id = u.id
WHERE a.created_at > NOW()
ORDER BY a.created_at DESC";

$result = $conn->query($query);

if (!$result) {
    echo "<p style='color: red;'>Error: " . $conn->error . "</p>";
    exit;
}

$count = $result->num_rows;

if ($count === 0) {
    echo "<p style='color: green;'><strong>✓ No future timestamps found!</strong></p>";
    exit;
}

echo "<p>Found <strong>$count</strong> records with future timestamps</p>";
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>ID</th><th>Job ID</th><th>Driver</th><th>Current Timestamp</th><th>Diff (hours)</th><th>Corrected Timestamp</th><th>Status</th></tr>";

$fixed = 0;
$errors = 0;

while ($row = $result->fetch_assoc()) {
    $id = $row['id'];
    $diffSeconds = $row['diff_seconds'];
    $diffHours = round($diffSeconds / 3600, 2);
    
    // The issue is likely a timezone offset
    // If the difference is around 5.5 hours (19800 seconds), it's an IST offset issue
    // Subtract the difference to get the correct time
    $correctedTimestamp = $row['created_timestamp'] - $diffSeconds;
    $correctedDatetime = date('Y-m-d H:i:s', $correctedTimestamp);
    
    echo "<tr>";
    echo "<td>" . $id . "</td>";
    echo "<td>" . $row['job_id'] . "</td>";
    echo "<td>" . $row['driver_name'] . "</td>";
    echo "<td>" . $row['created_at'] . "</td>";
    echo "<td style='color: red;'>+" . $diffHours . "h</td>";
    echo "<td>" . $correctedDatetime . "</td>";
    
    if (!$dryRun) {
        // Actually fix the timestamp
        $updateQuery = "UPDATE applyjobs SET created_at = '$correctedDatetime' WHERE id = $id";
        if ($conn->query($updateQuery)) {
            echo "<td style='color: green;'>✓ Fixed</td>";
            $fixed++;
        } else {
            echo "<td style='color: red;'>✗ Error: " . $conn->error . "</td>";
            $errors++;
        }
    } else {
        echo "<td style='color: gray;'>Would fix</td>";
    }
    
    echo "</tr>";
}

echo "</table>";
echo "<hr>";

if (!$dryRun) {
    echo "<p><strong>Summary:</strong></p>";
    echo "<ul>";
    echo "<li>Fixed: <strong style='color: green;'>$fixed</strong></li>";
    echo "<li>Errors: <strong style='color: red;'>$errors</strong></li>";
    echo "</ul>";
} else {
    echo "<p><a href='?fix=yes' style='background: red; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Click here to fix these timestamps</a></p>";
}

echo "<p><em>Generated at: " . date('Y-m-d H:i:s') . "</em></p>";
?>
