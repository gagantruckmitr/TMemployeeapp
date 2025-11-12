<?php
/**
 * Comprehensive Timestamp Fix for ALL Tables
 * Fixes timestamps in applyjobs, call_logs_match_making, call_logs, and other tables
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Comprehensive Timestamp Fix</h1>";
echo "<hr>";

$dryRun = !isset($_GET['fix']) || $_GET['fix'] !== 'yes';

if ($dryRun) {
    echo "<p style='color: orange;'><strong>DRY RUN MODE</strong> - No changes will be made</p>";
    echo "<p>To actually fix, add <code>?fix=yes</code> to the URL</p>";
} else {
    echo "<p style='color: red;'><strong>FIX MODE</strong> - Timestamps will be corrected</p>";
}
echo "<hr>";

// Current time info
echo "<h2>Current Time</h2>";
echo "<p><strong>PHP:</strong> " . date('Y-m-d H:i:s') . " IST</p>";
$mysqlTime = $conn->query("SELECT NOW() as now")->fetch_assoc()['now'];
echo "<p><strong>MySQL:</strong> $mysqlTime</p>";
echo "<hr>";

// Tables to fix - ONLY call_logs and call_logs_match_making
$tables = [
    'call_logs_match_making' => [
        'time_column' => 'created_at',
        'name_column' => 'driver_name',
        'days_back' => 30
    ],
    'call_logs' => [
        'time_column' => 'created_at',
        'name_column' => 'name',
        'days_back' => 30
    ]
];

$totalFixed = 0;
$totalSkipped = 0;
$totalErrors = 0;

foreach ($tables as $tableName => $config) {
    echo "<h2>Table: $tableName</h2>";
    
    // Check if table exists
    $tableCheck = $conn->query("SHOW TABLES LIKE '$tableName'");
    if (!$tableCheck || $tableCheck->num_rows === 0) {
        echo "<p style='color: gray;'>Table does not exist, skipping...</p><hr>";
        continue;
    }
    
    $timeCol = $config['time_column'];
    $nameCol = $config['name_column'];
    $daysBack = $config['days_back'];
    
    // Find records with potential wrong timestamps
    // Looking for records where created_at is significantly different from NOW()
    $query = "SELECT 
        id,
        $nameCol as name,
        $timeCol as time_value,
        TIMESTAMPDIFF(SECOND, $timeCol, NOW()) as seconds_diff
    FROM $tableName
    WHERE $timeCol >= DATE_SUB(NOW(), INTERVAL $daysBack DAY)
    ORDER BY $timeCol DESC
    LIMIT 200";
    
    $result = $conn->query($query);
    
    if (!$result) {
        echo "<p style='color: red;'>Query error: " . $conn->error . "</p><hr>";
        continue;
    }
    
    $count = $result->num_rows;
    echo "<p>Found $count recent records (last $daysBack days)</p>";
    
    if ($count === 0) {
        echo "<p style='color: green;'>No records to check</p><hr>";
        continue;
    }
    
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse; font-size: 12px;'>";
    echo "<tr><th>ID</th><th>Name</th><th>Current Time</th><th>Diff (hrs)</th><th>Corrected</th><th>Status</th></tr>";
    
    $tableFixed = 0;
    $tableSkipped = 0;
    $tableErrors = 0;
    
    while ($row = $result->fetch_assoc()) {
        $id = $row['id'];
        $timeValue = $row['time_value'];
        $secondsDiff = (int)$row['seconds_diff'];
        $hoursDiff = round($secondsDiff / 3600, 1);
        
        // Determine if needs fix
        // If time is 4-7 hours in the past (19800 seconds = 5.5 hours), likely UTC instead of IST
        $needsFix = false;
        $expectedDiff = 19800; // 5.5 hours in seconds
        
        // Check if the timestamp looks like it's in UTC (roughly 5.5 hours behind)
        if ($secondsDiff > 14400 && $secondsDiff < 25200) { // Between 4 and 7 hours
            $needsFix = true;
        }
        
        // Calculate corrected time (add 5 hours 30 minutes)
        $correctedTime = date('Y-m-d H:i:s', strtotime($timeValue) + 19800);
        
        echo "<tr>";
        echo "<td>" . $id . "</td>";
        echo "<td>" . htmlspecialchars(substr($row['name'] ?? 'N/A', 0, 20)) . "</td>";
        echo "<td>" . $timeValue . "</td>";
        echo "<td style='color: " . ($needsFix ? 'red' : 'green') . ";'>" . $hoursDiff . "h</td>";
        echo "<td>" . $correctedTime . "</td>";
        
        if (!$needsFix) {
            echo "<td style='color: gray;'>OK</td>";
            $tableSkipped++;
        } elseif (!$dryRun) {
            // Fix it
            $updateQuery = "UPDATE $tableName SET $timeCol = '$correctedTime' WHERE id = $id";
            if ($conn->query($updateQuery)) {
                echo "<td style='color: green;'>✓ Fixed</td>";
                $tableFixed++;
            } else {
                echo "<td style='color: red;'>✗ Error</td>";
                $tableErrors++;
            }
        } else {
            echo "<td style='color: orange;'>Would fix</td>";
        }
        
        echo "</tr>";
    }
    
    echo "</table>";
    
    if (!$dryRun) {
        echo "<p><strong>$tableName Summary:</strong> Fixed: $tableFixed, Skipped: $tableSkipped, Errors: $tableErrors</p>";
    }
    
    $totalFixed += $tableFixed;
    $totalSkipped += $tableSkipped;
    $totalErrors += $tableErrors;
    
    echo "<hr>";
}

// Overall summary
if (!$dryRun) {
    echo "<h2>Overall Summary</h2>";
    echo "<ul>";
    echo "<li><strong style='color: green;'>Total Fixed:</strong> $totalFixed</li>";
    echo "<li><strong style='color: gray;'>Total Skipped:</strong> $totalSkipped</li>";
    echo "<li><strong style='color: red;'>Total Errors:</strong> $totalErrors</li>";
    echo "</ul>";
} else {
    echo "<p><a href='?fix=yes' style='background: red; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-size: 16px;'>FIX ALL TIMESTAMPS NOW</a></p>";
}

echo "<p><em>Generated at: " . date('Y-m-d H:i:s') . " IST</em></p>";
?>
