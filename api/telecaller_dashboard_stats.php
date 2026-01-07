<?php
// Telecaller Dashboard Stats API
// Returns stats for a specific telecaller including pending leads
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once 'config.php';
require_once 'update_activity_middleware.php';

$callerId = (int)($_GET['caller_id'] ?? 1);
$period = $_GET['period'] ?? 'today'; // today, week, month, all

try {
    // Build date filter based on period - USING call_history table
    $dateFilter = "";
    switch($period) {
        case 'today':
            $dateFilter = "AND DATE(ch.created_at) = CURDATE()";
            break;
        case 'week':
            $dateFilter = "AND ch.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
            break;
        case 'month':
            $dateFilter = "AND ch.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            break;
        case 'year':
            $dateFilter = "AND ch.created_at >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
            break;
        case 'all':
        default:
            $dateFilter = "AND 1=1";
            break;
    }
    
    // 1. Get total assigned leads (users assigned to this telecaller)
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total_assigned
        FROM users 
        WHERE assigned_to = ? 
        AND role IN ('driver', 'transporter')
    ");
    $stmt->execute([$callerId]);
    $assignedData = $stmt->fetch();
    $totalAssigned = (int)$assignedData['total_assigned'];
    
    // 2. Get call history stats for this telecaller with period filter
    // USING call_history table with assigned_to field
    // call_history has enum: 'connected', 'not_connected', 'callback_later'
    
    // Get stats from call_history table
    $query = "
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN ch.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN ch.call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks_scheduled,
            SUM(CASE WHEN ch.call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected_calls,
            SUM(CASE 
                WHEN ch.call_feedback IS NOT NULL 
                AND ch.call_feedback != ''
                AND (LOWER(ch.call_feedback) LIKE '%agree%' 
                     OR LOWER(ch.call_feedback) LIKE '%demo%' 
                     OR LOWER(ch.call_feedback) LIKE '%subscribe%'
                     OR LOWER(ch.call_feedback) LIKE '%interested%')
                AND LOWER(ch.call_feedback) NOT LIKE '%not%interested%'
                THEN 1 ELSE 0 
            END) as interested_count
        FROM call_history ch
        WHERE ch.assigned_to = ?
        $dateFilter
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$callerId]);
    $callStats = $stmt->fetch();
    
    // Build date filter for call_logs_match_making (uses created_at column)
    $matchMakingDateFilter = "";
    switch($period) {
        case 'today':
            $matchMakingDateFilter = "AND DATE(clm.created_at) = CURDATE()";
            break;
        case 'week':
            $matchMakingDateFilter = "AND clm.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
            break;
        case 'month':
            $matchMakingDateFilter = "AND clm.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            break;
        case 'year':
            $matchMakingDateFilter = "AND clm.created_at >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
            break;
        case 'all':
        default:
            $matchMakingDateFilter = "AND 1=1";
            break;
    }
    
    // Second, get stats from call_logs_match_making table and map feedback to status
    $queryMatchMaking = "
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE 
                WHEN LOWER(clm.feedback) IN ('interview done', 'interview fixed', 'ready for interview', 
                                              'will confirm later', 'match making done', 'not interested', 'not selected')
                THEN 1 ELSE 0 
            END) as connected_calls,
            SUM(CASE 
                WHEN LOWER(clm.feedback) IN ('busy right now', 'call tomorrow morning', 
                                              'call in evening', 'call after 2 days')
                THEN 1 ELSE 0 
            END) as callbacks_scheduled,
            SUM(CASE 
                WHEN LOWER(clm.feedback) IN ('ringing', 'call busy', 'switched off', 
                                              'not reachable', 'disconnected')
                THEN 1 ELSE 0 
            END) as not_connected_calls,
            SUM(CASE 
                WHEN clm.feedback IS NOT NULL 
                AND clm.feedback != ''
                AND (LOWER(clm.feedback) LIKE '%interested%'
                     OR LOWER(clm.feedback) LIKE '%interview%'
                     OR LOWER(clm.feedback) LIKE '%ready%')
                AND LOWER(clm.feedback) NOT LIKE '%not%interested%'
                AND LOWER(clm.feedback) NOT LIKE '%not%selected%'
                THEN 1 ELSE 0 
            END) as interested_count
        FROM call_logs_match_making clm
        WHERE clm.caller_id = ?
        $matchMakingDateFilter
    ";
    $stmt = $pdo->prepare($queryMatchMaking);
    $stmt->execute([$callerId]);
    $matchMakingStats = $stmt->fetch();
    
    // Combine stats from both tables
    $totalCalls = (int)$callStats['total_calls'] + (int)$matchMakingStats['total_calls'];
    $connectedCalls = (int)$callStats['connected_calls'] + (int)$matchMakingStats['connected_calls'];
    $callbacksScheduled = (int)$callStats['callbacks_scheduled'] + (int)$matchMakingStats['callbacks_scheduled'];
    $notConnectedCalls = (int)$callStats['not_connected_calls'] + (int)$matchMakingStats['not_connected_calls'];
    $interestedCount = (int)$callStats['interested_count'] + (int)$matchMakingStats['interested_count'];
    
    // Verify: Total should equal Connected + Not Connected + Callbacks
    $calculatedTotal = $connectedCalls + $notConnectedCalls + $callbacksScheduled;
    if ($calculatedTotal !== $totalCalls) {
        error_log("WARNING: Total calls mismatch! Total: $totalCalls, Calculated: $calculatedTotal (Connected: $connectedCalls, Not Connected: $notConnectedCalls, Callbacks: $callbacksScheduled)");
    }
    
    // 3. Get unique users who have been called by THIS telecaller (with period filter)
    $query = "
        SELECT COUNT(DISTINCT ch.user_id) as called_users
        FROM call_history ch
        WHERE ch.assigned_to = ?
        AND ch.user_id IS NOT NULL
        $dateFilter
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$callerId]);
    $calledData = $stmt->fetch();
    $calledUsers = (int)$calledData['called_users'];
    
    // 4. Calculate pending leads - BULLETPROOF METHOD
    // Get users whose LATEST call (by ID, which is auto-increment) has status 'callback_later'
    // Using MAX(id) to get the absolute latest call for each user
    $query = "
        SELECT COUNT(*) as pending_count
        FROM (
            SELECT 
                ch.user_id,
                MAX(ch.id) as latest_call_id
            FROM call_history ch
            WHERE ch.assigned_to = ?
            AND ch.user_id IS NOT NULL
            GROUP BY ch.user_id
        ) latest_calls
        INNER JOIN call_history ch_status
            ON latest_calls.latest_call_id = ch_status.id
        WHERE ch_status.call_status = 'callback_later'
    ";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$callerId]);
    $pendingData = $stmt->fetch();
    $pendingCalls = (int)$pendingData['pending_count'];
    
    // 5. Calculate fresh leads from today-leads API (today's new leads assigned to this telecaller)
    // This matches what the Fresh Leads screen shows
    try {
        // Get token from Authorization header
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $token = null;
        
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
            if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
                $token = $matches[1];
            }
        }
        
        $freshLeads = 0;
        
        if ($token) {
            // Call today-leads API to get accurate count
            $ch = curl_init('https://truckmitr.com/api/telehead/today-leads');
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: Bearer ' . $token,
                'Accept: application/json'
            ]);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            if ($httpCode === 200) {
                $todayLeadsData = json_decode($response, true);
                
                // First try to get remaining_fresh from assigned_count array
                if (isset($todayLeadsData['assigned_count']) && is_array($todayLeadsData['assigned_count'])) {
                    foreach ($todayLeadsData['assigned_count'] as $assignedCount) {
                        if (isset($assignedCount['assigned_to']) && $assignedCount['assigned_to'] == $callerId) {
                            $freshLeads = (int)($assignedCount['remaining_fresh'] ?? 0);
                            break;
                        }
                    }
                }
                
                // Fallback: Count uncalled leads from data array
                if ($freshLeads === 0 && isset($todayLeadsData['data']) && is_array($todayLeadsData['data'])) {
                    foreach ($todayLeadsData['data'] as $lead) {
                        if (isset($lead['assigned_to']) && $lead['assigned_to'] == $callerId) {
                            // Only count if no call logs
                            $hasCallLogs = isset($lead['call_logs']) && is_array($lead['call_logs']) && count($lead['call_logs']) > 0;
                            if (!$hasCallLogs) {
                                $freshLeads++;
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback: If API call fails, use database query for uncalled assigned leads
        if ($freshLeads === 0) {
            $stmt = $pdo->prepare("
                SELECT COUNT(*) as fresh_count
                FROM users u
                WHERE u.role IN ('driver', 'transporter')
                AND u.assigned_to = ?
                AND u.id NOT IN (
                    SELECT DISTINCT user_id 
                    FROM call_history
                    WHERE assigned_to = ?
                    AND user_id IS NOT NULL
                )
            ");
            $stmt->execute([$callerId, $callerId]);
            $freshData = $stmt->fetch();
            $freshLeads = (int)$freshData['fresh_count'];
        }
    } catch (Exception $e) {
        error_log("Error fetching fresh leads count: " . $e->getMessage());
        $freshLeads = 0;
    }
    
    // 6. Get today's stats - FROM call_history table
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as calls_today,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_today
        FROM call_history 
        WHERE assigned_to = ?
        AND DATE(created_at) = CURDATE()
    ");
    $stmt->execute([$callerId]);
    $todayStats = $stmt->fetch();
    
    // From call_logs_match_making (still needed for match making calls)
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as calls_today,
            SUM(CASE 
                WHEN LOWER(feedback) IN ('interview done', 'interview fixed', 'ready for interview', 
                                         'will confirm later', 'match making done', 'not interested', 'not selected')
                THEN 1 ELSE 0 
            END) as connected_today
        FROM call_logs_match_making
        WHERE caller_id = ?
        AND DATE(created_at) = CURDATE()
    ");
    $stmt->execute([$callerId]);
    $todayMatchMakingStats = $stmt->fetch();
    
    // Combine today's stats
    $callsToday = (int)$todayStats['calls_today'] + (int)$todayMatchMakingStats['calls_today'];
    $connectedToday = (int)$todayStats['connected_today'] + (int)$todayMatchMakingStats['connected_today'];
    
    // 7. Calculate success rate
    $successRate = $totalCalls > 0 ? round(($connectedCalls / $totalCalls) * 100, 1) : 0;
    
    // 8. Get subscription count - Simple logic: users assigned to telecaller with captured payments
    // Build date filter for payments based on period
    $paymentDateFilter = "";
    switch($period) {
        case 'today':
            $paymentDateFilter = "AND DATE(p.created_at) = CURDATE()";
            break;
        case 'week':
            $paymentDateFilter = "AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
            break;
        case 'month':
            $paymentDateFilter = "AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            break;
        case 'year':
            $paymentDateFilter = "AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
            break;
        case 'all':
        default:
            $paymentDateFilter = "AND 1=1";
            break;
    }
    
    $stmt = $pdo->prepare("
        SELECT COUNT(DISTINCT p.id) as subscription_count
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_to = ?
        AND p.payment_status = 'captured'
        $paymentDateFilter
    ");
    $stmt->execute([$callerId]);
    $subscriptionData = $stmt->fetch();
    $subscriptionCount = (int)$subscriptionData['subscription_count'];
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_calls' => $totalCalls,
            'connected_calls' => $connectedCalls,
            'not_connected_calls' => $notConnectedCalls, // Calls with status 'callback'
            'pending_calls' => $pendingCalls, // Users with 'callback_later' status (actual callbacks)
            'fresh_leads' => $freshLeads, // Users never called
            'callbacks_scheduled' => $callbacksScheduled, // Same as pending_calls
            'interested_count' => $interestedCount,
            'calls_today' => $callsToday,
            'connected_today' => $connectedToday,
            'success_rate' => $successRate,
            'total_assigned' => $totalAssigned,
            'called_users' => $calledUsers,
            'subscription_count' => $subscriptionCount, // Users assigned with captured payments
        ],
        'caller_id' => $callerId,
        'period' => $period,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Failed to fetch dashboard stats: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
