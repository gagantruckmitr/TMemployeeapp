<?php
// Enhanced Telehead Backlog API - Adds call history, jobs, and other details
// This wraps the telehead API and enhances each lead with additional data

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';

try {
    // Get Authorization header
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }
    
    if (!$token) {
        throw new Exception('Authorization token required');
    }
    
    // Decode JWT to get caller_id
    $tokenParts = explode('.', $token);
    if (count($tokenParts) !== 3) {
        throw new Exception('Invalid token format');
    }
    
    $payload = json_decode(base64_decode($tokenParts[1]), true);
    $callerId = $payload['sub'] ?? null;
    
    if (!$callerId) {
        throw new Exception('Caller ID not found in token');
    }
    
    // Call the telehead backlog API
    $ch = curl_init('https://truckmitr.com/api/telehead/backlog-leads');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception('Failed to fetch backlog from telehead API');
    }
    
    $backlogData = json_decode($response, true);
    
    if (!$backlogData || $backlogData['status'] !== true) {
        throw new Exception('Invalid response from telehead API');
    }
    
    // Enhance each lead with additional data
    // Filter leads by assigned telecaller
    $enhancedLeads = [];
    foreach ($backlogData['data'] as $lead) {
        $userId = $lead['id'];
        
        // Check if this lead is assigned to current telecaller
        $stmt = $pdo->prepare("
            SELECT assigned_to 
            FROM users 
            WHERE id = ?
        ");
        $stmt->execute([$userId]);
        $userAssignment = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Skip if not assigned to this telecaller
        if ($userAssignment && $userAssignment['assigned_to'] != $callerId) {
            continue;
        }
        
        // Get call history
        $stmt = $pdo->prepare("
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
        $stmt->execute([$userId]);
        $lead['call_history'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get applied jobs (for drivers)
        if ($lead['role'] === 'driver') {
            $stmt = $pdo->prepare("
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
            $stmt->execute([$userId]);
            $lead['applied_jobs'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        // Get posted jobs (for transporters)
        if ($lead['role'] === 'transporter') {
            $stmt = $pdo->prepare("
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
            $stmt->execute([$userId]);
            $lead['posted_jobs'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get match making history
            $stmt = $pdo->prepare("
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
            $stmt->execute([$userId]);
            $lead['match_making_history'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        // Get training info (for drivers)
        if ($lead['role'] === 'driver') {
            $stmt = $pdo->prepare("
                SELECT 
                    is_completed,
                    rating,
                    total_questions,
                    tier
                FROM training_progress
                WHERE user_id = ?
                LIMIT 1
            ");
            $stmt->execute([$userId]);
            $trainingInfo = $stmt->fetch(PDO::FETCH_ASSOC);
            $lead['training_info'] = $trainingInfo ?: null;
        }
        
        // Get last feedback and remarks from latest call
        $stmt = $pdo->prepare("
            SELECT feedback, remarks, call_time
            FROM call_logs
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $lastCall = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($lastCall) {
            $lead['last_feedback'] = $lastCall['feedback'];
            $lead['last_call_time'] = $lastCall['call_time'];
            if (!$lead['remarks']) {
                $lead['remarks'] = $lastCall['remarks'];
            }
        }
        
        $enhancedLeads[] = $lead;
    }
    
    // Return enhanced data with same structure and updated counts
    $backlogData['data'] = $enhancedLeads;
    $backlogData['total_backlog'] = count($enhancedLeads);
    $backlogData['filtered_by_telecaller'] = $callerId;
    
    echo json_encode($backlogData);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'message' => $e->getMessage()
    ]);
}
?>
