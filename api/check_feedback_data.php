<?php
/**
 * Check if there's any feedback data in call_logs_match_making table
 */

require_once 'config.php';

$jobId = 'TMJB00481';

echo "Checking feedback data for job: $jobId\n";
echo "==========================================\n\n";

// Check call_logs_match_making table
$query = "SELECT * FROM call_logs_match_making WHERE job_id = '$jobId' ORDER BY created_at DESC LIMIT 10";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "Found " . $result->num_rows . " feedback records:\n\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . "\n";
        echo "  Driver TMID: " . ($row['unique_id_driver'] ?? 'NULL') . "\n";
        echo "  Transporter TMID: " . ($row['unique_id_transporter'] ?? 'NULL') . "\n";
        echo "  Feedback: " . ($row['feedback'] ?? 'NULL') . "\n";
        echo "  Match Status: " . ($row['match_status'] ?? 'NULL') . "\n";
        echo "  Remark: " . ($row['remark'] ?? 'NULL') . "\n";
        echo "  Created: " . ($row['created_at'] ?? 'NULL') . "\n";
        echo "\n";
    }
} else {
    echo "No feedback records found for this job.\n\n";
}

// Check table structure
echo "Table structure:\n";
echo "================\n";
$structureQuery = "DESCRIBE call_logs_match_making";
$structureResult = $conn->query($structureQuery);

if ($structureResult) {
    while ($row = $structureResult->fetch_assoc()) {
        echo $row['Field'] . " (" . $row['Type'] . ")\n";
    }
}
