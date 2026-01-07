<?php
// Backlog Leads API - Get detailed backlog leads for a telecaller
// Returns full driver/transporter details for leads with callback_later status
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';

try {
    // Get caller_id from query params or Authorization header
    $callerId = null;
    
    // Check query parameter first
    if (isset($_GET['caller_id'])) {
        $callerId = (int)$_GET['caller_id'];
    }
    
    // Check Authorization header (Bearer token)
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
            // Verify token and get caller_id
            $stmt = $pdo->prepare("SELECT id FROM admins WHERE remember_token = ?");
            $stmt->execute([$token]);
            $user = $stmt->fetch();
            if ($user) {
                $callerId = (int)$user['id'];
            }
        }
    }
    
    if (!$callerId) {
        throw new Exception('Caller ID is required');
    }
    
    // Get users whose LATEST call has status 'callback_later'
    // Using MAX(id) to get the absolute latest call for each user
    $query = "
        SELECT 
            u.id,
            u.name,
            u.mobile,
            u.role,
            u.tmid,
            u.state,
            u.license_type,
            u.fleet_size,
            u.profile_picture,
            u.created_at as registration_date,
            u.assigned_to,
            u.last_feedback,
            u.remarks,
            cl_latest.call_status,
            cl_latest.feedback,
            cl_latest.remarks as call_remarks,
            cl_latest.call_time as last_call_time,
            COALESCE(pc.completion_percentage, 0) as profile_completion_percentage,
            COALESCE(pc.missing_fields, '') as missing_fields,
            (SELECT name FROM admins WHERE id = u.assigned_to) as assigned_telecaller_name,
            (SELECT COUNT(*) FROM call_logs WHERE user_id = u.id AND caller_id = ?) as total_calls,
            (SELECT payment_date FROM payments WHERE user_id = u.id ORDER BY payment_date DESC LIMIT 1) as subscription_date
        FROM (
            SELECT 
                cl.user_id,
                MAX(cl.id) as latest_call_id
            FROM call_logs cl
            WHERE cl.caller_id = ?
            AND cl.user_id IS NOT NULL
            GROUP BY cl.user_id
        ) latest_calls
        INNER JOIN call_logs cl_latest
            ON latest_calls.latest_call_id = cl_latest.id
        INNER JOIN users u
            ON latest_calls.user_id = u.id
        LEFT JOIN profile_completion pc
            ON u.id = pc.user_id
        WHERE cl_latest.call_status = 'callback_later'
        AND u.role IN ('driver', 'transporter')
        ORDER BY cl_latest.call_time DESC
    ";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute([$callerId, $callerId]);
    $backlogLeads = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Enhance each lead with additional details
    foreach ($backlogLeads as &$lead) {
        // Get call history
        $callHistoryStmt = $pdo->prepare("
            SELECT 
                cl.id,
                cl.call_time,
                cl.call_status,
                cl.call_duration,
                cl.feedback,
                cl.remarks,
                cl.call_type,
                cl.other_party_name,
                cl.other_party_tmid,
                cl.match_status,
                cl.job_id,
                a.name as telecaller_name
            FROM call_logs cl
            LEFT JOIN admins a ON cl.caller_id = a.id
            WHERE cl.user_id = ?
            ORDER BY cl.call_time DESC
            LIMIT 10
        ");
        $callHistoryStmt->execute([$lead['id']]);
        $lead['call_history'] = $callHistoryStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get applied jobs (for drivers)
        if ($lead['role'] === 'driver') {
            $jobsStmt = $pdo->prepare("
                SELECT 
                    j.id,
                    j.job_code,
                    j.job_title,
                    j.location,
                    j.salary,
                    j.posted_date,
                    ja.applied_date,
                    ja.status as application_status
                FROM job_applications ja
                INNER JOIN jobs j ON ja.job_id = j.id
                WHERE ja.driver_id = ?
                ORDER BY ja.applied_date DESC
                LIMIT 5
            ");
            $jobsStmt->execute([$lead['id']]);
            $lead['applied_jobs'] = $jobsStmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        // Get posted jobs (for transporters)
        if ($lead['role'] === 'transporter') {
            $postedJobsStmt = $pdo->prepare("
                SELECT 
                    j.id,
                    j.job_code,
                    j.job_title,
                    j.location,
                    j.salary,
                    j.posted_date,
                    (SELECT COUNT(*) FROM job_applications WHERE job_id = j.id) as applicant_count
                FROM jobs j
                WHERE j.transporter_id = ?
                ORDER BY j.posted_date DESC
                LIMIT 5
            ");
            $postedJobsStmt->execute([$lead['id']]);
            $lead['posted_jobs'] = $postedJobsStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get match making history
            $matchStmt = $pdo->prepare("
                SELECT 
                    mm.id,
                    mm.driver_id,
                    mm.match_date,
                    mm.status,
                    u.name as driver_name,
                    u.tmid as driver_tmid
                FROM match_making mm
                INNER JOIN users u ON mm.driver_id = u.id
                WHERE mm.transporter_id = ?
                ORDER BY mm.match_date DESC
                LIMIT 5
            ");
            $matchStmt->execute([$lead['id']]);
            $lead['match_making_history'] = $matchStmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        // Get training info (for drivers)
        if ($lead['role'] === 'driver') {
            $trainingStmt = $pdo->prepare("
                SELECT 
                    is_completed,
                    rating,
                    total_questions,
                    tier
                FROM training_progress
                WHERE user_id = ?
                LIMIT 1
            ");
            $trainingStmt->execute([$lead['id']]);
            $trainingInfo = $trainingStmt->fetch(PDO::FETCH_ASSOC);
            $lead['training_info'] = $trainingInfo ?: null;
        }
        
        // Get callback requests count
        $callbackStmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM callback_requests
            WHERE user_id = ?
        ");
        $callbackStmt->execute([$lead['id']]);
        $callbackCount = $callbackStmt->fetch(PDO::FETCH_ASSOC);
        $lead['callback_requests_count'] = (int)$callbackCount['count'];
        
        // Get callback history
        $callbackHistoryStmt = $pdo->prepare("
            SELECT 
                id,
                request_datetime,
                contact_reason,
                status,
                notes,
                assigned_to,
                (SELECT name FROM admins WHERE id = callback_requests.assigned_to) as assigned_telecaller
            FROM callback_requests
            WHERE user_id = ?
            ORDER BY request_datetime DESC
            LIMIT 5
        ");
        $callbackHistoryStmt->execute([$lead['id']]);
        $lead['callback_history'] = $callbackHistoryStmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    echo json_encode([
        'success' => true,
        'data' => $backlogLeads,
        'count' => count($backlogLeads),
        'caller_id' => $callerId,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
