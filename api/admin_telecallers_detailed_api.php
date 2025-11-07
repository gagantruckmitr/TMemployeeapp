<?php
// Admin Telecallers Detailed API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

try {
    // Simple query to get telecallers with comprehensive call stats
    $stmt = $pdo->prepare("SELECT 
        a.id,
        a.name,
        a.email,
        a.mobile as phone,
        a.created_at,
        a.role,
        'driver' as telecaller_type,
        1 as calling_level,
        
        -- Basic call stats using subquery to avoid complex GROUP BY issues
        COALESCE(call_stats.total_calls, 0) as total_calls,
        COALESCE(call_stats.connected_calls, 0) as connected_calls,
        COALESCE(call_stats.not_answered_calls, 0) as not_answered_calls,
        COALESCE(call_stats.pending_calls, 0) as pending_calls,
        COALESCE(call_stats.callback_calls, 0) as callback_calls,
        COALESCE(call_stats.not_interested_calls, 0) as not_interested_calls,
        COALESCE(call_stats.calls_today, 0) as calls_today,
        COALESCE(call_stats.calls_this_week, 0) as calls_this_week,
        COALESCE(call_stats.calls_this_month, 0) as calls_this_month,
        COALESCE(call_stats.total_assigned_leads, 0) as total_assigned_leads,
        COALESCE(call_stats.contacted_leads, 0) as contacted_leads,
        COALESCE(call_stats.avg_call_duration, 0) as avg_call_duration,
        COALESCE(call_stats.total_call_duration, 0) as total_call_duration,
        call_stats.last_call_time,
        COALESCE(call_stats.conversion_rate, 0) as conversion_rate,
        COALESCE(call_stats.contact_rate, 100) as contact_rate
        
    FROM admins a
    LEFT JOIN (
        SELECT 
            caller_id,
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN call_status IN ('not_reachable', 'failed', 'cancelled') THEN 1 ELSE 0 END) as not_answered_calls,
            SUM(CASE WHEN call_status = 'pending' THEN 1 ELSE 0 END) as pending_calls,
            SUM(CASE WHEN call_status IN ('callback', 'callback_later') THEN 1 ELSE 0 END) as callback_calls,
            SUM(CASE WHEN call_status = 'not_interested' THEN 1 ELSE 0 END) as not_interested_calls,
            SUM(CASE WHEN DATE(call_time) = CURDATE() THEN 1 ELSE 0 END) as calls_today,
            SUM(CASE WHEN YEARWEEK(call_time, 1) = YEARWEEK(CURDATE(), 1) THEN 1 ELSE 0 END) as calls_this_week,
            SUM(CASE WHEN YEAR(call_time) = YEAR(CURDATE()) AND MONTH(call_time) = MONTH(CURDATE()) THEN 1 ELSE 0 END) as calls_this_month,
            COUNT(DISTINCT user_id) as total_assigned_leads,
            COUNT(DISTINCT CASE WHEN user_id IS NOT NULL THEN user_id END) as contacted_leads,
            AVG(CASE WHEN call_duration > 0 THEN call_duration ELSE NULL END) as avg_call_duration,
            SUM(CASE WHEN call_duration > 0 THEN call_duration ELSE 0 END) as total_call_duration,
            MAX(call_time) as last_call_time,
            ROUND(
                SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) * 100.0 / 
                NULLIF(COUNT(*), 0), 
                1
            ) as conversion_rate,
            ROUND(
                COUNT(DISTINCT CASE WHEN user_id IS NOT NULL THEN user_id END) * 100.0 / 
                NULLIF(COUNT(DISTINCT user_id), 0), 
                1
            ) as contact_rate
        FROM call_logs
        GROUP BY caller_id
    ) call_stats ON a.id = call_stats.caller_id
    WHERE a.role = 'telecaller'
    ORDER BY call_stats.total_calls DESC");
    
    $stmt->execute();
    $result = $stmt->fetchAll();
    
    $telecallers = [];
    
    foreach ($result as $row) {
        // Format last call time
        $lastCallTime = $row['last_call_time'];
        $lastCallFormatted = 'Never';
        $status = 'inactive';
        
        if ($lastCallTime) {
            $timeAgo = time() - strtotime($lastCallTime);
            if ($timeAgo < 60) {
                $lastCallFormatted = 'Just now';
                $status = 'active';
            } elseif ($timeAgo < 3600) {
                $lastCallFormatted = floor($timeAgo / 60) . ' min ago';
                $status = 'active';
            } elseif ($timeAgo < 86400) {
                $lastCallFormatted = floor($timeAgo / 3600) . ' hours ago';
                $status = 'idle';
            } else {
                $lastCallFormatted = floor($timeAgo / 86400) . ' days ago';
                $status = 'inactive';
            }
        }
        
        // Format durations
        $avgDuration = (int)$row['avg_call_duration'];
        $avgDurationFormatted = $avgDuration > 0 ? gmdate("i:s", $avgDuration) : '00:00';
        
        $totalDuration = (int)$row['total_call_duration'];
        $hours = floor($totalDuration / 3600);
        $minutes = floor(($totalDuration % 3600) / 60);
        $totalDurationFormatted = sprintf("%02d:%02d", $hours, $minutes);
        
        $assignedLeads = (int)$row['total_assigned_leads'];
        $contactedLeads = (int)$row['contacted_leads'];
        
        $telecallers[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'created_at' => $row['created_at'],
            'status' => $status,
            'telecaller_type' => $row['telecaller_type'],
            'calling_level' => (int)$row['calling_level'],
            
            // Call metrics
            'total_calls' => (int)$row['total_calls'],
            'connected_calls' => (int)$row['connected_calls'],
            'not_answered_calls' => (int)$row['not_answered_calls'],
            'pending_calls' => (int)$row['pending_calls'],
            'callback_calls' => (int)$row['callback_calls'],
            'not_interested_calls' => (int)$row['not_interested_calls'],
            'calls_today' => (int)$row['calls_today'],
            'calls_this_week' => (int)$row['calls_this_week'],
            'calls_this_month' => (int)$row['calls_this_month'],
            
            // Lead metrics
            'total_assigned_leads' => $assignedLeads,
            'contacted_leads' => $contactedLeads,
            'uncontacted_leads' => max(0, $assignedLeads - $contactedLeads),
            
            // Duration metrics
            'avg_call_duration' => $avgDurationFormatted,
            'total_call_duration' => $totalDurationFormatted,
            'total_call_duration_seconds' => $totalDuration,
            
            // Rates
            'conversion_rate' => (float)$row['conversion_rate'],
            'contact_rate' => (float)$row['contact_rate'],
            
            // Activity
            'last_call_time' => $lastCallTime,
            'last_call_formatted' => $lastCallFormatted,
            
            // Empty trend data for now (can be added later if needed)
            'call_trend' => []
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $telecallers,
        'total' => count($telecallers)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
        'trace' => $e->getTraceAsString()
    ]);
}
