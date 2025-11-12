<?php
/**
 * Comprehensive diagnosis of call logs issues
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$diagnosis = [
    'call_logs_summary' => [],
    'recent_call_logs' => [],
    'jobs_with_applicants' => [],
    'transporter_lookup_test' => [],
    'recommendations' => []
];

try {
    // 1. Summary of call logs
    $summaryQuery = "SELECT 
        COUNT(*) as total_logs,
        SUM(CASE WHEN unique_id_transporter IS NULL OR unique_id_transporter = '' THEN 1 ELSE 0 END) as blank_transporter_tmid,
        SUM(CASE WHEN transporter_name IS NULL OR transporter_name = '' THEN 1 ELSE 0 END) as blank_transporter_name,
        SUM(CASE WHEN unique_id_driver IS NULL OR unique_id_driver = '' THEN 1 ELSE 0 END) as blank_driver_tmid,
        SUM(CASE WHEN driver_name IS NULL OR driver_name = '' THEN 1 ELSE 0 END) as blank_driver_name,
        SUM(CASE WHEN job_id IS NULL OR job_id = '' THEN 1 ELSE 0 END) as blank_job_id
    FROM call_logs_match_making";
    
    $result = $conn->query($summaryQuery);
    $diagnosis['call_logs_summary'] = $result->fetch_assoc();
    
    // 2. Recent call logs with details
    $recentQuery = "SELECT 
        id,
        caller_id,
        unique_id_driver,
        driver_name,
        unique_id_transporter,
        transporter_name,
        job_id,
        feedback,
        match_status,
        created_at
    FROM call_logs_match_making
    ORDER BY created_at DESC
    LIMIT 10";
    
    $result = $conn->query($recentQuery);
    while ($row = $result->fetch_assoc()) {
        $diagnosis['recent_call_logs'][] = $row;
    }
    
    // 3. Jobs with applicants and transporter info
    $jobsQuery = "SELECT 
        j.id,
        j.job_id,
        j.job_title,
        j.transporter_id,
        t.unique_id as transporter_tmid,
        t.name as transporter_name,
        t.role as transporter_role,
        COUNT(a.id) as applicant_count
    FROM jobs j
    LEFT JOIN users t ON j.transporter_id = t.id
    LEFT JOIN applyjobs a ON j.id = a.job_id
    GROUP BY j.id
    HAVING applicant_count > 0
    ORDER BY j.id DESC
    LIMIT 5";
    
    $result = $conn->query($jobsQuery);
    while ($row = $result->fetch_assoc()) {
        $diagnosis['jobs_with_applicants'][] = $row;
    }
    
    // 4. Test transporter lookup for call logs with job_id but no transporter
    $lookupQuery = "SELECT 
        clm.id as call_log_id,
        clm.job_id,
        clm.unique_id_transporter as current_transporter_tmid,
        j.transporter_id as job_transporter_id,
        u.unique_id as lookup_transporter_tmid,
        u.name as lookup_transporter_name,
        u.role as lookup_transporter_role
    FROM call_logs_match_making clm
    LEFT JOIN jobs j ON clm.job_id = j.job_id
    LEFT JOIN users u ON j.transporter_id = u.id
    WHERE (clm.unique_id_transporter IS NULL OR clm.unique_id_transporter = '')
    AND clm.job_id IS NOT NULL AND clm.job_id != ''
    LIMIT 5";
    
    $result = $conn->query($lookupQuery);
    while ($row = $result->fetch_assoc()) {
        $diagnosis['transporter_lookup_test'][] = $row;
    }
    
    // 5. Generate recommendations
    $summary = $diagnosis['call_logs_summary'];
    
    if ($summary['blank_transporter_tmid'] > 0) {
        $diagnosis['recommendations'][] = [
            'issue' => 'Blank transporter TMIDs',
            'count' => $summary['blank_transporter_tmid'],
            'solution' => 'Run cleanup script or check if jobs have transporter_id set'
        ];
    }
    
    if ($summary['blank_job_id'] > 0) {
        $diagnosis['recommendations'][] = [
            'issue' => 'Blank job IDs',
            'count' => $summary['blank_job_id'],
            'solution' => 'Ensure job_id is passed when submitting feedback'
        ];
    }
    
    // Check if jobs have transporter_id
    $jobsWithoutTransporter = 0;
    foreach ($diagnosis['jobs_with_applicants'] as $job) {
        if (empty($job['transporter_id']) || $job['transporter_id'] == 0) {
            $jobsWithoutTransporter++;
        }
    }
    
    if ($jobsWithoutTransporter > 0) {
        $diagnosis['recommendations'][] = [
            'issue' => 'Jobs missing transporter_id',
            'count' => $jobsWithoutTransporter,
            'solution' => 'Update jobs table to set transporter_id for each job',
            'critical' => true
        ];
    }
    
    // Check if transporter lookup would work
    $canLookup = 0;
    $cannotLookup = 0;
    foreach ($diagnosis['transporter_lookup_test'] as $test) {
        if (!empty($test['lookup_transporter_tmid'])) {
            $canLookup++;
        } else {
            $cannotLookup++;
        }
    }
    
    if ($canLookup > 0) {
        $diagnosis['recommendations'][] = [
            'issue' => 'Transporter info can be recovered',
            'count' => $canLookup,
            'solution' => 'Run the cleanup script to populate missing transporter info',
            'action' => 'https://truckmitr.com/truckmitr-app/api/admin_cleanup_call_logs.html'
        ];
    }
    
    if ($cannotLookup > 0) {
        $diagnosis['recommendations'][] = [
            'issue' => 'Transporter info cannot be recovered',
            'count' => $cannotLookup,
            'solution' => 'Jobs need transporter_id set first',
            'critical' => true
        ];
    }
    
    echo json_encode($diagnosis, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
