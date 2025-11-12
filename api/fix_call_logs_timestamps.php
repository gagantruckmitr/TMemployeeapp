<?php
/**
 * Fix Timestamps in call_logs_match_making and call_logs Tables
 * Adds 5 hours 30 minutes to all timestamps that are in UTC instead of IST
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Fix Call Logs Timestamps</h1>";
echo "<p>Fixes both <code>call_logs_match_making</code> and <code>call_logs</code> tables</p>";
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

// Get current time info
echo "<h2>Current Time Information</h2>";
echo "<p><strong>PHP Time:</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>PHP Timezone:</strong> " . date_default_timezone_get() . "</p>";

$mysqlTime = $conn->query("SELECT NOW() as now")->fetch_assoc()['now'];
echo "<p><strong>MySQL NOW():</strong> $mysqlTime</p>";

$mysqlTz = $conn->query("SELECT @@session.time_zone as tz")->fetch_assoc()['tz'];
echo "<p><strong>MySQL Timezone:</strong> $mysqlTz</p>";
echo "<hr>";

// Process both tables
$tables = [
    'call_logs_match_making' => [
        'name_field' => 'driver_name',
        'time_fields' => ['created_at', 'updated_at']
    ],
    'call_logs' => [
        'name_field' => 'name',
        'time_fields' => ['created_at']
    ]
];

foreach ($tables as $tableName => $config) {
    echo "<h2>Table: $tableName</h2>";
    
    // Check if table exists
    $tableCheck = $conn->query("SHOW TABLES LIKE '$tableName'");
    if (!$tableCheck || $tableCheck->num_rows === 0) {
        echo "<p style='color: orange;'>Table <code>$tableName</code> does not exist, skipping...</p>";
        continue;
    }
    
    $nameField = $config['name_field'];
    $timeFields = $config['time_fields'];
    
    $query = "SELECT 
        id,
        $nameField as name,
        created_at,
        TIMESTAMPDIFF(HOUR, created_at, NOW()) as hours_diff
    FROM $tableName
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ORDER BY created_at DESC
    LIMIT 100";

    $result = $conn->query($query);

    if (!$result) {
        echo "<p style='color: red;'>Error: " . $conn->error . "</p>";
        continue;
    }

    $count = $result->num_rows;
    echo "<p>Found <strong>$count</strong> recent records (last 7 days)</p>";

    if ($count === 0) {
        echo "<p style='color: green;'>No recent records to check</p>";
        continue;
    }

    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Name</th><th>Current Time</th><th>Hours Diff</th><th>Corrected Time</th><th>Status</th></tr>";

    $tableFixed = 0;
    $tableErrors = 0;
    $tableSkipped = 0;

    while ($row = $result->fetch_assoc()) {
        $id = $row['id'];
        $createdAt = $row['created_at'];
        $hoursDiff = (int)$row['hours_diff'];
        
        // If the timestamp is more than 4 hours in the past, it's likely UTC instead of IST
        // IST is UTC+5:30, so we need to add 5.5 hours
        $needsFix = false;
        if ($hoursDiff >= 4 && $hoursDiff <= 10) {
            // Likely a UTC timestamp that should be IST
            $needsFix = true;
        }
        
        // Calculate corrected timestamp (add 5 hours 30 minutes)
        $correctedTime = date('Y-m-d H:i:s', strtotime($createdAt) + (5 * 3600) + (30 * 60));
        
        echo "<tr>";
        echo "<td>" . $id . "</td>";
        echo "<td>" . ($row['name'] ?? 'N/A') . "</td>";
        echo "<td>" . $createdAt . "</td>";
        echo "<td style='color: " . ($needsFix ? 'red' : 'green') . ";'>" . $hoursDiff . "h</td>";
        echo "<td>" . $correctedTime . "</td>";
        
        if (!$needsFix) {
            echo "<td style='color: gray;'>OK - No fix needed</td>";
            $tableSkipped++;
        } elseif (!$dryRun) {
            // Build update query based on table's time fields
            $updateParts = [];
            foreach ($timeFields as $field) {
                $updateParts[] = "$field = '$correctedTime'";
            }
            $updateQuery = "UPDATE $tableName SET " . implode(', ', $updateParts) . " WHERE id = $id";
            
            if ($conn->query($updateQuery)) {
                echo "<td style='color: green;'>✓ Fixed</td>";
                $tableFixed++;
            } else {
                echo "<td style='color: red;'>✗ Error: " . $conn->error . "</td>";
                $tableErrors++;
            }
        } else {
            echo "<td style='color: orange;'>Would fix</td>";
        }
        
        echo "</tr>";
    }

    echo "</table>";
    
    if (!$dryRun) {
        echo "<p><strong>$tableName Summary:</strong></p>";
        echo "<ul>";
        echo "<li>Fixed: <strong style='color: green;'>$tableFixed</strong></li>";
        echo "<li>Skipped (OK): <strong style='color: gray;'>$tableSkipped</strong></li>";
        echo "<li>Errors: <strong style='color: red;'>$tableErrors</strong></li>";
        echo "</ul>";
    }
    
    echo "<hr>";
}

if ($dryRun) {
    echo "<p><a href='?fix=yes' style='background: red; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Click here to fix all timestamps</a></p>";
}

echo "<p><em>Generated at: " . date('Y-m-d H:i:s') . "</em></p>";
?>
