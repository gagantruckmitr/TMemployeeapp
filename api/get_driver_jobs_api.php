<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

$driver_id = $_GET['driver_id'] ?? 0;

if (!$driver_id) {
    echo json_encode(['success' => false, 'error' => 'Driver ID required']);
    exit;
}

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Get Driver's Unique ID first
    $stmt = $pdo->prepare("SELECT unique_id FROM users WHERE id = ?");
    $stmt->execute([$driver_id]);
    $driver = $stmt->fetch();
    $driver_unique_id = $driver['unique_id'] ?? '';

    // Fetch Applied Jobs with Details
    $sql = "
        SELECT 
            aj.id as application_id,
            aj.job_id as numeric_job_id,
            aj.created_at as applied_date,
            aj.accept_reject_status as application_status,
            
            j.job_id as job_code,
            j.job_title,
            j.Salary_Range as salary,
            j.Created_at as job_post_date,
            j.transporter_id,
            j.assigned_to as assigned_admin_id,
            j.active_inactive as job_active_status,
            j.Application_Deadline,
            j.status as job_approval_status,
            
            t.name as transporter_name,
            t.unique_id as transporter_tmid,
            
            a.name as assigned_telecaller_name
            
        FROM applyjobs aj
        JOIN jobs j ON aj.job_id = j.id
        LEFT JOIN users t ON j.transporter_id = t.id
        LEFT JOIN admins a ON j.assigned_to = a.id
        WHERE aj.driver_id = ?
        ORDER BY aj.created_at DESC
    ";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$driver_id]);
    $jobs = $stmt->fetchAll();
    
    // Process each job to get Final Status and Call History
    foreach ($jobs as &$job) {
        $jobCode = $job['job_code'];
        
        // Fetch Match Making / Call Logs for this specific job application
        // We filter by job_id (string) and driver's unique_id
        $logSql = "
            SELECT 
                clm.created_at as call_time,
                a.name as caller_name,
                clm.call_recording as recording_url,
                '00:00' as duration,
                'Connected' as call_status,
                clm.feedback,
                clm.remark as remarks,
                clm.match_status
            FROM call_logs_match_making clm
            LEFT JOIN admins a ON clm.caller_id = a.id
            WHERE clm.unique_id_driver = ? 
            AND clm.job_id = ?
            ORDER BY clm.created_at DESC
        ";
        
        $logStmt = $pdo->prepare($logSql);
        $logStmt->execute([$driver_unique_id, $jobCode]);
        $logs = $logStmt->fetchAll();
        
        $job['call_history'] = $logs;
        
        // Determine Final Status
        // Logic: Check latest match_status or feedback
        $finalStatus = 'Pending';
        if (!empty($logs)) {
            $latestLog = $logs[0];
            if (!empty($latestLog['match_status'])) {
                $finalStatus = $latestLog['match_status'];
            } elseif (!empty($latestLog['feedback'])) {
                $finalStatus = $latestLog['feedback'];
            }
        }
        $job['final_status'] = $finalStatus;
        
        // Determine Tab Status (Active, Inactive, Expired, Closed)
        $tabStatus = 'Active';
        
        // Check for Closed status (if job_brief_table exists and has closed_job=1)
        // For now, we'll rely on active_inactive and deadline
        if ($job['job_active_status'] == 0) {
            $tabStatus = 'Inactive';
        } elseif (!empty($job['Application_Deadline']) && strtotime($job['Application_Deadline']) < time()) {
            $tabStatus = 'Expired';
        }
        
        // If final status indicates closed/joined/dropped, maybe move to Closed?
        // User asked for "Closed" tab. Let's assume if job is inactive it's closed, or if specific status.
        // For now:
        // Active: Active job, not expired
        // Inactive: Inactive job
        // Expired: Deadline passed
        // Closed: ?? Maybe manually closed. We'll map 'Inactive' to 'Closed' if needed or keep separate.
        
        $job['tab_status'] = $tabStatus;
    }
    
    echo json_encode(['success' => true, 'data' => $jobs]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
