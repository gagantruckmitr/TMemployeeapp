<?php
header('Content-Type: text/plain');
require_once 'config.php';

echo "=== TESTING SQL QUERY ===\n\n";

$jobIdString = 'TMJB00461';

// First get the numeric id
$jobQuery = "SELECT id FROM jobs WHERE job_id = '$jobIdString' LIMIT 1";
echo "Step 1: Get numeric job ID\n";
echo "Query: $jobQuery\n";

$jobResult = $conn->query($jobQuery);
if (!$jobResult) {
    echo "ERROR: " . $conn->error . "\n";
    exit;
}

if ($jobResult->num_rows === 0) {
    echo "ERROR: Job not found\n";
    exit;
}

$jobRow = $jobResult->fetch_assoc();
$numericJobId = $jobRow['id'];
echo "✓ Found job ID: $numericJobId\n\n";

// Test the main query
echo "Step 2: Test main query\n";
echo str_repeat("=", 80) . "\n";

$query = "SELECT 
    u.id AS driver_id,
    u.name
FROM applyjobs a
INNER JOIN users u ON a.driver_id = u.id
INNER JOIN jobs j ON a.job_id = j.id
LEFT JOIN (
    SELECT 
        gm1.unique_id_driver,
        gm1.match_status as global_match_status,
        gm1.job_id as matched_job_id,
        gm1.unique_id_telecaller as matched_by_telecaller
    FROM call_logs_match_making gm1
    INNER JOIN (
        SELECT unique_id_driver, MAX(created_at) as max_created
        FROM call_logs_match_making
        WHERE match_status = 'Match Making Done'
        AND unique_id_driver IS NOT NULL AND unique_id_driver != ''
        GROUP BY unique_id_driver
    ) gm2 ON gm1.unique_id_driver = gm2.unique_id_driver 
          AND gm1.created_at = gm2.max_created
    WHERE gm1.match_status = 'Match Making Done'
) global_match ON u.unique_id = global_match.unique_id_driver
LEFT JOIN users matched_telecaller ON global_match.matched_by_telecaller = matched_telecaller.unique_id
WHERE a.job_id = $numericJobId
GROUP BY a.id, u.id
LIMIT 5";

echo "Executing query...\n";
$result = $conn->query($query);

if (!$result) {
    echo "✗ SQL ERROR:\n";
    echo $conn->error . "\n";
} else {
    echo "✓ Query successful\n";
    echo "Rows returned: " . $result->num_rows . "\n";
    
    if ($result->num_rows > 0) {
        echo "\nSample data:\n";
        while ($row = $result->fetch_assoc()) {
            echo "Driver ID: {$row['driver_id']}, Name: {$row['name']}\n";
        }
    }
}
?>
