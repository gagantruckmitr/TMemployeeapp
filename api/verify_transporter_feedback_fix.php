<?php
/**
 * Verify Transporter Feedback Fix
 * Quick verification that the fix is working in production
 */

require_once 'config.php';

header('Content-Type: application/json');

$response = [
    'success' => true,
    'checks' => [],
    'summary' => []
];

// Check 1: Table exists
$checkQuery = "SHOW TABLES LIKE 'job_brief_table'";
$result = $conn->query($checkQuery);
$response['checks']['table_exists'] = ($result && $result->num_rows > 0);

if (!$response['checks']['table_exists']) {
    $response['success'] = false;
    $response['error'] = 'Table job_brief_table does not exist';
    echo json_encode($response, JSON_PRETTY_PRINT);
    exit;
}

// Check 2: Required columns exist
$requiredColumns = ['id', 'unique_id', 'job_id', 'caller_id', 'name', 'call_status_feedback', 'call_recording', 'created_at'];
$structureQuery = "DESCRIBE job_brief_table";
$result = $conn->query($structureQuery);

$existingColumns = [];
while ($row = $result->fetch_assoc()) {
    $existingColumns[] = $row['Field'];
}

$missingColumns = array_diff($requiredColumns, $existingColumns);
$response['checks']['all_columns_exist'] = empty($missingColumns);
$response['checks']['missing_columns'] = $missingColumns;

// Check 3: Recent feedback entries (last 24 hours)
$recentQuery = "SELECT COUNT(*) as count FROM job_brief_table WHERE created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)";
$result = $conn->query($recentQuery);
$row = $result->fetch_assoc();
$response['checks']['recent_entries_24h'] = (int)$row['count'];

// Check 4: Entries with feedback
$feedbackQuery = "SELECT COUNT(*) as count FROM job_brief_table WHERE call_status_feedback IS NOT NULL";
$result = $conn->query($feedbackQuery);
$row = $result->fetch_assoc();
$response['checks']['entries_with_feedback'] = (int)$row['count'];

// Check 5: Entries with recordings
$recordingQuery = "SELECT COUNT(*) as count FROM job_brief_table WHERE call_recording IS NOT NULL";
$result = $conn->query($recordingQuery);
$row = $result->fetch_assoc();
$response['checks']['entries_with_recording'] = (int)$row['count'];

// Check 6: Entries with notes (feedback containing "Notes:")
$notesQuery = "SELECT COUNT(*) as count FROM job_brief_table WHERE call_status_feedback LIKE '%Notes:%'";
$result = $conn->query($notesQuery);
$row = $result->fetch_assoc();
$response['checks']['entries_with_notes'] = (int)$row['count'];

// Check 7: Total entries
$totalQuery = "SELECT COUNT(*) as count FROM job_brief_table";
$result = $conn->query($totalQuery);
$row = $result->fetch_assoc();
$response['checks']['total_entries'] = (int)$row['count'];

// Check 8: Latest entry details
$latestQuery = "SELECT id, unique_id, job_id, caller_id, name, 
                       SUBSTRING(call_status_feedback, 1, 100) as feedback_preview,
                       call_recording,
                       created_at 
                FROM job_brief_table 
                ORDER BY created_at DESC 
                LIMIT 1";
$result = $conn->query($latestQuery);
if ($result && $result->num_rows > 0) {
    $response['checks']['latest_entry'] = $result->fetch_assoc();
} else {
    $response['checks']['latest_entry'] = null;
}

// Summary
$response['summary'] = [
    'status' => $response['success'] ? 'OK' : 'ERROR',
    'table_exists' => $response['checks']['table_exists'] ? 'YES' : 'NO',
    'all_columns_present' => $response['checks']['all_columns_exist'] ? 'YES' : 'NO',
    'total_records' => $response['checks']['total_entries'],
    'records_last_24h' => $response['checks']['recent_entries_24h'],
    'records_with_feedback' => $response['checks']['entries_with_feedback'],
    'records_with_notes' => $response['checks']['entries_with_notes'],
    'records_with_recording' => $response['checks']['entries_with_recording'],
    'fix_working' => ($response['checks']['entries_with_feedback'] > 0) ? 'YES' : 'UNKNOWN'
];

// Recommendations
$response['recommendations'] = [];

if ($response['checks']['recent_entries_24h'] == 0) {
    $response['recommendations'][] = 'No entries in last 24 hours. Test the app to create a new feedback entry.';
}

if ($response['checks']['entries_with_notes'] == 0 && $response['checks']['total_entries'] > 0) {
    $response['recommendations'][] = 'No entries with notes found. The fix may not be fully deployed yet.';
}

if ($response['checks']['entries_with_feedback'] == 0 && $response['checks']['total_entries'] > 0) {
    $response['recommendations'][] = 'No entries with feedback found. Check if call_status_feedback column is being populated.';
}

if (empty($response['recommendations'])) {
    $response['recommendations'][] = 'Everything looks good! The fix appears to be working correctly.';
}

$conn->close();

echo json_encode($response, JSON_PRETTY_PRINT);
?>
