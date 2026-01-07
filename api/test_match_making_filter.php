<?php
/**
 * Test Match Making Filter - Debug Script
 * Check what feedback is stored in database
 */

header('Content-Type: text/html; charset=utf-8');

require_once 'config.php';

echo "<h1>Match Making Filter Debug</h1>";

// Get a driver TMID to test (you can change this)
$testDriverTmid = isset($_GET['driver_tmid']) ? $_GET['driver_tmid'] : '';

if (empty($testDriverTmid)) {
    echo "<p>Usage: test_match_making_filter.php?driver_tmid=TM2511HRDR18064</p>";
    echo "<p>Enter a driver TMID to check their feedback history</p>";
    exit;
}

echo "<h2>Testing Driver: $testDriverTmid</h2>";

// Get all feedback for this driver
$query = "SELECT 
    id,
    caller_id,
    feedback,
    match_status,
    remark,
    job_id,
    created_at,
    updated_at
FROM call_logs_match_making 
WHERE unique_id_driver = '$testDriverTmid'
ORDER BY created_at DESC
LIMIT 20";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<h3>Feedback History (Most Recent First)</h3>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>
            <th>ID</th>
            <th>Caller ID</th>
            <th>Feedback</th>
            <th>Match Status</th>
            <th>Remark</th>
            <th>Job ID</th>
            <th>Created At</th>
            <th>Updated At</th>
          </tr>";
    
    while ($row = $result->fetch_assoc()) {
        $isConnected = (
            strpos($row['feedback'], 'Connected:') !== false ||
            strpos($row['feedback'], 'Interview Done') !== false ||
            strpos($row['feedback'], 'Not Selected') !== false ||
            strpos($row['feedback'], 'Not Interested') !== false ||
            strpos($row['feedback'], 'Interview Fixed') !== false ||
            strpos($row['feedback'], 'Ready for Interview') !== false ||
            strpos($row['feedback'], 'Will Confirm Later') !== false ||
            strpos($row['feedback'], 'Match Making Done') !== false
        );
        
        $isMatchMaking = (
            strpos($row['feedback'], 'Match Making Done') !== false ||
            strpos($row['feedback'], 'Matchmaking Done') !== false
        );
        
        $bgColor = $isMatchMaking ? '#ffcccc' : ($isConnected ? '#ccffcc' : '#ffffff');
        
        echo "<tr style='background: $bgColor;'>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['caller_id'] . "</td>";
        echo "<td><strong>" . htmlspecialchars($row['feedback']) . "</strong></td>";
        echo "<td>" . ($row['match_status'] ?? 'NULL') . "</td>";
        echo "<td>" . ($row['remark'] ?? 'NULL') . "</td>";
        echo "<td>" . ($row['job_id'] ?? 'NULL') . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td>" . $row['updated_at'] . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
    
    echo "<p><strong>Legend:</strong></p>";
    echo "<ul>";
    echo "<li style='background: #ffcccc; padding: 5px;'>Red = Match Making Done (driver should be hidden)</li>";
    echo "<li style='background: #ccffcc; padding: 5px;'>Green = Connected section feedback (driver should be visible)</li>";
    echo "<li style='background: #ffffff; padding: 5px;'>White = Other section feedback (no effect on visibility)</li>";
    echo "</ul>";
    
} else {
    echo "<p>No feedback found for this driver</p>";
}

// Now check what the global match status query returns
echo "<h3>Global Match Status Query Result</h3>";

$gmsQuery = "SELECT 
    clm.unique_id_driver, 
    clm.feedback,
    clm.match_status,
    clm.created_at,
    CASE 
        WHEN clm.feedback LIKE '%Match Making Done%' OR clm.feedback LIKE '%Matchmaking Done%' 
        THEN 'Matchmaking Done'
        ELSE NULL
    END as global_match_status,
    u_caller.name as match_maker_name
FROM call_logs_match_making clm
LEFT JOIN users u_caller ON clm.caller_id = u_caller.id
INNER JOIN (
    SELECT unique_id_driver, MAX(created_at) as max_created
    FROM call_logs_match_making
    WHERE unique_id_driver IS NOT NULL AND unique_id_driver != ''
    AND (
        feedback LIKE 'Connected:%' 
        OR feedback LIKE '%Interview Done%'
        OR feedback LIKE '%Not Selected%'
        OR feedback LIKE '%Not Interested%'
        OR feedback LIKE '%Interview Fixed%'
        OR feedback LIKE '%Ready for Interview%'
        OR feedback LIKE '%Will Confirm Later%'
        OR feedback LIKE '%Match Making Done%'
    )
    GROUP BY unique_id_driver
) latest ON clm.unique_id_driver = latest.unique_id_driver AND clm.created_at = latest.max_created
WHERE clm.unique_id_driver = '$testDriverTmid'
AND (
    clm.feedback LIKE 'Connected:%' 
    OR clm.feedback LIKE '%Interview Done%'
    OR clm.feedback LIKE '%Not Selected%'
    OR clm.feedback LIKE '%Not Interested%'
    OR clm.feedback LIKE '%Interview Fixed%'
    OR clm.feedback LIKE '%Ready for Interview%'
    OR clm.feedback LIKE '%Will Confirm Later%'
    OR clm.feedback LIKE '%Match Making Done%'
)";

$gmsResult = $conn->query($gmsQuery);

if ($gmsResult && $gmsResult->num_rows > 0) {
    $gmsRow = $gmsResult->fetch_assoc();
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'>
            <th>Driver TMID</th>
            <th>Most Recent Connected Feedback</th>
            <th>Match Status</th>
            <th>Global Match Status</th>
            <th>Match Maker</th>
            <th>Created At</th>
          </tr>";
    
    $shouldHide = $gmsRow['global_match_status'] === 'Matchmaking Done';
    $bgColor = $shouldHide ? '#ffcccc' : '#ccffcc';
    
    echo "<tr style='background: $bgColor;'>";
    echo "<td>" . $gmsRow['unique_id_driver'] . "</td>";
    echo "<td><strong>" . htmlspecialchars($gmsRow['feedback']) . "</strong></td>";
    echo "<td>" . ($gmsRow['match_status'] ?? 'NULL') . "</td>";
    echo "<td><strong>" . ($gmsRow['global_match_status'] ?? 'NULL') . "</strong></td>";
    echo "<td>" . ($gmsRow['match_maker_name'] ?? 'NULL') . "</td>";
    echo "<td>" . $gmsRow['created_at'] . "</td>";
    echo "</tr>";
    
    echo "</table>";
    
    if ($shouldHide) {
        echo "<p style='color: red; font-weight: bold;'>❌ Driver WILL BE HIDDEN from job applicant lists</p>";
    } else {
        echo "<p style='color: green; font-weight: bold;'>✅ Driver WILL BE VISIBLE in job applicant lists</p>";
    }
    
} else {
    echo "<p style='color: green; font-weight: bold;'>✅ No Connected section feedback found - Driver WILL BE VISIBLE in job applicant lists</p>";
}

$conn->close();
?>
