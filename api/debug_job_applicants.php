<?php
/**
 * Debug Job Applicants API
 * Helps identify SQL or PHP errors
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

header('Content-Type: application/json');

$jobIdString = isset($_GET['job_id']) ? $_GET['job_id'] : 'TMJB00418';

echo json_encode([
    'debug' => true,
    'job_id_input' => $jobIdString,
    'connection_status' => $conn ? 'Connected' : 'Not connected',
    'steps' => []
], JSON_PRETTY_PRINT);

if (!$conn) {
    die(json_encode(['error' => 'Database connection failed']));
}

$steps = [];

// Step 1: Get numeric job ID
$jobQuery = "SELECT id FROM jobs WHERE job_id = '" . $conn->real_escape_string($jobIdString) . "' LIMIT 1";
$steps[] = ['step' => 1, 'query' => $jobQuery];

$jobResult = $conn->query($jobQuery);

if (!$jobResult) {
    die(json_encode(['error' => 'Job query failed', 'sql_error' => $conn->error, 'steps' => $steps]));
}

if ($jobResult->num_rows === 0) {
    die(json_encode(['error' => 'Job not found', 'steps' => $steps]));
}

$jobRow = $jobResult->fetch_assoc();
$numericJobId = $jobRow['id'];
$steps[] = ['step' => 2, 'numeric_job_id' => $numericJobId];

// Step 2: Test the main query
$query = "SELECT 
    j.id AS job_id,
    j.job_title,
    j.transporter_id AS contractor_id,
    u.id AS driver_id,
    u.unique_id AS driver_tmid,
    u.name,
    u.mobile,
    u.email,
    u.city,
    u.states as state_id,
    s.name as state_name,
    u.images,
    u.Sex,
    COALESCE(vt.vehicle_name, u.vehicle_type) as vehicle_type,
    s2.name as preferred_location_name,
    u.Driving_Experience,
    u.Type_of_License,
    u.License_Number,
    u.Preferred_Location,
    u.Aadhar_Number,
    u.PAN_Number,
    u.GST_Number,
    u.status,
    u.Created_at,
    u.Updated_at,
    a.created_at as applied_at,
    p.amount as subscription_amount,
    p.created_at as subscription_start_date,
    p.end_at as subscription_end_date,
    p.payment_status as payment_status,
    p.payment_type as payment_type,
    cl.feedback as call_feedback,
    cl.match_status as match_status,
    cl.remark as feedback_notes,
    t.unique_id as transporter_tmid,
    t.name as transporter_name
FROM applyjobs a
INNER JOIN users u ON a.driver_id = u.id
INNER JOIN jobs j ON a.job_id = j.id
LEFT JOIN vehicle_type vt ON CAST(u.vehicle_type AS UNSIGNED) = vt.id
LEFT JOIN states s ON CAST(u.states AS UNSIGNED) = s.id
LEFT JOIN states s2 ON CAST(u.Preferred_Location AS UNSIGNED) = s2.id
LEFT JOIN (
    SELECT p1.*
    FROM payments p1
    INNER JOIN (
        SELECT unique_id, MAX(created_at) as max_created
        FROM payments
        WHERE payment_type = 'subscription' AND payment_status = 'captured'
        GROUP BY unique_id
    ) p2 ON p1.unique_id = p2.unique_id AND p1.created_at = p2.max_created
    WHERE p1.payment_type = 'subscription' AND p1.payment_status = 'captured'
) p ON u.unique_id = p.unique_id
LEFT JOIN (
    SELECT cl1.*
    FROM call_logs_match_making cl1
    INNER JOIN (
        SELECT unique_id_driver, job_id, MAX(created_at) as max_created
        FROM call_logs_match_making
        WHERE unique_id_driver IS NOT NULL AND unique_id_driver != ''
        GROUP BY unique_id_driver, job_id
    ) cl2 ON cl1.unique_id_driver = cl2.unique_id_driver 
          AND cl1.job_id = cl2.job_id 
          AND cl1.created_at = cl2.max_created
) cl ON u.unique_id = cl.unique_id_driver AND cl.job_id = '" . $conn->real_escape_string($jobIdString) . "'
LEFT JOIN users t ON j.transporter_id = t.id
WHERE a.job_id = $numericJobId
ORDER BY a.created_at DESC
LIMIT 5";

$steps[] = ['step' => 3, 'query_length' => strlen($query)];

$result = $conn->query($query);

if (!$result) {
    die(json_encode([
        'error' => 'Main query failed',
        'sql_error' => $conn->error,
        'steps' => $steps,
        'query' => $query
    ], JSON_PRETTY_PRINT));
}

$steps[] = ['step' => 4, 'rows_found' => $result->num_rows];

$applicants = [];
$rowCount = 0;

while ($row = $result->fetch_assoc()) {
    $rowCount++;
    
    // Just return the raw row data for first applicant
    if ($rowCount === 1) {
        $applicants[] = [
            'raw_data' => $row,
            'feedback_fields' => [
                'call_feedback' => $row['call_feedback'] ?? 'NOT_SET',
                'match_status' => $row['match_status'] ?? 'NOT_SET',
                'feedback_notes' => $row['feedback_notes'] ?? 'NOT_SET',
                'transporter_tmid' => $row['transporter_tmid'] ?? 'NOT_SET',
                'transporter_name' => $row['transporter_name'] ?? 'NOT_SET',
            ]
        ];
    }
}

echo json_encode([
    'success' => true,
    'steps' => $steps,
    'total_applicants' => $rowCount,
    'sample_applicant' => $applicants[0] ?? null
], JSON_PRETTY_PRINT);
?>
